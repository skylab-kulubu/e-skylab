# SKY LAB admin paneli — durum, boşluk, yıl planı

Bu belge **kulüp yönetim paneli** (`superadmin`, prod: `https://admin.yildizskylab.com`) için bir yıl planlama haritasıdır. Kaynaklar birincildir; uydurma ürün yok. Sıralama Yusuf’un işi: bölüm 6 seçenekleri önceliksizdir. Operatör geri bildirimi (2026-09-19) ve aynı sınıftan bulunanlar **bölüm 8**; kod o dilimde yazılmaz.

**Bu dosya ne değildir.** Kod değişikliği, PR, sprint backlog, Account Console tasarımı, sky-app Dart rewire checklist’i (o ayrı: `docs/sky-app-api-cutover.md` / `sky_lab_genel/docs/sky-app-api-cutover.md`).

**Okunan birincil kaynaklar**

| Kaynak | Ne için |
|---|---|
| `src/app/(authorized)/**/page.tsx` (28 sayfa) + `src/lib/navigation/sidebar-nav.ts` | Ekran envanteri ve kim görür |
| `src/lib/chrome-nav.ts`, `src/components/layout/AuthenticatedChrome.tsx`, `ClubSwitcher.tsx` | Chrome, waffle, hesap UI’si olmadığı |
| `sky_lab_genel/CONTEXT.md` | Sözlük: Event, Ticket, QR aileleri, Account Console vs Account center, Form slot, Mail onayı, Owner team, Guest vs Member apply |
| `sky_lab_genel/docs/adr/0011`–`0034` | Kilitler (CMS News, skyl.app, forms bounce, mail onayı, Ticket=kapı, Skyevents sonra) |
| `superadmin-event-media/docs/sky-app-api-cutover.md` | Go `/v1` gerçekleri, kapı API, sertifika, CDN, parked UI |
| GitHub `skylab-kulubu/superadmin` PR #33–#45 | Bu oturumda gemiye binenler |
| `scripts/keycloak-forms-users-read.sh`, `scripts/keycloak-skymail-lists.sh` | SA rol / `aud` tuzakları |

**Aranan ama bulunmayan.** `notes/event-cycle.md` ve `notes/skyforms-handoff.md` ağaçta yok. Döngü ve forms bounce bunun yerine CONTEXT + ADR 0029/0030/0032/0034 ile yazıldı.

**Olgunluk etiketleri (ekran haritasında)**

| Etiket | Anlam |
|---|---|
| **Olgun** | Go/CMS’e bağlı, operatör kullanabilir, chrome geçişi (PR #45) yapılmış |
| **Orta** | Var, bağlanmış; veri, yetki veya ürün kilidi yüzünden yarım |
| **İnce** | Ekran veya API var; kapı/üyelik gerçeği başka yerde |
| **Yönlendirme** | Eski rota; asıl iş başka sayfada |
| **Parked** | Ürün kilitli; bu panelde (veya bu fazda) yapılmaz |

---

## 1. Amaç ve kapsam

### Bu panel kim için

**Privileged** (`ADMIN`, `YK`, `DK` veya alt grupları) ve **Leader** (`LIDERLER` / `KOORDINATORLER`). Sıradan **Member** (`UYELER` ağacı) bu panele menü almaz. Kısa URL rolü olan biri yalnız Özet + Kısa URL görür.

Kaynak: `src/lib/auth/groups.ts` (`isPrivileged`, `isLeader`), `src/lib/navigation/sidebar-nav.ts` (`filterSidebarNavForUser`).

Bu, **kulüp operasyon konsolu**dur: kimlik ağacı, etkinlik, başvuru (Ticket), duyuru (CMS News), kısa link, medya. Üye telefonundaki uygulama **sky-app**. Misafir formu **skyforms**. Toplu mail **skymail**. Şifre/oturum/passkey **Account Console**.

### Bu panel kim için değil

CONTEXT kelimesi kelimesine:

- **Account Console** — Keycloak self-service, `https://e.yildizskylab.com/realms/e-skylab/account`. Cutover insanları burada tutar. Superadmin şifre, oturum listesi, passkey, profil IdP UI’si **değildir**.
- **Account center** — Sonra gelecek SKY LAB origin; Keycloak Account REST. Place değil, superadmin değil, Keycloak theme o projenin bitişi değil. **Şimdi build yok.**
- Club switcher (waffle: Yönetim / Forms / Mail) **hesap UI’si değildir.** `src/lib/club-switcher.ts` üç kulüp konsolu; `e.` yok.
- **Staff scanner** — sky-app kapı ekranı (Mobile Lab). Superadmin `/qr` bu ürün değil (`docs/sky-app-api-cutover.md` §6, CONTEXT Staff scanner).
- **Skyevents** — `events.yildizskylab.com` / skyevents. ADR 0034: sonra. Microsite’ler (`skydays`, `yildizjam`) bu fazda durur; katılımcı gerçeği orada değil.
- Forms editörü, SMTP, ikinci IdP, ikinci user-store.

### Host ve komşular (kod / Dockerfile, uydurma yok)

| Ne | Origin / path |
|---|---|
| Admin | `https://admin.yildizskylab.com` (`Dockerfile` `NEXT_PUBLIC_APP_URL`) |
| Core API | `https://api.yildizskylab.com` `/v1` (yerel varsayılan `http://localhost:8080`) |
| CMS | `NEXT_PUBLIC_CMS_URL` prod bake `https://api.yildizskylab.com/api` → `/cms/collections/News`. Core `/v1` **değil** |
| Forms insan UI | `https://forms.yildizskylab.com` / admin `…/admin` |
| Mail insan UI | `https://mail.yildizskylab.com` |
| IdP | `https://e.yildizskylab.com/realms/e-skylab` (`src/lib/auth/oauth2.ts` sabit) |
| CDN | `https://cdn.yildizskylab.com` (`src/lib/event-media.ts`) |
| Short link | `https://skyl.app/{alias}` → core `GET /v1/go/{alias}` 301 (ADR 0020, 0033) |

README hâlâ `admin-skylab.vercel.app` ve Next 16.0.1 yazar; paket `next` 16.1.0, imaj `ghcr.io/skylab-kulubu/superadmin`. README’yi kaynak sayma.

### Yetki modeli (panelin omurgası)

Kimlik **Keycloak Group ağacı**. Realm role üyelik kopyası değil (CONTEXT Realm role). Core token: `aud` içinde `core`, roller yalnız `resource_access.core` (ADR 0019). Panel JWT’yi cookie’den okur (`sessionUserFromAccessToken`).

| Kim | Ne yapar |
|---|---|
| **Privileged** | Tüm identity + News + sezon + owner’suz Event + kapı görevlisi atama (grant B) + tam nav |
| **Leader** | Kendi Owner team etkinlikleri, oturum, kapı (grant A), yarışmacı, medya. Kullanıcı/grup/duyuru/sezon yok |
| **GECEKODU üyesi** | Create/update (delete değil) — `canWriteEvent` özel durum |
| **url:\*** / eski `skylapp:*` | Kısa URL. Privileged zaten geçer |
| Boş Owner team | Yalnız Privileged mutate eder (ADR 0018) |

Kapı taraması (API, ADR 0021): Privileged veya Owner team Leader (A); Event `doorStaffIds` (B); Group `team_door_scan=true` üye. Sıradan üye 403.

### Bu oturumda gemiye binen (doğru liste)

Parked ile karıştırma.

| PR / commit | Ne |
|---|---|
| #35 `fix/group-member-source` | Parent roster’da **Source group** (`sourceGroupPath`) |
| #34, #36, #37, #41 | Skyforms bounce, draft restore, reserved Event id, alias 409 retry |
| #39 | **Takvim** (`?view=calendar`), Member apply düğmesi, liste düzeltmeleri |
| #40, #42 | **Participant roster** + ticket detay (`/events/[id]/tickets/[ticketId]`) |
| #43 | **Event mail list** sync → Skymail compose (`POST /v1/events/{id}/mail-list`) |
| #45 (merged 2026-09-18) | **Forms language pass**: ListToolbar, StatusChip, StateCard, mix chart; roster/mail silinmedi |
| `a3394a4` | `NEXT_PUBLIC_MAIL_URL` boşken `https://mail.yildizskylab.com` |
| CDN | `publicMediaUrl` mutlak `cdn.yildizskylab.com`; Team media library aynı Owner team fotoğrafları |

**Parked (bilinçli, bu fazda panelde yok):** Skymail **Mail onayı** kuyruğu; kapı kamerası / **Walk-in** Event QR ürünü; **Skyevents** sitesi; branded **Account center**.

---

## 2. Bugünkü harita

Giriş: `/login` → `/api/auth/login` → Keycloak code → `/api/auth/callback` cookie (`auth_token`, `refresh_token`) → `/dashboard`. `src/proxy.ts` cookie yoksa `/login`. `(authorized)/layout.tsx` JWT’den `UserDto` basar; nav `filterSidebarNavForUser`.

Sidebar iki dilim: **Platform** (Kullanıcılar, Gruplar, Duyurular, Kısa URL) ve **Program** (Etkinlikler, Sezonlar, Oturumlar, Ekipler, Kapı, Yarışmacılar, Medya). Leader’da Platform yok. Altta ClubSwitcher.

Eski `/events/[id]/edit`, `/events/[id]/days`, `/sessions/new|edit|delete`, `/seasons/new|edit` **redirect**. Asıl iş Event hub ve liste drawer’ları.

---

### 2.1 Özet — `/dashboard` — Orta

**Ne.** Privileged/Leader sayacı: etkinlik, oturum, başvuru (yaklaşan etkinlik Ticket’ları), Privileged’da kullanıcı + duyuru. Mix chart: Misafir/üye, kapı durumu. Bar: son altı ay etkinlik, oturuma göre dağılım, aktif/pasif. Yaklaşan etkinlik listesi.

**Kim.** `isPrivileged \|\| isLeader`; değilse StateCard.

**Olgunluk.** Chrome olgun. Veri **örneklem**: başvuru sayısı yaklaşan 8 etkinliğin Ticket birleşimi (`upcomingEvents` + `ticketsApi.listByEvent`), tüm sezon değil. `sessionsApi.listAll` her Event × EventDay — yavaşlar. Observability yok (Sentry/audit).

**Sektör.** Eventbrite Home / Luma Host dashboard: gerçek zamanlı kayıt, check-in, gelir. Burada gelir yok; kulüp kapasite + Ticket.

---

### 2.2 Kullanıcılar — `/users`, `/users/[id]` — Olgun (identity), İnce (üyelik kartı)

**Liste.** Core `GET /v1/users?q=` — **User shadow** (email, schoolEmail, name), Keycloak Admin araması değil (CONTEXT User). Ekle: email, ad, soyad. Sayfalama 10.

**Kart.** Grup ekle/çıkar (picker), client-role katalog, inherited vs extra roller, `POST /v1/users/{id}/logout`. SkyNumber + schoolEmail chip. Promote = grubu `UYELER` ağacına koymak; LDAP yok.

**Yok (operatör, 8.1).** Üniversite, fakülte, bölüm, telefon, LinkedIn — `UserDto` (JWT) bu alanları taşır; kart `GET /v1/users/{id}` + `UserCardView` basmaz, `identityApi` **PATCH yok**. Şifre sıfırlama (Account Console), Student card UID bind UI, profil foto, self-service, toplu CSV, skyNumber elle basma.

**Sektör.** Keycloak Admin Users ≈ bu kartın kaba hali; WorkOS User Management / Google Admin “Users” org admin. `myaccount.google.com` = Account Console, bu ekran değil.

---

### 2.3 Gruplar — `/groups`, `/groups/[id]` — Olgun

**Liste.** `GET /v1/groups`, parent seçerek oluştur.

**Kart.** CONTEXT Group öznitelikleri:

- `public_listing` — Herkese açık üye listesi
- `public_leaders` — Yalnız liderler
- `team_door_scan` — Ekip kapı taraması (default off, ADR 0021)
- `display_name_tr/en`, `description_tr/en`

Üye roster **iç içe**: parent’ta görünen kişi Source group ile gelir (`memberSubtitle`, CONTEXT Source group). Çıkarma source üyeliği siler. Group → client-role mapping. Ekstra attribute kaçış vanası.

**Yok.** Sürükle-bırak ağaç, Privileged/Leader’ı path’ten “görsel rozet” olarak ayırma (yalnız subtitle), `team_door_scan` etkisinin Event kapısında canlı testi. Üye satırı path + e-posta; üniversite/bölüm yok (8.1 ile aynı ince `Person`).

**Sektör.** Keycloak Groups + attributes. Slack/Discord rolü değil; yetki ağacın kendisi.

---

### 2.4 Duyurular — `/announcements`, `/new`, `/[id]/edit` — Olgun (içerik), Orta (CMS yetki)

**Ne.** CMS `News` (ADR 0011). Core `/api/announcements` **ölü**. Privileged-only. Başlık, özet, gövde, kapak URL, etiket, yazar, featured. `canEdit` / `cms:access` site client (ADR 0014) panelde ayrı seçilmez: Privileged varsayılır.

**Yok.** WYSIWYG, medya kütüphanesinden kapak seç (URL yapıştırılır), yayın takvimi, site önizleme, Teams koleksiyonu (sky-app CMS Teams ayrı).

**Sektör.** WordPress/Ghost editorial; HubSpot blog. Club announcement ≠ Eventbrite “announce to attendees”.

---

### 2.5 Kısa URL — `/urls` — Olgun

**Ne.** ADR 0020: logged-in shortener **burada**; `skyl.app` yalnız redirect. `url:create` / `url:moderator` (eski `skylapp:*` hâlâ `canUseUrls` içinde). Benim linkler, moderatörde tümü, `clickCount` (toplam), QR drawer, alias düzenle.

**QR.** `shortQrUrl` → `GET /v1/go/{alias}/qr` **`?logo` yok**. Drawer `<object>` 192px; **indir yok**. Core `?logo=1` kulüp işareti, `?size=` 64–1024 (cutover §19). Java `generateQRCodeWithLogo` bırakıldı.

**Tıklama.** Liste “N tıklama” + “En çok tıklanan” bar. Hit satırı (IP, UA, hesap) **yok**. QR GET tıklama saymaz (cutover).

**Event ile.** Form slot kaydında `humanFormAlias` → nokta insan kimliği, skyl.app alfabesi `A-Za-z0-9_-` (nokta → tire, CONTEXT Short link, ADR 0033). 409’da yıl/`-2`…`-9` retry.

**Yok (operatör, 8.5–8.6).** Ortası logolu QR; PNG indir (oturum QR aynı). Per-hit log + analiz. Arbitrary `data=` QR (phishing, KALDIRILDI). Event hub’dan afiş indir (fırsat A).

**Sektör.** Bitly org / Dub.co branded QR + click analytics; Pretix “event URL”. Public SPA değil.

---

### 2.6 Etkinlikler listesi — `/events` — Olgun

**Ne.** `GET /v1/events?ownerTeam=`. Liste / **takvim** (`EventCalendar`). Filtre: Tümü / Yaklaşan / Aktif / Geçmiş. Arama ad-ekip-konum. `?ownerTeam=` Ekipler’den gelir. Skyforms `formUrl` query → `/events/new` handoff.

**Yok.** Haftalık/ajanda view, iCal dışa aktar, kapasite doluluk chip’i listede, drag-reschedule.

**Sektör.** Luma calendar-first; Eventbrite list+calendar; Google Calendar değil (ICS yok).

---

### 2.7 Yeni etkinlik — `/events/new` — Olgun (operatör), Orta (ürün uçları)

**Ne.** `EventEditor`: ad, konum, Owner team (Privileged boş bırakabilir, ADR 0018), açıklama, tarih, kapasite, kapak/galeri + **Team media library**, Form slot’lar, LinkedIn, ödül, sezon (Privileged), aktif, sıralamalı, **Attendance rule** (`none` / `once` / `ratio`), kapı görevlileri (yalnız Privileged picker).

Skyforms’a gitmeden draft `sessionStorage`; reserved Event id forms’a gider (PR #41).

**Yok.** Canlı önizleme, waitlist, bilet tipi fiyatı (kulüpte ücret yok), Walk-in aç/kapa, sertifika şablon seçici, Event QR afiş üret (Short link QR dolaylı).

---

### 2.8 Etkinlik hub — `/events/[id]` — Olgun (ops), İnce (kapı/sertifika)

Operatörün “tek Event brifingi”. Parçalar:

1. **Meta** — kapak, açıklama, aktif chip, başvuru sayısı.
2. **Üye kaydı** — `POST /v1/events/{id}/applications/me`. Metin: giriş yapmış kişi public forma düşmez (ADR 0029). Bu, **admin’in kendi bileti**; üye uygulaması sky-app.
3. **Guest link** — `formAlias` → skyl.app veya `formUrl`.
4. **Yarışmacılar** — skor, kazanan; `ranked` Event.
5. **Başvuranlar (Participant roster)** — ADR 0034 gerçeği. Filtre Misafir/Üye, Kayıtlı/Giriş yaptı. Satır → ticket detay. Mail → Skymail list sync. Kapı → `/qr` (UUID kasa). Mix chart. **Katılımcı ekle / satırdan check-in yok.**
6. **Günler ve oturumlar** — EventDay CRUD + Oturum CRUD + **Oturum QR** PNG (`GET /v1/sessions/{id}/qr`). Konuşmacı, tür (Atölye… Jam). Check-in sayısı satırda yok.
7. **Düzenle drawer** — aynı EventEditor; skyforms dönüşünde URL kaydı.

**Yok (hub’da).** Sertifika issue/recompute/revoke (API core’da CANLI, UI yok). Event QR (afiş) ayrı “katıl” PNG. Walk-in sayacı. Kapasite dolunca kapat. Kişi seçerek Ticket basma ve Oturum yoklaması (8.3). `current-session` saat eşlemesi. Üye kaydı bloğu **operatörün kendi** `applications/me` bileti — başkasını yazmaz.

**Sektör.** Eventbrite Manage + Orders + Check-in; Pretix event dashboard; Hopin “sessions” ≈ Oturum listesi.

---

### 2.9 Ticket detay — `/events/[id]/tickets/[ticketId]` — Olgun

**Ne.** `canListEventTickets` = Event update yetkisi. Ad, e-posta, misafir alanları (üniversite/fakülte/bölüm **yalnız GUEST**), bilet türü, kaynak form, `sent`, check-in satırları (başlık yoksa `sessionId` UUID). Detay alanı **Bilet** = `row.id` UUID.

**Yok.** REGISTERED Ticket’ta üyenin shadow üniversite/bölümü (8.1). Ticket QR PNG (core mint yok, cutover §12). İptal / “gelmeyecek”. Check-in geri al. Manuel GUEST→REGISTERED bağlama. Form yanıt gövdesi (skyforms ayrı).

**Sektör.** Eventbrite order detail; Pretix order position. Ticket = kapı kimliği (ADR 0032), form satırı değil.

---

### 2.10 Sezonlar — `/seasons` — Olgun (Privileged yazma)

CRUD + Event ata. Leader nav’da yok. Java `event-types` yok; filtre `ownerTeam`.

**Sektör.** Üniversite “akademik yıl” / Eventbrite repeating series değil; kulüp dönemi (SKYDİYS 2026). Ayrı sayfa **meşru**: katalog, Event’e bağlanan dönem. Oturum gibi EventDay tanesi değil (8.2).

---

### 2.11 Oturumlar — `/sessions` — Orta, **yanlış yer**

Global Oturum listesi (`listAll` N+1). Drawer: Event + EventDay seç, konuşma ekle. Asıl bağ EventDay altında; Event hub’da da var.

**Operatör (8.2):** Oturum Event’e bağlı bir tane; **ayrı sidebar sayfası gereksiz.** Luma/Hopin “sessions” ürünü sanal sahne içindir, kulüp konuşması Event hub’dadır. Nav’dan kaldırmak + hub’ı tek editör yapmak düzeltme; bu fazda kod yok.

---

### 2.12 Ekipler — `/teams` — İnce

`GET /v1/teams` **public listing**. Tıklayınca `/events?ownerTeam=`. Üye/lider roster burada yok (Grup kartı + public `GET /v1/teams/{team}/members` core’da, panel kullanmaz). İki “ekip” yüzeyi: bu sayfa Event filtresi, üyeler Grup kartında. CMS Teams değil.

**Sektör.** CMS “Teams” sayfası / Luma calendar org. Gizli ekip (SKYSEC) `public_listing` kapalıysa listede olmamalı.

---

### 2.13 Kapı — `/qr` — İnce (bilinçli)

**Ne.** Etkinlik + Oturum seç, **bilet UUID yapıştır**, `POST /v1/tickets/{id}/sessions/{sid}/check-in`. Başarı satırı `result.id` (check-in UUID). Son 8 kayıt subtitle’da yine `ticketId` UUID. `canCheckInForTeam` = Privileged veya Leader; `doorStaffIds` / `team_door_scan` **bu sayfada filtrelenmez** (API 403 olabilir).

**Operatör (8.3):** “Şu kişi katıldı” kişi/Ticket picker değil UUID kasa. Roster’dan check-in / panelden katılımcı ekleme yok.

**Ne değil.** Kamera, SkyPass QR, Ticket QR auto-detect, Student card NFC, Queued check-in, Oturum QR / Event QR okutma. CONTEXT: personel afişi ve projektörü okutmaz. Staff scanner sky-app.

**Sektör.** Eventbrite Entry Manager / pretixSCAN / Skidata gate. Bu ekran “kasa terminali UUID”, turnike değil.

---

### 2.14 Yarışmacılar — `/competitors`, `/new`, `/[id]/edit` — Orta

Skor, `isWinner`. `PersonPick` **burada var** (kapı ve roster’da yok). Kişi çözülmezse satır başlığı `userId` UUID. Leaderboard core `/v1/competitors/leaderboard/team/{ownerTeam}` panelde yok. `ranked` Event ile zayıf bağlı; Ticket roster’dan kopuk.

**Sektör.** CTF scoreboard / hackathon judging (Devpost). Ticket roster değil.

---

### 2.15 Medya — `/media` — Orta

`POST /v1/media` `file`. Liste, kopyala, Privileged sil. Event editörü aynı API + team library. Global kütüphane **team-scoped değil** (CONTEXT Team media library “asla başka ekip” — Event picker `eventsApi.list(ownerTeam)` ile sınırlı; `/media` tümünü gösterir).

CDN: göreli gelirse prefix. `cms.yildizskylab.com` yok.

---

### 2.16 Form slot (EventEditor içi) — Olgun bounce, Orta kapı

CONTEXT Form slot: apply + extras (Yarışma, CTF, özel). Harici URL veya Skyforms. Bounce `forms…/forms/new-form?returnTo&title&ownerTeam&eventId` (ADR 0030). Dönüş `formUrl` + `formSlot`. **Editor gömülmez.**

Gate: `GET /api/forms/{id}/meta` (410=kapalı) / admin PUT status. Yeni taslak açık.

Member apply public slot’a **gitmez**. Guest apply slot URL.

**Yok.** Forms yanıtlarını roster’a kolon olarak çekmek; Gecekodu live template (CONTEXT: draft path, live yok); Typeform.

---

### 2.17 Event mail list — Olgun tetik, parked onay

`openEventMail` → `POST /v1/events/{id}/mail-list` → `mailListId` → `https://mail.yildizskylab.com/mail-tasks/create?mail_list_id=`. Roster seçimi compose’a **gitmez** (seçim `ticketMailRecipients` hesaplanır, sync tüm Event listesi). Onay kuyruğu Skymail (ADR 0031). Superadmin SMTP yok. `mails:write` 403 ürün değil.

Kulüp geneli “tüm Üyeler” listesi burada yönetilmez.

---

### 2.18 Chrome / yetkisiz

StateCard: duyuru, URL, özet. `clubRoleLabel` şaka etiketleri (`CHAINLAB`/`SKYSIS` → “YAŞIYONUZ MU”) — planlama gürültüsü. Responsivity README’de “kapsam dışı”; chrome `md:` ile kısmen var.

---

### 2.19 API yüzeyi panelin çağırdığı (özet)

Core `/v1`: events, event-days, sessions (+ `/qr`), tickets, applications/me, check-in, mail-list, seasons, media, groups/users/client-roles, urls, go/qr, competitors, teams.

CMS: `/cms/collections/News`.

Forms: `/api/forms/…`, `/api/admin/forms/…` (zarf `data`).

**Çağrılmayan (core’da CANLI veya kilitli):** `/v1/certificates/*`, `/v1/skypass/*`, guest apply POST, session check-in/me|guest|skypass, `current-session`.

---

## 3. Sektör kıyası

Amaç “onlar gibi olalım” değil: **aynı işi kim nasıl çözüyor**, boşluğu adlandırmak için.

### 3.1 Etkinlik ops — Eventbrite / Luma / Pretix / Hopin

| İş | Eventbrite | Luma | Pretix (OSS, self-host) | Hopin / RingCentral Events | SKY LAB admin **şimdi** |
|---|---|---|---|---|---|
| Event oluştur | Sihirbaz, bilet tipi, ücret, kapasite | Takvim + tek sayfa, ücretsiz/ücretli | Shop + ürün (bilet) | Sanal “event” + stage | EventEditor; ücret yok; kapasite alan var, doluluk enforce UI yok |
| Çok gün / konuşma | Agenda **event içinde** | Schedule event içinde | Subevents parent event’te | Stage + session (ayrı ürün) | EventDay + **Oturum**; hub’da var **ve** `/sessions` çift yüzey (8.2) |
| Kayıt | Checkout → order | Guest list / apply | Order position | Registration | **Ticket** (REGISTERED üye, GUEST misafir). Form yanıtı kapı değil |
| Üye vs misafir | Account vs guest checkout | Luma account opsiyonel | Hesap opsiyonel | Zorunlu hesap sık | Member apply native; Guest form slot (ADR 0029) |
| Katılımcı listesi | Orders / attendees | Guests | Check-in list | Attendees | Participant roster (ADR 0034) |
| Mail katılımcılara | Eventbrite Email | Luma blast | pretix mail / plugin | In-product | Skymail list + compose; onay Skymail |
| Takvim | List+cal | Birincil | Değil | Değil | `?view=calendar` |
| Kapı | Organizer app + **isimle check-in** | Check-in list | **pretixSCAN** (arama) | Sanal “join” | API hazır; panel UUID kasa; kamera sky-app **UI SONRA**; masa başı kişi picker yok (8.3) |
| Poster QR “katıl” | Event URL / QR | Public event URL | Shop URL | Lobby link | Event QR = afiş, kişi id yok; Walk-in kilitli, panelde yok |
| Sertifika | Yok / badge eklenti | Yok | Plugin | Yok | Attendance rule Event’te; PDF API CANLI; admin UI yok |
| Public site | Eventbrite.com sayfası | luma.com/event | Shop | Hopin lobby | Microsite’ler durur; **Skyevents sonra** |
| Ödeme | Asıl iş | İsteğe bağlı | Çekirdek | B2B | Yok (bilinçli) |

**Luma** kulüp gecesine yakın: hızlı sayfa, guest list, takvim daveti. SKY LAB ekstra: Keycloak üyelik, SkyPass, Oturum yoklaması, sertifika oranı.

**Pretix** mimari yakın: self-host, Ticket=kapı, ayrı scan uygulaması, plugin. Fark: Pretix ticari shop; SKY LAB üyelik + misafir form + kapı kimliği.

**Eventbrite** ağır ops + ücret. Waitlist, promo, refund burada yok — kulüp ihtiyacı belirsiz.

**Hopin** sanal sahne. Oturum listesi analog; kapı/QR analog değil.

### 3.2 Form + CRM — Google Forms / Typeform + HubSpot

| İş | Google Forms | Typeform | HubSpot Forms+CRM | SKY LAB |
|---|---|---|---|---|
| Form tasarım | Sheets’e akar | Logic jump, ücretli | Marketing form | **skyforms** (ayrı app). Admin bounce (ADR 0030) |
| Yanıt = kayıt mı? | Sık hata: evet sanılır | Entegrasyon şart | Contact oluşturur | **Hayır.** Ticket önce; form extra (ADR 0032) |
| Yoklama | Tarihsel kulüp: Typeform + e-posta sayımı | Aynı anti-pattern | Workflow | CONTEXT: Typeform yoklama **yasak**. Oturum Check-in |
| Üye formu atlama | Yok | Yok | Lifecycle stage | Logged-in **Member apply** public forma düşmez |
| Çok form / Event | Ayrı formlar, elle link | Aynı | Form per landing | Form slot: apply + CTF + … + skyl.app |
| Onay / review | Yok | Typeform logic | HubSpot workflow | skyforms `requiresManualReview` (API alan); panel inceleme kuyruğu yok |
| CRM | Sheets | Zapier | Asıl ürün | User shadow + Ticket; HubSpot yok |

ARTLAB geçmişi (CONTEXT/ADR 0026): projektör Typeform + el ile e-posta. Hedef: Oturum QR / staff scan → aynı Check-in.

### 3.3 Mail — Mailchimp / Listmonk / Skymail

| İş | Mailchimp | Listmonk | SKY LAB |
|---|---|---|---|
| Liste | Audience, segment | Lists | Kulüp listeleri + **Event mail list** (GECEKODU vs AGC) |
| Kampanya | Campaigns / Customer Journey | Campaigns | skymail mail-tasks |
| Onay | Agency/Enterprise approval | Yok / opsiyonel | **Mail onayı skymail’de** (ADR 0031). Admin kuyruk **parked** |
| Tetik | Otomasyon | API | Admin “Etkinlik katılımcılarına mail” = sync + compose URL |
| SMTP | Mailchimp | Kendi SMTP | Core S2S welcome/sertifika; panel SMTP yok |
| 403 | API key | Auth | `mails:write` 403 **ürün değil** |

Seçilmiş roster satırları Skymail’e segment olarak gitmez (boşluk).

### 3.4 Kapı — Skidata / Eventbrite check-in / pretixSCAN

| İş | Skidata / stadyum | Eventbrite Entry Manager | pretixSCAN | SKY LAB kilit |
|---|---|---|---|---|
| Medya | RFID kart, bilet | Order barkod | QR / barcode | **SkyPass QR** (üye), **Ticket QR** (Event), **Student card** UID; **Event QR / Oturum QR personel okutmaz** |
| Offline | Gate fail-closed sık | Kısmi | Offline list | **Queued check-in**, campus fail-open (ADR 0022; path Oturum, EventDay 404) |
| Kim tarar | Turnike personeli | Organizer | Device + izin | A Leader/Privileged, B `doorStaffIds`, `team_door_scan` |
| Cihaz | Sabit okuyucu | Telefon | Telefon | sky-app kamera + isteğe USB okuyucu; **admin telefon kamerası yok** |
| Çift sayım | Anti-passback | Duplicate warn | Same | Aynı Oturum 409 |

`/qr` UUID kasa. Gerçek kapı Mobile Lab.

### 3.5 Kimlik — Keycloak vs WorkOS vs “hesap merkezi”

| İş | Keycloak Account Console | Keycloak Admin | WorkOS Admin Portal | Google `myaccount` vs Admin | SKY LAB |
|---|---|---|---|---|---|
| Şifre, oturum, passkey | Evet | Mümkün, yanlış yer | User mgmt | myaccount | **Account Console `e.` — şimdi** |
| Org kullanıcı kartı (üniversite, bölüm, telefon) | Profil (self) | User attributes | Directory user | Admin Console user details | **Kartta yok, PATCH yok (8.1).** Self alanlar `PUT /v1/users/me` (cutover §10.1); admin yüzeyi ince |
| Grup / org rol | Hayır | Groups/roles | Directory / FGA | Admin Console | **superadmin Grup + client-role** |
| Branded origin | Theme (sınırlı) | Hayır | AuthKit | Custom | **Account center sonra**; theme = o projenin bitişi değil |
| İkinci IdP | — | — | Enterprise SSO | — | **Yok** |

Cutover: sky-app Ayarlar → Custom Tabs `e.` Account Console. Superadmin’e gömme.

### 3.6 Kısa link — Bitly / Dub / skyl.app

| İş | Bitly | Dub.co | Google Campaign URL / UTM | SKY LAB **şimdi** |
|---|---|---|---|---|
| Kısalt | Org workspace | Self-host opsiyon | Kısaltmaz, parametre ekler | Admin `/urls`; public `skyl.app` 301 |
| Branded QR | Logo ortada, PNG/SVG indir | Aynı | Yok | Core `?logo=1` var; panel **düz** QR, indir yok |
| Tıklama | Hit: IP, UA, referrer, geo, cihaz | Aynı + bot filtre | Analytics property | `clickCount` toplam; hit yok |
| Giriş yapmış kullanıcı | Bitly hesabı değil, tıklayan | Aynı | GA user id (sitede) | skyl.app **SPA değil** (ADR 0020); hop’ta Keycloak cookie yok |
| Tıklayana bildirim | 301, interstitial yok | Aynı | Çerez banner hedef sitede | Hop zaten sessiz; log da yok |

Bitly/Dub hop’u tıklayana “izleniyorsun” demez; analitik org panelinde. skyl.app’i login SPA yapmak ADR 0020’yi bozar.

---

## 4. Boşluklar

### 4.1 UX

- Kullanıcı kartı identity-only: üniversite/bölüm/telefon/LinkedIn görünmez, güncellenmez (8.1).
- `/sessions` ayrı nav; yazma zaten Event hub’da (8.2).
- `/qr` ve Ticket “Bilet” UUID; operatör kişi değil id yapıştırır (8.3). Roster’dan check-in / katılımcı ekle yok.
- Kısa URL / Oturum QR düz kare, logo yok, indir yok (8.5).
- Kısa link tıklaması yalnız toplam sayı; kim/IP yok (8.6).
- Roster seçimi mail’e yansımaz; her seferinde tüm Event listesi.
- Oturum QR var, Event QR (afiş) Event hub’da yok (Short URL QR dolaylı).
- Sertifika kuralı kaydedilir; issue/revoke/verify yok.
- Leader `doorStaffIds` göremez/düzenleyemez (yalnız Privileged `assignDoorStaff`).
- `/media` team-scope değil.
- Özet başvuru sayısı örneklem.
- `listAll` oturum N+1.
- README / `backend_datalari/checklist.md` Java dönemi; yeni operatör yanılır.
- `UserDto.ldapUser` tipte kalmış; UI LDAP promote yok.

### 4.2 Veri

- `Person` / `UserCard` üniversite, fakülte, bölüm, telefon, LinkedIn, `studentCardUid` taşımaz; `GET /v1/users/{id}` bu yüzden kartta kısır. Self `PUT /v1/users/me` cutover’da var; **admin PATCH başka kullanıcı** 10.2 listesinde yok.
- REGISTERED Ticket detayı misafir üniversite alanlarını boş basar; üye profili bağlanmaz.
- Ticket ↔ skyforms yanıt senkronu panelde görünmez.
- Walk-in Ticket’ı ayırt edilmez (API ürünü parked).
- Check-in mix “en az bir Oturum”; ratio (6/8) roster’da yok.
- Capacity yazılır, satış/kapanış yok.
- `sent` alanı var, anlamı (welcome gitti mi) zayıf.
- Public team members paneldan çekilmez.
- Certificate serial/PDF admin’de yok.
- Short URL hit satırı yok; yalnız `clickCount` (8.6).

### 4.3 Entegrasyon

**Forms.** Bounce + gate var. İnceleme kuyruğu, şablon klon, yanıt grid, “formdan Ticket” yok (ve olmamalı — ADR 0032). Forms SA `users:read` + `aud=core` yoksa isimler `-` (`scripts/keycloak-forms-users-read.sh`).

**Skymail.** List sync + compose. Onay, şablon, teslimat, bounce admin’de yok (kilit). Core SA `skymail:access|lists:read|lists:write` + `aud` skymail şart (`scripts/keycloak-skymail-lists.sh`). Eksik → 500 wrapping 403.

**skyl.app.** Create/list/`clickCount` var. Panel QR `?logo` geçirmez, indir yok (8.5). Hit log yok; cutover QR GET sayaç artırmaz (8.6). Event “afiş paketi” yok (A).

**CMS.** News Privileged. `cms:access` per site client (ADR 0014) ekranda yok; Teams koleksiyonu yok; inscribed edit yok.

**sky-app.** Cutover: Member apply, tickets/me, SkyPass mint, Oturum check-in, certificates/me **UI SONRA / rewire**. Admin roster, mobil aktivite ve kapı **üç gerçek**; bugün kopuk.

**CDN.** Prefix var. Medya silme Privileged; Event’ten koparma ayrı.

### 4.4 Yetki

- Nav ≠ API: Leader `/qr` görür; Grant B / `team_door_scan` üye nav almaz (`canCheckInForTeam` de onları saymaz).
- `extractResourceRoles` hâlâ `skylapp` okur (Java artığı).
- GECEKODU üye create — bilinçli özel durum; diğer ekiplere bulaşırsa şaşırırlar.
- News = Privileged, `cms:access` değil.
- Kullanıcı silme API var, kartta yok (iyi / eksik, karar yok).

### 4.5 Gözlemlenebilirlik

- Problem+json `title` toast; traceId yok.
- Mail-list 403/500 ayrımı operatöre “Skymail listesi yenilenemedi”.
- Check-in 409 “zaten bu Oturum” metni zayıf.
- Audit (kim kapı görevlisi atadı, kim grubu değiştirdi) yok.
- Short link hit yok; tıklama izi operatöre kapalı (8.6).
- E2E smoke ince; Jest chrome/roster/mail için var, kapı kamerası yok (olmamalı).

---

## 5. Kilitli ama yapılmamış

Ürün kilitli. **Yanlış yere inşa etmek** boşluktan pahalı. CONTEXT + ADR.

### 5.1 Mail onayı — Skymail’de (ADR 0031)

Send yetkisi olmayan taslak → onaylayanlara mail → onayda gönderim. Core kuyruk değil. Superadmin SMTP değil. `mails:write` 403 ürün değil. Panel “onay kutusu” **yapılmaz**. Yapılan: list sync + compose. Eksik Skymail tarafında (şablon, onay UI, Event vs kulüp listesi).

### 5.2 Walk-in — Event QR (ADR 0032, CONTEXT)

Afiş, **katılan** okutur. Ticket yoksa Walk-in Ticket. Personel afişi okutmaz. Ticket mail yok veya “zaten içerde”. Check-in ayrı (Oturum QR veya SkyPass/Ticket QR).

Admin’de Event QR mint / walk-in sayacı / “afiş modu” yok. API cutover: Walk-in “ürün”; Java’da yok. Personel kamerasına Event QR **ekleme**.

### 5.3 Üye-içi başvuru — Member apply (ADR 0029)

Logged-in User → `POST …/applications/me` → REGISTERED Ticket. Public Form slot değil.

API CANLI. Admin’de operatör düğmesi var. Asıl UX **sky-app** (hâlâ Java path / yutulan 403). Panel ikinci üye app değildir. “Admin’den üye kaydı” ≠ kulüp içi başvuru ürünü.

Kimlik (ad, e-posta) User’dan gelir. Plaka, üniversite, beden gibi **etkinliğe özel** sorular User profiline yazılmaz; **Apply extra** (5.8). Üyeyi extras için public forma dökmek ADR 0029’u bozar.

### 5.8 Apply extra — üye hesabı varken de ek soru (2026-09-19)

**Sorun.** Member apply hesabı Ticket’a bağlar; Guest apply formda kilitli Ad/Soyad/E-posta ister. Operatör hâlâ plaka, üniversite, t-shirt, acil telefon gibi şeyler ister. Bunlar **User değildir** (plaka her etkinlikte değişir). Form yanıtını kapı kimliği saymak CONTEXT Ticket’ı bozar.

Kullanıcı kartındaki üniversite/fakülte/bölüm **ayrı boşluk (8.1)**: kulüp profili, Event extra’sı değil. Extra “bu ARTLAB’da hangi üniversiteden geliyorsun” olabilir; kart “üyenin kayıtlı bölümü”.

**Kilit (önerilen, rapor tarihi).** Event bir **extra şeması** tanımlar (alan adı, etiket, tip: metin/seçim/zorunlu). Aynı şema iki yolda:

| Yol | Kimlik | Extra |
|---|---|---|
| **Member apply** | Keycloak User (ad, e-posta, skyNumber) | In-product kısa adım: `Hesabınla kaydol` sonrası veya aynı ekranda. Public Form slot **yok**. sky-app aynı `POST …/applications/me` + extras gövdesi. |
| **Guest apply** | Formdaki kilitli Ad/Soyad/E-posta | Aynı şema, kilitli kimlikten **sonra** Form slot’a enjekte. Contest/CTF slot’u karışmaz. |
| **Walk-in** | Event QR → GUEST Ticket | Extra yok veya sonra “eksik extra” (kapı fail-open). Ayrı karar; afişte plaka sorma. |

Cevaplar **Ticket** üzerinde (ör. `extras` JSON). Roster ve ticket detay etiketli gösterir. Event mail list / Skymail merge sonra bu alanları kullanabilir; SoT hâlâ Ticket.

**Yapılmaz.** Plakayı User kolonuna yazmak. Üyeyi “formu da doldur” diye public slota atmak. Misafir ve üye için iki ayrı extra şeması. Extra’yı skyforms yanıtında bırakıp Ticket’ı boş bırakmak. Kapının extra’sız Ticket’ı reddetmesi (kulüp fail-open; extra operasyonel).

**Sektör.**

| Kim | Nasıl |
|---|---|
| **Eventbrite** | Ticket type + **custom questions** (order form). Hesaplı alıcı da soruları görür; kimlik checkout’tan, extra siparişten. |
| **Pretix** | Ürüne bağlı **Questions**; cevap `orderposition` / answer. Kapı barkodu extra değil. |
| **Luma** | Event **registration questions**; Google login olsa da soru kalır. |
| **Google Forms + Workspace** | Login e-postayı doldurur; diğer sorular formda. Kulüpte bunu Member apply’ın *tek* yolu yapmak CONTEXT’e aykırı. |
| **Hopin / Goldcast** | Profil (şirket, unvan) etkinlik kaydına kopyalanır; etkinlik sorusu ayrı. |

Kulüp farkı: gelir/SKU yok; extra operasyon (otopark, yemek, beden). Şema Event’te, cevap Ticket’ta — Pretix questions’a en yakın.

**Admin’de yapılacak (kod bu dosyada yok).** Event hub: extra şema editörü (alan ekle/sil, zorunlu). Roster: kolon + detay. Member apply API: extras kabul, şema doğrula. Guest Form: şemayı locked identity’den sonra bas. sky-app: aynı extras. Contest Form slot’una dokunma.

**Açık (sıralama sende, ürün kilidi değil).** Walk-in extra’sız mı. Extra değişince kayıtlı Ticket’lar mı güncellenir. `schoolEmail` üniversite extra’sının default’u mu (User’dan öner, Ticket’a kopyala, User’ı ezme).

### 5.4 Skyevents — sonra (ADR 0034, CONTEXT)

`events.yildizskylab.com`. Bu Event-ops döngüsünde site yok. Roster gerçeği superadmin. Microsite admin’leri SoT değil. Public program sayfası yılın ayrı projesi.

### 5.5 Account center — sonra; Account Console — şimdi

Şimdi: `e.` Account Console. sky-app Custom Tabs. Superadmin şifre/oturum **yok** (doğru).

Sonra: branded origin, Account REST. Place değil, waffle değil, Keycloak theme bitiş değil.

### 5.6 Staff scanner / Wallet / Student card — API CANLI, UI SONRA

Cutover §16–17. Superadmin kapı app değil. Wallet issuer hesapları core dışı. Apple VAS / Smart Tap sonra; personel telefonu terminal değil.

### 5.7 Sertifika — API CANLI, admin UI yok

Kural Event’te kaydolur (ADR 0026/0027). Issue/recompute/revoke/PDF core’da. Panel “sertifikaları bas” yok. Mail skymail S2S. Java WIP port yok. Typeform listesi kaynak değil.

---

## 6. Yapılabilir fırsatlar

Öncelik yok. Her madde: **ne / neden / sektörde kim nasıl**. Yusuf sıralar.

### A. Event “afiş paketi” (Event QR)

- **Ne.** Hub’da join Short link + `/v1/go/{alias}/qr?logo=1` PNG indir. Personel yönergesi: “afişi sen okutma”. Aynı PNG motoru **W / 8.5**.
- **Neden.** CONTEXT Event QR; walk-in ayrı faz. Operatör bugün URL sayfasına sapıyor.
- **Sektör.** Luma/Eventbrite public URL QR; Pretix shop QR.

### B. Sertifika operatör yüzeyi

- **Ne.** Kural (var) + liste + issue/recompute/revoke + verify link. Mail Skymail’de kalır.
- **Neden.** API CANLI; kural ölü alan gibi.
- **Sektör.** Coursera/event badge; Pretix plugin. Open Badges CONTEXT’te yok.

### C. Roster → Skymail segment

- **Ne.** Seçili Ticket e-postaları mevcut listeye veya geçici segmente.
- **Neden.** UI seçim hesaplıyor, sync tüm liste.
- **Sektör.** Eventbrite “email selected”; Mailchimp segment. Onay hâlâ Skymail.

### D. Check-in özeti Oturum bazında

- **Ne.** Hub’da Oturum satırı: N check-in / kapasite; ratio önizleme.
- **Neden.** Attendance paydası Oturum; mix “en az bir”.
- **Sektör.** pretixSCAN counts; Hopin session attendance.

### E. Kapı görevlisi Leader’a

- **Ne.** Owner Leader B-roster görsün/düzenlesin; Privileged tek kapı kalksın mı karar.
- **Neden.** ADR 0021 Superadmin atar; UX Privileged-only.
- **Sektör.** Eventbrite door staff; pretix device permissions.

### F. `/qr` kasa iyileştirme (kamera değil)

- **Ne.** Ticket detaydan “bu Oturum’a işaretle”; 409 Türkçe; B-roster uyumu.
- **Neden.** Staff scanner ayrı. UUID kasa kalabilir.
- **Sektör.** Pretix backend check-in vs pretixSCAN.

### G. Team-scoped medya

- **Ne.** `/media?ownerTeam=` veya kütüphaneyi Event picker ile hizala.
- **Neden.** CONTEXT asla başka ekip; global liste sızdırır.
- **Sektör.** Eventbrite org media; Brandfolder.

### H. CMS `cms:access` dürüstlüğü

- **Ne.** News’i Privileged yerine site client rolü; veya kopyada “YK yayını”.
- **Neden.** ADR 0014.
- **Sektör.** WordPress roles; Contentful space membership.

### I. Public team roster (okuma)

- **Ne.** `/teams/{key}` üyeler, `public_leaders` gizlisi.
- **Neden.** Core public; panel Ekipler ince.
- **Sektör.** Luma hosts; about-team.

### J. Leaderboard

- **Ne.** `ranked` Event’te `/v1/competitors/leaderboard/team/{ownerTeam}`.
- **Neden.** Skor tek tek; tablo yok.
- **Sektör.** CTFd / Devpost.

### K. sky-app rewire (bu repo değil)

- **Ne.** Cutover §25: `/v1`, zarfsız, `aud=core`, Member apply, SkyPass, certificates/me, Account Console link.
- **Neden.** Admin SoT, üye hâlâ Java.
- **Sektör.** Eventbrite organizer vs attendee app.

### L. Observability

- **Ne.** problem+json `title` + status operatör dili; mail-list 403 runbook; isteğe audit.
- **Neden.** Keycloak SA hataları “yenilenemedi” oluyor.
- **Sektör.** Datadog; WorkOS audit.

### M. Waitlist / kapasite kapat

- **Ne.** `capacity` enforce + bekleme.
- **Neden.** Alan var, ürün yok. Kulüp “gelsin” kültürüyle çelişebilir (Walk-in fail-open).
- **Sektör.** Eventbrite waitlist; Luma approve-to-join.

### N. iCal / dış takvim

- **Ne.** `/events.ics` veya Oturum ICS.
- **Neden.** Takvim view var, üye takvimi yok.
- **Sektör.** Luma Calendar; Google Calendar appointment.

### O. Forms yanıt kolonu (salt okunur)

- **Ne.** Ticket yanında form id link; gömülü tablo değil.
- **Neden.** SoT Ticket; operatör skyforms’a zıplar.
- **Sektör.** HubSpot form submissions on contact.

### P. Skyevents (ayrı proje)

- **Ne.** Public program. Roster burada kalır.
- **Neden.** ADR 0034.
- **Sektör.** Luma discover; Eventbrite search. **Bu paneli şişirme.**

### Q. Account center (ayrı proje)

- **Ne.** Branded Account REST.
- **Neden.** CONTEXT. **Şimdi `e.`**
- **Sektör.** WorkOS AuthKit; GitHub settings vs org admin.

### R. Stale docs temizliği

- **Ne.** README host/Next; checklist Java; `ldapUser` tip.
- **Neden.** Yeni lider Java duyuru API’sine gider.
- **Sektör.** İç runbook.

### S. Apply extra şeması (üye + misafir)

- **Ne.** Event’te extra soru listesi; Member apply in-product; Guest form aynı şema; cevap Ticket’ta; roster’da görünür. Ayrıntı **5.8**.
- **Neden.** Hesaplı kayıt kimlik getirir, plaka/üniversite getirmez. Public forma üye dökmek ADR 0029’u bozar.
- **Sektör.** Eventbrite custom questions; Pretix Questions; Luma registration questions.

### T. Kullanıcı kartı: profil gör + PATCH

- **Ne.** Üniversite, fakülte, bölüm, telefon, LinkedIn (ve shadow’daki diğer üye alanları) kartta etiketli; Privileged günceller. Şifre hâlâ Account Console.
- **Neden.** JWT `UserDto` alanları var; kart yalnız ad/e-posta/skyNumber/grup/rol. **8.1.**
- **Sektör.** Keycloak Admin user attributes; Google Admin user details (org admin, myaccount değil).

### U. Oturumları Event hub’a göm, `/sessions` nav’ını kaldır

- **Ne.** Konuşma ekle/düzenle/sil yalnız Event gün/oturum bloğunda. Global liste isteğe bağlı “tüm konuşmalar” araması hub’da veya hiç.
- **Neden.** Oturum EventDay tanesi; ayrı sayfa N+1 ve çift yüzey. **8.2.**
- **Sektör.** Eventbrite agenda event içinde; Pretix subevent event içinde. Hopin stage ayrı ürün.

### V. Panelden kişi seçerek Ticket + Check-in

- **Ne.** Roster’da kişi ara (üye picker / misafir e-posta) → Ticket bas veya var olanı seç → Oturum’a “katıldı”. `/qr` UUID kutusunu kişi aramasıyla değiştir veya Event hub’a taşı.
- **Neden.** Operatör UUID yazdırıyor; kapı sky-app’te kalsa bile **masa başı yoklama** lazım. **8.3.**
- **Sektör.** pretixSCAN list search; Eventbrite “check in attendee” isimle; Google Classroom “present”.

### W. Logolu kısa QR + PNG indir

- **Ne.** `/urls` ve Oturum QR drawer: `?logo=1` (ve baskı için `size=1024`); **İndir**. Hub afiş paketi (A) aynı PNG.
- **Neden.** Core logo query var; panel düz kare ve `<object>` — kaydetme yok. **8.5.**
- **Sektör.** Bitly/Dub branded QR download; Java `generateQRCodeWithLogo` (bırakıldı).

### X. Sessiz short-link hit log + panel analiz

- **Ne.** `GET /v1/go/{alias}` 301 kalır; sunucu hit yazar (zaman, IP, UA, Referer, alias). Panel: zaman çizelgesi, unique tahmini, bot filtresi. User id yalnız istekte zaten varsa.
- **Neden.** `clickCount` toplam; kim bastı yok. Tıklayana sayfa/`utm` zorlama yok. **8.6.**
- **Sektör.** Bitly Analytics; Dub events; GA hedef sitede (hop’ta değil).

---

## 7. Riskler

### 7.1 Keycloak service account roller

| Kim | Ne olmazsa | Belirti |
|---|---|---|
| Forms confidential (`forms` / eski `dotnet`) | `resource_access.core` `users:read` + **`aud` core** | Form yaratıcı adı `-`; core 401 |
| Core confidential | `skymail:access`, `lists:read`, `lists:write` + **`aud` skymail** | `POST /v1/events/{id}/mail-list` 500/403 |
| İnsan token (admin) | `aud` core; `url:create` | Event kaydı 401; kısa link 403 |
| CMS yazma | Site client `cms:access` (ADR 0014) | News 403; Privileged varsayımı yanıltır |

Wizard’lar: `scripts/keycloak-forms-users-read.sh`, `scripts/keycloak-skymail-lists.sh`. Token cache: core/forms restart.

`Full scope allowed` OFF ise `resource_access.skymail` hiç binmez.

### 7.2 403’ü ürün sanmak

- Skymail yazma 403 → onay ürünü değil (ADR 0031).
- Sıradan üye kapı 403 → beklenen (ADR 0021).
- Leader identity 403 → nav zaten gizler; deep link StateCard.
- Guest apply’ı üye JWT ile zorlamak 403/yanlış yol.

### 7.3 Env defaults (yanlış host’a konuşmak)

| Değişken | Kod default | Prod bake (`Dockerfile`) | Tuzak |
|---|---|---|---|
| `NEXT_PUBLIC_API_URL` | `http://localhost:8080` | `https://api.yildizskylab.com` | Bake edilmemiş imaj yerel core’a gider |
| `NEXT_PUBLIC_CMS_URL` | `http://localhost:5000` | `https://api.yildizskylab.com/api` | CMS `/v1`’e düşerse 404 (cutover §20) |
| `NEXT_PUBLIC_MAIL_URL` | `https://mail.yildizskylab.com` | aynı | Boş string artık public origin (commit `a3394a4`) |
| `NEXT_PUBLIC_FORMS_ADMIN_URL` | `https://forms.yildizskylab.com/admin` | aynı | Handoff kırılır |
| `NEXT_PUBLIC_CDN_URL` | `https://cdn.yildizskylab.com` | (arg yok, kod default) | Göreli URL prefix’siz kırılır |
| `NEXT_PUBLIC_SHORT_ORIGIN` | `https://skyl.app` | (arg yok) | |
| `OAUTH2_*` | Issuer **sabit** `e.yildizskylab.com` | redirect `admin…/callback` | Client id boş → `config_missing`. Secret yoksa public client |
| `AUTH_COOKIE_SECURE` | `NODE_ENV=production` → true | — | HTTP staging cookie düşer |
| `NEXT_PUBLIC_ADMIN_URL` | `https://admin.yildizskylab.com` | — | Switcher |

OAuth path’ler kodda sabit; Keycloak realm değişmez varsayılır.

### 7.4 Sözleşme sapması

- Java `DataResult` / EventDay check-in / `event-types` / `SKYPASS:` düz metin — bırakıldı. Panel Go `/v1` + Oturum check-in. `backend_datalari/` yanıltır.
- ADR 0022 metninde hâlâ EventDay check-in path; **main 404**. Güncel: cutover §16, `…/sessions/{sessionId}/check-in`.
- `skylapp` rolleri `canUseUrls` / `extractResourceRoles` içinde; kesim sonrası ölü, yanlış pozitif/negatif.
- README Vercel.

### 7.5 Ürün karıştırma (kapıyı kırar)

CONTEXT tablosu. Admin’de özellikle:

- `/qr` ≠ Staff scanner.
- Oturum QR PNG ≠ kapı belgesi.
- Form URL ≠ Ticket.
- Club switcher ≠ Account Console.
- Calendar view ≠ Skyevents.

### 7.6 Performans / ölçek

`sessionsApi.listAll` ve Özet’te çoklu `ticketsApi.listByEvent`. SKYDİYS ölçeğinde acımaz; yıl boyu Event şişince Özet/Oturumlar yavaşlar. Core’da aggregate yok.

### 7.7 İnsan süreci

Forms/Skymail SA mapper’ları “bir kez Keycloak” işi. Unutulursa admin “mail kırık / isimler tire”. Runbook’u panele gömme; wizard duruyor.

---

## 8. Operatör geri bildirimi ve aynı sınıftan boşluklar

Yusuf (2026-09-19). Kod bu bölümde **yazılmaz**; düzeltme sonraki dilim. **Kilit 2026-09-19 Q1–Q8:** CONTEXT + ADR 0035–0037 (`notes/admin-operator-gaps-grill.md`). Kaynak: `UserCardView`, `identityApi` (kullanıcı PATCH yok), `/sessions`, `/qr`, Event hub, `tickets-ui` alanı `Bilet` = UUID, `/urls` QR drawer (`shortQrUrl` logosuz), Oturum QR drawer. Fırsatlar **T–X**.

Üye **Apply extra** (plaka, etkinliğe özel üniversite — 5.8) ile **User shadow profil** (üniversite/bölüm kulüp kaydı) karışmaz. İlki Ticket’ta; ikincisi kullanıcı kartında.

### 8.1 Kullanıcı kartı — profil görünmez, güncellenmez

**Söylenen.** User sayfalarında tam detay yok, güncelleme yok: üniversite adı, bölüm, vb.

**Kod.** Liste `GET /v1/users?q=` → `Person` (ad, e-posta, schoolEmail, skyNumber). Satır subtitle skyNumber veya e-posta. Kart `GET /v1/users/{id}` → grup + inherited/extra roller + logout. `UserCardView` chip: skyNumber, schoolEmail. **Üniversite / fakülte / bölüm / telefon / LinkedIn / öğrenci kartı UID yok.** Create drawer yalnız email+ad+soyad.

Aynı isimler `UserDto`’da var — oturum açmış operatörün **kendi JWT / me** şekli, bakılan üyenin kartı değil. Go User (`cutover` §10.1) `linkedin`, `university`, `faculty`, `department`, `studentCardUid`, `profilePictureUrl` taşır; `PUT/PATCH /v1/users/me` self. Panel `identityApi.updateUser` **yok**. Admin `GET /v1/users/{id}` cutover 10.2’de var; yanıtı `Person`’a kesiliyor. Başka kullanıcıyı Privileged’ın yazması için core’da admin PATCH belki de yok — düzeltme hem tip/UI hem muhtemel API.

**Sektör.** Keycloak Admin → User → Attributes + Credentials ayrı. Google Workspace Admin kullanıcı kartı (org); `myaccount` self-service = Account Console, burası değil. WorkOS Directory user profile.

**Düzeltme yönü (T).** Kartta etiketli profil bloğu (üniversite, fakülte, bölüm, telefon, LinkedIn, skyNumber salt okunur, student card UID ayrı). Privileged günceller; şifre/passkey **yine `e.`**. Student card UID CONTEXT: User kolon, Keycloak attribute değil. Liste satırına bölüm/üniversite subtitle (arama hâlâ shadow `q=` — core genişletmesi ayrı).

### 8.2 Oturumlar ayrı sayfa — Event’e bağlı, nav’da durmamalı

**Söylenen.** Oturumlar için ayrı sayfa gereksiz; tamamen etkinliğe bağlı.

**Kod.** Sidebar Privileged+Leader: `/sessions`. Sayfa tüm Event’lerden `sessionsApi.listAll` (her Event × EventDay). Drawer’da Event ve gün seçmeden konuşma eklenemez — ürün zaten Event’e bağlı, yüzey değil.

Event hub (`/events/[id]`) gün + oturum listesi/ekleme **zaten var**. Çift yüzey: global N+1 liste vs hub.

**Sektör.** Eventbrite/Luma agenda **event manage** içinde. Pretix subevent parent event’te. Hopin “Sessions” sanal sahne kataloğu — kulüp Oturum’u o değil (CONTEXT: Oturum = EventDay üzerindeki konuşma).

**Düzeltme yönü (U).** `/sessions` nav ve sayfa kalkar veya “tüm konuşmalar” salt arama (Event adına tık → hub). Yazma yalnız hub. **Sezonlar** ayrı kalır: Privileged katalog, Event’e bağlanan dönem.

### 8.3 Panelden katılımcı + check-in — UUID kasa

**Söylenen.** Oturuma ve etkinliğe katılımcıları panelden ekleyebilmeliyiz; “şu kişi katıldı” check-in. Şu an UUID yazdırıyor.

**Kod.**

| Yer | Ne basıyor |
|---|---|
| `/qr` “Bilet” | `placeholder="Bilet kimliği"` serbest metin |
| Check-in başarı | `{result.id} · tarih` — **check-in satırı UUID** |
| Son kayıtlar subtitle | `eventName · ticketId · zaman` — **Ticket UUID** |
| Ticket detay “Bilet” | `row.id` UUID |
| Kişi çözülemezse roster / yarışmacı | `ownerId` veya `userId` |

`POST /v1/tickets/{id}/sessions/{sid}/check-in` kişi değil Ticket ister — doğru API; **UI yanlış tane**. Kişi seç → Ticket’ı çöz (`ownerId` veya guest e-posta) → check-in.

Event/Oturum’a **yeni katılımcı** (Ticket bas): roster’da “ekle” yok; Kapı butonu `/qr`’ye atar. Hub “Üye kaydı” yalnız `POST …/applications/me` (operatörün kendisi). Walk-in Event QR parked. Operatör “Ada’yı Gecekodu’na yaz” için panel picker + üye apply (başkası adına) veya guest apply (ad/e-posta) gerekir — ikisi de panelde yok. `PersonPick` yarışmacı ve kapı görevlisi atamada var; kapıda ve roster’da yok.

**Sektör.** pretixSCAN: isim/e-posta ara, tap check-in. Eventbrite Organizer: attendee list → Check in. Google Meet attendance isim listesi. Hiçbiri kasiyere UUID yazdırmaz (barkod kamera ayrı ürün; masa başı arama).

**Düzeltme yönü (V).** Event hub + Oturum satırı: kişi ara (`PersonPick` / roster filtresi) → Check-in. “Katılımcı ekle”: üye picker veya misafir ad/e-posta → Ticket. `/qr` bu akışa iner veya hub’a taşınır; başarıda **ad · oturum · saat**, UUID değil. Ticket detayda UUID kopyalanabilir ikincil, birincil etiket kişi.

Staff scanner (kamera) hâlâ sky-app; bu **masa başı yoklama**, turnike değil.

### 8.4 Aynı sınıftan bulunanlar (Yusuf demedi, aynı hastalık)

UUID / ham id operatöre:

- Kapı görevlisi picker: kişi yoksa subtitle ham `id` (`EventEditor`).
- Ticket detay check-in: oturum başlığı yoksa `sessionId`.
- Yarışmacı satırı: kişi çözülmezse `userId`.
- `/qr` başarı ve “son kayıtlar” (8.3).
- Grup üye listesi doğru (path · e-posta); üniversite yok — 8.1.

Yanlış tane / çift yüzey:

- **`/teams`** public listing → `?ownerTeam=` Event filtresi. Ekip üyeleri Grup kartında.
- **`/competitors`** Event `ranked` ile zayıf; Ticket roster’dan kopuk. CTF ayrı ürün gibi; Event hub’da “yarışma ekle” var, yoklama yok.
- **`/media`** global; Event picker team-scoped. CONTEXT Team media library “başka ekip görme” global sayfada delinir. Satır adı var (UUID değil); sorun kapsam.
- **`/qr` `canCheckInForTeam`** = Privileged veya Owner team Leader. Grant B (`doorStaffIds`) ve `team_door_scan` üye **nav almaz** (sidebar zaten Leader+Privileged) ve filtreye girmez. Masa başı yoklama yalnız lider; atanmış kapı görevlisi panele düşmez — sky-app varsayımı, 8.3 ile çelişir.
- Event hub Oturum satırında **check-in sayısı yok** (fırsat D); yoklama için `/qr` UUID’ye sapılıyor.
- Roster’dan “içeri alındı” yok; durum chip’i API’den, yazma yok.
- Sezonlar ayrı sayfa **meşru**. Oturumlar değil.
- Oturum QR drawer = kısa URL QR: logosuz, indir yok (8.5).
- `clickCount` var, hit yok — “ölçüyoruz” gibi durur, kim/IP yok (8.6).

Gözden kaçan operasyon:

- Ticket iptal / “gelmeyecek”.
- Manuel GUEST e-postayı User’a bağla (aynı kişi hesap açınca çift Ticket).
- Check-in geri al (yanlış Oturum).
- Event hub’da “şu an hangi Oturum” (core `current-session` panelde yok).
- Kullanıcı kartından o kişinin Ticket’ları / yaklaşan Event’leri.
- Başkası adına Member apply (Privileged/Leader, 8.3).

### 8.5 Kısa QR — logo yok, indir yok

**Söylenen.** Link kısaltınca QR düz; ortasında SKY LAB logosu yok. QR’ları indirebilmeliyiz.

**Kod.** `shortQrUrl(alias)` = `{CORE}/v1/go/{alias}/qr` — **query yok**. Drawer `<object data=… className="h-48 w-48">`. İndir / `download` / `Content-Disposition` yok. Event hub Oturum QR aynı: `sessionQrUrl` logosuz, indir yok.

Cutover §19: `?logo=1` kulüp işareti; `?size=` 64–1024, default 256. Java `GET /api/qrCodes/generateQRCodeWithLogo` checklist’te vardı; Go’da arbitrary `data=` yok.

**Sektör.** Bitly/Dub: logo ortada, PNG/SVG indir. Eventbrite event QR indir. Baskı 256px’de zayıf; 1024 iste.

**Düzeltme yönü (W).** Panel her kısa QR’ı `?logo=1&size=1024` (veya core default logo). Drawer’da **İndir** (`skylapp-{alias}.png`). Oturum QR aynı kulüp işareti (afiş/Event QR değil). Hub Event QR (A) bu PNG’yi paylaşır.

### 8.6 Tıklama logu — sessiz hop, panelde analiz

**Söylenen.** Linke tıklayanların logu: hangi IP, hangi hesap login olup bastı, kim; analiz. Kişiler o sırada farketmesin.

**Kod.** `ShortUrl.clickCount` + “En çok tıklanan” bar. Hit listesi / IP / UA / user **yok**. `urlsApi` yalnız CRUD. Cutover: `GET /v1/go/{alias}` 301; `…/qr` tıklama saymaz.

**Sessiz ne demek.** 301 aynı kalır: interstitial yok, “izleniyorsun” sayfası yok, hedefe görünür `utm` zorunlu değil, hop’ta SSO yok. Log **sunucuda** (`X-Forwarded-For`, UA, Referer, zaman, alias). Tıklayan Bitly’de olduğu gibi hop’u hissetmez.

**Hesap bağlama (kilit).** CONTEXT/ADR 0020: `skyl.app` logged-in SPA değil. Admin cookie `admin.yildizskylab.com`, IdP `e.yildizskylab.com` — hop bunları **göndermez**. İstekte User yoksa satır anonim (IP+UA). Gizli Keycloak round-trip hop’u yavaşlatır ve SPA yapar — **yapma**. User id yalnız ileride skyl.app’te first-party oturum varsa (bugün yok). Hedefte SKY LAB login’i shortener loguna geri yazılmaz.

**Analiz (panel, Privileged / `url:moderator`).** Alias detay: hit tablosu (zaman, IP, UA, Referer, bot?), günlük/saatlik, unique tahmini (IP+UA hash). Slack/iMessage unfurl sayacı şişirir — bot filtresi (Dub). IP kişisel veri; hop UI’siz, saklama TTL + yalnız moderatör.

**Sektör.** Bitly Analytics / Dub events: 301 + org dashboard. GA kullanıcı kimliği **hedef sitede**, kısaltıcıda değil.

**Düzeltme yönü (X).** Core: 301 öncesi hit insert (QR GET ayrı, sayaç değil). Panel `/urls` satır → analiz. Public hop değişmez.

### 8.7 Yapma (bu geri bildirimle karışmasın)

- Superadmin’i Staff scanner (kamera) yapmak.
- Check-in’i EventDay tanesine indirmek (retracted).
- Kullanıcı şifresini kartta sıfırlamak.
- Oturumu EventType gibi global kimlik yapmak.
- Üniversite/bölümü yalnız Apply extra yapmak (kulüp profili User shadow’da kalır; extra etkinliğe özeldir).
- `skyl.app`’i login SPA / waffle hesabı yapmak (ADR 0020).
- Hop’ta “izleniyorsun” sayfası, çerez banner’ı veya gizli SSO round-trip.
- Arbitrary `data=` QR (phishing).

---

## Ek A — `(authorized)` envanter

| Rota | Dosya | Nav | Olgunluk |
|---|---|---|---|
| `/dashboard` | `dashboard/page.tsx` | Hep (yetkili) | Orta |
| `/users` | `users/page.tsx` | Privileged | Olgun (arama), İnce (profil) |
| `/users/[id]` | `users/[id]/page.tsx` | — | Olgun (grup/rol), İnce (üyelik kartı) |
| `/groups` | `groups/page.tsx` | Privileged | Olgun |
| `/groups/[id]` | `groups/[id]/page.tsx` | — | Olgun |
| `/announcements` | `announcements/page.tsx` | Privileged | Olgun |
| `/announcements/new` | `announcements/new/page.tsx` | — | Olgun |
| `/announcements/[id]/edit` | `announcements/[id]/edit/page.tsx` | — | Olgun |
| `/urls` | `urls/page.tsx` | Privileged veya `url:*` | Olgun (CRUD), İnce (logo QR / hit log) |
| `/events` | `events/page.tsx` | Privileged+Leader | Olgun |
| `/events/new` | `events/new/page.tsx` | — | Olgun |
| `/events/[id]` | `events/[id]/page.tsx` | — | Olgun/İnce karışık |
| `/events/[id]/edit` | redirect → hub | — | Yönlendirme |
| `/events/[id]/days` | redirect → hub | — | Yönlendirme |
| `/events/[id]/tickets/[ticketId]` | ticket page | — | Olgun |
| `/seasons` | `seasons/page.tsx` | Privileged | Olgun |
| `/seasons/new` | redirect → `/seasons` | — | Yönlendirme |
| `/seasons/[id]/edit` | redirect → `/seasons` | — | Yönlendirme |
| `/sessions` | `sessions/page.tsx` | Privileged+Leader | Orta — **yanlış yer** (8.2) |
| `/sessions/new` | redirect → `/sessions` | — | Yönlendirme |
| `/sessions/[id]/edit` | redirect | — | Yönlendirme |
| `/sessions/[id]/delete` | redirect | — | Yönlendirme |
| `/teams` | `teams/page.tsx` | Privileged | İnce |
| `/qr` | `qr/page.tsx` | Privileged+Leader | İnce — UUID kasa (8.3) |
| `/competitors` | `competitors/page.tsx` | Privileged+Leader | Orta |
| `/competitors/new` | form page | — | Orta |
| `/competitors/[id]/edit` | form page | — | Orta |
| `/media` | `media/page.tsx` | Privileged+Leader | Orta |

Login `(authorized)` değil: `/login`, `/api/auth/*`. Kök `/` → dashboard veya login.

---

## Ek B — Sözlük (CONTEXT, panelde geçtiği yer)

Kullanırken Java/LDAP diline kayma.

- **User / Member / Group / Source group / Privileged / Leader / Owner team / Promote**
- **Account Console** (`e.`) ≠ **Account center** (sonra) ≠ superadmin
- **Event / EventDay / Oturum** — yoklama tane = Oturum
- **Ticket** REGISTERED | GUEST — kapı kimliği
- **Form slot / Event form / Guest apply / Member apply / Apply extra / Walk-in**
- **Event QR / Oturum QR / SkyPass QR / Ticket QR** — kim okutur, kapı belgesi mi
- **Check-in / Queued check-in / Door staff / Team door scan**
- **Attendance rule / Certificate**
- **Event mail list / Mail onayı**
- **Short link / Participant roster / Team media library / Skyevents**
- **Public listing / Public leaders / News / cms:access / Site client**

---

## Ek C — Bilinçli “yapma” listesi (yıl planını korur)

1. Superadmin içine şifre, oturum, passkey, ikinci IdP.
2. Skyforms editörünü iframe.
3. SMTP / Mail onayı kuyruğu core veya admin’de.
4. Typeform / e-posta sayımı yoklama.
5. Event QR veya Oturum QR’ı personel kamerasına.
6. Superadmin’i Staff scanner yapmak.
7. Skyevents’i bu Event-ops PR’ına gizlemek.
8. Account center’ı waffle’a koymak.
9. Ticket’ı form yanıtıyla değiştirmek.
10. EventType tablosunu / `GENEL` sahte ekibini geri getirmek.
11. Plaka/üniversiteyi User global profiline yazmak veya üyeyi extra için public Form slot’a atmak.
12. `skyl.app`’i logged-in SPA yapmak veya hop’ta IdP gizlice yoklamak.
13. Tıklayana “izleniyorsun” interstitial / `data=` QR.

---

*Üretim tarihi: 2026-09-19. Apply extra 5.8; operatör §8 (T–X) aynı gün. Q1–Q8 kilit 2026-09-19 (CONTEXT, ADR 0035–0037). Panel worktree: `superadmin-event-media`. Asıl dosya: `sky_lab_genel/docs/admin-panel-gap-report.md`; kopya worktree `docs/`.*
