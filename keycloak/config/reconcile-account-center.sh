#!/usr/bin/env bash
set -Eeuo pipefail
shopt -s inherit_errexit

umask 077

KCADM=${KCADM_BIN:-/opt/keycloak/bin/kcadm.sh}
CONFIG_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
ADMIN_URL=${KEYCLOAK_ADMIN_URL:-http://keycloak:8080}
TARGET_REALM=${KEYCLOAK_REALM:-e-skylab}
BASE_URL=${ACCOUNT_CENTER_BASE_URL:-https://my.yildizskylab.com}
CONFIG_CLIENT_ID=${KEYCLOAK_CONFIG_CLIENT_ID:-account-center-config}
CLIENT_ID=account-center
FLOW_ALIAS=account-center-browser
SCOPE_NAME=account-center-account-api
CORE_SCOPE_NAME=account-center-core-claims
KCADM_CONFIG=$(mktemp /tmp/account-center-kcadm.XXXXXX)

# shellcheck source=account-center-origin.sh
source "$CONFIG_DIR/account-center-origin.sh"

cleanup() {
  rm -f "$KCADM_CONFIG"
}
trap cleanup EXIT

require() {
  local variable_name=$1
  if [[ -z ${!variable_name:-} ]]; then
    printf 'Missing required environment variable: %s\n' "$variable_name" >&2
    exit 1
  fi
}

require KEYCLOAK_CONFIG_CLIENT_SECRET

BASE_URL=$(normalize_account_center_base_url \
  "$BASE_URL" \
  "${ACCOUNT_CENTER_REQUIRE_PRODUCTION_HOST:-false}")

kcadm() {
  local command=$1
  shift
  "$KCADM" "$command" --config "$KCADM_CONFIG" "$@"
}

authenticate() {
  local attempt
  for attempt in $(seq 1 60); do
    if "$KCADM" config credentials \
      --config "$KCADM_CONFIG" \
      --server "$ADMIN_URL" \
      --realm "$TARGET_REALM" \
      --client "$CONFIG_CLIENT_ID" \
      --secret "$KEYCLOAK_CONFIG_CLIENT_SECRET" >/dev/null 2>&1; then
      return 0
    fi
    sleep 2
  done
  printf 'Keycloak did not become ready for reconciliation\n' >&2
  return 1
}

client_id_by_client_id() {
  local wanted=$1
  local clients_csv id client_id
  if ! clients_csv=$(kcadm get clients -r "$TARGET_REALM" \
    --fields id,clientId \
    --format csv \
    --noquotes); then
    printf 'Failed to read clients while looking up %s\n' "$wanted" >&2
    return 2
  fi
  while IFS=, read -r id client_id; do
    if [[ $client_id == "$wanted" ]]; then
      printf '%s\n' "$id"
      return 0
    fi
  done <<<"$clients_csv"
  return 1
}

flow_id_by_alias() {
  local wanted=$1
  local flows_csv id alias
  if ! flows_csv=$(kcadm get authentication/flows -r "$TARGET_REALM" \
    --fields id,alias \
    --format csv \
    --noquotes); then
    printf 'Failed to read authentication flows while looking up %s\n' "$wanted" >&2
    return 2
  fi
  while IFS=, read -r id alias; do
    if [[ $alias == "$wanted" ]]; then
      printf '%s\n' "$id"
      return 0
    fi
  done <<<"$flows_csv"
  return 1
}

client_scope_id_by_name() {
  local wanted=$1
  local scopes_csv id name
  if ! scopes_csv=$(kcadm get client-scopes -r "$TARGET_REALM" \
    --fields id,name \
    --format csv \
    --noquotes); then
    printf 'Failed to read client scopes while looking up %s\n' "$wanted" >&2
    return 2
  fi
  while IFS=, read -r id name; do
    if [[ $name == "$wanted" ]]; then
      printf '%s\n' "$id"
      return 0
    fi
  done <<<"$scopes_csv"
  return 1
}

client_role_id_by_name() {
  local client_id=$1
  local wanted=$2
  local roles_csv id name
  if ! roles_csv=$(kcadm get "clients/$client_id/roles" -r "$TARGET_REALM" \
    --fields id,name \
    --format csv \
    --noquotes); then
    printf 'Failed to read client roles while looking up %s\n' "$wanted" >&2
    return 2
  fi
  while IFS=, read -r id name; do
    if [[ $name == "$wanted" ]]; then
      printf '%s\n' "$id"
      return 0
    fi
  done <<<"$roles_csv"
  return 1
}

optional_lookup() {
  local result status
  if result=$("$@"); then
    printf '%s\n' "$result"
    return 0
  else
    status=$?
  fi
  if [[ $status == 1 ]]; then
    return 0
  fi
  return "$status"
}

authentication_config_signature() {
  local provider_id=$1
  local config_id=$2
  local config_json

  if [[ -z $config_id ]]; then
    printf 'NONE\n'
    return 0
  fi
  if [[ $provider_id != conditional-credential ]]; then
    printf 'CONFIGURED\n'
    return 0
  fi

  if ! config_json=$(kcadm get "authentication/config/$config_id" \
    -r "$TARGET_REALM" -c); then
    printf 'Failed to read authentication configuration %s\n' "$config_id" >&2
    return 2
  fi
  if [[ $config_json == *'"config":{"credentials":"webauthn-passwordless"}'* ]]; then
    printf 'BUILTIN_PASSWORDLESS\n'
  else
    printf 'DRIFTED\n'
  fi
}

flow_graph_signature() {
  local alias=$1
  local executions_csv
  local level priority requirement provider_id authentication_flow authentication_config
  local kind config_state
  if ! executions_csv=$(kcadm get "authentication/flows/$alias/executions" \
    -r "$TARGET_REALM" \
    --fields level,priority,requirement,providerId,authenticationFlow,authenticationConfig \
    --format csv \
    --noquotes); then
    printf 'Failed to read authentication flow executions for %s\n' "$alias" >&2
    return 2
  fi
  while IFS=, read -r level priority requirement provider_id authentication_flow authentication_config; do
    [[ -n $level ]] || continue
    if [[ $authentication_flow == true ]]; then
      kind=FLOW
    else
      kind=$provider_id
    fi
    if ! config_state=$(authentication_config_signature \
      "$provider_id" "$authentication_config"); then
      printf 'Failed to read authentication configuration for %s\n' "$provider_id" >&2
      return 2
    fi
    printf '%s|%s|%s|%s|%s\n' \
      "$level" "$priority" "$requirement" "$kind" "$config_state"
  done <<<"$executions_csv"
}

ensure_browser_flow() {
  local client_id=$1
  local flow_id actual_graph expected_graph
  expected_graph=$(<"$CONFIG_DIR/account-center-browser.graph")
  if flow_id=$(optional_lookup flow_id_by_alias "$FLOW_ALIAS"); then
    :
  else
    return $?
  fi

  if [[ -n $flow_id ]]; then
    if ! actual_graph=$(flow_graph_signature "$FLOW_ALIAS"); then
      return 2
    fi
    if [[ $actual_graph != "$expected_graph" ]]; then
      kcadm update "clients/$client_id" -r "$TARGET_REALM" \
        -d 'attributes."authentication.flow.binding.override.browser"' >/dev/null
      kcadm delete "authentication/flows/$flow_id" -r "$TARGET_REALM" >/dev/null
      flow_id=''
    fi
  fi

  if [[ -z $flow_id ]]; then
    kcadm create authentication/flows/browser/copy \
      -r "$TARGET_REALM" \
      -s "newName=$FLOW_ALIAS" >/dev/null
    if flow_id=$(flow_id_by_alias "$FLOW_ALIAS"); then
      :
    else
      return $?
    fi
  fi

  if ! actual_graph=$(flow_graph_signature "$FLOW_ALIAS"); then
    return 2
  fi
  if [[ $actual_graph != "$expected_graph" ]]; then
    printf 'Expected %s graph:\n%s\nActual graph:\n%s\n' \
      "$FLOW_ALIAS" "$expected_graph" "$actual_graph" >&2
    printf 'The %s execution graph differs from desired state\n' "$FLOW_ALIAS" >&2
    return 1
  fi
  printf '%s\n' "$flow_id"
}

reconcile_required_actions() {
  local alias enabled default_action
  while IFS='|' read -r alias enabled default_action; do
    [[ -n $alias ]] || continue
    kcadm update "authentication/required-actions/$alias" \
      -r "$TARGET_REALM" \
      -s "enabled=$enabled" \
      -s "defaultAction=$default_action" >/dev/null
  done < "$CONFIG_DIR/account-center-required-actions.tsv"
}

prune_protocol_mappers() {
  local scope_id=$1
  shift
  local mappers_csv id name allowed_name
  local seen_names='|'
  local keep
  if ! mappers_csv=$(kcadm get "client-scopes/$scope_id/protocol-mappers/models" \
    -r "$TARGET_REALM" \
    --fields id,name \
    --format csv \
    --noquotes); then
    printf 'Failed to read protocol mappers for client scope %s\n' "$scope_id" >&2
    return 2
  fi
  while IFS=, read -r id name; do
    [[ -n $id ]] || continue
    keep=false
    for allowed_name in "$@"; do
      if [[ $name == "$allowed_name" && $seen_names != *"|$name|"* ]]; then
        seen_names="$seen_names$name|"
        keep=true
        break
      fi
    done
    if [[ $keep == true ]]; then
      continue
    fi
    kcadm delete "client-scopes/$scope_id/protocol-mappers/models/$id" \
      -r "$TARGET_REALM" >/dev/null
  done <<<"$mappers_csv"
}

ensure_protocol_mapper() {
  local scope_id=$1
  local mapper_name=$2
  local mapper_body=$3
  local mappers_csv mapper_id id name
  mapper_id=''
  if ! mappers_csv=$(kcadm get "client-scopes/$scope_id/protocol-mappers/models" \
    -r "$TARGET_REALM" \
    --fields id,name \
    --format csv \
    --noquotes); then
    printf 'Failed to read protocol mappers for client scope %s\n' "$scope_id" >&2
    return 2
  fi
  while IFS=, read -r id name; do
    if [[ $name == "$mapper_name" ]]; then
      mapper_id=$id
      break
    fi
  done <<<"$mappers_csv"
  if [[ -z $mapper_id ]]; then
    kcadm create "client-scopes/$scope_id/protocol-mappers/models" \
      -r "$TARGET_REALM" \
      -b "$mapper_body" >/dev/null
  else
    local update_body
    update_body="{\"id\":\"$mapper_id\",${mapper_body#\{}"
    kcadm update "client-scopes/$scope_id/protocol-mappers/models/$mapper_id" \
      -r "$TARGET_REALM" \
      -n \
      -b "$update_body" >/dev/null
  fi
}

authenticate
kcadm get "realms/$TARGET_REALM" >/dev/null
kcadm update "realms/$TARGET_REALM" \
  -n \
  -f "$CONFIG_DIR/account-center-realm.json" >/dev/null
reconcile_required_actions

client_uuid=$(optional_lookup client_id_by_client_id "$CLIENT_ID")
if [[ -z $client_uuid ]]; then
  client_uuid=$(kcadm create clients -r "$TARGET_REALM" -i \
    -s "clientId=$CLIENT_ID" \
    -s name='SKY LAB Account Center' \
    -s enabled=true \
    -s protocol=openid-connect \
    -s publicClient=false \
    -s bearerOnly=false)
fi

flow_uuid=$(ensure_browser_flow "$client_uuid")

callback_uri="$BASE_URL/api/auth/callback"
logout_uri="$BASE_URL/api/auth/logout/callback"
backchannel_logout_uri="$BASE_URL/api/auth/backchannel-logout"

kcadm update "clients/$client_uuid" -r "$TARGET_REALM" \
  -s "clientId=$CLIENT_ID" \
  -s name='SKY LAB Account Center' \
  -s enabled=true \
  -s protocol=openid-connect \
  -s clientAuthenticatorType=client-secret \
  -s publicClient=false \
  -s bearerOnly=false \
  -s standardFlowEnabled=true \
  -s implicitFlowEnabled=false \
  -s directAccessGrantsEnabled=false \
  -s serviceAccountsEnabled=false \
  -s authorizationServicesEnabled=false \
  -s consentRequired=false \
  -s frontchannelLogout=false \
  -s fullScopeAllowed=false \
  -s "rootUrl=$BASE_URL" \
  -s "baseUrl=$BASE_URL/" \
  -s "adminUrl=$BASE_URL" \
  -s "redirectUris=[\"$callback_uri\"]" \
  -s 'webOrigins=[]' \
  -s 'attributes."pkce.code.challenge.method"=S256' \
  -s 'attributes."require.pushed.authorization.requests"=true' \
  -s "attributes.\"backchannel.logout.url\"=$backchannel_logout_uri" \
  -s 'attributes."backchannel.logout.session.required"=true' \
  -s 'attributes."backchannel.logout.revoke.offline.tokens"=true' \
  -s "attributes.\"post.logout.redirect.uris\"=$logout_uri" \
  -s "attributes.\"authentication.flow.binding.override.browser\"=$flow_uuid" >/dev/null

scope_uuid=$(optional_lookup client_scope_id_by_name "$SCOPE_NAME")
if [[ -z $scope_uuid ]]; then
  scope_uuid=$(kcadm create client-scopes -r "$TARGET_REALM" -i \
    -s "name=$SCOPE_NAME" \
    -s protocol=openid-connect \
    -s 'attributes."include.in.token.scope"=false' \
    -s 'attributes."display.on.consent.screen"=false')
fi

kcadm update "client-scopes/$scope_uuid" -r "$TARGET_REALM" \
  -s "name=$SCOPE_NAME" \
  -s protocol=openid-connect \
  -s 'attributes."include.in.token.scope"=false' \
  -s 'attributes."display.on.consent.screen"=false' >/dev/null

prune_protocol_mappers "$scope_uuid" account-api-audience account-api-roles

ensure_protocol_mapper "$scope_uuid" account-api-audience \
  '{"name":"account-api-audience","protocol":"openid-connect","protocolMapper":"oidc-audience-mapper","consentRequired":false,"config":{"included.client.audience":"account","id.token.claim":"false","access.token.claim":"true","introspection.token.claim":"true"}}'

ensure_protocol_mapper "$scope_uuid" account-api-roles \
  '{"name":"account-api-roles","protocol":"openid-connect","protocolMapper":"oidc-usermodel-client-role-mapper","consentRequired":false,"config":{"usermodel.clientRoleMapping.clientId":"account","claim.name":"resource_access.account.roles","jsonType.label":"String","multivalued":"true","id.token.claim":"false","access.token.claim":"true","userinfo.token.claim":"false","introspection.token.claim":"true"}}'

core_scope_uuid=$(optional_lookup client_scope_id_by_name "$CORE_SCOPE_NAME")
if [[ -z $core_scope_uuid ]]; then
  core_scope_uuid=$(kcadm create client-scopes -r "$TARGET_REALM" -i \
    -s "name=$CORE_SCOPE_NAME" \
    -s protocol=openid-connect \
    -s 'attributes."include.in.token.scope"=false' \
    -s 'attributes."display.on.consent.screen"=false')
fi

kcadm update "client-scopes/$core_scope_uuid" -r "$TARGET_REALM" \
  -s "name=$CORE_SCOPE_NAME" \
  -s protocol=openid-connect \
  -s 'attributes."include.in.token.scope"=false' \
  -s 'attributes."display.on.consent.screen"=false' >/dev/null

prune_protocol_mappers "$core_scope_uuid" sub auth_time

ensure_protocol_mapper "$core_scope_uuid" sub \
  '{"name":"sub","protocol":"openid-connect","protocolMapper":"oidc-sub-mapper","consentRequired":false,"config":{"introspection.token.claim":"true","access.token.claim":"true"}}'

ensure_protocol_mapper "$core_scope_uuid" auth_time \
  '{"name":"auth_time","protocol":"openid-connect","protocolMapper":"oidc-usersessionmodel-note-mapper","consentRequired":false,"config":{"user.session.note":"AUTH_TIME","id.token.claim":"true","introspection.token.claim":"true","access.token.claim":"true","claim.name":"auth_time","jsonType.label":"long"}}'

default_scopes=$(kcadm get "clients/$client_uuid/default-client-scopes" \
  -r "$TARGET_REALM" \
  --fields id,name \
  --format csv \
  --noquotes)
while IFS=, read -r default_scope_id default_scope_name; do
  [[ -n $default_scope_id ]] || continue
  if [[ $default_scope_id != "$scope_uuid" && $default_scope_id != "$core_scope_uuid" ]]; then
    kcadm delete "clients/$client_uuid/default-client-scopes/$default_scope_id" \
      -r "$TARGET_REALM" >/dev/null
  fi
done <<<"$default_scopes"
for required_default_scope_id in "$scope_uuid" "$core_scope_uuid"; do
  if ! grep -Eq "^$required_default_scope_id," <<<"$default_scopes"; then
    kcadm update "clients/$client_uuid/default-client-scopes/$required_default_scope_id" \
      -r "$TARGET_REALM" \
      -n \
      -b '{}' >/dev/null
  fi
done

optional_scopes=$(kcadm get "clients/$client_uuid/optional-client-scopes" \
  -r "$TARGET_REALM" \
  --fields id,name \
  --format csv \
  --noquotes)
while IFS=, read -r optional_scope_id optional_scope_name; do
  [[ -n $optional_scope_id ]] || continue
  kcadm delete "clients/$client_uuid/optional-client-scopes/$optional_scope_id" \
    -r "$TARGET_REALM" >/dev/null
done <<<"$optional_scopes"

account_client_uuid=$(optional_lookup client_id_by_client_id account)
if [[ -z $account_client_uuid ]]; then
  printf 'Built-in account client was not found\n' >&2
  exit 1
fi

assigned_account_roles=$(kcadm get \
  "clients/$client_uuid/scope-mappings/clients/$account_client_uuid" \
  -r "$TARGET_REALM" \
  --fields id,name \
  --format csv \
  --noquotes)

while IFS=, read -r assigned_role_id assigned_role_name; do
  [[ -n $assigned_role_id ]] || continue
  case "$assigned_role_name" in
    manage-account|view-profile) ;;
    *)
      kcadm delete "clients/$client_uuid/scope-mappings/clients/$account_client_uuid" \
        -r "$TARGET_REALM" \
        -b "[{\"id\":\"$assigned_role_id\",\"name\":\"$assigned_role_name\"}]" >/dev/null
      ;;
  esac
done <<<"$assigned_account_roles"

for role_name in manage-account view-profile; do
  role_uuid=$(optional_lookup client_role_id_by_name "$account_client_uuid" "$role_name")
  if [[ -z $role_uuid ]]; then
    printf 'Built-in account role was not found: %s\n' "$role_name" >&2
    exit 1
  fi
  if ! grep -Eq "^[^,]+,$role_name$" <<<"$assigned_account_roles"; then
    kcadm create "clients/$client_uuid/scope-mappings/clients/$account_client_uuid" \
      -r "$TARGET_REALM" \
      -b "[{\"id\":\"$role_uuid\",\"name\":\"$role_name\"}]" >/dev/null
  fi
done

printf 'Account Center Keycloak configuration is reconciled.\n'
