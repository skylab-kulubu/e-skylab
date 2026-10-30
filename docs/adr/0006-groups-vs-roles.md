# Groups are the org; client roles are per-app; realm roles go away

Club admin (users, groups, membership, group → client-role mappings, and extra per-user client roles) lives in the SKY LAB UI via the Keycloak Admin API. Keycloak's own console is only for IdP and OAuth2/client/token setup. Core Go authorizes from group paths in the JWT. Realm roles that duplicate the org tree are dropped at cutover.

*(2026-10-30: kişiye ek client rolü kalkar, realm rolü kalmaz ve konsol master'daki ayrı hesaplarla yalnız ayarlar ve acil durum için kullanılır; bkz. ADR-0076 ve ADR-0079.)*
