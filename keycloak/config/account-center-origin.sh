#!/usr/bin/env bash

normalize_account_center_base_url() {
  local raw_url=${1:-}
  local require_production_host=${2:-false}
  local host port normalized

  case "$require_production_host" in
    true|false) ;;
    *)
      printf 'ACCOUNT_CENTER_REQUIRE_PRODUCTION_HOST must be true or false\n' >&2
      return 1
      ;;
  esac

  if [[ ! $raw_url =~ ^https://([A-Za-z0-9]([A-Za-z0-9.-]*[A-Za-z0-9])?)(:([0-9]{1,5}))?/?$ ]]; then
    printf 'ACCOUNT_CENTER_BASE_URL must be one HTTPS origin without userinfo, path, query, fragment or wildcard\n' >&2
    return 1
  fi

  host=${BASH_REMATCH[1]}
  port=${BASH_REMATCH[4]:-}
  if [[ $host == *..* || $host == *.-* || $host == *-. ]]; then
    printf 'ACCOUNT_CENTER_BASE_URL contains an invalid host\n' >&2
    return 1
  fi
  if [[ -n $port ]] && ((10#$port < 1 || 10#$port > 65535)); then
    printf 'ACCOUNT_CENTER_BASE_URL contains an invalid port\n' >&2
    return 1
  fi

  normalized=${raw_url%/}
  if [[ $require_production_host == true && $normalized != https://my.yildizskylab.com ]]; then
    printf 'Production ACCOUNT_CENTER_BASE_URL must be exactly https://my.yildizskylab.com\n' >&2
    return 1
  fi

  printf '%s\n' "$normalized"
}
