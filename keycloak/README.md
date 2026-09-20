# SKY LAB Keycloak image

This directory owns the Keycloak runtime used by `e.yildizskylab.com`.

## Runtime contract

- Keycloak `26.7.4`, pinned as one atomic tag-plus-digest image reference.
- Java 21 for Keycloak and both provider builds.
- Digest-pinned Maven, PostgreSQL and RabbitMQ build/test images.
- An optimized PostgreSQL image built with `kc.sh build`.
- Exactly one SKY LAB SPI (`1.8.0`), one source-built SKY LAB login theme (`2.0.0`) and
  one RabbitMQ event provider (`3.1.0`) in `/opt/keycloak/providers`.
- `account-api:v1`, PAR, passkeys and WebAuthn are explicitly enabled at
  image build time.
- Realm/client configuration is reconciled by
  `config/reconcile-account-center.sh`; it is not a one-time realm import.
- Production is pull-only from the source-controlled
  `ghcr.io/skylab-kulubu/e-skylab-keycloak` repository and accepts only a
  validated `KEYCLOAK_IMAGE_DIGEST` input. Runtime, preflight and reconciler
  resolve to the same `repository@sha256:digest`.
  Local builds use the standalone `docker-compose.build.yml` explicitly.
- Production connects to the existing shared PostgreSQL 18 service. Compose
  never declares a PostgreSQL service, mounts its data volume or creates a
  Keycloak data volume. A read-only, non-root preflight validates the immutable
  image and shared-database inputs, then proves the configured database endpoint
  is reachable without receiving the database password. Keycloak performs the
  authenticated database and schema checks during normal startup.
- Forwarded headers are accepted only from the required
  `KEYCLOAK_PROXY_TRUSTED_ADDRESSES` allowlist.

The login theme is rebuilt from [`theme/`](theme/) with Keycloakify `11.16.0`.
The optimized image installs exactly one generated JAR and never consumes the
removed, source-less `1.1.1` binary. Unit, artifact and Chromium tests protect
the Keycloak 26.7 WebAuthn fields, retry execution, conditional-passkey
remember-me propagation, AIA controls, landmarks, keyboard operation,
contrast and reduced motion. Representative Touch ID, Face ID, Android,
Windows Hello and mobile-WebView checks on physical hardware remain an
explicit rollout gate.

## Account Center client

The reconciler manages a confidential `account-center` client with:

- Authorization Code only; implicit, Direct Access Grants and service accounts
  disabled.
- exact `https://my.yildizskylab.com/api/auth/callback` redirect and no web
  origins;
- required S256 PKCE and Pushed Authorization Requests;
- exact backchannel logout and post-logout callback URLs;
- a client-specific copy of the browser flow whose first alternative execution
  atomically redeems `sky_native_handoff` over HMAC-authenticated mTLS;
- one custom default client scope that limits and emits the built-in Account
  API audience and `manage-account` / `view-profile` roles;
- one source-controlled core-claims scope that emits only access-token `sub`
  and ID/access-token `auth_time`, without depending on the realm-global
  `basic`, `profile` or `email` scopes;
- no optional client scopes, matching the BFF's minimal `openid`
  authorization request.

Realm session, AIA, theme and passwordless WebAuthn settings live in
`config/account-center-realm.json`. The standard client browser execution graph
has an exact source-controlled signature; reconciliation rebuilds it if an
execution requirement, priority, provider, subflow or authenticator
configuration drifts. Mapper, Account role, default-scope and optional-scope
allowlists remove unknown entries.

The steady reconciler authenticates as the service-only
`account-center-config` client. Creating or rotating that client is a separate,
audited bootstrap step; master administrator credentials are absent from the
normal compose stack.

The `sky-native-handoff` execution is bound only to the Account Center client.
Without a bridge hint it marks itself attempted and leaves normal desktop login
unchanged. With a hint it removes the note before network I/O, redeems exactly
once, selects the enabled user only by `sub`, and carries the original
`auth_time` into the new browser session. A failed or replayed bridge never
falls back to the password form.

## Local verification

Requirements: Docker, `bash`, `curl` and `jq`.

```bash
docker build --platform linux/amd64 -t account-keycloak:test keycloak
KEYCLOAK_TEST_IMAGE=account-keycloak:test bash keycloak/tests/run-integration.sh
```

For a local image build, use the standalone build definition. It deliberately
does not inherit production's external-volume or preflight contract:

```bash
docker compose -f keycloak/docker-compose.build.yml build
```

Static/render checks deliberately run before the candidate exists. After the
build, a separate runtime preflight reaches a PostgreSQL fixture across an
internal Docker network and rejects an unreachable endpoint or malformed
production input. The main fixture then starts PostgreSQL, RabbitMQ and the
optimized image; runs reconciliation twice with deliberate configuration drift
between runs; checks
the exact OIDC client contract and a live minimal `openid` PAR request;
completes a browser Authorization Code + S256 exchange; asserts the ID
token's `sub`, `sid` and integer/non-future `auth_time`; and proves an actual
Keycloak admin event reaches RabbitMQ. Source-level Chromium coverage runs
before the image build; the runtime fixture verifies the generated theme loads
on Keycloak 26.7.4. Physical-authenticator evidence remains a release gate.

`keycloak/vX.Y.Z` releases are accepted only when the tag points at the current
`main` commit and matches the version in the pinned Keycloak image reference.
The protected build job has no package-write permission: it builds and loads
one candidate image, runs the full fixture and commit-bound physical WebAuthn
gate, then uploads a one-day artifact containing the tested image, its exact
source-built theme JAR, commit SHA, image ID and checksums. Only the dependent
publish job receives package-write permission. It verifies those identities,
the one-JAR/theme contract and the transferred checksums before retagging and
pushing the same image bytes as `X.Y.Z`, `latest`, `main` and `production`; it
never rebuilds them. The mutable aliases are updated only by this gated release
path, never by an ordinary push to `main`. Production deployment still uses the
immutable manifest digest recorded by the workflow, not a mutable alias.

Production deployment must follow
[`docs/keycloak-26.7.4-upgrade-runbook.md`](../docs/keycloak-26.7.4-upgrade-runbook.md).
