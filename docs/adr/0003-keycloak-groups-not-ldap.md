# Keycloak groups, not LDAP

LDAP will be removed. Club membership, team roster, leadership, and privilege are already modeled as Keycloak groups (and group attributes such as `public_listing`); OPA and the public team listing already read that tree from the JWT and Admin API. LDAP today is only a promotion/federation sidecar plus a direct write into Keycloak's `user_entity` — a second source of truth we do not need. Promote becomes "add to groups." Keycloak's own admin console remains for realm/client/token setup; day-to-day group and member admin can live in our UI via the Admin API.
