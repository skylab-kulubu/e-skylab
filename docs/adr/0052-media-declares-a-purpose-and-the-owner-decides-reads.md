---
status: accepted
---

# Media is one core service where every file declares a purpose and the owning product decides who reads it

Until now every SKY LAB product uploaded through one generic `POST /v1/media`. Any signed-in person could store any file type. Every file got a lasting public CDN address, whether it was an Event cover or an applicant's CV. Nothing recorded why a file existed, and files nothing used were never deleted. The research found no mature platform that combines one rule set with permanent public addresses for everything.

## Decision

We keep **one media service in core**. Every Media has a **Media purpose**: profile picture, Event cover or gallery, certificate asset, CMS image or file, Answer file, club large file, or video.

**What a purpose fixes:**
- who may upload,
- which types are allowed (judged from content, not the extension),
- the maximum size,
- public or private.

**How purposes are defined and limited:**
- Purposes are defined in a reviewed config file in the core repo.
- Hard ceilings live in code: public purposes accept re-encoded raster images (animated GIF re-encoded frame by frame), sanitized SVG where the catalogue names it, plus PDF, MP4 and download-only ZIP where the catalogue names them. SVG and ZIP are always served as attachments, never inline. Animated WebP, which Go cannot re-encode, is the one format kept as uploaded after its structure is validated (amended 2026-09-26).
- The product that owns a record may narrow a purpose, but never widen it. Example: a Skyforms question that allows only PDF up to 5 MB.

**How a Media lives and dies:**
- A Media is pending until a **Media attachment** links it to a record in core or another product.
- A pending Media expires after 24 hours; a detached Media expires after 30 days.
- Account erasure deletes personal purposes. Club purposes stay, with the uploader removed.
- Answer files are also erased six months after their form closes.

**Private purposes (Answer file, certificate asset):**
- They never get a public address.
- Core encrypts each file with its own data key, wrapped by a key held by the secret service (OpenBao) that rotates every 90 days. This follows KVKK's cloud guidance that data reaches the cloud already encrypted.
- Core reaches the secret service with its own identity. That identity may only encrypt, decrypt and rewrap.
- The owning product decides who may open a file. For Answer files that is Skyforms. It then asks core for a five-minute link; core decrypts and streams the file and records who opened what.

**Uploads and images:**
- Small files go through core in one step.
- Large files (about 1 GB downloads, about 2 GB videos) use **Direct upload**: core starts a multipart upload, the browser sends parts straight to R2, and core checks the result before the Media can be attached.
- Video is plain MP4 on R2. Core moves the index to the front, without re-encoding, when a file needs it.
- Answer files and large files are scanned by ClamAV in its own container before they can be opened. An infected file is deleted and the uploader is told.
- Images are re-encoded at upload, capped at 2560 px, with fixed smaller sizes generated alongside. Clients ask by Media id and a size name, and core builds the address. This lets a later move to Cloudflare transformations or a separate content domain be a configuration change.

## Considered options

- **Each product stores its own files** (Skyforms and CMS each with their own bucket and checks). Rejected because type checks, SVG handling, disposition, orphan cleanup and erasure would be written three times in two languages. The hole closed on 2026-09-25 (HTML served from `cdn.`) would then have three places to reappear.
- **R2 presigned read links for private files.** Rejected once private files are encrypted with our own key: R2 cannot decrypt them.
- **Cloudflare Stream or Mux for video.** Deferred. About $15 and $5.40 a month against about $0.30–0.75 for plain MP4 at club scale.
- **A separate user-content domain.** Deferred: public purposes serve only re-encoded images. Storing Media ids instead of addresses keeps the switch cheap.
- **Purpose definitions edited from superadmin.** Rejected. An admin could widen a rule into the hole this design closes.

## Consequences

- Core depends on OpenBao at runtime for private Media. If OpenBao is down, private uploads and opens fail; public Media is unaffected.
- Skyforms and inscribed change their contracts: send a purpose, store Media ids, attach, and read Answer files through Skyforms. Fatih makes those changes from a handoff note after core's stages ship. Until then, existing Answer files stay public.
- A purpose-less upload keeps working, for old mobile builds, but only under the strictest rule: an image of at most 5 MB, public, expiring unless attached. This applies only after Skyforms and CMS send purposes.
