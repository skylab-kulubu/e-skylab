#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
FIXTURE_DIGEST=aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
POSTGRES_IMAGE=postgres:17.6-alpine@sha256:ef257d85f76e48da1c64832459b59fcaba1a4dac97bf5d7450c77753542eee94
TEST_IMAGE=${KEYCLOAK_TEST_IMAGE:?set KEYCLOAK_TEST_IMAGE to the already-built candidate image}
TEST_PLATFORM=${KEYCLOAK_TEST_PLATFORM:-linux/amd64}
INITIALIZED_DB_VOLUME="keycloak-preflight-initialized-$RANDOM-$$"
FABRICATED_DB_VOLUME="keycloak-preflight-fabricated-$RANDOM-$$"
POSTGRES_CONTAINER="keycloak-preflight-postgres-$RANDOM-$$"

cleanup() {
  docker rm -f "$POSTGRES_CONTAINER" >/dev/null 2>&1 || true
  docker volume rm "$INITIALIZED_DB_VOLUME" "$FABRICATED_DB_VOLUME" \
    >/dev/null 2>&1 || true
}
trap cleanup EXIT

fail() {
  printf 'production preflight validation failure: %s\n' "$1" >&2
  exit 1
}

docker image inspect "$TEST_IMAGE" >/dev/null 2>&1 \
  || fail "candidate image is not built locally: $TEST_IMAGE"

# Exercise the production preflight against the ownership and 0700 mode made by
# the pinned PostgreSQL Alpine entrypoint, not a host-created approximation.
docker volume create "$INITIALIZED_DB_VOLUME" >/dev/null
docker volume create "$FABRICATED_DB_VOLUME" >/dev/null
docker run -d --name "$POSTGRES_CONTAINER" \
  -e POSTGRES_DB=keycloak \
  -e POSTGRES_USER=keycloak \
  -e POSTGRES_PASSWORD=fixture-db-password \
  -v "$INITIALIZED_DB_VOLUME:/var/lib/postgresql/data" \
  -v "$SCRIPT_DIR/postgres-readiness-race.sql:/docker-entrypoint-initdb.d/00-readiness-race.sql:ro" \
  "$POSTGRES_IMAGE" >/dev/null
postgres_ready=false
temporary_server_observed=false
for _ in $(seq 1 60); do
  # initdb briefly starts a temporary PostgreSQL server before the entrypoint
  # replaces PID 1 with the durable server. pg_isready alone can observe that
  # temporary process and race its shutdown on a fast fresh runner.
  if docker exec "$POSTGRES_CONTAINER" pg_isready -U keycloak -d keycloak \
    >/dev/null 2>&1; then
    pid_one_name=$(docker exec "$POSTGRES_CONTAINER" cat /proc/1/comm)
    if [[ $pid_one_name == postgres ]]; then
      postgres_ready=true
      break
    fi
    temporary_server_observed=true
  fi
  if [[ $(docker inspect --format '{{.State.Running}}' "$POSTGRES_CONTAINER") != true ]]; then
    docker logs "$POSTGRES_CONTAINER" >&2 || true
    fail 'PostgreSQL permission fixture exited during initialization'
  fi
  sleep 1
done
[[ $temporary_server_observed == true ]] \
  || fail 'PostgreSQL fixture did not reproduce temporary init-server readiness'
if [[ $postgres_ready != true ]]; then
  docker logs "$POSTGRES_CONTAINER" >&2 || true
  fail 'PostgreSQL permission fixture did not reach its durable server'
fi
docker stop "$POSTGRES_CONTAINER" >/dev/null

pgdata_stat=$(docker run --rm --user 0:0 \
  -v "$INITIALIZED_DB_VOLUME:/fixture:ro" \
  "$POSTGRES_IMAGE" sh -c 'stat -c "%u:%g:%a" /fixture')
[[ $pgdata_stat == 70:70:700 ]] \
  || fail "PostgreSQL fixture did not reproduce UID/GID/mode 70:70:700 (got $pgdata_stat)"

# Recreate the exact old marker-only false positive: PG_VERSION, pg_control and
# one base directory. It must not be accepted as a PostgreSQL cluster.
docker run --rm --user 0:0 \
  -v "$FABRICATED_DB_VOLUME:/fixture" \
  "$POSTGRES_IMAGE" sh -eu -c '
    mkdir -p /fixture/global /fixture/base/1
    printf "17\n" > /fixture/PG_VERSION
    printf "fixture-control-file\n" > /fixture/global/pg_control
  '

preflight_container() {
  local volume_name=$1
  docker run --rm \
    --platform "$TEST_PLATFORM" \
    --entrypoint /opt/keycloak/config/preflight-production.sh \
    --user 0:0 \
    --read-only \
    --network none \
    --cap-drop ALL \
    --cap-add DAC_READ_SEARCH \
    --security-opt no-new-privileges:true \
    -e KEYCLOAK_IMAGE_DIGEST="$FIXTURE_DIGEST" \
    -e KEYCLOAK_DB_VOLUME_NAME="$volume_name" \
    -e KEYCLOAK_DATA_VOLUME_NAME=existing-keycloak-data \
    -e ACCOUNT_CENTER_BASE_URL=https://my.yildizskylab.com \
    -v "$volume_name:/mnt/keycloak-db:ro" \
    "$TEST_IMAGE"
}

preflight_container "$INITIALIZED_DB_VOLUME" >/dev/null
if preflight_container "$FABRICATED_DB_VOLUME" >/dev/null 2>&1; then
  fail 'production preflight accepted the marker-only fabricated volume'
fi

printf 'Production preflight accepts a real initialized cluster and rejects fabricated markers.\n'
