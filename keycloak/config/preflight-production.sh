#!/usr/bin/env bash
set -Eeuo pipefail

CONFIG_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

"$CONFIG_DIR/validate-production-inputs.sh" >/dev/null

fail() {
  printf 'Shared PostgreSQL endpoint preflight failed: %s\n' "$1" >&2
  exit 1
}

probe_timeout=${KEYCLOAK_DB_CONNECT_TIMEOUT_SECONDS:-5}
[[ $probe_timeout =~ ^[1-9][0-9]*$ && $probe_timeout -le 30 ]] \
  || fail 'KEYCLOAK_DB_CONNECT_TIMEOUT_SECONDS must be an integer from 1 through 30'
command -v timeout >/dev/null 2>&1 \
  || fail 'candidate image does not contain the timeout utility'

if ! timeout "$probe_timeout" bash -c \
  'exec 3<>"/dev/tcp/$1/$2"' _ "$KEYCLOAK_DB_HOST" "$KEYCLOAK_DB_PORT"; then
  fail "cannot reach $KEYCLOAK_DB_HOST:$KEYCLOAK_DB_PORT"
fi

printf 'Production image, origin and shared PostgreSQL endpoint preflight passed.\n'
