# Superadmin is the club admin UI

Day-to-day administration is the existing Next.js app (superadmin, admin.yildizskylab.com), not a new SPA and not HTML from Go. Go exposes APIs; superadmin is rewritten onto Keycloak groups (JWT `groups`, membership, group → client-role mapping) rather than LDAP promote and realm-role strings. Member/team listings in that UI come from Keycloak via the Go Admin API facade, not from the local User table.
