# Authorization lives in the Go app, not OPA

OPA will be removed. Club rules are small (privileged groups, owner-team member/leader, otherwise read) and already sourced from Keycloak group paths in the JWT. A fail-closed HTTP hop plus another container is not worth it on a RAM-constrained host with no Java maintainers. The same checks become in-process functions behind one Authorize(user, resource, action) seam.
