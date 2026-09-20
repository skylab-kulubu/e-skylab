# Keycloak 26.7.4 upgrade and Account Center cutover

This runbook is mandatory. Do not point the new image or reconciler at
production until the backup, production-clone rehearsal and rollback rehearsal
below have recorded evidence and an owner.

## Known gates

- `e-skylab-theme` is now rebuilt from source with Keycloakify 11.16.0. CI
  covers real Keycloak 26.7 password login, password/TOTP AIA cancel and
  completion, WebAuthn error retry, registration and a cookie-cleared
  passwordless assertion with a Chromium virtual authenticator, plus
  conditional-passkey remember-me, locale, keyboard,
  reduced motion and contrast contracts. CI cannot supply production platform
  authenticators. The initial rollout records successful registration,
  cancellation, passwordless login and failure recovery on the available
  Touch ID surface; mocked or virtual credentials are not a substitute for
  this evidence. Face ID, Android Credential Manager, Windows Hello and mobile
  WebView coverage are explicitly deferred to post-release compatibility
  testing. A failure on a deferred surface is handled as a compatibility fix
  and does not retroactively expand the recorded release evidence.

  The production clone must report
  `webAuthnPolicyPasswordlessPasskeysEnabled=true` and
  `webAuthnPolicyPasswordlessMediation=conditional` after reconciliation.
  Without both fields Keycloak renders only password login even when the user
  owns a valid passwordless WebAuthn credential.

  The `keycloak-production` release environment must define all three variables
  below. The release gate rejects absent data, evidence for another commit, or
  a surface list different from the recorded rollout scope before registry
  login or image publication:

  - `KEYCLOAK_PHYSICAL_WEBAUTHN_APPROVED_COMMIT`: the exact candidate commit
    from the release job;
  - `KEYCLOAK_PHYSICAL_WEBAUTHN_EVIDENCE_URL`: HTTPS URL to the retained test
    record for the tested rollout scope;
  - `KEYCLOAK_PHYSICAL_WEBAUTHN_APPROVED_SURFACES`:
    `touch-id`.

  The protected build/test job has read-only repository permission and no
  registry write capability. It packages the already-tested image and exact
  theme JAR only after the commit-bound physical gate. The dependent publish
  job alone receives `packages: write`; it verifies the one-day artifact's
  commit SHA, checksums, image ID and one-JAR/theme contract, and cannot rebuild
  the candidate.
- The `sky-native-handoff` authenticator, protected mTLS/HMAC redemption client,
  client-specific browser flow and `skyapp` audience mapper are included in the
  candidate. Native application WebView coverage remains part of the deferred
  post-release compatibility scope.
- `https://my.yildizskylab.com/api/auth/backchannel-logout` is the agreed
  Keycloak contract, but the Account Center route must exist and pass logout
  tests before production enablement.
- A production-clone database upgrade and rollback have not been performed by
  repository tests. They require an operator and production-derived data.
- The fixture proves minimal `openid` PAR acceptance, negative redirect and
  plain-PKCE rejection, a browser-driven Authorization Code flow, password and
  TOTP AIA mutation, virtual WebAuthn registration/retry/passwordless
  assertion, ID-token
  `sub`/`sid`/`auth_time`, token audience/roles, Account REST profile read and
  source-built theme rendering. It does not replace the recorded Touch ID
  check or deliver backchannel logout to the BFF; those remain release gates.
  Face ID and the other deferred surfaces stay post-release compatibility work.

## 1. Capture and verify a backup

1. Announce a change window and identify the current Keycloak image digest,
   database server/version, realm export location and rollback owner.
2. Quiesce administrative writes or take a transactionally consistent
   PostgreSQL backup using the platform's managed-backup mechanism. Never copy
   a live data directory.
3. Record a checksum, backup timestamp and PostgreSQL version. Restore the
   backup into an isolated production-clone database.
4. Confirm the clone is network-isolated from production RabbitMQ, SMTP,
   identity providers and application callback URLs. Use sink services or
   disabled event listeners.
5. Export the current `e-skylab` realm from the clone with the old image as a
   secondary logical recovery artifact. Keep credentials encrypted and out of
   the repository.

## 2. Production-clone rehearsal

1. Start the exact candidate image digest against the restored clone with
   outbound integrations isolated.
2. Wait for schema migration and readiness. Save migration logs without tokens,
   secrets or user attributes.
3. Run the reconciler using the clone admin credential and the production base
   URL. Run it twice; the second run must make no duplicate client, flow, scope
   or mapper.
4. Verify:
   - existing browser and brokered login;
   - password, OTP and passkey flows;
   - the Microsoft department mapper and Core user-creation execution;
   - RabbitMQ publishing against a sink broker;
   - Account REST profile, credentials and sessions with a real user token;
   - PAR, S256 PKCE, exact redirect rejection and backchannel logout;
   - one SPI JAR, one theme JAR and one RabbitMQ provider JAR at runtime.
5. Measure migration and restart duration. The production change window must
   include this time plus rollback margin.

## 3. Client-secret custody

The reconciler creates a confidential client but never prints, accepts or
rotates its secret. Keycloak generates the initial value.

1. An authorized operator retrieves the generated secret once through a secure
   admin session. Disable shell tracing and terminal recording. Do not paste it
   into a ticket, chat, CI output or repository file.
2. Store it as `OIDC_CLIENT_SECRET` in the Account Center production secret
   store. Only the BFF runtime may receive it; it must never use a
   `NEXT_PUBLIC_` variable.
3. Deploy Account Center, then validate one Authorization Code + PAR login.
4. For rotation, use Keycloak's client-secret rotation with an overlap window:
   generate the new secret, write it as a new secret-store version, roll all BFF
   replicas, verify login, then invalidate the old secret. If the configured
   Keycloak policy cannot retain an overlap secret, perform a coordinated
   maintenance-window rotation and keep rollback credentials ready.
5. Never retrieve or echo the secret in routine reconciliation. Audit rotation
   by secret version identifier and time, never by value.

## 4. One-time reconciler bootstrap

Steady-state reconciliation uses the `account-center-config` service account in
the `e-skylab` realm. It receives only `manage-clients`, `view-clients`,
`manage-realm` and `view-realm` from `realm-management`. The production compose
file never exposes a master/bootstrap administrator to Keycloak or the config
job.

1. Generate `KEYCLOAK_CONFIG_CLIENT_SECRET` in the production secret store. Do
   not print it or put it in shell history.
2. On a brand-new database only, create a temporary bootstrap administrator
   using Keycloak's offline `bootstrap-admin user` command before starting the
   server. Existing realms use a separately issued temporary administrator.
3. Start Keycloak, then run the `keycloak-bootstrap` service from
   `docker-compose.bootstrap.yml` with the temporary administrator and scoped
   client secret injected by the platform secret store.
4. Verify the service account role allowlist, then delete or disable the
   temporary administrator and remove its credentials from the deployment.
5. Run the normal `keycloak-config` job. Rotation repeats the guarded bootstrap
   job with a new scoped secret; master credentials never enter steady state.

## 5. Immutable artifact and proxy boundary

The release workflow builds one candidate, tests that local image, and pushes
the same image as the version plus the `latest`, `main` and `production`
aliases. Those mutable aliases move only after the tagged release passes the
physical WebAuthn gate. The workflow records the registry manifest digest in
its summary. The repository is hardcoded in Compose as
`ghcr.io/skylab-kulubu/e-skylab-keycloak`; operators can supply only the 64
hexadecimal characters after `sha256:` as `KEYCLOAK_IMAGE_DIGEST`. Production
compose constructs one exact `repository@sha256:digest` for runtime, preflight
and reconciler. The validator rejects tags, `latest`, digest prefixes and
malformed digests, while the rendered-Compose gate proves repository override
environment variables cannot alter a service image. Record the release tag,
digest, workflow run and candidate commit in the change evidence.

Set `KEYCLOAK_PROXY_TRUSTED_ADDRESSES` to only the actual reverse-proxy
container IPs or the smallest dedicated proxy-network CIDR. Do not use the
whole shared `skynet` range. The reverse proxy must discard client-supplied
`Forwarded`/`X-Forwarded-*` headers and write its own values before forwarding.
Keep Keycloak's HTTP and management ports bound to loopback or private networks;
only the trusted proxy may reach the HTTP listener across the application
network.

## 6. Shared PostgreSQL preflight

Production stores Keycloak alongside the other SKY LAB databases in the
existing PostgreSQL 18 service. The Keycloak deployment must not start another
PostgreSQL container, attach the shared `PGDATA` volume or create a Keycloak
data volume. Keycloak's durable state remains in its existing database.

1. Record the running PostgreSQL service name, port, database, user and schema.
   The current service hostname is `sky-lab-production-postgres-ik33fe`, the
   database is `keycloak`, and the schema is `public`. Retrieve the existing
   username and password from the platform secret store; never copy them from
   process output into the repository or change record.
2. Confirm the Keycloak and PostgreSQL services share only the intended Dokploy
   application network. Do not publish PostgreSQL's port on the host.
3. Confirm the fresh backup has been copied off the server, restored into an
   isolated PostgreSQL 18 clone and checked before changing the image.
4. With production inputs injected, run the preflight alone:

   ```bash
   docker compose -f keycloak/docker-compose.yml run --rm --no-deps keycloak-preflight
   ```

   It must validate the immutable image, exact Account Center origin and shared
   database endpoint, then prove the endpoint is reachable. The preflight runs
   as UID 1000 with a read-only root filesystem, all capabilities dropped and
   `no-new-privileges`. It does not receive the database password. Authenticated
   database and schema validation happens when Keycloak starts.
5. Render `docker compose ... config` and verify all three Keycloak services use
   the same `repository@sha256:digest`, only the external `skynet` network is
   present, and there is no `keycloak-db` service or production volume.

## 7. Production rollout

1. Reconfirm a fresh backup and the tested rollback owner.
2. Deploy the exact candidate by setting `KEYCLOAK_IMAGE_DIGEST` and the
   recorded shared PostgreSQL endpoint inputs; the GHCR repository is
   source-controlled and cannot be overridden. Do not mount the old provider
   directory: providers are already inside the optimized image. Do not mount
   the shared PostgreSQL volume into the Keycloak deployment.
3. Confirm `/health/ready` on the management port before routing traffic.
4. Run `reconcile-account-center.sh` once, then inspect the client contract with
   read-only admin calls. Save redacted evidence.
5. Verify existing logins before exposing Account Center. Then perform desktop
   PAR/PKCE login, Account REST reads, AIA return and backchannel logout tests.
6. Watch login error rate, database errors, provider exceptions, RabbitMQ
   channel state and latency through the full change window.

## 8. Rollback rehearsal and production rollback

Keycloak database migrations are not assumed to be backward-compatible with
the prior image.

1. In the isolated clone, stop Keycloak after the 26.7.4 upgrade, discard the
   migrated clone database, restore the pre-upgrade backup into a fresh
   database, and start the exact old image digest. Prove existing login works.
2. Record the full restore time and commands in the change record.
3. If production rollback is required, stop all candidate replicas first. Do
   not start the old image against the migrated database.
4. Restore the pre-upgrade backup to a clean database, point the exact old image
   digest at it, validate readiness/login, then reopen traffic.
5. Account for writes made after the backup explicitly. Do not silently merge
   Keycloak tables between old and migrated databases.
