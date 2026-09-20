#!/usr/bin/env bash
set -Eeuo pipefail

expected_commit=${GITHUB_SHA:?GITHUB_SHA must identify the exact release commit}
approved_commit=${PHYSICAL_WEBAUTHN_APPROVED_COMMIT:-}
evidence_url=${PHYSICAL_WEBAUTHN_EVIDENCE_URL:-}
approved_surfaces=${PHYSICAL_WEBAUTHN_APPROVED_SURFACES:-}
required_surfaces='touch-id,face-id'

fail() {
  printf 'physical WebAuthn release gate failure: %s\n' "$1" >&2
  exit 1
}

[[ $approved_commit == "$expected_commit" ]] \
  || fail 'approval must name the exact candidate commit'
[[ $evidence_url =~ ^https://[^[:space:]]+$ ]] \
  || fail 'an HTTPS evidence URL is required'
[[ $approved_surfaces == "$required_surfaces" ]] \
  || fail "approved surfaces must record exactly the tested rollout scope: $required_surfaces"

printf 'Physical WebAuthn evidence is bound to candidate commit %s.\n' "$expected_commit"
