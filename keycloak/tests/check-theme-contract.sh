#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
KEYCLOAK_DIR=$(cd -- "$SCRIPT_DIR/.." && pwd)
THEME_DIR="$KEYCLOAK_DIR/theme"
THEME_JAR=${THEME_JAR:-$THEME_DIR/dist_keycloak/e-skylab-theme-2.0.0.jar}
THEME_JAR_DIR=$(cd -- "$(dirname -- "$THEME_JAR")" && pwd)
THEME_JAR="$THEME_JAR_DIR/$(basename -- "$THEME_JAR")"

fail() {
  printf 'theme contract failure: %s\n' "$1" >&2
  exit 1
}

[[ $(jq -r '.dependencies.keycloakify' "$THEME_DIR/package.json") == 11.16.0 ]] \
  || fail 'Keycloakify must stay pinned to 11.16.0 or a separately reviewed newer release'
[[ $(jq -r '.packages["node_modules/keycloakify"].version' "$THEME_DIR/package-lock.json") == 11.16.0 ]] \
  || fail 'package-lock does not resolve the reviewed Keycloakify release'

theme_jar_count=$(find "$THEME_JAR_DIR" -maxdepth 1 -type f -name '*.jar' -print | wc -l | tr -d ' ')
[[ $theme_jar_count == 1 ]] || fail 'theme build did not produce exactly one JAR'
actual_theme_jar=$(find "$THEME_JAR_DIR" -maxdepth 1 -type f -name '*.jar' -print)
[[ $actual_theme_jar == "$THEME_JAR" ]] || fail 'theme JAR has an unexpected name'

theme_entries=$(unzip -Z1 "$THEME_JAR")
[[ $(grep -c '^META-INF/keycloak-themes.json$' <<<"$theme_entries") == 1 ]] \
  || fail 'theme registry metadata is missing or duplicated'
[[ $(grep -c '^theme/e-skylab-theme/login/theme.properties$' <<<"$theme_entries") == 1 ]] \
  || fail 'the e-skylab-theme login theme is missing or duplicated'
[[ $(grep -c '^theme/e-skylab-theme/login/passkey-offer.ftl$' <<<"$theme_entries") == 1 ]] \
  || fail 'the branded passkey offer page is missing or duplicated'

theme_metadata=$(unzip -p "$THEME_JAR" META-INF/keycloak-themes.json)
jq -e '.themes == [{"name":"e-skylab-theme","types":["login"]}]' <<<"$theme_metadata" >/dev/null \
  || fail 'theme metadata exposes an unexpected name or theme type'

bundle_text=$(unzip -p "$THEME_JAR" 'theme/e-skylab-theme/login/resources/dist/assets/*.js')
for required_token in \
  residentKey \
  requireResidentKey \
  authenticatorAttachment \
  authenticationExecution \
  isSetRetry \
  rememberMe \
  '30 gün boyunca tekrar sorma' \
  mediation; do
  grep -Fq "$required_token" <<<"$bundle_text" \
    || fail "generated theme bundle lost $required_token"
done

if grep -Fq '\${execution}' <<<"$bundle_text"; then
  fail 'WebAuthn retry still contains the historical literal execution defect'
fi

grep -Fq '@media (prefers-reduced-motion: reduce)' "$THEME_DIR/src/login/theme.css" \
  || fail 'reduced-motion behavior is missing'
grep -Fq '.sl-button--secondary' "$THEME_DIR/src/login/theme.css" \
  || fail 'secondary button contrast contract is missing'
grep -Fq 'id="sl-main-content"' "$THEME_DIR/src/login/Template.tsx" \
  || fail 'semantic main landmark is missing'

printf 'Keycloak theme source, artifact and WebAuthn contracts passed.\n'
