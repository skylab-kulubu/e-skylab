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
require SKY_NATIVE_BRIDGE_REDEEM_URL
require SKY_NATIVE_BRIDGE_HMAC_SECRET
require SKY_NATIVE_BRIDGE_TLS_CERT_FILE
require SKY_NATIVE_BRIDGE_TLS_KEY_FILE
require SKY_NATIVE_BRIDGE_CA_CERT_FILE
require SKY_NATIVE_BRIDGE_TIMEOUT_MILLISECONDS

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

if [[ ! $SKY_NATIVE_BRIDGE_REDEEM_URL =~ ^https://[A-Za-z0-9][A-Za-z0-9.-]*(:[0-9]{1,5})?/internal/v1/native-handoff/redeem$ ]]; then
  printf 'SKY_NATIVE_BRIDGE_REDEEM_URL must be the exact internal HTTPS redemption URL\n' >&2
  exit 1
fi
if [[ ! $SKY_NATIVE_BRIDGE_TIMEOUT_MILLISECONDS =~ ^[0-9]+$ ]] ||
  (( SKY_NATIVE_BRIDGE_TIMEOUT_MILLISECONDS < 100 || SKY_NATIVE_BRIDGE_TIMEOUT_MILLISECONDS > 5000 )); then
  printf 'SKY_NATIVE_BRIDGE_TIMEOUT_MILLISECONDS must be an integer from 100 through 5000\n' >&2
  exit 1
fi
if [[ ! $SKY_NATIVE_BRIDGE_HMAC_SECRET =~ ^[A-Za-z0-9+/_-]+={0,2}$ ]]; then
  printf 'SKY_NATIVE_BRIDGE_HMAC_SECRET must be base64 encoded\n' >&2
  exit 1
fi
normalized_secret=${SKY_NATIVE_BRIDGE_HMAC_SECRET//-/+}
normalized_secret=${normalized_secret//_/\/}
padding=$(( (4 - ${#normalized_secret} % 4) % 4 ))
case $padding in
  0) ;;
  1) normalized_secret+='=' ;;
  2) normalized_secret+='==' ;;
  *)
    printf 'SKY_NATIVE_BRIDGE_HMAC_SECRET must be base64 encoded\n' >&2
    exit 1
    ;;
esac
if ! decoded_secret_bytes=$(printf '%s' "$normalized_secret" | base64 --decode 2>/dev/null | wc -c); then
  printf 'SKY_NATIVE_BRIDGE_HMAC_SECRET must be base64 encoded\n' >&2
  exit 1
fi
decoded_secret_bytes=${decoded_secret_bytes//[[:space:]]/}
if (( decoded_secret_bytes < 32 )); then
  printf 'SKY_NATIVE_BRIDGE_HMAC_SECRET must decode to at least 32 bytes\n' >&2
  exit 1
fi

for certificate_file in SKY_NATIVE_BRIDGE_TLS_CERT_FILE SKY_NATIVE_BRIDGE_CA_CERT_FILE; do
  certificate_path=${!certificate_file}
  if [[ $certificate_path != /* || ! -r $certificate_path ]] ||
    ! grep -q '^-----BEGIN CERTIFICATE-----$' "$certificate_path"; then
    printf '%s must point to a readable absolute PEM certificate file\n' "$certificate_file" >&2
    exit 1
  fi
done
if [[ $SKY_NATIVE_BRIDGE_TLS_KEY_FILE != /* || ! -r $SKY_NATIVE_BRIDGE_TLS_KEY_FILE ]] ||
  ! grep -q '^-----BEGIN PRIVATE KEY-----$' "$SKY_NATIVE_BRIDGE_TLS_KEY_FILE"; then
  printf 'SKY_NATIVE_BRIDGE_TLS_KEY_FILE must point to a readable absolute unencrypted PKCS#8 PEM key\n' >&2
  exit 1
fi

printf 'Production image, shared database endpoint, Account Center origin and native bridge inputs are valid.\n'
