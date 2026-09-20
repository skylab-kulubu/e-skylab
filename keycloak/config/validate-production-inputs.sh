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
require KEYCLOAK_DB_VOLUME_NAME
require KEYCLOAK_DATA_VOLUME_NAME
require ACCOUNT_CENTER_BASE_URL

if [[ ! $KEYCLOAK_IMAGE_DIGEST =~ ^[0-9a-f]{64}$ ]]; then
  printf 'KEYCLOAK_IMAGE_DIGEST must be exactly 64 lowercase hexadecimal characters without a sha256: prefix\n' >&2
  exit 1
fi
for volume_variable in KEYCLOAK_DB_VOLUME_NAME KEYCLOAK_DATA_VOLUME_NAME; do
  volume_name=${!volume_variable}
  if [[ ! $volume_name =~ ^[A-Za-z0-9][A-Za-z0-9_.-]+$ ]]; then
    printf '%s is not an explicit Docker volume name\n' "$volume_variable" >&2
    exit 1
  fi
done
if [[ $KEYCLOAK_DB_VOLUME_NAME == "$KEYCLOAK_DATA_VOLUME_NAME" ]]; then
  printf 'Database and Keycloak data volumes must be different\n' >&2
  exit 1
fi

normalize_account_center_base_url "$ACCOUNT_CENTER_BASE_URL" true >/dev/null
printf 'Production image, volume and Account Center origin inputs are valid.\n'
