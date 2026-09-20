#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
KEYCLOAK_DIR=$(cd -- "$SCRIPT_DIR/.." && pwd)
COMPOSE_FILE="$KEYCLOAK_DIR/docker-compose.yml"
VALIDATOR="$KEYCLOAK_DIR/config/validate-production-inputs.sh"
FIXTURE_REPOSITORY=ghcr.io/skylab-kulubu/e-skylab-keycloak
FIXTURE_DIGEST=aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
FIXTURE_IMAGE="$FIXTURE_REPOSITORY@sha256:$FIXTURE_DIGEST"
FIXTURE_DB_HOST=sky-lab-production-postgres-ik33fe
FIXTURE_SECRET_DIR=$(mktemp -d)

cleanup() {
  rm -rf "$FIXTURE_SECRET_DIR"
}
trap cleanup EXIT

chmod 0755 "$FIXTURE_SECRET_DIR"
printf '%s\n' \
  '-----BEGIN CERTIFICATE-----' \
  'fixture' \
  '-----END CERTIFICATE-----' \
  >"$FIXTURE_SECRET_DIR/ca.crt"
cp "$FIXTURE_SECRET_DIR/ca.crt" "$FIXTURE_SECRET_DIR/keycloak.crt"
printf '%s\n' \
  '-----BEGIN PRIVATE KEY-----' \
  'fixture' \
  '-----END PRIVATE KEY-----' \
  >"$FIXTURE_SECRET_DIR/keycloak.key"
chmod 0644 "$FIXTURE_SECRET_DIR"/*

fail() {
  printf 'production compose validation failure: %s\n' "$1" >&2
  exit 1
}

production_env() {
  env \
    KEYCLOAK_IMAGE_DIGEST="$FIXTURE_DIGEST" \
    KEYCLOAK_HOSTNAME=https://e.yildizskylab.com \
    KEYCLOAK_PROXY_TRUSTED_ADDRESSES=172.30.0.0/24 \
    KEYCLOAK_DB_HOST="$FIXTURE_DB_HOST" \
    KEYCLOAK_DB_PORT=5432 \
    KEYCLOAK_DB_NAME=keycloak \
    KEYCLOAK_DB_USERNAME=keycloak \
    KEYCLOAK_DB_PASSWORD=fixture-db-password \
    KEYCLOAK_DB_SCHEMA=public \
    KEYCLOAK_CONFIG_CLIENT_SECRET=fixture-config-secret \
    ACCOUNT_CENTER_BASE_URL=https://my.yildizskylab.com \
    SKY_NATIVE_BRIDGE_REDEEM_URL=https://account-center-internal/internal/v1/native-handoff/redeem \
    SKY_NATIVE_BRIDGE_HMAC_SECRET=AQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQE \
    SKY_NATIVE_BRIDGE_SECRETS_DIR="$FIXTURE_SECRET_DIR" \
    SKY_NATIVE_BRIDGE_TLS_CERT_FILE="$FIXTURE_SECRET_DIR/keycloak.crt" \
    SKY_NATIVE_BRIDGE_TLS_KEY_FILE="$FIXTURE_SECRET_DIR/keycloak.key" \
    SKY_NATIVE_BRIDGE_CA_CERT_FILE="$FIXTURE_SECRET_DIR/ca.crt" \
    SKY_NATIVE_BRIDGE_TIMEOUT_MILLISECONDS=1500 \
    RABBITMQ_HOST=rabbitmq \
    RABBITMQ_USERNAME=fixture-rabbit \
    RABBITMQ_PASSWORD=fixture-rabbit-password \
    "$@"
}

for missing_variable in \
  KEYCLOAK_IMAGE_DIGEST \
  KEYCLOAK_DB_HOST \
  KEYCLOAK_DB_USERNAME \
  KEYCLOAK_DB_PASSWORD \
  KEYCLOAK_PROXY_TRUSTED_ADDRESSES \
  SKY_NATIVE_BRIDGE_REDEEM_URL \
  SKY_NATIVE_BRIDGE_HMAC_SECRET \
  SKY_NATIVE_BRIDGE_SECRETS_DIR; do
  if production_env env -u "$missing_variable" \
    docker compose -f "$COMPOSE_FILE" config --quiet >/dev/null 2>&1; then
    fail "production compose accepted missing $missing_variable"
  fi
done

rendered_json=$(production_env \
  KEYCLOAK_IMAGE_REPOSITORY=attacker.invalid/substituted-image \
  KEYCLOAK_IMAGE_REF=attacker.invalid/substituted-image:latest \
  docker compose -f "$COMPOSE_FILE" config --format json)

jq -e --arg image "$FIXTURE_IMAGE" '
  .services.keycloak.image == $image and
  .services["keycloak-config"].image == $image and
  .services["keycloak-preflight"].image == $image and
  (.services | has("keycloak-db") | not)
' <<<"$rendered_json" >/dev/null \
  || fail 'production must use only the immutable custom image and the existing shared database'

jq -e --arg host "$FIXTURE_DB_HOST" --arg secrets "$FIXTURE_SECRET_DIR" '
  .services["keycloak-preflight"].user == "1000:0" and
  .services["keycloak-preflight"].read_only == true and
  .services["keycloak-preflight"].cap_drop == ["ALL"] and
  (.services["keycloak-preflight"] | has("cap_add") | not) and
  .services["keycloak-preflight"].security_opt == ["no-new-privileges:true"] and
  (.services["keycloak-preflight"].networks | keys) == ["skynet"] and
  .services["keycloak-preflight"].volumes == [{"type":"bind","source":$secrets,"target":"/run/secrets/native-bridge","read_only":true,"bind":{"create_host_path":true}}] and
  .services["keycloak-preflight"].environment.KEYCLOAK_DB_HOST == $host and
  (.services["keycloak-preflight"].environment | has("KEYCLOAK_DB_PASSWORD") | not) and
  .services["keycloak-preflight"].environment.SKY_NATIVE_BRIDGE_TLS_CERT_FILE == "/run/secrets/native-bridge/keycloak.crt" and
  .services["keycloak-preflight"].environment.SKY_NATIVE_BRIDGE_TLS_KEY_FILE == "/run/secrets/native-bridge/keycloak.key" and
  .services["keycloak-preflight"].environment.SKY_NATIVE_BRIDGE_CA_CERT_FILE == "/run/secrets/native-bridge/ca.crt" and
  (.services["keycloak-preflight"].environment | has("KEYCLOAK_IMAGE_REPOSITORY") | not) and
  (.services.keycloak.user == null) and
  (.services["keycloak-config"].user == null)
' <<<"$rendered_json" >/dev/null \
  || fail 'shared-database preflight isolation differs from the narrow contract'

jq -e '
  .services.keycloak.depends_on["keycloak-preflight"].condition == "service_completed_successfully" and
  (.services.keycloak.depends_on | length) == 1 and
  .services["keycloak-config"].depends_on["keycloak-preflight"].condition == "service_completed_successfully" and
  .services["keycloak-config"].depends_on.keycloak.condition == "service_started"
' <<<"$rendered_json" >/dev/null \
  || fail 'service startup dependencies do not fail closed on preflight'

jq -e '
  (.volumes // {}) == {} and
  (.networks | keys) == ["skynet"] and
  .networks.skynet.external == true and
  .networks.skynet.name == "skynet" and
  ([.services[] | (.networks | keys[])] | unique) == ["skynet"]
' <<<"$rendered_json" >/dev/null \
  || fail 'production compose must not own database, Keycloak data volumes or a private database network'

jq -e --arg host "$FIXTURE_DB_HOST" '
  .services.keycloak.environment.KC_PROXY_TRUSTED_ADDRESSES == "172.30.0.0/24" and
  .services.keycloak.environment.KC_DB_URL == ("jdbc:postgresql://" + $host + ":5432/keycloak") and
  .services.keycloak.environment.KC_DB_USERNAME == "keycloak" and
  .services.keycloak.environment.KC_DB_SCHEMA == "public" and
  .services["keycloak-config"].environment.ACCOUNT_CENTER_REQUIRE_PRODUCTION_HOST == "true" and
  .services["keycloak-config"].environment.KEYCLOAK_CONFIG_CLIENT_SECRET == "fixture-config-secret" and
  .services.keycloak.environment.SKY_NATIVE_BRIDGE_REDEEM_URL == "https://account-center-internal/internal/v1/native-handoff/redeem" and
  .services.keycloak.environment.SKY_NATIVE_BRIDGE_TLS_CERT_FILE == "/run/secrets/native-bridge/keycloak.crt" and
  .services.keycloak.environment.SKY_NATIVE_BRIDGE_TLS_KEY_FILE == "/run/secrets/native-bridge/keycloak.key" and
  .services.keycloak.environment.SKY_NATIVE_BRIDGE_CA_CERT_FILE == "/run/secrets/native-bridge/ca.crt" and
  ([.services[].environment // {} | keys[] | select(startswith("KC_BOOTSTRAP_ADMIN_"))] | length) == 0
' <<<"$rendered_json" >/dev/null \
  || fail 'database, proxy, reconciler or steady-state credential boundary differs'

production_env "$VALIDATOR" >/dev/null
for bad_digest in \
  latest \
  "sha256:$FIXTURE_DIGEST" \
  aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaag \
  aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa; do
  if production_env KEYCLOAK_IMAGE_DIGEST="$bad_digest" \
    "$VALIDATOR" >/dev/null 2>&1; then
    fail "invalid image digest was accepted: $bad_digest"
  fi
done
for bad_host in localhost 127.0.0.1 _invalid invalid/host; do
  if production_env KEYCLOAK_DB_HOST="$bad_host" "$VALIDATOR" >/dev/null 2>&1; then
    fail "invalid or loopback database host was accepted: $bad_host"
  fi
done
for bad_port in 0 65536 invalid; do
  if production_env KEYCLOAK_DB_PORT="$bad_port" "$VALIDATOR" >/dev/null 2>&1; then
    fail "invalid database port was accepted: $bad_port"
  fi
done
if production_env KEYCLOAK_DB_SCHEMA=private "$VALIDATOR" >/dev/null 2>&1; then
  fail 'unexpected database schema was accepted'
fi

bootstrap_json=$(production_env \
  KEYCLOAK_BOOTSTRAP_ADMIN_USERNAME=fixture-bootstrap-admin \
  KEYCLOAK_BOOTSTRAP_ADMIN_PASSWORD=fixture-bootstrap-password \
  docker compose \
    -f "$COMPOSE_FILE" \
    -f "$KEYCLOAK_DIR/docker-compose.bootstrap.yml" \
    --profile bootstrap \
    config --format json)

jq -e --arg image "$FIXTURE_IMAGE" '
  .services["keycloak-bootstrap"].image == $image and
  .services["keycloak-bootstrap"].pull_policy == "always" and
  .services["keycloak-bootstrap"].entrypoint == ["/opt/keycloak/config/bootstrap-reconciler.sh"] and
  .services["keycloak-bootstrap"].depends_on.keycloak.condition == "service_started" and
  (.services["keycloak-bootstrap"].networks | keys) == ["skynet"] and
  .services["keycloak-bootstrap"].restart == "no" and
  .services["keycloak-bootstrap"].environment == {
    "KEYCLOAK_ADMIN_REALM":"master",
    "KEYCLOAK_ADMIN_URL":"http://keycloak:8080",
    "KEYCLOAK_BOOTSTRAP_ADMIN_PASSWORD":"fixture-bootstrap-password",
    "KEYCLOAK_BOOTSTRAP_ADMIN_USERNAME":"fixture-bootstrap-admin",
    "KEYCLOAK_CONFIG_CLIENT_ID":"account-center-config",
    "KEYCLOAK_CONFIG_CLIENT_SECRET":"fixture-config-secret",
    "KEYCLOAK_REALM":"e-skylab"
  }
' <<<"$bootstrap_json" >/dev/null \
  || fail 'rendered bootstrap service differs from the exact image, credential or network contract'

printf 'Production Compose uses the shared PostgreSQL endpoint without owning its service or volumes.\n'
