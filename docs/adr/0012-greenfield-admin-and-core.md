# Java and the current admin can go down; Go and superadmin are greenfield

The running Java stack and the current superadmin are not in daily use. They stay as a behaviour reference (and for a DB dump), but we will not keep them live during the rewrite or preserve superadmin's LDAP/realm-role UI. Superadmin can be taken from scratch against Keycloak groups and the new Go/CMS APIs.
