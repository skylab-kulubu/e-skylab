# SKY LAB Keycloak login theme

This directory is the authoritative source for the `e-skylab-theme` login
theme. The removed `e-skylab-theme-v1-1-1` JAR is not a source dependency.
Only the two original brand image assets were carried forward.

## Runtime contract

- Keycloakify is pinned to `11.16.0` and targets Keycloak `26.7.4` through the
  single `all-other-versions` artifact `e-skylab-theme-2.0.0.jar`.
- The foundation image builds the theme from this directory and installs one
  login-theme JAR. A checked-in generated JAR is not used.
- The WebAuthn registration context must retain `authenticatorAttachment`,
  `requireResidentKey`, `residentKey` and `userVerificationRequirement`.
- WebAuthn retry posts the runtime `execution` as `authenticationExecution`;
  the historical literal `${execution}` value is forbidden.
- Conditional passkey submission mirrors the visible `rememberMe` choice into
  the WebAuthn form. Mediation and authenticator-attachment inputs continue to
  come from Keycloak's 26.7 context.
- App-initiated password, TOTP and passkey pages expose Keycloak's native
  `cancel-aia` control. `delete-credential.ftl` is the only credential-delete
  surface; the built-in delete-account action is not an Account Center
  destination.
- The custom template owns the semantic banner/main/content-info landmarks,
  skip link, native keyboard-operable language menu, visible focus treatment,
  WCAG AA button colors and `prefers-reduced-motion` behavior.

## Account Center boundary

The theme does not construct Account Center AIA URLs. The BFF must create a PAR
request for exactly one of:

- `UPDATE_PASSWORD`
- `CONFIGURE_TOTP`
- `webauthn-register-passwordless`
- `delete_credential:{ownedCredentialId}`

The BFF remains responsible for state, nonce, S256 PKCE, fresh authentication,
expected-subject binding, an allowlisted local return path, owned-credential
validation and a fresh Account REST read after success. It must never use the
Account Console or Keycloak's built-in delete-account action as a destination.

The SPI's automatic Passkey Offer is intentionally skipped for the
`account-center` client and for every request carrying `kc_action`; Account
Center actions must not be interrupted by an unsolicited offer.

Realm desired state enables Keycloak's integrated passkey UI with
`conditional` mediation. This is separate from the custom Passkey Offer:
conditional/modal passkey sign-in remains available while the unsolicited
post-login offer stays disabled for Account Center and AIA traffic.

## Verification

```bash
npm ci --ignore-scripts
npm audit --audit-level=high
npm test
npx playwright install chromium
npm run test:browser
npm run build-keycloak-theme
bash ../tests/check-theme-contract.sh
```

Vitest covers the remember-me bridge and static accessibility invariants.
The theme Chromium suite covers deterministic rendered-page contracts. The
Keycloak integration runner additionally drives Chromium through a live
Keycloak `26.7.4` instance for Turkish/English locale switching, password
login, password/TOTP AIA cancel and completion, WebAuthn error retry and
registration plus a cookie-cleared passwordless assertion with the same
virtual authenticator.

CI browser automation cannot prove platform authenticator behavior on real
Touch ID, Face ID, Android Credential Manager, Windows Hello or the supported
mobile WebViews. The initial production rollout records registration and
passwordless sign-in on physical Touch ID; cancellation and failure recovery
remain covered by the real-Keycloak automated fixture. Face ID and the other
device surfaces are deferred to post-release compatibility testing. Registry
publication is blocked unless the release environment binds an HTTPS evidence
record and the exact tested surface list to the candidate commit; a virtual
browser success is not a substitute.
