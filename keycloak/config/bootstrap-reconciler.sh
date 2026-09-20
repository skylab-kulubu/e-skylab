#!/usr/bin/env bash
set -Eeuo pipefail
shopt -s inherit_errexit

umask 077

KCADM=${KCADM_BIN:-/opt/keycloak/bin/kcadm.sh}
ADMIN_URL=${KEYCLOAK_ADMIN_URL:-http://keycloak:8080}
ADMIN_REALM=${KEYCLOAK_ADMIN_REALM:-master}
TARGET_REALM=${KEYCLOAK_REALM:-e-skylab}
CONFIG_CLIENT_ID=${KEYCLOAK_CONFIG_CLIENT_ID:-account-center-config}
KCADM_CONFIG=$(mktemp /tmp/account-center-bootstrap-kcadm.XXXXXX)

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

require KEYCLOAK_BOOTSTRAP_ADMIN_USERNAME
require KEYCLOAK_BOOTSTRAP_ADMIN_PASSWORD
require KEYCLOAK_CONFIG_CLIENT_SECRET

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
      --realm "$ADMIN_REALM" \
      --user "$KEYCLOAK_BOOTSTRAP_ADMIN_USERNAME" \
      --password "$KEYCLOAK_BOOTSTRAP_ADMIN_PASSWORD" >/dev/null 2>&1; then
      return 0
    fi
    sleep 2
  done
  printf 'Keycloak did not become ready for reconciler bootstrap\n' >&2
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

authenticate
kcadm get "realms/$TARGET_REALM" >/dev/null

config_client_uuid=$(optional_lookup client_id_by_client_id "$CONFIG_CLIENT_ID")
if [[ -z $config_client_uuid ]]; then
  config_client_uuid=$(kcadm create clients -r "$TARGET_REALM" -i \
    -s "clientId=$CONFIG_CLIENT_ID" \
    -s name='Account Center configuration reconciler' \
    -s enabled=true \
    -s protocol=openid-connect \
    -s publicClient=false \
    -s bearerOnly=false \
    -s standardFlowEnabled=false \
    -s implicitFlowEnabled=false \
    -s directAccessGrantsEnabled=false \
    -s serviceAccountsEnabled=true \
    -s authorizationServicesEnabled=false \
    -s fullScopeAllowed=false \
    -s "secret=$KEYCLOAK_CONFIG_CLIENT_SECRET")
fi

kcadm update "clients/$config_client_uuid" -r "$TARGET_REALM" \
  -s "clientId=$CONFIG_CLIENT_ID" \
  -s name='Account Center configuration reconciler' \
  -s enabled=true \
  -s protocol=openid-connect \
  -s publicClient=false \
  -s bearerOnly=false \
  -s standardFlowEnabled=false \
  -s implicitFlowEnabled=false \
  -s directAccessGrantsEnabled=false \
  -s serviceAccountsEnabled=true \
  -s authorizationServicesEnabled=false \
  -s fullScopeAllowed=false \
  -s "secret=$KEYCLOAK_CONFIG_CLIENT_SECRET" >/dev/null

service_user_id=$(kcadm get "clients/$config_client_uuid/service-account-user" \
  -r "$TARGET_REALM" \
  --fields id \
  --format csv \
  --noquotes)
[[ -n $service_user_id && $service_user_id != *,* ]] || {
  printf 'The reconciler service-account user could not be resolved exactly\n' >&2
  exit 1
}
realm_management_uuid=$(client_id_by_client_id realm-management)

assigned_roles=$(kcadm get \
  "users/$service_user_id/role-mappings/clients/$realm_management_uuid" \
  -r "$TARGET_REALM" \
  --fields id,name \
  --format csv \
  --noquotes)
client_scope_roles=$(kcadm get \
  "clients/$config_client_uuid/scope-mappings/clients/$realm_management_uuid" \
  -r "$TARGET_REALM" \
  --fields id,name \
  --format csv \
  --noquotes)

while IFS=, read -r role_id role_name; do
  [[ -n $role_id ]] || continue
  case "$role_name" in
    manage-clients|view-clients|manage-realm|view-realm) ;;
    *)
      kcadm delete \
        "users/$service_user_id/role-mappings/clients/$realm_management_uuid" \
        -r "$TARGET_REALM" \
        -b "[{\"id\":\"$role_id\",\"name\":\"$role_name\"}]" >/dev/null
      ;;
  esac
done <<<"$assigned_roles"

while IFS=, read -r role_id role_name; do
  [[ -n $role_id ]] || continue
  case "$role_name" in
    manage-clients|view-clients|manage-realm|view-realm) ;;
    *)
      kcadm delete \
        "clients/$config_client_uuid/scope-mappings/clients/$realm_management_uuid" \
        -r "$TARGET_REALM" \
        -b "[{\"id\":\"$role_id\",\"name\":\"$role_name\"}]" >/dev/null
      ;;
  esac
done <<<"$client_scope_roles"

for role_name in manage-clients view-clients manage-realm view-realm; do
  if grep -Eq "^[^,]+,$role_name$" <<<"$assigned_roles"; then
    user_has_role=true
  else
    user_has_role=false
  fi
  if role_id=$(client_role_id_by_name "$realm_management_uuid" "$role_name"); then
    :
  else
    role_lookup_status=$?
    if [[ $role_lookup_status == 1 ]]; then
      printf 'realm-management role was not found: %s\n' "$role_name" >&2
    fi
    exit "$role_lookup_status"
  fi
  if [[ $user_has_role == false ]]; then
    kcadm create \
      "users/$service_user_id/role-mappings/clients/$realm_management_uuid" \
      -r "$TARGET_REALM" \
      -b "[{\"id\":\"$role_id\",\"name\":\"$role_name\"}]" >/dev/null
  fi
  if ! grep -Eq "^[^,]+,$role_name$" <<<"$client_scope_roles"; then
    kcadm create \
      "clients/$config_client_uuid/scope-mappings/clients/$realm_management_uuid" \
      -r "$TARGET_REALM" \
      -b "[{\"id\":\"$role_id\",\"name\":\"$role_name\"}]" >/dev/null
  fi
done

printf 'Scoped Account Center reconciler identity is bootstrapped.\n'
