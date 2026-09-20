#!/usr/bin/env bash
set -Eeuo pipefail

FIXTURE_DIGEST=aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
POSTGRES_IMAGE=postgres:17.6-alpine@sha256:ef257d85f76e48da1c64832459b59fcaba1a4dac97bf5d7450c77753542eee94
TEST_IMAGE=${KEYCLOAK_TEST_IMAGE:?set KEYCLOAK_TEST_IMAGE to the already-built candidate image}
TEST_PLATFORM=${KEYCLOAK_TEST_PLATFORM:-linux/amd64}
POSTGRES_CONTAINER="keycloak-preflight-postgres-$RANDOM-$$"
NETWORK="keycloak-preflight-network-$RANDOM-$$"
SECRET_DIR=$(mktemp -d)

cleanup() {
  docker rm -f "$POSTGRES_CONTAINER" >/dev/null 2>&1 || true
  docker network rm "$NETWORK" >/dev/null 2>&1 || true
  rm -rf "$SECRET_DIR"
}
trap cleanup EXIT

fail() {
  printf 'production preflight validation failure: %s\n' "$1" >&2
  exit 1
}

docker image inspect "$TEST_IMAGE" >/dev/null 2>&1 \
  || fail "candidate image is not built locally: $TEST_IMAGE"

chmod 0755 "$SECRET_DIR"
openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048 \
  -out "$SECRET_DIR/ca.key" >/dev/null 2>&1
openssl req -x509 -new -key "$SECRET_DIR/ca.key" -sha256 -days 1 \
  -subj '/CN=SKY LAB preflight CA' \
  -out "$SECRET_DIR/ca.crt" >/dev/null 2>&1
openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048 \
  -out "$SECRET_DIR/keycloak.key" >/dev/null 2>&1
openssl req -new -key "$SECRET_DIR/keycloak.key" \
  -subj '/CN=keycloak-preflight' \
  -out "$SECRET_DIR/keycloak.csr" >/dev/null 2>&1
openssl x509 -req -in "$SECRET_DIR/keycloak.csr" \
  -CA "$SECRET_DIR/ca.crt" -CAkey "$SECRET_DIR/ca.key" -CAcreateserial \
  -sha256 -days 1 -out "$SECRET_DIR/keycloak.crt" >/dev/null 2>&1
chmod 0644 "$SECRET_DIR/ca.crt" "$SECRET_DIR/keycloak.crt" "$SECRET_DIR/keycloak.key"

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
    -v "$SECRET_DIR:/run/secrets/native-bridge:ro" \
    -e KEYCLOAK_IMAGE_DIGEST="$FIXTURE_DIGEST" \
    -e KEYCLOAK_DB_HOST="$database_host" \
    -e KEYCLOAK_DB_PORT=5432 \
    -e KEYCLOAK_DB_NAME=keycloak \
    -e KEYCLOAK_DB_USERNAME=keycloak \
    -e ACCOUNT_CENTER_BASE_URL=https://my.yildizskylab.com \
    -e SKY_NATIVE_BRIDGE_REDEEM_URL=https://account-center-internal/internal/v1/native-handoff/redeem \
    -e SKY_NATIVE_BRIDGE_HMAC_SECRET=AQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQE \
    -e SKY_NATIVE_BRIDGE_TLS_CERT_FILE=/run/secrets/native-bridge/keycloak.crt \
    -e SKY_NATIVE_BRIDGE_TLS_KEY_FILE=/run/secrets/native-bridge/keycloak.key \
    -e SKY_NATIVE_BRIDGE_CA_CERT_FILE=/run/secrets/native-bridge/ca.crt \
    -e SKY_NATIVE_BRIDGE_TIMEOUT_MILLISECONDS=1500 \
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
if preflight_container shared-postgres \
  -e SKY_NATIVE_BRIDGE_REDEEM_URL=http://account-center-internal/internal/v1/native-handoff/redeem \
  >/dev/null 2>&1; then
  fail 'production preflight accepted a non-HTTPS native bridge endpoint'
fi
if preflight_container shared-postgres \
  -e SKY_NATIVE_BRIDGE_HMAC_SECRET=c2hvcnQ \
  >/dev/null 2>&1; then
  fail 'production preflight accepted a short native bridge HMAC secret'
fi
if preflight_container shared-postgres \
  -e SKY_NATIVE_BRIDGE_TLS_KEY_FILE=/run/secrets/native-bridge/missing.key \
  >/dev/null 2>&1; then
  fail 'production preflight accepted a missing native bridge client key'
fi

printf 'Production preflight accepts the reachable shared database and native bridge inputs, and rejects invalid inputs.\n'
