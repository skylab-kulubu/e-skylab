#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
TEST_IMAGE=${KEYCLOAK_TEST_IMAGE:?set KEYCLOAK_TEST_IMAGE to the already-built candidate image}
COMPOSE_FILE="$SCRIPT_DIR/docker-compose.integration.yml"
COMPOSE=(docker compose -f "$COMPOSE_FILE")
KCADM=("${COMPOSE[@]}" exec -T keycloak /opt/keycloak/bin/kcadm.sh)
ADMIN_CONFIG=/tmp/integration-kcadm.config
TEST_STATE_DIR=$(mktemp -d)
CURRENT_STAGE=startup
export TEST_STATE_DIR

cleanup() {
  "${COMPOSE[@]}" down --volumes --remove-orphans >/dev/null 2>&1 || true
  rm -rf "$TEST_STATE_DIR"
}
trap 'exit_code=$?; trap - EXIT; cleanup; exit "$exit_code"' EXIT

docker image inspect "$TEST_IMAGE" >/dev/null 2>&1 || {
  printf 'integration candidate image is not built locally: %s\n' "$TEST_IMAGE" >&2
  exit 1
}

trap 'status=$?; printf "integration command failed during %s (line %s)\n" "$CURRENT_STAGE" "$LINENO" >&2; exit "$status"' ERR

CURRENT_STAGE='native bridge test identity setup'
native_bridge_dir="$TEST_STATE_DIR/native-bridge"
mkdir -p "$native_bridge_dir"
chmod 0755 "$native_bridge_dir"
openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048 \
  -out "$native_bridge_dir/ca.key" >/dev/null 2>&1
openssl req -x509 -new -key "$native_bridge_dir/ca.key" -sha256 -days 1 \
  -subj '/CN=SKY LAB native bridge integration CA' \
  -out "$native_bridge_dir/ca.crt" >/dev/null 2>&1
openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048 \
  -out "$native_bridge_dir/server.key" >/dev/null 2>&1
openssl req -new -key "$native_bridge_dir/server.key" \
  -subj '/CN=native-bridge' \
  -out "$native_bridge_dir/server.csr" >/dev/null 2>&1
printf 'subjectAltName=DNS:native-bridge\nextendedKeyUsage=serverAuth\n' \
  >"$native_bridge_dir/server.ext"
openssl x509 -req -in "$native_bridge_dir/server.csr" \
  -CA "$native_bridge_dir/ca.crt" -CAkey "$native_bridge_dir/ca.key" \
  -CAcreateserial -sha256 -days 1 -extfile "$native_bridge_dir/server.ext" \
  -out "$native_bridge_dir/server.crt" >/dev/null 2>&1
openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048 \
  -out "$native_bridge_dir/keycloak.key" >/dev/null 2>&1
openssl req -new -key "$native_bridge_dir/keycloak.key" \
  -subj '/CN=keycloak-native-bridge' \
  -out "$native_bridge_dir/keycloak.csr" >/dev/null 2>&1
printf 'extendedKeyUsage=clientAuth\n' >"$native_bridge_dir/keycloak.ext"
openssl x509 -req -in "$native_bridge_dir/keycloak.csr" \
  -CA "$native_bridge_dir/ca.crt" -CAkey "$native_bridge_dir/ca.key" \
  -CAcreateserial -sha256 -days 1 -extfile "$native_bridge_dir/keycloak.ext" \
  -out "$native_bridge_dir/keycloak.crt" >/dev/null 2>&1
chmod 0644 "$native_bridge_dir/ca.crt" \
  "$native_bridge_dir/server.crt" "$native_bridge_dir/server.key" \
  "$native_bridge_dir/keycloak.crt" "$native_bridge_dir/keycloak.key"
export NATIVE_BRIDGE_HMAC_SECRET
NATIVE_BRIDGE_HMAC_SECRET=$(openssl rand -base64 32 | tr -d '\n')
export NATIVE_BRIDGE_CLIENT_SHA256
NATIVE_BRIDGE_CLIENT_SHA256=$(openssl x509 \
  -in "$native_bridge_dir/keycloak.crt" -outform DER \
  | openssl dgst -sha256 -r \
  | awk '{print $1}')
export NATIVE_BRIDGE_AUTH_TIME
NATIVE_BRIDGE_AUTH_TIME=$(( $(date -u +%s) - 3600 ))

"$SCRIPT_DIR/check-version-consistency.sh"
"$SCRIPT_DIR/check-fresh-runner.sh"
"$SCRIPT_DIR/check-production-preflight.sh"
"$SCRIPT_DIR/check-account-center-origin.sh"

fail() {
  if [[ $CURRENT_STAGE == 'native handoff real Keycloak SSO contract' ]]; then
    printf 'native authorization diagnostic: status=%s url=%s\n' \
      "${AUTHORIZATION_RESULT_STATUS:-unset}" \
      "${AUTHORIZATION_RESULT_URL:-unset}" >&2
    if [[ -n ${AUTHORIZATION_RESULT_BODY:-} && -f $AUTHORIZATION_RESULT_BODY ]]; then
      sed -E \
        -e 's/A{43}/[REDACTED-BRIDGE-CODE]/g' \
        -e 's/U{43}/[REDACTED-BRIDGE-CODE]/g' \
        -e 's/D{43}/[REDACTED-BRIDGE-CODE]/g' \
        "$AUTHORIZATION_RESULT_BODY" \
        | head -c 2000 >&2 || true
      printf '\n' >&2
    fi
    "${COMPOSE[@]}" logs --no-color --tail=120 keycloak native-bridge >&2 || true
  fi
  printf 'integration failure: %s\n' "$1" >&2
  exit 1
}

wait_for_url() {
  local url=$1
  local attempt
  for attempt in $(seq 1 90); do
    if curl --fail --silent --show-error "$url" >/dev/null 2>&1; then
      return 0
    fi
    sleep 2
  done
  fail "timed out waiting for $url"
}

json_assert() {
  local json=$1
  local expression=$2
  local message=$3
  shift 3
  jq -e "$@" "$expression" <<<"$json" >/dev/null || fail "$message"
}

walk_authorization_redirects() {
  local label=$1
  local current_url=$2
  local cookie_file=$3
  local attempt status location
  AUTHORIZATION_RESULT_URL=''
  AUTHORIZATION_RESULT_STATUS=''
  AUTHORIZATION_RESULT_BODY=''
  AUTHORIZATION_RESULT_HEADERS=''
  for attempt in $(seq 1 12); do
    AUTHORIZATION_RESULT_BODY="$TEST_STATE_DIR/$label-$attempt.body"
    AUTHORIZATION_RESULT_HEADERS="$TEST_STATE_DIR/$label-$attempt.headers"
    status=$(curl --silent --show-error \
      --output "$AUTHORIZATION_RESULT_BODY" \
      --dump-header "$AUTHORIZATION_RESULT_HEADERS" \
      --write-out '%{http_code}' \
      --cookie-jar "$cookie_file" \
      --cookie "$cookie_file" \
      "$current_url")
    location=$(awk '
      tolower($1) == "location:" {
        sub(/^[^:]*:[[:space:]]*/, "")
        sub(/\r$/, "")
        print
      }
    ' "$AUTHORIZATION_RESULT_HEADERS")
    if [[ $location == https://my.yildizskylab.com/api/auth/callback?* ]]; then
      AUTHORIZATION_RESULT_URL=$location
      AUTHORIZATION_RESULT_STATUS=$status
      return 0
    fi
    if [[ $status =~ ^30[12378]$ && $location == http://localhost:18080/* ]]; then
      current_url=$location
      continue
    fi
    if [[ $status =~ ^30[12378]$ && $location == /* ]]; then
      current_url="http://localhost:18080$location"
      continue
    fi
    AUTHORIZATION_RESULT_URL=$current_url
    AUTHORIZATION_RESULT_STATUS=$status
    return 0
  done
  fail "authorization redirect chain exceeded its bounded length for $label"
}

"${COMPOSE[@]}" up -d postgres rabbitmq native-bridge keycloak
CURRENT_STAGE='Keycloak readiness'
wait_for_url http://localhost:19000/health/ready
for _ in $(seq 1 60); do
  if "${COMPOSE[@]}" logs native-bridge 2>&1 | grep -Fq 'Native bridge fixture is ready.'; then
    break
  fi
  sleep 1
done
"${COMPOSE[@]}" logs native-bridge 2>&1 \
  | grep -Fq 'Native bridge fixture is ready.' \
  || fail 'native bridge fixture did not become ready'

"${KCADM[@]}" config credentials \
  --config "$ADMIN_CONFIG" \
  --server http://localhost:8080 \
  --realm master \
  --user admin \
  --password integration-admin-password >/dev/null

kcadm() {
  local command=$1
  shift
  "${KCADM[@]}" "$command" --config "$ADMIN_CONFIG" "$@"
}

CURRENT_STAGE='scoped reconciler bootstrap'
"${COMPOSE[@]}" run --rm --no-deps keycloak-bootstrap >/dev/null

# Capture the immutable built-in scope inventory before reconciliation. This
# catches accidental fallback to an arbitrary scope when exact lookup fails.
built_in_scope_snapshot=$(kcadm get client-scopes -r e-skylab-test -c \
  | jq -c '[.[] | {id, name}] | sort_by(.id)')

CURRENT_STAGE='first reconciliation'
"${COMPOSE[@]}" run --rm --no-deps keycloak-config >/dev/null

# Inject drift before the second pass. Reconciliation must repair the existing
# realm, flow, scope and allowlists rather than merely treating names as success.
client_uuid=$(kcadm get clients -r e-skylab-test -c \
  | jq -r '.[] | select(.clientId == "account-center") | .id')
drift_scope_uuid=$(kcadm get client-scopes -r e-skylab-test -c \
  | jq -r '.[] | select(.name == "account-center-account-api") | .id')
core_scope_uuid=$(kcadm get client-scopes -r e-skylab-test -c \
  | jq -r '.[] | select(.name == "account-center-core-claims") | .id')
drift_mapper_uuid=$(kcadm get "client-scopes/$drift_scope_uuid/protocol-mappers/models" \
  -r e-skylab-test -c \
  | jq -r '.[] | select(.name == "account-api-audience") | .id')
kcadm update "client-scopes/$drift_scope_uuid" -r e-skylab-test \
  -s 'attributes."include.in.token.scope"=true' >/dev/null
kcadm update "client-scopes/$drift_scope_uuid/protocol-mappers/models/$drift_mapper_uuid" \
  -r e-skylab-test \
  -s 'config."included.client.audience"=wrong-audience' >/dev/null
kcadm create "client-scopes/$drift_scope_uuid/protocol-mappers/models" \
  -r e-skylab-test \
  -b '{"name":"unexpected-account-mapper","protocol":"openid-connect","protocolMapper":"oidc-hardcoded-claim-mapper","config":{"claim.name":"unexpected","claim.value":"true","jsonType.label":"boolean","access.token.claim":"true"}}' >/dev/null
core_auth_time_mapper_uuid=$(kcadm get \
  "client-scopes/$core_scope_uuid/protocol-mappers/models" \
  -r e-skylab-test -c \
  | jq -r '.[] | select(.name == "auth_time") | .id')
kcadm update \
  "client-scopes/$core_scope_uuid/protocol-mappers/models/$core_auth_time_mapper_uuid" \
  -r e-skylab-test \
  -s 'config."claim.name"=wrong_auth_time' \
  -s 'config."id.token.claim"=false' >/dev/null
kcadm create "client-scopes/$core_scope_uuid/protocol-mappers/models" \
  -r e-skylab-test \
  -b '{"name":"email-drift","protocol":"openid-connect","protocolMapper":"oidc-usermodel-property-mapper","config":{"user.attribute":"email","claim.name":"email","id.token.claim":"true","access.token.claim":"true"}}' >/dev/null
skyapp_client_uuid=$(kcadm get clients -r e-skylab-test -c \
  | jq -r '.[] | select(.clientId == "skyapp") | .id')
skyapp_scope_uuid=$(kcadm get client-scopes -r e-skylab-test -c \
  | jq -r '.[] | select(.name == "skyapp-account-center-audience") | .id')
skyapp_mapper_uuid=$(kcadm get \
  "client-scopes/$skyapp_scope_uuid/protocol-mappers/models" \
  -r e-skylab-test -c \
  | jq -r '.[] | select(.name == "account-center-audience") | .id')
kcadm update \
  "client-scopes/$skyapp_scope_uuid/protocol-mappers/models/$skyapp_mapper_uuid" \
  -r e-skylab-test \
  -s 'config."included.client.audience"=wrong-audience' >/dev/null
kcadm create "client-scopes/$skyapp_scope_uuid/protocol-mappers/models" \
  -r e-skylab-test \
  -b '{"name":"unexpected-skyapp-mapper","protocol":"openid-connect","protocolMapper":"oidc-hardcoded-claim-mapper","config":{"claim.name":"unexpected","claim.value":"true","jsonType.label":"boolean","access.token.claim":"true"}}' >/dev/null
kcadm delete "clients/$skyapp_client_uuid/default-client-scopes/$skyapp_scope_uuid" \
  -r e-skylab-test >/dev/null
profile_scope_uuid=$(kcadm get client-scopes -r e-skylab-test -c \
  | jq -r '.[] | select(.name == "profile") | .id')
kcadm update "clients/$client_uuid/default-client-scopes/$profile_scope_uuid" \
  -r e-skylab-test -n -b '{}' >/dev/null
email_scope_uuid=$(kcadm get client-scopes -r e-skylab-test -c \
  | jq -r '.[] | select(.name == "email") | .id')
kcadm update "clients/$client_uuid/default-client-scopes/$email_scope_uuid" \
  -r e-skylab-test -n -b '{}' >/dev/null
address_scope_uuid=$(kcadm get client-scopes -r e-skylab-test -c \
  | jq -r '.[] | select(.name == "address") | .id')
kcadm update "clients/$client_uuid/optional-client-scopes/$address_scope_uuid" \
  -r e-skylab-test -n -b '{}' >/dev/null

account_client_uuid=$(kcadm get clients -r e-skylab-test -c \
  | jq -r '.[] | select(.clientId == "account") | .id')
extra_account_role=$(kcadm get "clients/$account_client_uuid/roles" -r e-skylab-test -c \
  | jq -c '[.[] | select(.name != "manage-account" and .name != "view-profile")][0] | [{id, name}]')
kcadm create "clients/$client_uuid/scope-mappings/clients/$account_client_uuid" \
  -r e-skylab-test -b "$extra_account_role" >/dev/null

flow_execution=$(kcadm get authentication/flows/account-center-browser/executions \
  -r e-skylab-test -c \
  | jq -c '.[] | select(.providerId == "auth-cookie") | .requirement = "REQUIRED"')
printf '%s' "$flow_execution" | "${KCADM[@]}" update --config "$ADMIN_CONFIG" \
  authentication/flows/account-center-browser/executions \
  -r e-skylab-test -n -f - >/dev/null
idp_redirector_execution_uuid=$(kcadm get \
  authentication/flows/account-center-browser/executions \
  -r e-skylab-test -c \
  | jq -r '.[] | select(.providerId == "identity-provider-redirector") | .id')
kcadm create "authentication/executions/$idp_redirector_execution_uuid/config" \
  -r e-skylab-test \
  -b '{"alias":"drift-idp-redirector","config":{"defaultProvider":"drift-provider"}}' >/dev/null
configured_execution_count=$(kcadm get \
  authentication/flows/account-center-browser/executions \
  -r e-skylab-test -c \
  | jq '[.[] | select(.providerId == "identity-provider-redirector" and (.authenticationConfig | type) == "string" and (.authenticationConfig | length) > 0)] | length')
[[ $configured_execution_count == 1 ]] \
  || fail "identity-provider redirector authenticationConfig drift was not injected"

# A failed security-state read must abort reconciliation. Process-substitution
# readers can otherwise mask kcadm failures as an empty allowlist and continue.
CURRENT_STAGE='injected reconciler read failure'
if "${COMPOSE[@]}" run --rm --no-deps \
  -e KCADM_BIN=/tmp/kcadm-read-failure.sh \
  -v "$SCRIPT_DIR/kcadm-read-failure.sh:/tmp/kcadm-read-failure.sh:ro" \
  keycloak-config >/dev/null 2>&1; then
  fail "reconciliation succeeded after an injected protocol-mapper read failure"
fi
unexpected_mapper_count=$(kcadm get \
  "client-scopes/$drift_scope_uuid/protocol-mappers/models" \
  -r e-skylab-test -c \
  | jq '[.[] | select(.name == "unexpected-account-mapper")] | length')
[[ $unexpected_mapper_count == 1 ]] \
  || fail "failed reconciliation mutated mapper state after its read failed"

kcadm update realms/e-skylab-test \
  -s ssoSessionMaxLifespan=123 \
  -s webAuthnPolicyPasswordlessPasskeysEnabled=false \
  -s webAuthnPolicyPasswordlessMediation=none >/dev/null
kcadm update authentication/required-actions/UPDATE_PASSWORD \
  -r e-skylab-test -s enabled=false >/dev/null

# A second pass proves both idempotence and drift repair.
CURRENT_STAGE='second reconciliation and drift repair'
"${COMPOSE[@]}" run --rm --no-deps keycloak-config >/dev/null

[[ -n $client_uuid ]] || fail "account-center client was not created"

client=$(kcadm get "clients/$client_uuid" -r e-skylab-test -c)
json_assert "$client" '.standardFlowEnabled == true' 'authorization code flow is not enabled'
json_assert "$client" '.implicitFlowEnabled == false' 'implicit flow is enabled'
json_assert "$client" '.directAccessGrantsEnabled == false' 'direct grants are enabled'
json_assert "$client" '.serviceAccountsEnabled == false' 'service account is enabled'
json_assert "$client" '.publicClient == false' 'client is not confidential'
json_assert "$client" '.redirectUris == ["https://my.yildizskylab.com/api/auth/callback"]' 'redirect URI is not exact'
json_assert "$client" '.webOrigins == []' 'web origins are not empty/exact'
json_assert "$client" '.attributes["pkce.code.challenge.method"] == "S256"' 'S256 PKCE is not required'
json_assert "$client" '.attributes["require.pushed.authorization.requests"] == "true"' 'PAR is not required'
json_assert "$client" '.attributes["backchannel.logout.url"] == "https://my.yildizskylab.com/api/auth/backchannel-logout"' 'backchannel logout URL differs'
json_assert "$client" '.attributes["backchannel.logout.session.required"] == "true"' 'backchannel session requirement is off'

realm=$(kcadm get realms/e-skylab-test -c)
json_assert "$realm" \
  '.sslRequired == "external" and .registrationAllowed == false and .resetPasswordAllowed == true and .ssoSessionIdleTimeout == 1800 and .ssoSessionMaxLifespan == 28800 and .accessCodeLifespanUserAction == 300 and .internationalizationEnabled == true and .defaultLocale == "tr" and (.supportedLocales | sort) == ["en", "tr"] and .loginTheme == "e-skylab-theme"' \
  'realm security, session or theme desired state differs'
json_assert "$realm" \
  '.webAuthnPolicyPasswordlessRpEntityName == "SKY LAB" and .webAuthnPolicyPasswordlessResidentKey == "required" and .webAuthnPolicyPasswordlessUserVerificationRequirement == "required" and .webAuthnPolicyPasswordlessPasskeysEnabled == true and .webAuthnPolicyPasswordlessMediation == "conditional"' \
  'passwordless WebAuthn desired state differs'

required_actions=$(kcadm get authentication/required-actions -r e-skylab-test -c)
for required_action in UPDATE_PASSWORD CONFIGURE_TOTP webauthn-register-passwordless delete_credential; do
  json_assert "$required_actions" \
    '[.[] | select(.alias == $alias and .enabled == true and .defaultAction == false)] | length == 1' \
    "required action $required_action differs" \
    --arg alias "$required_action"
done

flow_uuid=$(jq -r '.authenticationFlowBindingOverrides.browser' <<<"$client")
flow_count=$(kcadm get authentication/flows -r e-skylab-test -c \
  | jq '[.[] | select(.alias == "account-center-browser" and .id == $flow)] | length' --arg flow "$flow_uuid")
[[ $flow_count == 1 ]] || fail "client-specific browser flow is missing or duplicated"
flow_graph=$(kcadm get authentication/flows/account-center-browser/executions \
  -r e-skylab-test -c \
  | jq -r '.[] | [.level, .priority, .requirement, (if .authenticationFlow then "FLOW" else .providerId end), (if (.providerId == "conditional-credential" and (.authenticationConfig | type) == "string" and (.authenticationConfig | length) > 0) then "BUILTIN_PASSWORDLESS" elif ((.authenticationConfig | type) == "string" and (.authenticationConfig | length) > 0) then "CONFIGURED" else "NONE" end)] | join("|")')
expected_flow_graph=$(<"$SCRIPT_DIR/../config/account-center-browser.graph")
[[ $flow_graph == "$expected_flow_graph" ]] \
  || fail "client-specific browser flow graph drift was not repaired"
conditional_credential_config_uuid=$(kcadm get \
  authentication/flows/account-center-browser/executions \
  -r e-skylab-test -c \
  | jq -r '.[] | select(.providerId == "conditional-credential") | .authenticationConfig')
conditional_credential_config=$(kcadm get \
  "authentication/config/$conditional_credential_config_uuid" \
  -r e-skylab-test -c)
json_assert "$conditional_credential_config" \
  '(.alias | type) == "string" and (.alias | length) > 0 and .config == {"credentials":"webauthn-passwordless"}' \
  'conditional credential authenticationConfig drift was not repaired'

scope_count=$(kcadm get client-scopes -r e-skylab-test -c \
  | jq '[.[] | select(.name == "account-center-account-api")] | length')
[[ $scope_count == 1 ]] || fail "Account API client scope is missing or duplicated"
core_scope_count=$(kcadm get client-scopes -r e-skylab-test -c \
  | jq '[.[] | select(.name == "account-center-core-claims")] | length')
[[ $core_scope_count == 1 ]] || fail "Account Center core-claims scope is missing or duplicated"
skyapp_scope_count=$(kcadm get client-scopes -r e-skylab-test -c \
  | jq '[.[] | select(.name == "skyapp-account-center-audience")] | length')
[[ $skyapp_scope_count == 1 ]] || fail "skyapp audience scope is missing or duplicated"

built_in_scope_after=$(kcadm get client-scopes -r e-skylab-test -c \
  | jq -c '[.[] | select(.name != "account-center-account-api" and .name != "account-center-core-claims" and .name != "skyapp-account-center-audience") | {id, name}] | sort_by(.id)')
[[ $built_in_scope_after == "$built_in_scope_snapshot" ]] \
  || fail "a built-in client scope id or name was mutated"

while IFS= read -r built_in_scope_uuid; do
  built_in_mappers=$(kcadm get \
    "client-scopes/$built_in_scope_uuid/protocol-mappers/models" \
    -r e-skylab-test -c)
  json_assert "$built_in_mappers" \
    '[.[] | select(.name == "account-api-audience" or .name == "account-api-roles" or .name == "account-center-audience")] | length == 0' \
    "an Account Center mapper was injected into built-in scope $built_in_scope_uuid"
done < <(jq -r '.[].id' <<<"$built_in_scope_snapshot")

scope_uuid=$(kcadm get client-scopes -r e-skylab-test -c \
  | jq -r '.[] | select(.name == "account-center-account-api") | .id')
scope=$(kcadm get "client-scopes/$scope_uuid" -r e-skylab-test -c)
json_assert "$scope" '.protocol == "openid-connect" and .attributes["include.in.token.scope"] == "false"' 'Account API scope drift was not repaired'
mappers=$(kcadm get "client-scopes/$scope_uuid/protocol-mappers/models" -r e-skylab-test -c)
json_assert "$mappers" 'length == 2' 'unexpected or duplicate Account API mappers remain'
json_assert "$mappers" '[.[] | select(.name == "account-api-audience" and .config["included.client.audience"] == "account")] | length == 1' 'Account API audience mapper differs'
json_assert "$mappers" '[.[] | select(.name == "account-api-roles" and .config["usermodel.clientRoleMapping.clientId"] == "account")] | length == 1' 'Account API role mapper differs'

core_scope_uuid=$(kcadm get client-scopes -r e-skylab-test -c \
  | jq -r '.[] | select(.name == "account-center-core-claims") | .id')
core_scope=$(kcadm get "client-scopes/$core_scope_uuid" -r e-skylab-test -c)
json_assert "$core_scope" \
  '.protocol == "openid-connect" and .attributes["include.in.token.scope"] == "false"' \
  'Account Center core-claims scope drift was not repaired'
core_mappers=$(kcadm get \
  "client-scopes/$core_scope_uuid/protocol-mappers/models" \
  -r e-skylab-test -c)
json_assert "$core_mappers" \
  'length == 2 and ([.[].name] | sort) == ["auth_time", "sub"]' \
  'unexpected, profile or email mappers remain in the core-claims scope'
json_assert "$core_mappers" \
  '[.[] | select(.name == "sub" and .protocolMapper == "oidc-sub-mapper" and .config["access.token.claim"] == "true" and .config["introspection.token.claim"] == "true")] | length == 1' \
  'source-controlled sub mapper contract differs'
json_assert "$core_mappers" \
  '[.[] | select(.name == "auth_time" and .protocolMapper == "oidc-usersessionmodel-note-mapper" and .config["user.session.note"] == "AUTH_TIME" and .config["claim.name"] == "auth_time" and .config["jsonType.label"] == "long" and .config["id.token.claim"] == "true" and .config["access.token.claim"] == "true" and .config["introspection.token.claim"] == "true")] | length == 1' \
  'source-controlled auth_time mapper contract differs'

skyapp_scope_uuid=$(kcadm get client-scopes -r e-skylab-test -c \
  | jq -r '.[] | select(.name == "skyapp-account-center-audience") | .id')
skyapp_scope=$(kcadm get "client-scopes/$skyapp_scope_uuid" -r e-skylab-test -c)
json_assert "$skyapp_scope" \
  '.protocol == "openid-connect" and .attributes["include.in.token.scope"] == "false"' \
  'skyapp audience scope drift was not repaired'
skyapp_mappers=$(kcadm get \
  "client-scopes/$skyapp_scope_uuid/protocol-mappers/models" \
  -r e-skylab-test -c)
json_assert "$skyapp_mappers" \
  'length == 1 and .[0].name == "account-center-audience" and .[0].protocolMapper == "oidc-audience-mapper" and .[0].config["included.client.audience"] == "account-center" and .[0].config["access.token.claim"] == "true"' \
  'skyapp account-center audience mapper drift was not repaired'
skyapp_default_scopes=$(kcadm get \
  "clients/$skyapp_client_uuid/default-client-scopes" \
  -r e-skylab-test -c)
json_assert "$skyapp_default_scopes" \
  '[.[] | select(.id == $scope and .name == "skyapp-account-center-audience")] | length == 1' \
  'skyapp audience scope is not attached as a default scope' \
  --arg scope "$skyapp_scope_uuid"

default_scopes=$(kcadm get "clients/$client_uuid/default-client-scopes" -r e-skylab-test -c)
json_assert "$default_scopes" \
  '([.[].name] | sort) == ["account-center-account-api", "account-center-core-claims"]' \
  'unexpected Account Center default client scopes remain'
optional_scopes=$(kcadm get "clients/$client_uuid/optional-client-scopes" -r e-skylab-test -c)
json_assert "$optional_scopes" \
  'length == 0' \
  'unexpected Account Center optional client scopes remain'

account_roles=$(kcadm get \
  "clients/$client_uuid/scope-mappings/clients/$account_client_uuid" \
  -r e-skylab-test -c)
json_assert "$account_roles" \
  '([.[].name] | sort) == ["manage-account", "view-profile"]' \
  'unexpected Account API role mappings remain'

config_client_uuid=$(kcadm get clients -r e-skylab-test -c \
  | jq -r '.[] | select(.clientId == "account-center-config") | .id')
config_client=$(kcadm get "clients/$config_client_uuid" -r e-skylab-test -c)
json_assert "$config_client" \
  '.serviceAccountsEnabled == true and .standardFlowEnabled == false and .directAccessGrantsEnabled == false and .fullScopeAllowed == false' \
  'configuration client is not service-account-only'
config_service_user=$(kcadm get "clients/$config_client_uuid/service-account-user" \
  -r e-skylab-test -c | jq -r .id)
realm_management_uuid=$(kcadm get clients -r e-skylab-test -c \
  | jq -r '.[] | select(.clientId == "realm-management") | .id')
config_roles=$(kcadm get \
  "users/$config_service_user/role-mappings/clients/$realm_management_uuid" \
  -r e-skylab-test -c)
json_assert "$config_roles" \
  '([.[].name] | sort) == ["manage-clients", "manage-realm", "view-clients", "view-realm"]' \
  'configuration client realm-management roles exceed the allowlist'

CURRENT_STAGE='minimal openid PAR contract'
discovery=$(curl --fail --silent --show-error \
  http://localhost:18080/realms/e-skylab-test/.well-known/openid-configuration)
json_assert "$discovery" '.pushed_authorization_request_endpoint == "http://localhost:18080/realms/e-skylab-test/protocol/openid-connect/ext/par/request"' 'PAR endpoint is not advertised'

client_secret=$(kcadm get "clients/$client_uuid/client-secret" -r e-skylab-test -c | jq -r .value)
[[ -n $client_secret && $client_secret != null ]] || fail "client secret was not generated"

CURRENT_STAGE='skyapp account-center audience token contract'
skyapp_token_response=$(curl --fail --silent --show-error \
  --data-urlencode grant_type=password \
  --data-urlencode client_id=skyapp \
  --data-urlencode username=account-fixture \
  --data-urlencode password=fixture-password-change-me \
  --data-urlencode scope=openid \
  http://localhost:18080/realms/e-skylab-test/protocol/openid-connect/token)
skyapp_access_token=$(jq -r .access_token <<<"$skyapp_token_response")
[[ -n $skyapp_access_token && $skyapp_access_token != null ]] \
  || fail 'skyapp direct grant did not return an access token'
skyapp_payload_segment=$(cut -d. -f2 <<<"$skyapp_access_token")
case $((${#skyapp_payload_segment} % 4)) in
  2) skyapp_payload_segment="${skyapp_payload_segment}==" ;;
  3) skyapp_payload_segment="${skyapp_payload_segment}=" ;;
esac
skyapp_payload=$(tr '_-' '/+' <<<"$skyapp_payload_segment" | base64 --decode)
json_assert "$skyapp_payload" \
  '.azp == "skyapp" and ((.aud == "account-center") or ((.aud | type) == "array" and (.aud | index("account-center") != null)))' \
  'skyapp access token is missing the account-center audience or changed azp'

par_response=$(curl --fail --silent --show-error \
  --user "account-center:$client_secret" \
  --data-urlencode client_id=account-center \
  --data-urlencode response_type=code \
  --data-urlencode scope=openid \
  --data-urlencode redirect_uri=https://my.yildizskylab.com/api/auth/callback \
  --data-urlencode code_challenge=QWxhZGRpbjpPcGVuU2VzYW1lMTIzNDU2Nzg5MDEyMzQ1Njc \
  --data-urlencode code_challenge_method=S256 \
  http://localhost:18080/realms/e-skylab-test/protocol/openid-connect/ext/par/request)
json_assert "$par_response" '.request_uri | startswith("urn:ietf:params:oauth:request_uri:")' 'PAR request was not accepted'

wrong_redirect_status=$(curl --silent --show-error \
  --output "$TEST_STATE_DIR/wrong-redirect.json" \
  --write-out '%{http_code}' \
  --user "account-center:$client_secret" \
  --data-urlencode client_id=account-center \
  --data-urlencode response_type=code \
  --data-urlencode scope=openid \
  --data-urlencode redirect_uri=https://attacker.invalid/callback \
  --data-urlencode code_challenge=QWxhZGRpbjpPcGVuU2VzYW1lMTIzNDU2Nzg5MDEyMzQ1Njc \
  --data-urlencode code_challenge_method=S256 \
  http://localhost:18080/realms/e-skylab-test/protocol/openid-connect/ext/par/request)
[[ $wrong_redirect_status == 400 ]] || fail "PAR accepted a non-allowlisted redirect URI"

plain_pkce_status=$(curl --silent --show-error \
  --output "$TEST_STATE_DIR/plain-pkce.json" \
  --write-out '%{http_code}' \
  --user "account-center:$client_secret" \
  --data-urlencode client_id=account-center \
  --data-urlencode response_type=code \
  --data-urlencode scope=openid \
  --data-urlencode redirect_uri=https://my.yildizskylab.com/api/auth/callback \
  --data-urlencode code_challenge=plain-code-challenge-that-is-long-enough-for-pkce \
  --data-urlencode code_challenge_method=plain \
  http://localhost:18080/realms/e-skylab-test/protocol/openid-connect/ext/par/request)
[[ $plain_pkce_status == 400 ]] || fail "PAR accepted plain PKCE"

request_uri=$(jq -r .request_uri <<<"$par_response")
request_uri_query=$(jq -rn --arg value "$request_uri" '$value | @uri')
CURRENT_STAGE='login theme render smoke test'
login_page=$(curl --fail --silent --show-error --location \
  --cookie-jar "$TEST_STATE_DIR/login.cookies" \
  --cookie "$TEST_STATE_DIR/login.cookies" \
  "http://localhost:18080/realms/e-skylab-test/protocol/openid-connect/auth?client_id=account-center&request_uri=$request_uri_query")
[[ $login_page == *e-skylab-theme* ]] \
  || fail "the configured SKY LAB login theme did not render"

CURRENT_STAGE='AIA PAR acceptance'
aia_par_response=$(curl --fail --silent --show-error \
  --user "account-center:$client_secret" \
  --data-urlencode client_id=account-center \
  --data-urlencode response_type=code \
  --data-urlencode scope=openid \
  --data-urlencode redirect_uri=https://my.yildizskylab.com/api/auth/callback \
  --data-urlencode code_challenge=QWxhZGRpbjpPcGVuU2VzYW1lMTIzNDU2Nzg5MDEyMzQ1Njc \
  --data-urlencode code_challenge_method=S256 \
  --data-urlencode kc_action=UPDATE_PASSWORD \
  http://localhost:18080/realms/e-skylab-test/protocol/openid-connect/ext/par/request)
json_assert "$aia_par_response" \
  '.request_uri | startswith("urn:ietf:params:oauth:request_uri:")' \
  'allowlisted UPDATE_PASSWORD AIA PAR request was not accepted'

fixture_user_uuid=$(kcadm get users -r e-skylab-test -q username=account-fixture -c \
  | jq -r '.[] | select(.username == "account-fixture") | .id')
kcadm create "users/$fixture_user_uuid/role-mappings/clients/$account_client_uuid" \
  -r e-skylab-test -b "$account_roles" >/dev/null

CURRENT_STAGE='native handoff real Keycloak SSO contract'
native_code_verifier=account-center-native-handoff-verifier-0123456789abcdefghijklmnop
native_code_challenge=$(printf '%s' "$native_code_verifier" \
  | openssl dgst -binary -sha256 \
  | openssl base64 -A \
  | tr '+/' '-_' \
  | tr -d '=')
native_par_request() {
  local bridge_code=$1
  local state=$2
  curl --fail --silent --show-error \
    --user "account-center:$client_secret" \
    --data-urlencode client_id=account-center \
    --data-urlencode response_type=code \
    --data-urlencode scope=openid \
    --data-urlencode redirect_uri=https://my.yildizskylab.com/api/auth/callback \
    --data-urlencode "code_challenge=$native_code_challenge" \
    --data-urlencode code_challenge_method=S256 \
    --data-urlencode "state=$state" \
    --data-urlencode "nonce=$state-nonce" \
    --data-urlencode "sky_native_handoff=$bridge_code" \
    http://localhost:18080/realms/e-skylab-test/protocol/openid-connect/ext/par/request
}

valid_bridge_code=$(printf 'A%.0s' $(seq 1 43))
valid_native_par=$(native_par_request "$valid_bridge_code" native-valid-state)
json_assert "$valid_native_par" \
  '.request_uri | startswith("urn:ietf:params:oauth:request_uri:")' \
  'valid native bridge PAR request was not accepted'
valid_native_request_uri=$(jq -r .request_uri <<<"$valid_native_par")
valid_native_request_uri_query=$(jq -rn \
  --arg value "$valid_native_request_uri" '$value | @uri')
valid_native_browser_url="http://localhost:18080/realms/e-skylab-test/protocol/openid-connect/auth?client_id=account-center&request_uri=$valid_native_request_uri_query"
[[ $valid_native_browser_url != *"$valid_bridge_code"* ]] \
  || fail 'native bridge code leaked into the browser authorization URL'
walk_authorization_redirects \
  native-valid \
  "$valid_native_browser_url" \
  "$TEST_STATE_DIR/native-valid.cookies"
[[ $AUTHORIZATION_RESULT_URL == https://my.yildizskylab.com/api/auth/callback?* ]] \
  || fail 'valid native handoff did not reach the exact Account Center callback'
[[ $AUTHORIZATION_RESULT_URL == *'state=native-valid-state'* ]] \
  || fail 'valid native handoff lost OIDC state'
native_authorization_code=$(sed -n \
  's/.*[?&]code=\([^&]*\).*/\1/p' <<<"$AUTHORIZATION_RESULT_URL")
[[ -n $native_authorization_code ]] \
  || fail 'valid native handoff callback lacks an authorization code'
grep -Eq '[[:space:]]KEYCLOAK_(SESSION|IDENTITY)[[:space:]]' \
  "$TEST_STATE_DIR/native-valid.cookies" \
  || fail 'valid native handoff did not create a real Keycloak SSO cookie'

native_token_response=$(curl --fail --silent --show-error \
  --user "account-center:$client_secret" \
  --data-urlencode grant_type=authorization_code \
  --data-urlencode client_id=account-center \
  --data-urlencode "code=$native_authorization_code" \
  --data-urlencode redirect_uri=https://my.yildizskylab.com/api/auth/callback \
  --data-urlencode "code_verifier=$native_code_verifier" \
  http://localhost:18080/realms/e-skylab-test/protocol/openid-connect/token)
native_id_token=$(jq -r .id_token <<<"$native_token_response")
[[ -n $native_id_token && $native_id_token != null ]] \
  || fail 'valid native handoff code exchange did not return an ID token'
native_id_payload_segment=$(cut -d. -f2 <<<"$native_id_token")
case $((${#native_id_payload_segment} % 4)) in
  2) native_id_payload_segment="${native_id_payload_segment}==" ;;
  3) native_id_payload_segment="${native_id_payload_segment}=" ;;
esac
native_id_payload=$(tr '_-' '/+' <<<"$native_id_payload_segment" | base64 --decode)
json_assert "$native_id_payload" \
  '.sub == "11111111-1111-4111-8111-111111111111" and .auth_time == $auth_time' \
  'native handoff ID token changed the subject or original auth_time' \
  --argjson auth_time "$NATIVE_BRIDGE_AUTH_TIME"

for native_failure_case in \
  "replay:$valid_bridge_code" \
  "unknown:$(printf 'U%.0s' $(seq 1 43))" \
  "disabled:$(printf 'D%.0s' $(seq 1 43))"; do
  native_failure_label=${native_failure_case%%:*}
  native_failure_code=${native_failure_case#*:}
  native_failure_par=$(native_par_request \
    "$native_failure_code" "native-$native_failure_label-state")
  native_failure_request_uri=$(jq -r .request_uri <<<"$native_failure_par")
  native_failure_request_uri_query=$(jq -rn \
    --arg value "$native_failure_request_uri" '$value | @uri')
  native_failure_browser_url="http://localhost:18080/realms/e-skylab-test/protocol/openid-connect/auth?client_id=account-center&request_uri=$native_failure_request_uri_query"
  [[ $native_failure_browser_url != *"$native_failure_code"* ]] \
    || fail "$native_failure_label bridge code leaked into the browser URL"
  walk_authorization_redirects \
    "native-$native_failure_label" \
    "$native_failure_browser_url" \
    "$TEST_STATE_DIR/native-$native_failure_label.cookies"
  [[ $AUTHORIZATION_RESULT_URL != https://my.yildizskylab.com/api/auth/callback?* ]] \
    || fail "$native_failure_label native handoff reached the Account Center callback"
  if grep -Eqi '<input[^>]+name=["'\'']password["'\'']' \
      "$AUTHORIZATION_RESULT_BODY"; then
    fail "$native_failure_label native handoff fell back to the password form"
  fi
  if grep -Eq '"showTryAnotherWayLink"[[:space:]]*:[[:space:]]*true' \
      "$AUTHORIZATION_RESULT_BODY"; then
    fail "$native_failure_label native handoff exposed another login path"
  fi
  if grep -Fq "$native_failure_code" \
      "$AUTHORIZATION_RESULT_BODY" "$AUTHORIZATION_RESULT_HEADERS"; then
    fail "$native_failure_label native handoff exposed the bridge code in its response"
  fi
done

native_bridge_logs=$("${COMPOSE[@]}" logs --no-color keycloak native-bridge 2>&1)
for secret_bridge_code in \
  "$valid_bridge_code" \
  "$(printf 'U%.0s' $(seq 1 43))" \
  "$(printf 'D%.0s' $(seq 1 43))"; do
  [[ $native_bridge_logs != *"$secret_bridge_code"* ]] \
    || fail 'native bridge code leaked into Keycloak or bridge fixture logs'
done

CURRENT_STAGE='real browser authorization-code login'
code_verifier=account-center-integration-code-verifier-0123456789abcdefghijklmnop
code_challenge=$(printf '%s' "$code_verifier" \
  | openssl dgst -binary -sha256 \
  | openssl base64 -A \
  | tr '+/' '-_' \
  | tr -d '=')
browser_par_response=$(curl --fail --silent --show-error \
  --user "account-center:$client_secret" \
  --data-urlencode client_id=account-center \
  --data-urlencode response_type=code \
  --data-urlencode scope=openid \
  --data-urlencode redirect_uri=https://my.yildizskylab.com/api/auth/callback \
  --data-urlencode "code_challenge=$code_challenge" \
  --data-urlencode code_challenge_method=S256 \
  --data-urlencode state=integration-state \
  --data-urlencode nonce=integration-nonce \
  http://localhost:18080/realms/e-skylab-test/protocol/openid-connect/ext/par/request)
browser_request_uri=$(jq -r .request_uri <<<"$browser_par_response")
browser_request_uri_query=$(jq -rn --arg value "$browser_request_uri" '$value | @uri')
browser_login_page=$(curl --fail --silent --show-error --location \
  --cookie-jar "$TEST_STATE_DIR/browser-login.cookies" \
  --cookie "$TEST_STATE_DIR/browser-login.cookies" \
  "http://localhost:18080/realms/e-skylab-test/protocol/openid-connect/auth?client_id=account-center&request_uri=$browser_request_uri_query")
login_action_literals=$(grep -Eo '"loginAction"[[:space:]]*:[[:space:]]*"[^"]*"' \
  <<<"$browser_login_page" || true)
[[ $(grep -c . <<<"$login_action_literals") == 1 ]] \
  || fail "login theme did not expose one exact login action"
login_action_literal=$(sed -E \
  's/^"loginAction"[[:space:]]*:[[:space:]]*//' \
  <<<"$login_action_literals")
login_action=$(jq -r . <<<"$login_action_literal")
login_submit_status=$(curl --silent --show-error \
  --output "$TEST_STATE_DIR/login-submit.body" \
  --dump-header "$TEST_STATE_DIR/login-submit.headers" \
  --write-out '%{http_code}' \
  --cookie-jar "$TEST_STATE_DIR/browser-login.cookies" \
  --cookie "$TEST_STATE_DIR/browser-login.cookies" \
  --data-urlencode username=account-fixture \
  --data-urlencode password=fixture-password-change-me \
  --data-urlencode credentialId= \
  "$login_action")
[[ $login_submit_status == 302 ]] || fail "browser credential submission did not redirect"
authorization_redirects=$(awk '
  tolower($1) == "location:" {
    sub(/^[^:]*:[[:space:]]*/, "")
    sub(/\r$/, "")
    print
  }
' "$TEST_STATE_DIR/login-submit.headers")
[[ $(grep -c . <<<"$authorization_redirects") == 1 ]] \
  || fail "browser login did not return one exact authorization redirect"
authorization_redirect=$authorization_redirects
[[ $authorization_redirect == https://my.yildizskylab.com/api/auth/callback?* ]] \
  || fail "browser login redirected outside the exact callback"
[[ $authorization_redirect == *"state=integration-state"* ]] \
  || fail "browser authorization redirect lost state"
authorization_code=$(sed -n 's/.*[?&]code=\([^&]*\).*/\1/p' <<<"$authorization_redirect")
[[ -n $authorization_code ]] || fail "browser authorization redirect lacks a code"

CURRENT_STAGE='minimal openid ID and access token contract'
token_response=$(curl --fail --silent --show-error \
  --user "account-center:$client_secret" \
  --data-urlencode grant_type=authorization_code \
  --data-urlencode client_id=account-center \
  --data-urlencode "code=$authorization_code" \
  --data-urlencode redirect_uri=https://my.yildizskylab.com/api/auth/callback \
  --data-urlencode "code_verifier=$code_verifier" \
  http://localhost:18080/realms/e-skylab-test/protocol/openid-connect/token)
access_token=$(jq -r .access_token <<<"$token_response")
[[ -n $access_token && $access_token != null ]] || fail "browser code exchange did not receive an access token"
token_header_segment=$(cut -d. -f1 <<<"$access_token")
case $((${#token_header_segment} % 4)) in
  2) token_header_segment="${token_header_segment}==" ;;
  3) token_header_segment="${token_header_segment}=" ;;
esac
token_header=$(tr '_-' '/+' <<<"$token_header_segment" | base64 --decode)
json_assert "$token_header" \
  '.alg == "RS256" and .typ == "JWT"' \
  'access token JOSE header differs from the pinned RS256/JWT contract'
token_payload_segment=$(cut -d. -f2 <<<"$access_token")
case $((${#token_payload_segment} % 4)) in
  2) token_payload_segment="${token_payload_segment}==" ;;
  3) token_payload_segment="${token_payload_segment}=" ;;
esac
token_payload=$(tr '_-' '/+' <<<"$token_payload_segment" | base64 --decode)
json_assert "$token_payload" \
  '((.aud == "account") or (.aud == ["account"])) and .azp == "account-center" and .scope == "openid" and ((.resource_access.account.roles | index("manage-account")) != null) and ((.resource_access.account.roles | index("view-profile")) != null)' \
  'issued token differs from the exact audience, authorized-party, scope or required-role contract'

id_token=$(jq -r .id_token <<<"$token_response")
[[ -n $id_token && $id_token != null ]] || fail "minimal openid request did not receive an ID token"
id_token_payload_segment=$(cut -d. -f2 <<<"$id_token")
case $((${#id_token_payload_segment} % 4)) in
  2) id_token_payload_segment="${id_token_payload_segment}==" ;;
  3) id_token_payload_segment="${id_token_payload_segment}=" ;;
esac
id_token_payload=$(tr '_-' '/+' <<<"$id_token_payload_segment" | base64 --decode)
now_epoch=$(date +%s)
json_assert "$id_token_payload" \
  '(.sub | type) == "string" and (.sub | length) > 0 and (.sid | type) == "string" and (.sid | length) > 0 and (.auth_time | type) == "number" and .auth_time == (.auth_time | floor) and .auth_time > 0 and .auth_time <= $now' \
  'ID token lacks a non-future integer auth_time, sub or sid' \
  --argjson now "$now_epoch"

CURRENT_STAGE='Account REST profile contract'
account_profile=$(curl --fail --silent --show-error \
  -H "Authorization: Bearer $access_token" \
  -H 'Accept: application/json' \
  http://localhost:18080/realms/e-skylab-test/account/)
json_assert "$account_profile" \
  '.username == "account-fixture" and .email == "account-fixture@example.invalid"' \
  'live Account REST profile contract failed'

CURRENT_STAGE='real Chromium login and AIA contracts'
real_browser_config="$TEST_STATE_DIR/real-keycloak-browser.json"
jq -n \
  --arg baseUrl 'http://localhost:18080' \
  --arg callbackUrl 'https://my.yildizskylab.com/api/auth/callback' \
  --arg clientId 'account-center' \
  --arg clientSecret "$client_secret" \
  --arg username 'account-fixture' \
  --arg password 'fixture-password-change-me' \
  --arg changedPassword 'fixture-password-changed-by-browser' \
  '{
    baseUrl: $baseUrl,
    callbackUrl: $callbackUrl,
    clientId: $clientId,
    clientSecret: $clientSecret,
    username: $username,
    password: $password,
    changedPassword: $changedPassword
  }' \
  >"$real_browser_config"
chmod 0600 "$real_browser_config"
(
  cd "$SCRIPT_DIR/../theme"
  REAL_KEYCLOAK_BROWSER_CONFIG="$real_browser_config" \
    npx --no-install playwright test \
      --config=playwright.integration.config.ts \
      tests/integration/real-keycloak.spec.ts
)
kcadm set-password \
  -r e-skylab-test \
  --userid "$fixture_user_uuid" \
  --new-password fixture-password-change-me \
  --temporary=false >/dev/null

# Provision the RabbitMQ topology expected by the provider, then use an admin
# event to prove the rebuilt provider can publish on Keycloak 26.7.4.
CURRENT_STAGE='RabbitMQ provider contract'
curl --fail --silent --show-error --user keycloak:integration-rabbit-password \
  -X PUT -H 'content-type: application/json' \
  -d '{"type":"topic","durable":true,"auto_delete":false,"internal":false,"arguments":{}}' \
  http://localhost:15673/api/exchanges/%2F/keycloak.events >/dev/null
curl --fail --silent --show-error --user keycloak:integration-rabbit-password \
  -X PUT -H 'content-type: application/json' \
  -d '{"durable":false,"auto_delete":true,"arguments":{}}' \
  http://localhost:15673/api/queues/%2F/keycloak-foundation-test >/dev/null
curl --fail --silent --show-error --user keycloak:integration-rabbit-password \
  -X POST -H 'content-type: application/json' \
  -d '{"routing_key":"KK.EVENT.#","arguments":{}}' \
  http://localhost:15673/api/bindings/%2F/e/keycloak.events/q/keycloak-foundation-test >/dev/null

kcadm update realms/e-skylab-test -s displayName='SKY LAB integration event' >/dev/null
for attempt in $(seq 1 30); do
  message_count=$(curl --fail --silent --show-error --user keycloak:integration-rabbit-password \
    http://localhost:15673/api/queues/%2F/keycloak-foundation-test | jq -r '.messages // 0')
  if [[ ${message_count:-0} -gt 0 ]]; then
    break
  fi
  sleep 1
done
[[ ${message_count:-0} -gt 0 ]] || fail "RabbitMQ provider did not publish the Keycloak admin event"

provider_names=$("${COMPOSE[@]}" exec -T keycloak sh -c \
  "find /opt/keycloak/providers -maxdepth 1 -type f -name '*.jar' -printf '%f\\n' | sort")
[[ $(grep -c '^e-skylab-spi-' <<<"$provider_names") == 1 ]] || fail "runtime does not contain exactly one SKY LAB SPI"
[[ $(grep -c '^e-skylab-theme-' <<<"$provider_names") == 1 ]] || fail "runtime does not contain exactly one SKY LAB theme"
[[ $(grep -c '^keycloak-to-rabbit-' <<<"$provider_names") == 1 ]] || fail "runtime does not contain exactly one RabbitMQ provider"

printf 'Keycloak 26.7.4 Account Center integration contract passed.\n'
