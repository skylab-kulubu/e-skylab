#!/usr/bin/env bash
set -Eeuo pipefail

CONFIG_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=account-center-origin.sh
source "$CONFIG_DIR/account-center-origin.sh"

require() {
  local variable_name=$1
  if [[ -z ${!variable_name:-} ]]; then
    printf 'Missing required environment variable: %s\n' "$variable_name" >&2
    exit 1
  fi
}

require KEYCLOAK_IMAGE_DIGEST
require KEYCLOAK_DB_HOST
require KEYCLOAK_DB_PORT
require KEYCLOAK_DB_NAME
require KEYCLOAK_DB_USERNAME
require ACCOUNT_CENTER_BASE_URL

if [[ ! $KEYCLOAK_IMAGE_DIGEST =~ ^[0-9a-f]{64}$ ]]; then
  printf 'KEYCLOAK_IMAGE_DIGEST must be exactly 64 lowercase hexadecimal characters without a sha256: prefix\n' >&2
  exit 1
fi
if [[ ! $KEYCLOAK_DB_HOST =~ ^[A-Za-z0-9][A-Za-z0-9.-]*$ ]] ||
  [[ $KEYCLOAK_DB_HOST == localhost || $KEYCLOAK_DB_HOST == 127.0.0.1 ]]; then
  printf 'KEYCLOAK_DB_HOST must be a non-loopback DNS name or IPv4 address\n' >&2
  exit 1
fi
if [[ ! $KEYCLOAK_DB_PORT =~ ^[0-9]+$ ]] ||
  (( KEYCLOAK_DB_PORT < 1 || KEYCLOAK_DB_PORT > 65535 )); then
  printf 'KEYCLOAK_DB_PORT must be an integer from 1 through 65535\n' >&2
  exit 1
fi
for identifier_variable in KEYCLOAK_DB_NAME KEYCLOAK_DB_USERNAME; do
  identifier=${!identifier_variable}
  if [[ ! $identifier =~ ^[A-Za-z0-9][A-Za-z0-9_.-]*$ ]]; then
    printf '%s contains unsupported characters\n' "$identifier_variable" >&2
    exit 1
  fi
done
if [[ ${KEYCLOAK_DB_SCHEMA:-public} != public ]]; then
  printf 'KEYCLOAK_DB_SCHEMA must remain public for the existing production database\n' >&2
  exit 1
fi

normalize_account_center_base_url "$ACCOUNT_CENTER_BASE_URL" true >/dev/null
printf 'Production image, shared database endpoint and Account Center origin inputs are valid.\n'
