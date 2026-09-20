# SKY LAB Keycloak image

This directory owns the Keycloak runtime used by `e.yildizskylab.com`.

## Runtime contract

- Keycloak `26.7.4`, pinned as one atomic tag-plus-digest image reference.
- Java 21 for Keycloak and both provider builds.
- Digest-pinned Maven, PostgreSQL and RabbitMQ build/test images.
- An optimized PostgreSQL image built with `kc.sh build`.
- Exactly one SKY LAB SPI (`1.7.0`), one SKY LAB login theme (`1.1.1`) and
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
- Production data volumes are required external resources with operator-supplied
  names. A networkless, read-only preflight checks the PostgreSQL 17 control
  file, fixed system catalogs/databases, transaction state and a complete WAL
  segment before the database or Keycloak is allowed to start. Marker-only or
  empty volumes cannot pass. Only that preflight runs as UID 0 with
  `DAC_READ_SEARCH`, so it can inspect 0700 volumes owned by either the prior
  Debian image UID or the pinned Alpine image UID; runtime privileges are not
  widened.
- Forwarded headers are accepted only from the required
  `KEYCLOAK_PROXY_TRUSTED_ADDRESSES` allowlist.

The theme JAR is the latest known deployed binary. Its original Keycloakify
source is not present in this repository and has **not** been reconstructed or
represented as source. The binary was built with Keycloakify 11.15.0 and is not
production-ready for Account Center: its passkey pages lose required WebAuthn
options, its retry action is malformed, and its HTML/a11y behavior has not met
the release contract. Issue 05 must replace it with a source-controlled
Keycloakify 11.16-or-newer rebuild and real WebAuthn/AIA browser tests. The
fixture here proves only that the currently deployed binary loads and renders.

## Account Center client

The reconciler manages a confidential `account-center` client with:

- Authorization Code only; implicit, Direct Access Grants and service accounts
  disabled.
- exact `https://my.yildizskylab.com/api/auth/callback` redirect and no web
  origins;
- required S256 PKCE and Pushed Authorization Requests;
- exact backchannel logout and post-logout callback URLs;
- a client-specific copy of the browser flow;
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

The copied browser flow intentionally contains only Keycloak's standard browser
executions. The `sky-native-handoff` authenticator does not exist yet. Native
SSO bridge work must add that provider and execution before mobile handoff can
be declared ready.

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
build, a separate runtime preflight initializes a real PostgreSQL Alpine 0700
volume, accepts it, and rejects the former marker-only false-positive fixture.
The main fixture then starts PostgreSQL, RabbitMQ and the optimized image; runs
reconciliation twice with deliberate configuration drift between runs; checks
the exact OIDC client contract and a live minimal `openid` PAR request;
completes a real browser Authorization Code + S256 exchange; asserts the ID
token's `sub`, `sid` and integer/non-future `auth_time`; and proves an actual
Keycloak admin event reaches RabbitMQ. Theme verification is a load/render and
password-form smoke test, not a WebAuthn/AIA behavior or accessibility test.

`keycloak/vX.Y.Z` releases are accepted only when the tag points at the current
`main` commit and matches the version in the pinned Keycloak image reference.
CI builds and loads one candidate image, runs the full fixture against it, then
retags and pushes those same local image bytes as `X.Y.Z` and `latest` without a
second build.

Production deployment must follow
[`docs/keycloak-26.7.4-upgrade-runbook.md`](../docs/keycloak-26.7.4-upgrade-runbook.md).
