# Secrets rotate nightly, and database logins alternate

ADR-0049 put every secret in OpenBao behind references but left rotation for later. The owner asked for bank-style rotation: every day.

Dokploy resolves a reference only when it deploys, so a rotated value reaches a service only through a redeploy. Postgres gives a login one password at a time, so changing it would refuse new connections until the service restarts. Some secrets also cannot be changed blindly:
- the Auth.js and session secrets log everyone out;
- `TOKEN_ENCRYPTION_KEY` makes stored ciphertext unreadable;
- SMTP and Cloudflare R2 credentials belong to outside providers.

We decided on a rotator: a job on the Dokploy server, started nightly by a systemd timer. It works through three classes, sandbox first.

1. **Database passwords, every night, without downtime.** Each service's database owner becomes a group role with two login roles in it. Each login role defaults its session to the owner (`ALTER ROLE … SET role`), so migrations keep creating objects owned by the owner. Every night the rotator:
   - sets a new password on the idle login;
   - writes a `DATABASE_URL` that uses it into OpenBao;
   - redeploys the service and checks it.

   The login that was active until then stays valid until the next night, so no connection is ever refused and a rollback only points back at it. Keycloak's own database login rotates the same way, weekly on Sunday, because its restart blocks sign-in for a minute or two.
2. **Keycloak client secrets, every night.** The rotator regenerates each service's client secret through the admin API, stores it and redeploys that service at once. It accepts the few seconds of failed token calls during the nightly run rather than enabling Keycloak's preview client-secret rotation in production.
3. **Redis ACL passwords, every night, without downtime.** Redis lets a user hold two passwords, so the rotator:
   - adds the new one;
   - redeploys the service;
   - then removes the old one.

**On any failure** the rotator:
- puts that service back on its previous value, which is still valid;
- leaves the remaining services for the next night;
- mails the members of Keycloak's `/ADMIN` group through SMTP directly, so an alert still arrives when SkyMail itself is the broken service.

A weekly summary goes to the same people.

**The rotator's own access:**
- an OpenBao periodic token limited to what it rotates;
- a dedicated Keycloak client per realm with the realm-management roles it needs;
- a Dokploy API key.

All three are kept in OpenBao under a path the Dokploy providers cannot read.

**Never rotated automatically:**
- Auth.js and session secrets, `TOKEN_ENCRYPTION_KEY`, SMTP, R2;
- the GitHub-held SkyMail seed secret;
- credentials Dokploy manages for its own database services.

Rejected:
- **Weekly or monthly rotation:** the owner chose daily.
- **Rotate-and-restart with a single login:** refuses connections for seconds every night.
- **Runtime credential renewal inside each service** (OpenBao Agent, pool password callbacks): the strongest, but it needs code in the Go, Node, .NET and Java services; a later stage if ever.
- **OpenBao's database secrets engine as the source:** Dokploy reads only KV, so a second copy step would be needed anyway.
- **Keycloak's preview client-secret rotation:** a preview feature in production.
- **Silent rollback:** a failure nobody hears about repeats every night.
