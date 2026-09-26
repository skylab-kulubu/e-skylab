# Mimari karar kayıtları (ADR)

SKY LAB platformunun servisler arası kalıcı mimari kararları bu klasörde tutulur.

Yeni bir ADR bu klasöre PR ile eklenir ve numarası mevcut en büyük numaranın bir fazlasıdır; var olan numaralar değiştirilmez.

| No | Başlık | Dosya |
| --- | --- | --- |
| 0001 | Go for application services | [0001-go-for-application-services.md](0001-go-for-application-services.md) |
| 0002 | Single Postgres instance, multiple databases | [0002-single-postgres-instance.md](0002-single-postgres-instance.md) |
| 0003 | Keycloak groups, not LDAP | [0003-keycloak-groups-not-ldap.md](0003-keycloak-groups-not-ldap.md) |
| 0004 | Ingress is Dokploy's Traefik, not Eureka or a Java gateway | [0004-dokploy-traefik.md](0004-dokploy-traefik.md) |
| 0005 | Authorization lives in the Go app, not OPA | [0005-in-process-authz-not-opa.md](0005-in-process-authz-not-opa.md) |
| 0006 | Groups are the org; client roles are per-app; realm roles go away | [0006-groups-vs-roles.md](0006-groups-vs-roles.md) |
| 0007 | Java is frozen; Go is a greenfield port, then cutover, then new work | [0007-single-prod-cutover.md](0007-single-prod-cutover.md) |
| 0008 | Local users are JIT from JWT; Keycloak remains the directory | [0008-jit-local-users.md](0008-jit-local-users.md) |
| 0009 | Superadmin is the club admin UI | [0009-superadmin-is-admin-ui.md](0009-superadmin-is-admin-ui.md) |
| 0010 | HTTP is the resource plus RFC 7807 errors | [0010-rfc7807-not-dataresult.md](0010-rfc7807-not-dataresult.md) |
| 0011 | Announcements are CMS News | [0011-announcements-are-cms-news.md](0011-announcements-are-cms-news.md) |
| 0012 | Java and the current admin can go down; Go and superadmin are greenfield | [0012-greenfield-admin-and-core.md](0012-greenfield-admin-and-core.md) |
| 0013 | skyticket-backend is legacy reference only | [0013-skyticket-is-legacy.md](0013-skyticket-is-legacy.md) |
| 0014 | CMS access is per site client; scope inside a site comes from Groups | [0014-cms-per-client-access.md](0014-cms-per-client-access.md) |
| 0015 | Single Redis instance, multiple logical databases | [0015-single-redis-instance.md](0015-single-redis-instance.md) |
| 0016 | Public traffic uses Dokploy (optional Cloudflare Tunnel); internal traffic uses Docker DNS | [0016-ingress-vs-internal-dns.md](0016-ingress-vs-internal-dns.md) |
| 0017 | Superadmin visual language is a snapshot of forms-frontend admin chrome | [0017-superadmin-looks-like-forms.md](0017-superadmin-looks-like-forms.md) |
| 0018 | Events may have no Owner team | [0018-events-may-have-no-owner-team.md](0018-events-may-have-no-owner-team.md) |
| 0019 | One resource server client per API process | [0019-one-resource-server-per-api.md](0019-one-resource-server-per-api.md) |
| 0020 | Minor product UIs live in superadmin; skyl.app is a redirect host | [0020-minor-uis-in-superadmin.md](0020-minor-uis-in-superadmin.md) |
| 0021 | Door check-in is owner-team Leader plus per-event staff | [0021-door-check-in-leader-and-event-staff.md](0021-door-check-in-leader-and-event-staff.md) |
| 0022 | Door QR authenticity is on-device; check-in settles online | [0022-door-qr-on-device-verify-online-settle.md](0022-door-qr-on-device-verify-online-settle.md) |
| 0023 | Wallet SkyPass QR rotates on platform terms, not every open | [0023-wallet-skypass-qr-platform-rotation.md](0023-wallet-skypass-qr-platform-rotation.md) |
| 0024 | SkyPass and Wallet pass show name and skyNumber, not a photo | [0024-skypass-face-name-skynumber-no-photo.md](0024-skypass-face-name-skynumber-no-photo.md) |
| 0025 | Student-card UID lives on the User shadow, not in Keycloak | [0025-student-card-uid-on-user-shadow.md](0025-student-card-uid-on-user-shadow.md) |
| 0026 | Certificate eligibility is a per-event rule on Oturum check-ins | [0026-attendance-rule-on-the-event.md](0026-attendance-rule-on-the-event.md) |
| 0027 | Current Oturum is clock plus pick; ratio counts remaining scheduled talks | [0027-oturum-check-in-bind-and-ratio-edges.md](0027-oturum-check-in-bind-and-ratio-edges.md) |
| 0028 | Dokploy pulls GHCR; one Postgres is the platform only | [0028-dokploy-pulls-ghcr-platform-postgres.md](0028-dokploy-pulls-ghcr-platform-postgres.md) |
| 0029 | Logged-in apply is native; guests use Event forms | [0029-logged-in-apply-is-native-guests-use-forms.md](0029-logged-in-apply-is-native-guests-use-forms.md) |
| 0030 | Event form create bounces to skyforms | [0030-event-form-handoff-bounces-to-skyforms.md](0030-event-form-handoff-bounces-to-skyforms.md) |
| 0031 | Mail approval lives in skymail | [0031-mail-approval-lives-in-skymail.md](0031-mail-approval-lives-in-skymail.md) |
| 0032 | Ticket is door identity; Event QR Walk-in is apply | [0032-ticket-is-door-identity.md](0032-ticket-is-door-identity.md) |
| 0033 | Short links are readable slugs, available wherever a link is created | [0033-short-links-are-readable-slugs.md](0033-short-links-are-readable-slugs.md) |
| 0034 | Participant roster is shared superadmin; Skyevents is later | [0034-participants-in-superadmin-skyevents-later.md](0034-participants-in-superadmin-skyevents-later.md) |
| 0035 | Admin writes club profile; User phone is admin-only PII | [0035-admin-writes-club-profile-phone-is-admin-only.md](0035-admin-writes-club-profile-phone-is-admin-only.md) |
| 0036 | Apply-for-other is admin Member apply, not Guest apply | [0036-apply-for-other-is-admin-member-apply.md](0036-apply-for-other-is-admin-member-apply.md) |
| 0037 | Short-link hits are silent; userId only if JWT already on the hop | [0037-short-link-hits-are-silent.md](0037-short-link-hits-are-silent.md) |
| 0038 | Certificate templates resolve by scope and issued certificates pin a version | [0038-certificate-templates-resolve-by-scope-and-pin-versions.md](0038-certificate-templates-resolve-by-scope-and-pin-versions.md) |
| 0039 | Certificate issuance follows attendance finalization and runs as durable jobs | [0039-certificate-issuance-follows-attendance-finalization.md](0039-certificate-issuance-follows-attendance-finalization.md) |
| 0040 | Certificate links stay short while the club site owns verification UI | [0040-certificate-links-redirect-to-the-club-site.md](0040-certificate-links-redirect-to-the-club-site.md) |
| 0041 | Account center lives at my.yildizskylab.com; sky-app opens it in-product | [0041-account-center-is-my-yildizskylab.md](0041-account-center-is-my-yildizskylab.md) |
| 0042 | Durable domain records are archived, not physically deleted | [0042-durable-domain-records-are-archived-not-deleted.md](0042-durable-domain-records-are-archived-not-deleted.md) |
| 0043 | Account center owns every self-service account action; Keycloak is extended by SPI, never forked or hopped to | [0043-account-center-owns-every-self-service-action-keycloak-extended-by-spi.md](0043-account-center-owns-every-self-service-action-keycloak-extended-by-spi.md) |
| 0044 | A person has a school e-mail and a personal e-mail; either signs in; the person chooses the primary | [0044-two-e-mails-per-person-either-signs-in-primary-is-chosen.md](0044-two-e-mails-per-person-either-signs-in-primary-is-chosen.md) |
| 0045 | Keycloak system e-mails are templated and sent by SkyMail, with Keycloak SMTP as fallback | [0045-keycloak-system-mail-is-templated-and-sent-by-skymail.md](0045-keycloak-system-mail-is-templated-and-sent-by-skymail.md) |
| 0046 | Mail templates are written in three authoring modes; one main source is sent, and every change is a version | [0046-mail-templates-have-three-authoring-modes-one-main-source-and-versions.md](0046-mail-templates-have-three-authoring-modes-one-main-source-and-versions.md) |
| 0047 | The repo and SkyMail both write Mail templates, and neither silently overwrites the other | [0047-repo-and-skymail-both-write-mail-templates-no-silent-overwrite.md](0047-repo-and-skymail-both-write-mail-templates-no-silent-overwrite.md) |
| 0048 | SkyApp-to-web handoff lives in Keycloak, not in Account center | [0048-skyapp-to-web-handoff-lives-in-keycloak.md](0048-skyapp-to-web-handoff-lives-in-keycloak.md) |
| 0049 | Secrets live in OpenBao, and services hold references to them | [0049-secrets-live-in-openbao-and-services-hold-references.md](0049-secrets-live-in-openbao-and-services-hold-references.md) |
| 0050 | Secrets rotate nightly, and database logins alternate | [0050-secrets-rotate-nightly-and-database-logins-alternate.md](0050-secrets-rotate-nightly-and-database-logins-alternate.md) |
| 0051 | Core orchestrates cross-service account erasure | [0051-core-orchestrates-cross-service-erasure.md](0051-core-orchestrates-cross-service-erasure.md) |
| 0052 | Media is one core service where every file declares a purpose and the owning product decides who reads it | [0052-media-declares-a-purpose-and-the-owner-decides-reads.md](0052-media-declares-a-purpose-and-the-owner-decides-reads.md) |
| 0053 | Erasure is replayed after a restore by reading addresses from matching backups | [0053-erasure-is-replayed-after-a-restore-from-matching-backups.md](0053-erasure-is-replayed-after-a-restore-from-matching-backups.md) |
| 0054 | Split Keycloak and convert e-skylab to the platform hub | [0054-split-keycloak-and-convert-e-skylab-to-platform-hub.md](0054-split-keycloak-and-convert-e-skylab-to-platform-hub.md) |
| 0055 | skylcn-ui is the shared design system for SKY LAB web products | [0055-skylcn-ui-is-the-shared-design-system.md](0055-skylcn-ui-is-the-shared-design-system.md) |
