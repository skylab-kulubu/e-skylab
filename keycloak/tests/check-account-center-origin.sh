#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=../config/account-center-origin.sh
source "$SCRIPT_DIR/../config/account-center-origin.sh"

fail() {
  printf 'Account Center origin validation failure: %s\n' "$1" >&2
  exit 1
}

[[ $(normalize_account_center_base_url https://my.yildizskylab.com true) == \
  https://my.yildizskylab.com ]] \
  || fail 'the exact production origin was rejected'
[[ $(normalize_account_center_base_url https://my.yildizskylab.com/ true) == \
  https://my.yildizskylab.com ]] \
  || fail 'a root-only trailing slash was not normalized'
[[ $(normalize_account_center_base_url https://preview.example.test:8443/ false) == \
  https://preview.example.test:8443 ]] \
  || fail 'a valid non-production HTTPS origin was rejected'

malicious_origins=(
  'http://my.yildizskylab.com'
  'https://user@my.yildizskylab.com'
  'https://my.yildizskylab.com/admin'
  'https://my.yildizskylab.com//'
  'https://my.yildizskylab.com?next=https://attacker.invalid'
  'https://my.yildizskylab.com#fragment'
  'https://*.yildizskylab.com'
  'https://my.yildizskylab.com.evil.invalid'
  'https://evil-my.yildizskylab.com'
  'https://my.yildizskylab.com:443'
  'https://my..yildizskylab.com'
  'https://-my.yildizskylab.com'
  'https://my.yildizskylab.com:99999'
)
for malicious_origin in "${malicious_origins[@]}"; do
  if normalize_account_center_base_url "$malicious_origin" true >/dev/null 2>&1; then
    fail "malicious production origin was accepted: $malicious_origin"
  fi
done

printf 'Account Center HTTPS origin validation cases passed.\n'
