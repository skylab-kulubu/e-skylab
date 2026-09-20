#!/usr/bin/env bash
set -Eeuo pipefail

if [[ ${1:-} == get && " $* " == *'/protocol-mappers/models '* ]]; then
  printf 'Injected protocol-mapper read failure\n' >&2
  exit 42
fi

exec /opt/keycloak/bin/kcadm.sh "$@"
