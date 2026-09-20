#!/usr/bin/env bash
set -Eeuo pipefail

FIXTURE_DIGEST=aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
POSTGRES_IMAGE=postgres:17.6-alpine@sha256:ef257d85f76e48da1c64832459b59fcaba1a4dac97bf5d7450c77753542eee94
TEST_IMAGE=${KEYCLOAK_TEST_IMAGE:?set KEYCLOAK_TEST_IMAGE to the already-built candidate image}
TEST_PLATFORM=${KEYCLOAK_TEST_PLATFORM:-linux/amd64}
POSTGRES_CONTAINER="keycloak-preflight-postgres-$RANDOM-$$"
NETWORK="keycloak-preflight-network-$RANDOM-$$"

cleanup() {
  docker rm -f "$POSTGRES_CONTAINER" >/dev/null 2>&1 || true
  docker network rm "$NETWORK" >/dev/null 2>&1 || true
}
trap cleanup EXIT

fail() {
  printf 'production preflight validation failure: %s\n' "$1" >&2
  exit 1
}

docker image inspect "$TEST_IMAGE" >/dev/null 2>&1 \
  || fail "candidate image is not built locally: $TEST_IMAGE"

docker network create --internal "$NETWORK" >/dev/null
docker run -d --name "$POSTGRES_CONTAINER" \
  --network "$NETWORK" \
  --network-alias shared-postgres \
  -e POSTGRES_DB=keycloak \
  -e POSTGRES_USER=keycloak \
  -e POSTGRES_PASSWORD=fixture-db-password \
  "$POSTGRES_IMAGE" >/dev/null

postgres_ready=false
for _ in $(seq 1 60); do
  if docker exec "$POSTGRES_CONTAINER" pg_isready -U keycloak -d keycloak \
      >/dev/null 2>&1 &&
    [[ $(docker exec "$POSTGRES_CONTAINER" cat /proc/1/comm) == postgres ]]; then
    postgres_ready=true
    break
  fi
  if [[ $(docker inspect --format '{{.State.Running}}' "$POSTGRES_CONTAINER") != true ]]; then
    docker logs "$POSTGRES_CONTAINER" >&2 || true
    fail 'PostgreSQL endpoint fixture exited during initialization'
  fi
  sleep 1
done
if [[ $postgres_ready != true ]]; then
  docker logs "$POSTGRES_CONTAINER" >&2 || true
  fail 'PostgreSQL endpoint fixture did not reach its durable server'
fi

preflight_container() {
  local database_host=$1
  shift
  docker run --rm \
    --platform "$TEST_PLATFORM" \
    --network "$NETWORK" \
    --entrypoint /opt/keycloak/config/preflight-production.sh \
    --user 1000:0 \
    --read-only \
    --cap-drop ALL \
    --security-opt no-new-privileges:true \
    -e KEYCLOAK_IMAGE_DIGEST="$FIXTURE_DIGEST" \
    -e KEYCLOAK_DB_HOST="$database_host" \
    -e KEYCLOAK_DB_PORT=5432 \
    -e KEYCLOAK_DB_NAME=keycloak \
    -e KEYCLOAK_DB_USERNAME=keycloak \
    -e ACCOUNT_CENTER_BASE_URL=https://my.yildizskylab.com \
    "$@" \
    "$TEST_IMAGE"
}

preflight_container shared-postgres >/dev/null
if preflight_container missing-database >/dev/null 2>&1; then
  fail 'production preflight accepted an unreachable database endpoint'
fi
if preflight_container shared-postgres \
  -e KEYCLOAK_DB_CONNECT_TIMEOUT_SECONDS=0 >/dev/null 2>&1; then
  fail 'production preflight accepted an invalid connection timeout'
fi

printf 'Production preflight accepts the reachable shared database endpoint and rejects invalid inputs.\n'
