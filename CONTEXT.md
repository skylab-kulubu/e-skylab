# SKY LAB Platform

Yıldız Teknik Üniversitesi SKY LAB kulübünün etkinlik, üyelik, kimlik ve yayın platformu. Kimlikte kaynak Keycloak; her uygulama kendi verisini tutar. Servis ve depo sahipliği için [`docs/repositories.md`](docs/repositories.md), sistem sınırları için [`docs/architecture.md`](docs/architecture.md), kararlar için [`docs/adr/`](docs/adr/README.md) kanoniktir. Bu sözlük değişiklikleri PR ile gelir.

**Deletion lifecycle**:
A user-facing durable domain record is Archived, Revoked, Disabled, or Anonymized rather than physically deleted. Normal reads hide it; authorized management views may include and restore it when the domain permits restoration. `DELETE` may remain the HTTP verb but means an idempotent lifecycle transition. Secrets and ephemeral infrastructure data (sessions, handoff/reset tokens, caches, expired drafts and queue residue), removable relationship rows, and PII erased by Account erasure are hard-deleted; keeping those as “soft-deleted” data is forbidden. Database `ON DELETE CASCADE` may clean children inside an aggregate only on maintenance purge, never erase independent history through a public delete operation.
_Avoid_: one generic `deleted` boolean for every domain; physically deleting Events, Tickets, Check-ins, Certificates, Forms, published CMS content, mail history, or templates from an operator action; retaining account PII behind `deleted_at`; exposing archived rows in normal/public reads; migrating inactive legacy repositories

## Language

**User**:
A person who can sign in through Keycloak. The core app keeps a local shadow of that person (same id as Keycloak `sub`) for domain foreign keys and club-profile fields: schoolEmail, skyNumber, avatar, LinkedIn, university, faculty, department, phone, and the bound Student-card UID (unique on this table; not a Keycloak attribute). The directory of members is Keycloak, not this table. `schoolEmail` comes from the JWT `school_email` claim on JIT; empty claims do not wipe a stored value. User search (`GET /v1/users?q=`) is against this shadow (email, schoolEmail, name), not Keycloak. Club profile on this shadow is not an Event Apply extra. Privileged people (or whoever already may manage that User in admin) may PATCH name, LinkedIn, university, faculty, department (not for a YTÜ-linked User), and phone; skyNumber and password stay off that write.
_Avoid_: LDAP user, account, ldapUser; storing a Mifare UID in Keycloak; treating the operator JWT `UserDto` as another person's card; treating university/faculty/department as only an Apply extra; resetting password on the admin card

**User phone**:
The phone number on the User shadow. Written only by admins (the Privileged user card and admin PATCH) until phone verification exists; the person may see their own number read-only in Account center, so `GET /v1/users/me` returns the caller's own phone. Not the public team roster, not SkyPass, not CMS, not guest-facing Ticket UI as "User phone", not forms.
_Avoid_: returning another person's phone on any non-admin payload; treating JWT `phoneNumber` as another person's card; treating guest Ticket phone as this field; self-editing phone before verification exists

**Member**:
A User in the `UYELER` tree. There is no second flag or LDAP status; membership *is* that group.
_Avoid_: LDAP user, federated user, ldapUser, member flag

**Account Console**:
Keycloak's self-service UI on `e.yildizskylab.com` (`/realms/{realm}/account`) for password, sessions, passkeys, and IdP profile. It remains the IdP console; sky-app does not open it today and must not grow a Custom Tabs path to it as a stopgap. Superadmin is club admin, not this panel.
_Avoid_: stuffing password/sessions into superadmin; treating waffle or the club switcher as the account UI; treating Custom Tabs to `e.` as the sky-app account product; writing a second IdP or user-store

**Account center**:
The standalone Next.js account product at `https://my.yildizskylab.com` where a User manages everything about their own account: name (unless a Verified YTÜ account), username, Personal e-mail and Primary e-mail, password, passkeys, TOTP, sessions and devices, club profile and profile picture, a read-only Permissions view, own phone read-only, and deleting the account. Reached from club consoles and in-product from sky-app so it does not feel like a website. `my.` owns the product UI, the BFF session and every self-service action; credential and e-mail mutations run through the sky-account SPI after Sudo mode, never through a hop to `e.`. `e.` is visible only for the initial login (including Self-registration and the Login code), the YTÜ Microsoft link, and the Microsoft fallback of Sudo mode for a YTÜ-linked person who has no password, passkey or TOTP. Self-delete is requested here and blocks access immediately; the Account erasure that follows is run by core, and Account center only shows its progress. There is no "applications you use" screen. Not Place, not superadmin.
_Avoid_: sending the person to `e.` for password, passkey, TOTP or e-mail changes; treating Keycloak Account Console as a destination; stuffing account management into superadmin or the club switcher; making a Keycloak theme the product; handing sky-app account management to the system browser (Custom Tabs / Safari); `account.yildizskylab.com` as the hostname; hard-deleting the core User through the cascade-prone admin delete path; managing other people's accounts here; Account center orchestrating the erasure in other services

**Account erasure**:
What follows a confirmed deletion request. Access is already blocked everywhere; core's deletion worker then has every service that holds the person's data erase it (one Erasure command each), anonymizes core, and deletes the Keycloak identity last, only after every service has confirmed. Records the club keeps stay without the person's data: actors become Silinmiş kullanıcı, and mail bodies and free text naming the person are deleted. Issued Certificates keep the recipient name and published News keeps its author byline. It must finish within 30 days, and proof that it finished, without the e-mail, is kept at least three years. See ADR-0051.
_Avoid_: Account center or an outbox consumer as the orchestrator; deleting the Keycloak identity before every service confirms; treating a disabled or closed account as erased; partial masking as erasure; keeping a hash of the e-mail to prove the erasure

**Erasure command**:
Core's instruction to one service to erase one person's data for one deletion request. It names the request and the person and carries the person's e-mail addresses only for the length of the call, never in the outbox, logs or storage. Repeating it returns the first result. The service decides, within the Deletion lifecycle rules, what it deletes and what it keeps under Silinmiş kullanıcı.
_Avoid_: event, message or webhook (there is no broker); a service pulling deletions from core; sending only an opaque id to a service that keys data by e-mail; storing the addresses to retry later

**Silinmiş kullanıcı**:
The one shared stand-in that replaces an erased person wherever a service keeps a record that must name an actor (who sent, approved, edited, archived). Everyone erased becomes the same placeholder, so it links nothing and cannot be signed in as.
_Avoid_: a per-person pseudonym; keeping the former name or e-mail beside it; treating it as a User; ghost user

**Retention period**:
How long one category of personal data is kept, set by its purpose and its KVKK art. 5 basis (ADR-0062). It runs from an anchor: the end of the Event, the close of the form, the send, or the record time. When it ends, the data is erased or anonymized. The record stays and the person goes, as in the Deletion lifecycle. "Indefinite" is allowed only while the purpose lasts (the account is open, the consent stands, the certificate is verified, the result is published) or once the data is anonymous. Archiving a record does not stop its clock.
_Avoid_: keeping data "just in case"; an indefinite period with no purpose behind it; treating archived as expired or expired as archived; one period for a whole table when its columns serve different purposes (an IP and the click it belongs to)

**Contact consent** (Davet onayı):
A person's explicit, optional consent to receive SKY LAB's future event invitations by e-mail. It is the only basis for inviting someone who is not a Member: a guest, a player, or a rejected applicant. Core keeps the single record in `contact_consents`: e-mail, purpose, channel, text version, source, given, withdrawn, end reason, last event. Guest apply, Forms, Place and Guessr write to it, and SkyMail reads its invitation list only from it. The box is unticked, separate from the aydınlatma, and never a condition of the service. Every invitation carries a signed opt-out link, and withdrawing can be repeated with the same result. Three years without attendance triggers one renewal question. Account erasure deletes it. Member and alumni announcements are not Contact consent; they run on legitimate interest with an opt-out.
_Avoid_: a pre-ticked box; folding it into the aydınlatma or the terms; staff ticking it for someone else; asking past guests for consent by mailing them; each app keeping its own consent list; sponsor or commercial content in an invitation; a suppression list after erasure

**Club archive**:
What the club keeps indefinitely as its history: published winners, speakers and event photos, issued Certificates (name, Event, serial), announcements without recipients, a Member's attendance and contest history while the account exists, and anonymous counts. A guest's history joins it only after the guest identity is cleared. It is published with notice at registration and at the venue, and a person may ask to be removed. Groups smaller than ten are merged in statistics, so that they cannot point to a person.
_Avoid_: treating the archive as a reason to keep contact data, IPs or mail bodies; keeping unpublished results as "archive"; refusing a removal request because the item is archived

**Periodic destruction run**:
One daily execution of a service's retention job. It erases or anonymizes whatever passed its Retention period that day and writes a person-free receipt (rule, time, row count) that is kept at least three years. Each service runs its own job over its own data. The 90-day `PERIODIC_DESTRUCTION_INTERVAL` is the reporting and alarm unit, not the run frequency: each period ends with a destruction report, and a period with no successful run raises an alarm. Modes are `off`, `dry-run` and `apply`, and every service starts in dry-run. After a backup restore it runs once in apply mode.
_Avoid_: a 90-day batch as the only run; an in-process timer that restarts with every release; core writing into another service's database; receipts that name a person, an e-mail or a row id; switching straight to apply without a dry-run

**Sudo mode**:
A fresh re-verification inside Account center that a sensitive action (password, passkey, TOTP, e-mail, delete) requires: the person proves it is them with their password, a passkey or a TOTP code, and the proof is good for five minutes. A person who has none of these proves it with a six-digit code mailed to their current Primary e-mail (the Login code's rules, bound to that Account center session, sent by the sky-account SPI); a Verified YTÜ account is also offered re-authentication with Microsoft. See ADR-0063.
_Avoid_: a Keycloak `prompt=login` hop as the default step-up; treating the login `auth_time` as sudo; skipping sudo because the session is fresh; offering the e-mail code to someone who has a password, passkey or TOTP; sending it to any address but the current Primary e-mail

**sky-account SPI**:
The SKY LAB Keycloak extension that performs every self-service identity mutation for Account center: credentials and e-mail after Sudo mode, plus name and username changes (the realm keeps names, e-mail and username read-only for the person elsewhere, so this extension is the single place the Verified YTÜ lock, uniqueness and cooldown rules are enforced). Keycloak remains the identity store; the extension is deployed inside the Keycloak image like the other SKY LAB providers.
_Avoid_: a Keycloak fork; Keycloak Admin REST through a service account; Application Initiated Actions as the product path for credential, e-mail, name or username changes; calling it from any client other than Account center. Not covered by that rule: the YTÜ Microsoft link, which Account center starts with `kc_action=idp_link` because only a login at Microsoft can prove it, and the offers the sign-in flow on `e.` makes right after Self-registration (YTÜ link, passkey, password), which are part of sign-in and may use Keycloak's built-in actions (ADR-0063)

**Web handoff**:
How SkyApp opens a SKY LAB website inside its WebView already signed in: the app asks Keycloak (the `sky-handoff` SPI provider, not Account center) for a 45-second single-use code for a Handoff target and a path, the WebView opens it with the per-code proof header, and Keycloak sets up the browser session and sends the person to the target's own sign-in entry, which completes silently. The browser session keeps the app's original `auth_time`, so actions that need a fresh login still ask for one. See ADR-0048.
_Avoid_: routing it through `my.`; putting the target URL, the proof or a token in logs; asking for credentials inside the WebView; treating the handoff as a fresh login; calling it "native handoff" (the retired Account center version)

**Handoff target**:
A Keycloak client that a Web handoff may land on, named by its `client_id` (first `account-center` and `skyforms`) and enabled by attributes on that client: on/off, sign-in entry path, return parameter name. Only members of the `/ADMIN` group change them, through superadmin (the SPI accepts only the superadmin client's token); the origin is always `https://*.yildizskylab.com`.
_Avoid_: a free-form URL allowlist; storing the list in env vars; giving core or superadmin `manage-clients`

**Verified YTÜ account**:
A User whose Keycloak identity has a federated link to the YTÜ Microsoft identity provider (alias `OBS`). Its name and School e-mail are locked; an unverified account (for example one opened by Self-registration) may link YTÜ later, from Account center or right after Self-registration, and becomes locked then.
_Avoid_: inferring verification from `emailVerified` or from the presence of a school-looking address; unlocking the name for support cases outside superadmin

**YTÜ-linked**:
A User whose university, faculty and department follow the YTÜ Microsoft login. Core alone decides it: the first token (or the one-time backfill of Keycloak attributes) carrying the `university` attribute that the OBS login writes sets `users.ytu_linked`, and a token without the claims (Account center's never has them) does not clear it. From then on every YTÜ login writes the current university and department (program codes and space-less names cleaned, an unknown code left empty), and faculty comes from core's department → faculty table. The three fields are read-only for the person and for admins: core refuses a change with `409 ytu_managed_field`, and Account center shows them with "YTÜ hesabından gelir". Account center reads core's `ytuLinked` and never decides this itself. In practice these are the same people as a Verified YTÜ account, but the decision rests on the attribute core can see, not on the federated link.
_Avoid_: deciding it from `schoolEmail`, the OBS federated link or the current request's token; an admin override of the three fields (the next login would put them back); storing an unknown program code as the department

**School e-mail**:
The YTÜ address proven by the YTÜ Microsoft link: the `schoolEmail` user attribute (kept in sync from Microsoft on every YTÜ login) and the `school_email` token claim. Immutable by the person.
_Avoid_: `school_email` as the attribute name or `schoolEmail` as the claim name; self-editing it; treating it as the Primary e-mail by definition

**Personal e-mail**:
An address the person proves by typing the short-lived code mailed to it, in one of two places: in Account center while signed in as themselves, or at Self-registration in the sign-in session that asked for the code (the address then also becomes the Primary e-mail). Either way the code only ever confirms the requester's own pending change. Stored as the `personalEmail` user attribute. May be removed by the person. One-time exception (A1c, 2026-09): a pre-v2 primary address that Keycloak had already verified by link was adopted as the Personal e-mail; an unverified one is proven with the same code.
_Avoid_: accepting it unverified; a verification link that works without the requester being signed in; a second `email` claim for it; writing it through Account REST

**Primary e-mail**:
The one of School e-mail and Personal e-mail the person has chosen; stored as Keycloak `email`, so it is what tokens, core, SkyMail and notifications see. Either address signs in. Its starting value: an account opened by a first YTÜ login starts with the School e-mail, an account opened by Self-registration with its Personal e-mail. A YTÜ login never changes the primary of an account that already exists or is being linked.
_Avoid_: assuming primary equals school; services learning both addresses; login that only accepts the primary; overwriting an existing account's primary on a YTÜ login

**Self-registration**:
Opening a SKY LAB account without YTÜ through the single "E-postayla devam et" door: a person with no account proves an address with a Login code and then gives a first and last name; no password is asked. The address becomes both the Primary e-mail and the Personal e-mail. It is not offered for YTÜ school domains (`std.yildiz.edu.tr`, `yildiz.edu.tr`); that person is sent to the YTÜ Microsoft login. It grants no rights: groups and roles are the realm defaults, and membership stays an admin decision. The account is not a Verified YTÜ account until YTÜ is linked. Right after it, the sign-in flow offers once to link YTÜ and to add a passkey or a password; each can be skipped. See ADR-0063.
_Avoid_: Keycloak's built-in registration page (`registrationAllowed`); verifying the address with a link; asking for a password at registration; opening the account before the code is verified; a school-domain address as a self-registered address; treating a self-registered account as a Member

**Login code**:
A six-digit, single-use code that Keycloak mails for signing in or Self-registration. It works only in the sign-in session (browser and tab) that asked for it, lives ten minutes, dies after five wrong tries, and only its salted hash is stored; a wrong code counts toward Keycloak's brute-force lock. For sign-in it goes to the account's Primary e-mail (the School e-mail if there is no primary); for Self-registration it goes to the typed address. It is a first factor: a person with TOTP is still asked for TOTP after it. The address screen looks the same whether or not an account exists, and sending is limited per address, per sign-in session, per IP class (never storing the IP) and overall. See ADR-0063.
_Avoid_: magic link; the code in the subject line; letting it skip TOTP; saying whether an account exists before the code is verified; treating it as a 2FA step for a person with a password or passkey

**Permissions view**:
The read-only, human-language rendering in Account center of a person's teams, leadership, privilege level and application permissions (client roles), with technical codes collapsed. Changes are made in superadmin, never here.
_Avoid_: raw role codes as the primary UI; showing realm roles; editing groups or roles from Account center

**Passkey RP ID**:
`yildizskylab.com`, the WebAuthn relying-party id used for every SKY LAB origin so one passkey works on `e.`, `my.` and in-product WebViews.
_Avoid_: `e.yildizskylab.com` as RP ID; per-host passkeys

**SkyPass**:
A Member's club membership card (name and skyNumber on the face, no photo); door proof is SkyPass QR from sky-app or Wallet, or a bound Student card tapped at the door. Apple Wallet and Google Wallet are a required substitute when sky-app is not installed, and are not SkyPass itself.
_Avoid_: Wallet as a synonym for SkyPass; treating SkyPass as parked until another conversation; treating Wallet as optional, patron-only, or visual-only; treating a bound Student card as needing sky-app at the door; putting a photo or profilePicture on SkyPass; treating SkyPass as a student ID with photo

**Event**:
A named club happening that may span several calendar days (ARTLAB, Gecekodu). Tickets and the Attendance rule belong to the Event, not to one day.
_Avoid_: treating one calendar day as the Event; treating EventDay as the Event

**Event QR**:
A shared event **poster** QR the **attendee** scans to join (`dahil olmak`). If they have no Ticket, that scan is Walk-in. Staff does **not** scan the poster; it has no person id and is not a door credential. Oturum QR is the same family (attendee scans a shared code) but marks Check-in for that talk, not join.
_Avoid_: treating Event QR as the membership card; treating a poster Event QR as a person credential; staff scanning the poster at the door; treating poster apply vs door as unsettled; treating an Oturum QR as this join poster; treating Walk-in as a staff scan of the poster

**EventDay**:
A calendar day of an Event (already exists). Not a talk. ARTLAB this year has two EventDays.
_Avoid_: treating EventDay as oturum, session, or a talk (that lock is **retracted** 2026-09-17); counting EventDays for a certificate ratio; one Check-in per day when the day has many Oturum

**Oturum**:
A talk or slot **on an EventDay**. Many per day. English name in the model is Session — already the schedule table `sessions` under EventDay (`core-backend/db/migrations/20260916180000_create_schedule.up.sql`); Check-in binds to that row. ARTLAB used to be one day with five Oturum; this year day 1 had five and day 2 had three (eight total). Operators add and edit talks only on the Event hub; there is no global Oturum product page.
_Avoid_: using Oturum for a Sign-in session; treating EventDay as Oturum; treating Session as agenda-only and not yoklama; treating a calendar day as one talk; inventing a second talk entity beside schedule Session; a global `/sessions` catalogue as a second editor

**Oturum QR**:
A shared QR for **one Oturum** the attendee scans at the end of that talk to Check-in their Ticket (same family as Event QR: attendee scans, no person id). Not an EventDay QR.
_Avoid_: treating this as EventDay check-in; staff scanning the projector; a Typeform on the projector; treating this as the Event poster (join); a new attendance row per scan of the same Oturum

**SkyPass QR**:
The Member's Istanbulkart-style credential: the Member shows it, staff scans it. In sky-app it refreshes every open; the Staff scanner verifies the signature on-device (authenticity does not need a mint or core call), settles check-in online, and if core is unreachable accepts a valid unexpired signature as a Queued check-in. Wallet shows the same scannable credential on platform terms: Google TOTP every 60 seconds, Apple a signed barcode with about 5 minutes `exp` if a PassKit update did not arrive. A 60-second Google code and a 5-minute Apple code are both valid at the door if unexpired and signed.
_Avoid_: forgeable `SKYPASS:{skyNumber}:{name}`; treating a decorative card-back pattern as this credential; treating Wallet barcode rotation as the same every-open lock as sky-app; treating the door as SkyPass-QR-only; treating authenticity as a mint or core round-trip; treating the door as concert fail-closed when core is down; refusing a signed unexpired Wallet code because its window is longer than Google's

**Ticket QR**:
A per-User event ticket the attendee shows at the door. The Staff scanner auto-detects it on the same camera as SkyPass QR; both must work, and if the ticket is signed it follows the same on-device authenticity plus online settlement (Queued check-in when core is down) as SkyPass QR.
_Avoid_: treating this as the Event poster QR; treating staff door scan as SkyPass-only; treating a signed Ticket QR as mint-round-trip authenticity or concert fail-closed

**Wallet**:
Apple Wallet or Google Wallet as a SkyPass QR surface for Members without sky-app; the pass face is name and skyNumber, no photo, matching SkyPass. Opening the pass must show a scannable SkyPass QR: Google Wallet rotates on-device (`rotatingBarcode` TOTP, 60-second period); Apple Wallet has no on-device rotate — PassKit `webServiceURL` so the device can pull a fresh signed barcode, with signed `exp` about 5 minutes if an update did not arrive. Apple VAS / Google Smart Tap is a later certified-terminal slice after physical Student-card NFC, and is not the staff camera or staff-phone NFC.
_Avoid_: Wallet as a synonym for SkyPass; treating Wallet as optional or visual-only; claiming Apple VAS or Google Smart Tap works on a staff phone or phone camera; treating Wallet NFC as the first NFC cut; using Google's 3-second transit example as the club period; APNs-pushing a new `.pkpass` every 60 seconds; putting a photo on the Wallet pass; treating Wallet as a student-ID-with-photo

**Student card**:
A physical campus ISO 14443-A card (YTÜ Mifare Classic etc.) bound to a Member from a phone as a unique UID column on the Go User shadow (one card one user; rebind replaces; not a Keycloak attribute). At the door that same plastic card is a check-in credential (a cloned Mifare UID is accepted as sufficient): the tap is an online postgres lookup of the bound UID to the User, not Keycloak Admin API and not an on-device-signed QR; attendees who have one do not need sky-app or Wallet QR. The Privileged admin user card may show the UID read-only; bind stays sky-app / SkyPass.
_Avoid_: treating this as Apple VAS or Google Smart Tap; treating the in-app UID poll as already persisted; treating Wallet NFC as this card; treating a cloned UID as invalid; treating Student-card tap as decoration while QR is the only real proof; treating Student-card tap as on-device-signed like SkyPass QR; treating a last-known UID cache as locked; storing the UID in Keycloak; looking the tap up via Keycloak Admin API; putting the UID on the public roster; a bind UI in superadmin

**Door NFC reader**:
The door-side ISO 14443-A reader for a bound Student card: optional staff-phone NFC in sky-app, plus a dedicated USB/door reader. Both if possible; the dedicated reader is the guaranteed path when staff-phone NFC is unreliable (especially iOS). Staff phones cannot tap someone else's Apple Wallet or Google Wallet pass (certified Apple VAS / Google Smart Tap terminal, later slice).
_Avoid_: treating the Member's phone as the turnstile for plastic cards; treating staff-phone NFC as the only door path; treating a dedicated reader as optional when staff-phone NFC fails; treating staff-phone NFC as Wallet tap; treating a generic UID reader as VAS/Smart Tap

**Staff scanner**:
The sky-app door screen (Mobile Lab implements; this platform cutover does not). One camera, no mode switch: auto-detects both SkyPass QR (sky-app or Wallet) and the attendee's Ticket QR, verifies a signed QR on-device, settles check-in online (`içeri al`) for the **current Oturum** (schedule-clock when that EventDay’s talks do not overlap; staff **pick** when they overlap or the clock is wrong), and records a Queued check-in if core is unreachable. Both QR types must work. Staff do not scan the Event poster QR or the Oturum QR. Optional staff-phone NFC for a bound Student-card UID (online postgres lookup); dedicated USB/door reader is the fallback.
_Avoid_: a mode toggle between QR types; two QR cameras; scanning the Event poster QR or Oturum QR at the door; treating a talk-time scan as EventDay-only; clock-only when talks overlap; pick-only on a sequential day; treating ticket-QR auto-detect as unconfirmed; treating the door as SkyPass-only; treating this camera as the only Student-card path; treating superadmin or a new Go-owned app as this UI; treating authenticity as a core or mint hop; treating the door as fail-closed when core is down

**Check-in**:
The settled mark that a Ticket attended one **Oturum**. Attendee Oturum QR, staff SkyPass/ticket scan, Student-card tap, and Desk check-in all write this same mark; a second scan of the same Oturum is a duplicate, not a second count. Guests identify by email once on the guest Ticket, then Check-in that Ticket per Oturum.
_Avoid_: counting emails; counting EventDays; treating EventDay as the grain (retracted 2026-09-17); a Typeform as the attendance ledger; treating a Queued check-in as already settled; UUID as the operator's primary success label

**Queued check-in**:
A door check-in the Staff scanner holds after accepting a valid unexpired SkyPass QR or signed Ticket QR while core is unreachable, then syncs later; duplicates are reconciled after sync. Club/campus fail-open, not concert fail-closed.
_Avoid_: refusing a valid unexpired signature because core is down; treating the queued accept as a settled core count

**Door staff**:
A User allowed to check attendees in at an Event on their own phone. Leaders of that Event's Owner team and Privileged people always may (A); Superadmin may also assign specific people for that Event (B); ordinary members need B unless that Owner team has Team door scan on.
_Avoid_: treating door check-in as Leader-only; treating door check-in as a per-Event roster only; treating every Owner-team member as Door staff by default; treating superadmin as the door UI; a new Go-owned door app; club-issued devices as the default

**Team door scan**:
A Group attribute on an Owner team, same pattern as Public listing, default off. When on, members of that team may check attendees in at that team's events without the per-Event Door staff roster.
_Avoid_: treating this as on by default; treating every Owner-team member as Door staff; treating Public listing as this grant

**Group**:
A Keycloak group in the realm tree, identified by path (for example `/UYELER/ARGE/WEBLAB`). Team membership, leadership, privilege, public listing, and team door scan all come from this tree and its attributes. A parent roster is that tree: people in subgroups appear on the parent because they sit in those subgroups.
_Avoid_: LDAP group, role as a duplicate of the tree, a second membership flag besides the tree

**Source group**:
The Group a User is actually in when they appear on a parent roster. Direct members of the parent have that parent as source; nested appearance has the subgroup they sit in. Removing them from the parent roster removes that source membership.
_Avoid_: inherited flag, nested member flag, a second membership record on the parent

**Realm role**:
A realm-wide Keycloak role. Not used for club membership or core authorization. Leftover names that duplicate Groups (ADMIN, YK, WEBLAB) should not be assigned.
_Avoid_: realm role as a copy of a Group

**Client role**:
A permission that belongs to one application (for example `core` `url:create`, `skyforms:form:manage`, or `cms:access`). Group → client-role mappings and extra per-user grants are both managed from the SKY LAB admin UI. Keycloak's own console is not used for this.
_Avoid_: client roles as the way to represent a team; realm roles; `skylapp` client roles after Java is gone

**Resource server**:
The Keycloak client that stands for one API process. Core's resource server is `core`. A token is for core when `aud` contains `core`. Core reads roles only from `resource_access.core`.
_Avoid_: unsigned JWT as an auth path; aggregating `skylapp` (or any other client) roles; treating `azp` as audience for core

**Sign-in session**:
A person's signed-in state with SKY LAB: their single sign-on session at Keycloak together with each application's own session that rides on it. In Turkish, "giriş oturumu".
_Avoid_: "oturum" on its own (that is a talk on an EventDay, see Oturum); treating an access token or its cookie as the session

**Group overage**:
The state where a person is in more Groups than a token carries (above 30 paths). Their tokens carry a marker instead of the group list, and a service that needs their Groups asks for them.
_Avoid_: reading a missing group list as "no Groups"; cutting the group list short

**Promote**:
Granting Member status by placing a User into the right Keycloak groups. No directory write.
_Avoid_: promote to LDAP, federation link

**Privileged**:
Membership in `ADMIN`, `YK`, or `DK` (or a subgroup under them). These people can manage club resources regardless of team ownership.
_Avoid_: superuser, admin role (unless you mean the `ADMIN` group itself)

**Leader**:
Membership in a team's `LIDERLER` or `KOORDINATORLER` subgroup.
_Avoid_: `*_LEADER` role, synthetic leader role

**Owner team**:
The Keycloak group that owns a domain resource (an event, ticket, session, event site) when one exists. Authorization checks whether the caller is a member or leader of that group. An Event may have no Owner team; then only Privileged people may mutate it. Certificate-template resolution may use the Event and this string before falling back to the SKY LAB default; it never uses an EventType table. HTTP paths and query names use `ownerTeam` / `team`.
_Avoid_: event type as a separate identity source, a fake GENEL team, ownerGroup as something other than a Group; reviving EventType for certificate templates; URLs or query names that say eventType

**Attendance rule**:
Per-Event certificate eligibility: `none` (no certificates), `once` (at least one Oturum Check-in), or `ratio` (Oturum Check-ins / scheduled Oturum that still exist on that Event ≥ a decimal the organizers set). Cancelled talks are deleted or marked cancelled and excluded so they do not inflate the %. Zero Oturum rows: no certificate until at least one talk exists; `once` is still one Oturum Check-in. ARTLAB 2026 example: eight Oturum, 0.75 ≈ six Check-ins. Required when they want certificates; there is no club-wide 70/80 default.
_Avoid_: counting EventDays; treating `once` as one EventDay; a global ratio; EventType-keyed rule; the retracted EventDay=oturum lock; counting cancelled talks in the denominator; issuing a certificate on EventDays with zero Oturum

**Certificate**:
A participation credential for one person on one Event: an immutable issued record, a human public-verification page, and a PDF containing a verification QR. The canonical QR target is the stable `skyl.app/c/{serial}` Short link; core redirects it to the human page at `yildizskylab.com/sertifika/{serial}`. Check-ins update eligibility but do not issue it; automatic issuance begins only after Attendance finalization, while an authorized operator may issue one manually. An issued Certificate pins its Certificate template version and remains unchanged when the template changes.
_Avoid_: treating eligibility as issuance; issuing immediately after a Check-in; regenerating an existing Certificate when its template changes; putting email, User id, or Ticket id on public verification; an EventType table for templates; Typeform lists as the source of truth

**Attendance finalization**:
An organizer's explicit declaration that an Event's Check-in ledger is complete and automatic Certificate issuance may begin. Passing the Event end date or making an Event inactive is not Attendance finalization.
_Avoid_: issuing on the first eligible Check-in; using `active=false` as certificate finalization; silently finalizing from the clock alone

**Certificate template**:
An editable certificate design identity whose published version is selected for future issuance. Resolution order is Event binding, then Owner-team binding, then the required SKY LAB default.
_Avoid_: EventType template; hard-coded HTML as the hidden default; resolving fallback separately in each caller

**Certificate template version**:
An immutable published snapshot of a Certificate template, including its layout and assets. Existing Certificates keep their pinned version; editing creates a draft that must be published as a new version.
_Avoid_: mutating a published version; changing historical PDFs when a template is edited; silently publishing an external-design sync

**Certificate manager**:
An Owner-team Member explicitly granted one or more certificate-management capabilities in addition to the access Privileged people and that team's Leaders already have. The grant does not extend outside Owner teams that person belongs to; an Event without an Owner team remains Privileged-only.
_Avoid_: a realm role that represents a team; a grant that unlocks every team's certificates; making every team Member a manager by default

**Public listing**:
A Group attribute (`public_listing=true`). Visitors may see that team and its members. Unset means hidden (SKYSEC, YK, ADMIN). Managed on the Group in Keycloak / superadmin, not an app allowlist.
_Avoid_: hiding a team only in CMS, a second privacy table

**Public leaders**:
A Group attribute (`public_leaders=true`). Visitors may see Leaders only. Use when the roster stays private but coordinators are public. `public_listing` already implies leaders are visible.
_Avoid_: a second Group tree for "visible SKYSEC"

**News**:
A CMS collection item (title, summary, body, hero, tags). Club announcements in the new world live here. Only Privileged people may edit News.
_Avoid_: Announcement as a core-API entity, `/api/announcements` on super-skylab

**Site client**:
The Keycloak OAuth client of one public site (for example `frontend-main` for the main club site, `frontend-arge` for arge, `frontend-artlab`, `frontend-yildizjam` and `frontend-skydays` for event sites) and that site's Site tenant: its content is stored under the client's id (`azp`). CMS rights are client roles on that client (`content:read`, `content:write`, `schema:sync`; people get them through `cms:access`), not a global CMS master key; the site's own server-side account only reads. Full scope is off, so a token for one site never carries another site's roles. One site, one client; it is made by the Keycloak configuration scripts, and its secret goes from Keycloak straight into the secret store.
_Avoid_: one `cms:access` on `skycms` that unlocks every site; a site's server-side account that can write content; Full scope on a Site client; a localhost redirect on a production Site client; one client shared by several sites; handing a client secret to a developer or putting it in a build

**Site tenant**:
One public site's content space in the CMS (inscribed), keyed by its Site client's id. Every site that is edited in the CMS, event sites included, is its own tenant on the one live CMS; adding a site adds a Site client, a tenant registration with anonymous reads of published content, a CORS origin and the site's own deployment, but no backend code. Published content is read at run time without a token; editing uses the editor's own token for that site. Collections are not per tenant: they are shared by every site, so event sites start with page blocks only.
_Avoid_: a new CMS backend, fork or reborn cms-backend per site; reading the CMS with a secret at build time; treating a collection key as private to one site

**Site editor**:
A User who may edit one site in the CMS, that is, who holds `cms:access` on that Site client through a Group. For an event site the rule is: Privileged Groups, plus the Leader groups of the lab team that owns the site (its Owner team), plus the Leader groups of the event's organization team (`/UYELER/ORGANIZASYON/<EVENT>`): ARTLAB → AIRLAB and ORGANIZASYON/ARTLAB, YıldızJam → GAMELAB and ORGANIZASYON/YILDIZJAM, SkyDays → SKYSEC and ORGANIZASYON/SKYDAYS. For the main site and arge the groups are listed in ADR-0056. The existing Group tree carries it; there is no separate editor group. The admin panel's list of sites a person can edit is a hint for the UI, not the authorization; the CMS decides. SkyApp edits the main site's News and Teams with the same rule: `frontend-main`'s `cms:access` (and `client:admin`) include SkyApp's own CMS roles, so the main site's grant is the only one, and the app writes the shared collections with the person's own token (ADR-0056, SkyApp addendum).
_Avoid_: a `site-editorleri` (per-site editor) group tree; granting an event site to every Leader group or to every member of its organization team; granting `cms:access` to a single person; turning on Full scope to learn which sites a person edits; a SkyApp tenant, a server that writes for SkyApp, or granting SkyApp's CMS roles to a Group

**cms:access**:
A client role on a Site client meaning this User is a CMS editor of that site: it bundles `content:read` and `content:write`, and the site shows its editor only to holders of it. It is granted only to Groups (Privileged and Leader groups; which ones per site is in ADR-0056, and for an event site the Site editor rule), never to single people. Write access is site-wide, so it covers every page of that site but no other site; which Teams items a Leader may change still follows Group membership.
_Avoid_: treating cms:access as superuser of all content; treating it as retired by the inscribed cutover (ADR-0056); granting it to a single person, to all members, or as a default role

**client:admin**:
A client role on a Site client for CMS tenant administration: creating a team and fixing any team's Teams item, for example after its Leader leaves. It can also change that site's CMS tenant settings, so only the `ADMIN` group holds it until the CMS separates tenant settings from content administration.
_Avoid_: giving it to Leaders or to YK; treating it as the editor role (that is `cms:access`)

### Event operations

**Ticket**:
A person's door identity for one Event. Member apply writes a REGISTERED Ticket; Guest apply and Walk-in write a GUEST Ticket. Capacity and the door read this row, not a forms response. Ticket QR is the door proof, distinct from SkyPass QR (membership) and Event QR (join poster).
_Avoid_: treating a skyforms response as the door identity; treating Ticket as the Event poster QR; treating Ticket as only an email row

**Form slot**:
A named form attachment on an Event (apply, contest, …). One Event may have several. A slot is an external URL or a Skyforms Event form; the public attach handle is a Short link (`formUrl` on the Event).
_Avoid_: a single unnamed formUrl as the only product model forever; Typeform as a slot; parsing a Form id out of the URL string; dumping a logged-in User onto this link

**Event form**:
A skyforms Form bound to an Event. Creating one bounces the operator into skyforms (Gecekodu draft as a Group extra, when it exists) and returns to the same Event page. Forms stay skyforms; this is not a second forms product.
_Avoid_: embedding the skyforms editor in superadmin; inventing a new forms app; treating a component-group clone as the whole Form; Typeform; Google Forms

**Skyforms draft template**:
A skyforms form draft bound to a Group as a reusable starting point (for example Gecekodu). There is no live Gecekodu template form today; drafts are the path.
_Avoid_: one shared live form that every Event mutates; inventing a template that does not exist yet

**Member apply**:
A logged-in User registering for an Event with their Keycloak account. That writes the Ticket. They are not sent to a public Form slot. Identity (name, email) comes from the User. Event-specific questions are Apply extras on that Ticket, collected in-product, not by dumping the Member onto Guest apply. Apply-for-other is the admin exception that writes another User's REGISTERED Ticket.
_Avoid_: redirecting a signed-in User to skyforms as the only apply path; forcing Members through Guest apply; treating Keycloak profile as the only place for plate/university/t-shirt

**Guest apply**:
A person without an account, or who will not create one, registering through a public Form slot (skyforms or an external URL). Operators may also Guest apply from the Event hub (name, email, phone) so a guest Ticket exists before Desk check-in.
_Avoid_: forcing every attendee through a public form; treating Guest apply as the logged-in path; a second guest identity besides the guest Ticket email; using Guest apply to enroll a Member

**Apply-for-other**:
A Privileged or Owner-team Leader Member apply on behalf of another User from admin, writing that person's REGISTERED Ticket. The attendee is not sent to a public Form slot. Walk-in Event QR is not this.
_Avoid_: Guest apply for a Member; dumping the Member onto skyforms; treating this as the attendee's own `/applications/me`; Walk-in; inventing a second Ticket type

**Desk check-in**:
Operator yoklama in superadmin: pick a person or guest email, resolve the Ticket, mark Check-in on an Oturum. Surfaces: `/qr` and the Event hub roster/session. Success copy is name · session · time. Same Check-in row as the Staff scanner; the camera stays sky-app.
_Avoid_: UUID as the primary label; treating superadmin as the Staff scanner camera; EventDay grain; staff scanning the Event poster

**Apply extra**:
A per-Event question beyond Keycloak identity (licence plate, university, t-shirt size, …). The Event defines the schema once. Member apply answers it in-product; Guest apply answers the same schema on the Form slot after locked name/email. Answers live on the Ticket. The door still reads the Ticket, not the extra, unless a later product says otherwise.
_Avoid_: storing plate on the User as a global profile field; a second identity besides the Ticket; skyforms as the only store of extras; a different extra schema for Members vs Guests on the same Event; stuffing extras into a contest Form slot

**Walk-in**:
A person with no Ticket who scans the Event QR and receives a Ticket. No ticket mail, or a mail that says they are already in if that scan also wrote Check-in. Staff still do not scan that poster at the door.
_Avoid_: staff scanning Event QR; treating Walk-in as a second door credential beside SkyPass QR and Ticket QR; Walk-up as a second term

**Mail template**:
A SkyMail message definition — a subject, an HTML body and a plain-text body — rendered for each recipient with the variables of that send. Archived, never deleted.
_Avoid_: "template" on its own where a Certificate template or a Skyforms draft template could be meant; e-mail theme; treating the React Email file as the template rather than one way of writing it

**System template**:
A Mail template another service sends by its Template key: core's welcome and certificate mail, Keycloak's account mail. It cannot be archived and its key never changes; its wording is edited in SkyMail like any other Mail template's.
_Avoid_: locked template; read-only template; treating "system" as "not editable in SkyMail"

**Template key**:
The stable, readable handle a service addresses a Mail template by (`core.welcome`, `keycloak.verify-email`). A System template always has one; its UUID is never the contract.
_Avoid_: a template id as the integration contract; renaming a key in place

**Authoring mode**:
One of the three ways a Mail template's body is written in SkyMail: JSX (React Email code using the club's mail components), Visual (the block editor) and HTML (raw markup). A Mail template may hold a source in several modes at once.
_Avoid_: editor type; treating a switch of mode as converting or discarding the other sources

**Main source**:
The one source of a Mail template, among its Authoring modes, whose render is what gets sent. Making another source main is a deliberate choice; the other sources are kept, never overwritten by it.
_Avoid_: active mode; primary source (Primary e-mail is another thing); last-saved-wins

**Mail template version**:
A snapshot of a Mail template — its subject, every source and which one is main — written on every change, with who wrote it: an operator or a Template seed. An operator's version is a draft until published; one published version is sent at a time, and any version can be compared with another as rendered mail and restored.
_Avoid_: a save that changes live mail; comparing versions as raw HTML diffs; hard-deleting old versions; treating a Template seed write as outside the history

**Required variable**:
A variable a Mail template must keep referencing because the mail cannot do its job without it: the reset link, the certificate VerifyURL, the ticket QR. The ones the sending service's contract declares are fixed alongside the Template key; an operator may mark further variables required, but cannot release a contract one.
_Avoid_: locked parts or fixed sections; letting an operator remove a service's link from its mail; treating every variable a sender supplies as required

**Template seed**:
The run that writes the Mail templates kept in the repo (`emails/`) into SkyMail by Template key. It is one of two writers beside SkyMail's own editor, and it updates a template only when no operator has changed it since the last seed; otherwise it refuses unless forced.
_Avoid_: a seed as a one-off migration; a seed silently overwriting an operator's change; expecting an image deploy to change live mail (only a seed does)

**Mail onayı**:
A skymail draft a User without send permission submits; submitting needs read access to what is submitted (the template, and the list when it goes to one). It goes to a mailing list or to named people, each of whom gets their own send once approved. Approvers (the `skymail:mails:approve` role, separate from sending) get mail in skymail; if they approve, the send goes out as submitted. An approver (who may also decide their own submission) may instead edit it and then either send the edited version directly or return it to the submitter for their approval; every edit is recorded and the submitter is told. A rejection carries a reason and the submitter may edit and resubmit. A submission undecided for 7 days expires and never goes out. Superadmin does not SMTP.
_Avoid_: putting the approval queue in core or admin; submitting what the submitter cannot read; treating `mails:write` 403 as the product; sending from superadmin; treating Forms review as mail approval; an approver's edit going out unrecorded; a stale submission going out weeks later

**Event mail list**:
A recipient set for one Event's attendees, managed separately from club-wide lists such as all Members (GECEKODU attendees vs AGC attendees).
_Avoid_: one global club list as the only audience; treating Keycloak group membership as the Event attendee list; treating skyforms responses as the only list

**Short link**:
A skyl.app alias for a URL, created in admin or for a Form. Default alias is a readable slug plus year (`gecekodu`, `skydays2026`), numbered (`gecekodu-2`) when taken; aliases that differ only by case count as the same. Its creator may edit it unless it is a Form link. Human identity may use dots (`gecekodu.skydays`); the skyl.app alias alphabet is alphanumeric plus `_` `-`, so dots become hyphens (`gecekodu-skydays`). UUID is not the public identity. Wherever a link is created, a Short link can be created too. The hop is a silent 301; analysis lives in admin.
_Avoid_: opaque UUIDs as the public identity; treating skyl.app as a logged-in SPA (ADR 0020); using a dotted slug as the skyl.app alias itself; an interstitial or hop SSO; two aliases that differ only by case

**Short-link hit**:
A server-side row written on every Short link redirect, with or without a Channel suffix, immediately before the 301: time, IP / `X-Forwarded-For`, UA, Referer, alias, source (UTM tags or the Channel suffix), and `userId` only if that hop already carried a valid core JWT (Bearer and/or a session cookie this host already accepts). A normal public click (WhatsApp, Instagram, Safari) does not send admin or IdP cookies; empty `userId` is expected, not a bug. Fetching a QR image is not a hit; a scan is, and a code printed with `utm_source=qr` counts scans apart from clicks.
_Avoid_: redirecting through Keycloak to discover the clicker; hidden iframe or silent SSO; delaying the 301; waffle/login on skyl.app; counting QR GET as a click; treating empty `userId` as something to “fix” with SSO

**Form link**:
The one Short link of a Form, which every collaborator of that Form sees with the same alias, QR code and clicks. It belongs to the Form, not to its creator: form owners and editors rename it in Forms, and while an Event names the Form the Event decides its alias (an event-managed Form link). Only a URL moderator may disable it.
_Avoid_: one personal link per collaborator; renaming a Form link from the generic admin link list; the Form and an Event both renaming one alias

**Retired alias**:
A Short link's previous alias after a rename. It keeps redirecting to the same link and is never given to another link, so printed QR codes survive the rename; every spelling is kept, a case-only rename included.
_Avoid_: freeing an old alias for reuse; a rename that kills printed links; renaming a link to a name nobody chose

**Channel suffix**:
A short path after a Short link (`/ig`, `/wa`, `/li`, `/mail`, `/web`) naming where it was shared; its Short-link hit records it as the source. An unknown suffix still redirects, untagged, so a mistyped printed link keeps working.
_Avoid_: a separate Short link per channel; answering an unknown suffix with 404; `qr` or `c` as a suffix (`/qr` is the QR image, `/c/…` the Certificate address)

**Participant roster**:
The shared superadmin surface that lists an Event's Tickets. Organizers see attendees here, not only inside skyforms responses or a per-microsite admin.
_Avoid_: Forms as the only roster; a separate admin per skydays/yildizjam site as the source of truth

**Team media library**:
Photos already used on Events of this Owner team. Organizers may reuse them on a new Event of the same team. Never another team's photos.
_Avoid_: a global media picker; cross-team reuse

**Media**:
A file that core stores for any SKY LAB product: a profile picture, an Event cover, a CMS image, an Answer file, a large download or a video. Every Media has exactly one Media purpose.
_Avoid_: asset; upload (for the stored file); attachment

**Media purpose**:
The declared reason a Media exists, such as Event cover, profile picture or Answer file. It fixes who may upload, which file types, how large, and whether the Media is public or private; the product that owns the record may narrow these limits but never widen them.
_Avoid_: category; bucket; preset; a Media without a purpose

**Media attachment**:
The link between a Media and the record that uses it, in core or in another product (an Event, a Skyforms response, a CMS page). A Media with no Media attachment is pending and expires; nothing is kept "just in case".
_Avoid_: attachment on its own (a Form slot is also called a form attachment); reference

**Answer file**:
A Media that a person uploads to answer a Skyforms file question: a CV, a transcript, a student certificate, a portfolio, or a large submission such as a game-jam build. Always private: Skyforms decides who may open it, and the opener gets a short-lived link, never a lasting public address. Erased with the person's Account erasure, and six months after its form closes unless the form's owner keeps it longer.
_Avoid_: application document; başvuru belgesi; treating an Answer file as public CDN content; keeping Answer files with no end date

**Direct upload**:
The path for large Media (big downloads and videos): core grants a one-time upload address for one Media purpose, and the browser sends the file straight to storage instead of through core.
_Avoid_: sending large files through core; a direct upload with no Media purpose

**Skyevents**:
A later public Event site (`events.yildizskylab.com` / skyevents / skyevent). Not this phase. Existing microsites (`skydays.yildizskylab.com`, `yildizjam.yildizskylab.com`) stay until that phase.
_Avoid_: building this site in the current Event-ops loop; treating a microsite as the shared Participant roster

**Secret reference**:
What a service's environment holds in place of a secret value: a pointer to the secret in OpenBao, resolved by Dokploy at deploy time (ADR-0049). Production and sandbox references resolve only through their own provider, so a production reference copied into a sandbox application fails the deploy.
_Avoid_: pasting a secret value into Dokploy, GitHub or a chat; copying one environment's settings into another; one provider token that reads both production and sandbox

**Data network**:
A private Docker overlay network that holds one environment's data services (Postgres, Redis, OpenBao, Dokploy's own database) and only the applications that use them (ADR-0061). Membership is written in Dokploy (Advanced → Networks), so every deploy rebuilds it. `dokploy-network` keeps only what Traefik must reach; event applications cannot reach the platform's data services.
_Avoid_: putting a data service on `dokploy-network`; adding a network to a service by hand with `docker service update` on a Dokploy-managed service (the next deploy drops it); deleting a network in Dokploy while a service still uses it; one data network shared by production and sandbox
