# SKY LAB Platform

Yıldız Teknik Üniversitesi SKY LAB kulübünün etkinlik, üyelik, kimlik ve yayın platformu. Kimlikte kaynak Keycloak; her uygulama kendi verisini tutar.

## Language

**User**:
A person who can sign in through Keycloak. The core app keeps a local shadow of that person (same id as Keycloak `sub`) for domain foreign keys and club-profile fields: schoolEmail, skyNumber, avatar, LinkedIn, university, faculty, department, phone, and the bound Student-card UID (unique on this table; not a Keycloak attribute). The directory of members is Keycloak, not this table. `schoolEmail` comes from the JWT `school_email` claim on JIT; empty claims do not wipe a stored value. User search (`GET /v1/users?q=`) is against this shadow (email, schoolEmail, name), not Keycloak. Club profile on this shadow is not an Event Apply extra. Privileged people (or whoever already may manage that User in admin) may PATCH name, LinkedIn, university, faculty, department, and phone; skyNumber and password stay off that write.
_Avoid_: LDAP user, account, ldapUser; storing a Mifare UID in Keycloak; treating the operator JWT `UserDto` as another person's card; treating university/faculty/department as only an Apply extra; resetting password on the admin card

**User phone**:
The phone number on the User shadow. Admin-panel-only PII: the Privileged user card and admin PATCH. Not the public team roster, not sky-app `/me` or SkyPass, not CMS, not guest-facing Ticket UI as “User phone”, not forms.
_Avoid_: returning phone on `GET /v1/users/me` or any non-admin payload; treating JWT `phoneNumber` as another person's card; treating guest Ticket phone as this field; showing phone in sky-app

**Member**:
A User in the `UYELER` tree. There is no second flag or LDAP status; membership *is* that group.
_Avoid_: LDAP user, federated user, ldapUser, member flag

**Account Console**:
Keycloak's self-service UI on `e.yildizskylab.com` (`/realms/{realm}/account`) where a User changes password, sessions, passkeys, and profile. Cutover keeps people on this IdP console. Superadmin is club admin, not this panel. Club consoles (admin, forms, mail) and any sidebar switcher among them do not replace `e.`.
_Avoid_: stuffing password/sessions into superadmin; treating waffle or the club switcher as the account UI; treating a custom branded origin as this cutover; writing a second IdP or user-store

**Account center**:
A later SKY LAB-branded origin that would call Keycloak Account REST. Not this cutover and not Place. Do not build it now.
_Avoid_: treating this as the cutover path; stuffing it into superadmin; a Keycloak theme as that later project's end state

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
_Avoid_: treating EventDay as Oturum; treating Session as agenda-only and not yoklama; treating a calendar day as one talk; inventing a second talk entity beside schedule Session; a global `/sessions` catalogue as a second editor

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
The Keycloak group that owns a domain resource (an event, ticket, session) when one exists. Authorization checks whether the caller is a member or leader of that group. An Event may have no Owner team; then only Privileged people may mutate it. Certificate templates key off the Event or this string, not an EventType table. HTTP paths and query names use `ownerTeam` / `team`.
_Avoid_: event type as a separate identity source, a fake GENEL team, ownerGroup as something other than a Group; reviving EventType for certificate templates; URLs or query names that say eventType

**Attendance rule**:
Per-Event certificate eligibility: `none` (no certificates), `once` (at least one Oturum Check-in), or `ratio` (Oturum Check-ins / scheduled Oturum that still exist on that Event ≥ a decimal the organizers set). Cancelled talks are deleted or marked cancelled and excluded so they do not inflate the %. Zero Oturum rows: no certificate until at least one talk exists; `once` is still one Oturum Check-in. ARTLAB 2026 example: eight Oturum, 0.75 ≈ six Check-ins. Required when they want certificates; there is no club-wide 70/80 default.
_Avoid_: counting EventDays; treating `once` as one EventDay; a global ratio; EventType-keyed rule; the retracted EventDay=oturum lock; counting cancelled talks in the denominator; issuing a certificate on EventDays with zero Oturum

**Certificate**:
A participation record for one person on one Event after the Attendance rule is met: stored row, public verify URL, and PDF. Issued on recompute after an Oturum Check-in (and at event end) if none exists yet; mail is skymail, same path as welcome. An Event with zero Oturum rows issues none until at least one talk exists (a one-talk day is 1 EventDay + 1 Oturum). Manual issue or revoke is Privileged or Leader of the Owner team (empty Owner team: Privileged only).
_Avoid_: porting the Java certificate WIP; PAdES/TSA as v1; an EventType table for templates; Open Badges; Typeform lists as the source of truth; ordinary members issuing or revoking; a fallback certificate when the Event has EventDays but no Oturum

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
The Keycloak OAuth client of one public site (for example `skylab-site`, `arge`). CMS page blocks are stored under that client's id (`azp`). Editor access is `cms:access` on that client, not a global CMS master key.
_Avoid_: one `cms:access` on `skycms` that unlocks every site

**cms:access**:
A client role meaning this User may open the CMS editor for that Site client. It does not mean they may edit every team or every site. Which team pages they may change follows Group membership.
_Avoid_: treating cms:access as superuser of all content

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

**Mail onayı**:
A skymail draft a User without send permission submits. Approvers get mail in skymail; if they approve, the send goes out. Superadmin does not SMTP.
_Avoid_: putting the approval queue in core or admin; treating `mails:write` 403 as the product; sending from superadmin; treating Forms review as mail approval

**Event mail list**:
A recipient set for one Event's attendees, managed separately from club-wide lists such as all Members (GECEKODU attendees vs AGC attendees).
_Avoid_: one global club list as the only audience; treating Keycloak group membership as the Event attendee list; treating skyforms responses as the only list

**Short link**:
A skyl.app alias for a URL created in admin. Default alias is a readable slug plus year (`gecekodu`, `skydays2026`); the Event creator may edit it. Human identity may use dots (`gecekodu.skydays`); the skyl.app alias alphabet is alphanumeric plus `_` `-`, so dots become hyphens (`gecekodu-skydays`). UUID is not the public identity. Wherever a link is created, a Short link can be created too. The hop is a silent 301; analysis lives in admin.
_Avoid_: opaque UUIDs as the public identity; treating skyl.app as a logged-in SPA (ADR 0020); using a dotted slug as the skyl.app alias itself; an interstitial or hop SSO

**Short-link hit**:
A server-side row written on `GET /v1/go/{alias}` immediately before the 301: time, IP / `X-Forwarded-For`, UA, Referer, alias, and `userId` only if that hop already carried a valid core JWT (Bearer and/or a session cookie this host already accepts). A normal public click (WhatsApp, Instagram, Safari) does not send admin or IdP cookies; empty `userId` is expected, not a bug. QR PNG GET is not a hit.
_Avoid_: redirecting through Keycloak to discover the clicker; hidden iframe or silent SSO; delaying the 301; waffle/login on skyl.app; counting QR GET as a click; treating empty `userId` as something to “fix” with SSO

**Participant roster**:
The shared superadmin surface that lists an Event's Tickets. Organizers see attendees here, not only inside skyforms responses or a per-microsite admin.
_Avoid_: Forms as the only roster; a separate admin per skydays/yildizjam site as the source of truth

**Team media library**:
Photos already used on Events of this Owner team. Organizers may reuse them on a new Event of the same team. Never another team's photos.
_Avoid_: a global media picker; cross-team reuse

**Skyevents**:
A later public Event site (`events.yildizskylab.com` / skyevents / skyevent). Not this phase. Existing microsites (`skydays.yildizskylab.com`, `yildizjam.yildizskylab.com`) stay until that phase.
_Avoid_: building this site in the current Event-ops loop; treating a microsite as the shared Participant roster
