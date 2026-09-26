# Single Postgres instance, multiple databases

All services share one Postgres container. Each service keeps its own named database and role (Keycloak, super-skylab, CMS, forms, SkyMail, and so on). This cuts idle RAM versus one Postgres per service and makes backup a single `pg_dumpall`, without mixing Keycloak or CMS tables into the core schema. Application services remain separate processes; only the database *process* is shared. Redis follows the same rule (one container; see ADR 0015).
