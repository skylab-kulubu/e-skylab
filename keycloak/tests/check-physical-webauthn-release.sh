#!/usr/bin/env bash
set -Eeuo pipefail

expected_commit=${GITHUB_SHA:?GITHUB_SHA must identify the exact release commit}
approved_commit=${PHYSICAL_WEBAUTHN_APPROVED_COMMIT:-}
evidence_url=${PHYSICAL_WEBAUTHN_EVIDENCE_URL:-}
approved_surfaces=${PHYSICAL_WEBAUTHN_APPROVED_SURFACES:-}
required_surfaces='touch-id,face-id,android-credential-manager,windows-hello,mobile-webview'

fail() {
  printf 'physical WebAuthn release gate failure: %s\n' "$1" >&2
  exit 1
}

[[ $approved_commit == "$expected_commit" ]] \
  || fail 'approval must name the exact candidate commit'
[[ $evidence_url =~ ^https://[^[:space:]]+$ ]] \
  || fail 'an HTTPS evidence URL is required'
[[ $approved_surfaces == "$required_surfaces" ]] \
  || fail "required surfaces must be recorded exactly as $required_surfaces"

printf 'Physical WebAuthn evidence is bound to candidate commit %s.\n' "$expected_commit"
