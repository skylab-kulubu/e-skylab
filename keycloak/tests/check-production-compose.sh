#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
KEYCLOAK_DIR=$(cd -- "$SCRIPT_DIR/.." && pwd)
COMPOSE_FILE="$KEYCLOAK_DIR/docker-compose.yml"
VALIDATOR="$KEYCLOAK_DIR/config/validate-production-inputs.sh"
FIXTURE_REPOSITORY=ghcr.io/skylab-kulubu/e-skylab-keycloak
FIXTURE_DIGEST=aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
FIXTURE_IMAGE="$FIXTURE_REPOSITORY@sha256:$FIXTURE_DIGEST"
POSTGRES_IMAGE=postgres:17.6-alpine@sha256:ef257d85f76e48da1c64832459b59fcaba1a4dac97bf5d7450c77753542eee94
FIXTURE_DB_VOLUME=existing-keycloak-postgres
FIXTURE_DATA_VOLUME=existing-keycloak-data

fail() {
  printf 'production compose validation failure: %s\n' "$1" >&2
  exit 1
}

production_env() {
  env \
    KEYCLOAK_IMAGE_DIGEST="$FIXTURE_DIGEST" \
    KEYCLOAK_DB_VOLUME_NAME="$FIXTURE_DB_VOLUME" \
    KEYCLOAK_DATA_VOLUME_NAME="$FIXTURE_DATA_VOLUME" \
    KEYCLOAK_HOSTNAME=https://e.yildizskylab.com \
    KEYCLOAK_PROXY_TRUSTED_ADDRESSES=172.30.0.0/24 \
    KEYCLOAK_DB_PASSWORD=fixture-db-password \
    KEYCLOAK_CONFIG_CLIENT_SECRET=fixture-config-secret \
    ACCOUNT_CENTER_BASE_URL=https://my.yildizskylab.com \
    RABBITMQ_HOST=rabbitmq \
    RABBITMQ_USERNAME=fixture-rabbit \
    RABBITMQ_PASSWORD=fixture-rabbit-password \
    "$@"
}

for missing_variable in \
  KEYCLOAK_IMAGE_DIGEST \
  KEYCLOAK_DB_VOLUME_NAME \
  KEYCLOAK_DATA_VOLUME_NAME \
  KEYCLOAK_PROXY_TRUSTED_ADDRESSES; do
  if production_env env -u "$missing_variable" \
    docker compose -f "$COMPOSE_FILE" config --quiet >/dev/null 2>&1; then
    fail "production compose accepted missing $missing_variable"
  fi
done

rendered_json=$(production_env \
  KEYCLOAK_IMAGE_REPOSITORY=attacker.invalid/substituted-image \
  KEYCLOAK_IMAGE_REF=attacker.invalid/substituted-image:latest \
  docker compose -f "$COMPOSE_FILE" config --format json)

jq -e --arg image "$FIXTURE_IMAGE" --arg postgres "$POSTGRES_IMAGE" '
  .services.keycloak.image == $image and
  .services["keycloak-config"].image == $image and
  .services["keycloak-preflight"].image == $image and
  .services["keycloak-db"].image == $postgres
' <<<"$rendered_json" >/dev/null \
  || fail 'rendered service images are not the exact source-controlled repositories and digests'

jq -e '
  .services["keycloak-preflight"].user == "0:0" and
  .services["keycloak-preflight"].read_only == true and
  .services["keycloak-preflight"].network_mode == "none" and
  .services["keycloak-preflight"].cap_drop == ["ALL"] and
  .services["keycloak-preflight"].cap_add == ["DAC_READ_SEARCH"] and
  .services["keycloak-preflight"].security_opt == ["no-new-privileges:true"] and
  (.services["keycloak-preflight"].environment | has("KEYCLOAK_IMAGE_REPOSITORY") | not) and
  .services["keycloak-preflight"].volumes == [{
    "type":"volume",
    "source":"keycloak_db_data",
    "target":"/mnt/keycloak-db",
    "read_only":true,
    "volume":{}
  }] and
  (.services.keycloak.user == null) and
  (.services["keycloak-config"].user == null)
' <<<"$rendered_json" >/dev/null \
  || fail 'preflight privilege or read-only isolation differs from the narrow contract'

jq -e '
  .services.keycloak.depends_on["keycloak-preflight"].condition == "service_completed_successfully" and
  .services.keycloak.depends_on["keycloak-db"].condition == "service_started" and
  .services["keycloak-config"].depends_on["keycloak-preflight"].condition == "service_completed_successfully" and
  .services["keycloak-config"].depends_on.keycloak.condition == "service_started" and
  .services["keycloak-db"].depends_on["keycloak-preflight"].condition == "service_completed_successfully"
' <<<"$rendered_json" >/dev/null \
  || fail 'service startup dependencies do not fail closed on preflight'

jq -e --arg db "$FIXTURE_DB_VOLUME" --arg data "$FIXTURE_DATA_VOLUME" '
  .volumes.keycloak_db_data == {"name":$db,"external":true} and
  .volumes.keycloak_data == {"name":$data,"external":true} and
  .networks.skynet.external == true and
  .networks["keycloak-db"].internal == true
' <<<"$rendered_json" >/dev/null \
  || fail 'external volume names or network boundaries differ from the exact contract'

jq -e '
  .services.keycloak.environment.KC_PROXY_TRUSTED_ADDRESSES == "172.30.0.0/24" and
  .services["keycloak-config"].environment.ACCOUNT_CENTER_REQUIRE_PRODUCTION_HOST == "true" and
  .services["keycloak-config"].environment.KEYCLOAK_CONFIG_CLIENT_SECRET == "fixture-config-secret" and
  ([.services[].environment // {} | keys[] | select(startswith("KC_BOOTSTRAP_ADMIN_"))] | length) == 0
' <<<"$rendered_json" >/dev/null \
  || fail 'proxy, reconciler or steady-state credential boundary differs'

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
  (.services["keycloak-bootstrap"].networks | keys | sort) == ["keycloak-db", "skynet"] and
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

printf 'Production and bootstrap Compose image, volume, proxy and reconciler boundaries are enforced.\n'
