# Secrets live in OpenBao, and services hold references to them

Until now SKY LAB's secrets (database passwords, Keycloak client secrets, SMTP and Redis credentials, deploy hooks) lived as plain values in each Dokploy application's environment and in GitHub secrets, and people moved them by copy and paste. On 2026-09-24 that went wrong twice. A whole production environment was pasted into a sandbox application, so sandbox SkyMail ran on the production database and a sandbox seed wrote to production templates. Separately, the production database password was pasted into a chat. Both were rotated by hand.

We decided to keep every secret in one self-hosted OpenBao, and to give services a reference instead of a value. OpenBao is the Linux Foundation continuation of Vault under MPL-2.0. Owner Yusuf's criterion was "the most widely used open-source option". The industry standard is the Vault API, but Vault itself has been under the non-OSI Business Source License since 1.15, and OpenBao is the open-source line of that API. Dokploy (already running) reads OpenBao natively as a secrets provider at deploy time.

The deployment:
- one OpenBao on the Dokploy server, reachable only from the internal network;
- integrated Raft storage on its own volume;
- automatic unseal;
- a file audit device;
- people sign in through Keycloak OIDC (`e-skylab`).

Production and sandbox are separate mounts with separate policies, and each has its own Dokploy provider token. The production provider is assigned only to production applications, so a production reference copied into a sandbox application fails the deploy instead of connecting. Custody of the recovery and unseal keys is kept outside this record; a break-glass way in exists for when Keycloak is down. Secrets that ever left OpenBao are regenerated inside it, so no person sees the new value.

The first stage only centralises. Scheduled rotation, runtime short-lived database credentials, GitHub Actions OIDC and Keycloak's preview client-secret rotation are later stages, each with its own decision.

Rejected:
- **Vault Community:** the most widely used, but not open source under the owner's criterion, and namespaces and automated snapshots are Enterprise features.
- **Infisical:** the easiest UI, but dynamic credentials, rotation, audit logs and Keycloak SSO are paid features in self-hosting.
- **Conjur OSS:** low activity, and no dynamic credentials.
- **SOPS alone:** encrypts files in git but does not rotate or stop copy and paste.
- **Shamir unseal by three people:** safest, but every reboot and upgrade would need people before a deploy could run.
- **A second server for transit unseal:** extra cost and upkeep.
- **Storage in the shared PostgreSQL:** the same failure domain as the databases OpenBao manages.
- **Exposing OpenBao to the internet for GitHub Actions:** CI deploy hooks stay in GitHub secrets for now.
- **Two OpenBao instances for production and sandbox:** double the upkeep. Neither option removes the risk of root on the shared server.
