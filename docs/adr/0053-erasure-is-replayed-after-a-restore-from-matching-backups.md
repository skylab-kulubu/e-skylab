# Erasure is replayed after a restore by reading addresses from matching backups

Restoring a service database from a backup taken before some erasures brings those people's e-mail-keyed data back into the live database: SkyMail recipient rows, list memberships and queued mail. Core cannot find them again. After an erasure completes, core keeps no address and no hash of one (CONTEXT: Account erasure), and SkyMail keeps no suppression list (ADR-0051). Replaying the Erasure command with `emails: []` re-erases only subject-keyed data. The rows stay live; they do not age out with the backup.

Regulators agree on the outcome and leave the method to the controller. After a restore, deletions are applied again: the EDPB's 2025 coordinated enforcement report, Denmark's Datatilsynet, CNIL's developer guide, the ICO's "beyond use" guidance and KVKK deletion regulation art. 8.

We decided (Yusuf, 2026-09-26): **no new record is kept. A restore replays erasure by reading the addresses from the matching core and Keycloak backups.**
- After service X is restored to time T, core lists the requests completed after T.
- For each request, it loads the newest core backup taken before that request's `anonymize_core` step, and the newest Keycloak backup taken before its `delete_identity` step. Each goes into a temporary Postgres with no network.
- It reads the person's addresses into memory only and re-sends the normal Erasure command. Endpoints and contract are unchanged.
- The temporary databases are destroyed. The replay is recorded without personal data, like any erasure (regulation art. 7(3)).

Rejected:
- **An encrypted, time-limited address ledger (OpenBao).** It stores exactly what the rule forbids, if only for a while, and its decrypt permission is a new attack surface.
- **A ledger of deleted row ids.** It changes three services' contracts, Forms' included, and serial ids can be reissued after a restore.
- **A keyed hash (HMAC) ledger.** It is pseudonymous personal data and breaks the "no hash of the e-mail" rule.

Consequences:
- **Backup discipline becomes a requirement.**
  - Core and Keycloak backups are taken at least as often, and kept at least as long, as any service backup. Otherwise a service backup can exist with no matching core backup.
  - Hand-made dumps (SkyMail and Keycloak dumps on the server and on an operator's machine) get a retention limit.
  - Dump wizards refuse, or warn, when a service dump has no core and Keycloak dump beside it.
- **The replay tool must refuse** a service backup that has no matching core backup, rather than silently leave residue.
- **An address the person changed between two backups can be missed.** This is the same limit as "earlier addresses cannot be found".
- **A whole-server restore still loses** the deletion requests opened after the last backup. That gap is separate and is not closed by this decision.
- **Until the replay tool exists,** a restore that needs it is replayed by hand from the matching core backup. This does not block enabling erasure: a restore is a rare disaster operation.
