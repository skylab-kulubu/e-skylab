# Core orchestrates cross-service account erasure

A confirmed account deletion must remove the person's personal data from every service that holds it (ADR-0042), not only from core and Keycloak. Today core's deletion worker blocks the subject, logs them out, anonymizes core and deletes the Keycloak user within seconds. It also writes an `account_deletion_outbox` row that nothing reads; core's docs leave that consumer to an Account center orchestrator that was never designed. SkyMail, CMS and Forms have no erase path at all. Three facts shape the choice:
- production has no message broker; the only service-to-service pattern is HTTP with OAuth client credentials;
- SkyMail keys recipients and sent mail by e-mail address, and Forms can recognise a guest response only by an address inside the answers, while the outbox carries UUIDs only;
- core erases the e-mail and deletes the Keycloak user without waiting for any other service.

Every published industry design (Twitter, Airbnb, Uber, Meta) has one central component start the erasure and track its completion. The erase command carries the identifier the receiving system keys its data by, and the root identity is deleted last.

We decided (Yusuf, 2026-09-25):

1. **Core's existing deletion worker orchestrates.**
   - It sends SkyMail, CMS and Forms one idempotent HTTP erase command each, keyed by the deletion `request_id`, authenticated with OAuth client credentials and a per-service erase role.
   - Each call is a checkpointed saga step under the worker's existing lease, fence, retry and `manual_intervention` rules. A request is complete only when every service has confirmed.
   - A watchdog alerts on every request still open on day 20, ahead of the KVKK 30-day deadline.
   - The outbox stays a producer-only record. Core's statement that an Account center orchestrator consumes it is withdrawn.
2. **The command carries the addresses; the identity is deleted last.**
   - The request body holds `request_id`, `subject_id` and the person's school, personal and primary addresses. Core reads them fresh on every attempt and never writes them to the outbox, logs or any durable store.
   - Service steps run after logout and before core anonymizes its own data. Deleting the Keycloak user waits for every service checkpoint.
3. **Records stay, personal data goes** (ADR-0042 applied).
   - Required actor columns (sender, approver, editor, archiver) take one shared placeholder, "Silinmiş kullanıcı", the same for everyone.
   - Rendered mail bodies and free text naming the person are deleted whole, not partially masked.
   - Proof of each completed erasure (request, step times, per-service counts, no e-mail) is kept at least three years (KVKK deletion regulation art. 7(3)).
4. **SkyMail keeps no suppression list.** Nothing derived from the address survives, so a manual mailing list can take the address again.
5. **Published CMS News keeps its free-text author byline** as editorial record; the `UpdatedBy`/`ArchivedBy` subjects are cleared.

Consequences:
- Core must know every service that holds personal data. A new service that stores personal data is not finished until it has an erase step.
- An unavailable service delays the Keycloak deletion. The identity is already disabled and logged out, so this delays erasure but grants no access. Retries must outlast the nightly secret rotation (ADR-0050).
- Every service gains an erase endpoint, a receipt table and an erase role. SkyMail and CMS token checks grow an `azp`, audience and role check for that route.
- Addresses the person used earlier are stored nowhere and cannot be found. This limit is documented, not solved.
- Whether the club or YTÜ is the data controller is undecided, and the periodic-destruction interval (six months or three) depends on it. The interval is therefore configuration, not code.
- Forms belongs to Fatih. Its part (response redaction default and exceptions, guest responses found by address, owner handover) waits on his decisions, and erasure is not enabled before it ships.
- Core's `docs/account-lifecycle.md` and the enablement gates change with this decision.

Rejected:
- **An Account center orchestrator reading the outbox through a new core API.** It breaks Account center's no-service-account contract and writes the saga machinery a second time. The e-mail is also gone from core before Account center could read it.
- **Each service pulling deletions from core.** Three pollers plus a new core read API, and completion would still need a callback. It does not solve the e-mail window either.
- **A message broker.** None runs in production; RabbitMQ was stopped at cutover. The published designs that use Kafka still close completion centrally, and Twitter treats a direct API call as the simplest case for data an API can delete in real time.
- **E-mails in the outbox.** The outbox is a durable log, so addresses written there would outlive the erasure they serve.
- **A suppression hash of the address.** A hash of an address is still pseudonymous personal data (EDPB Guidelines 01/2025, WP216). Core's receipt hash already lets the person prove the request.
- **Per-person pseudonyms in actor columns.** They preserve "the same person did these three things", and at club scale that link, combined with role and date, re-identifies the person (KVKK deletion regulation art. 10: "even when matched with other data").

## Addendum: the CMS is inscribed (2026-10-03)

cms-backend, whose erase endpoint followed this decision, was retired; the CMS is stock inscribed (ADR-0056). inscribed keeps no accounts, sessions, addresses or request logs (`Auth__Mode=External`). The one personal datum it holds is the editor's Keycloak subject in `UpdatedBy` of its content tables. That subject stays personal data after the erasure: core's durable deletion request, its media access log, Keycloak's events and the backups still link it to the person, and at club scale "who edited this page when" identifies them on its own (decision 5, and the per-person pseudonym rejection above). The decision stands; the CMS part shrinks:

- **Inscribed participates through a small endpoint its owner writes.** It is the same idempotent command, path and token as the other services (`PUT …/internal/v1/account-erasures/{request_id}`, the subject in the body, `azp=core-erasure`, the `cms:account:erase` role on the `skycms` client). It replaces the subject in `UpdatedBy` with the shared placeholder in one transaction, leaves version and update time unchanged, and reports `actor_columns_replaced`. It needs no receipt table, because the work is idempotent by nature, and it resolves no tenant, because the caller is not a site. Content and published bylines stay, as decision 5 says. Unsaved Redis drafts expire on their own within seven days, inside the KVKK 30 days.
- **inscribed has no account access gate.** It has no account a stale token could revive, so the "no old JWT works anywhere" rule is relaxed for it alone; core, SkyMail, Forms and Account center keep the gate. Its endpoint therefore has no `409 subject_not_blocked`: changing an editor attribution to the placeholder deletes no content, so a compromised caller could only cost attribution.
- **Core waits six minutes before the CMS step.** Without a gate, inscribed accepts an access token issued before Keycloak disabled the person until it expires: Keycloak's 300-second access token lifespan plus inscribed's 30-second clock skew. An edit made in that window would write the subject back. Core sends the CMS command no earlier than six minutes after the identity is closed (the latest of the platform block and the disable and logout checkpoints, since Keycloak does not read the marker and can mint tokens until the disable). Until then the step is deferred without spending an attempt, and the other services do not wait. The enablement precheck verifies that the realm and every site client keep the access token lifespan at or below 300 seconds; a longer lifespan needs a longer wait first.
- **The `ArchivedBy` columns cms-backend left behind** hold archivers' subjects that inscribed neither reads nor writes. They are cleared once for everyone, not per erasure.

Considered and not chosen: core writing the inscribed database directly through a column-scoped database role. It needed no work from the owner, but it is shared-database integration and breaks "each service erases its own data". Putting the subject in the endpoint path was also rejected, since paths reach access logs.
