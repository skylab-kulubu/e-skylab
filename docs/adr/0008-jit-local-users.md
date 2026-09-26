# Local users are JIT from JWT; Keycloak remains the directory

A local User row exists so domain tables can have foreign keys and app fields (skyNumber, avatar). It is created or updated on authenticated API requests from the JWT (JIT upsert on Keycloak `sub`). Admin UI mutations write Keycloak and the local row together. Member and team listings come from Keycloak, not from the local table. RabbitMQ is not used for identity sync. The SKY LAB admin UI is the existing superadmin app (admin.yildizskylab.com), not a new SPA and not HTML from Go.
