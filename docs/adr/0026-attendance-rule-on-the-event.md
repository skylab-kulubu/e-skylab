# Certificate eligibility is a per-event rule on Oturum check-ins

Club yoklama today is a projector Typeform plus a hand count of emails per talk. EventDay stays a calendar day; Oturum (Session) is a talk on that day — ARTLAB can be one day with five talks or two days with five plus three. Go already has schedule Session under EventDay (`sessions` in `core-backend/db/migrations/20260916180000_create_schedule.up.sql`); Check-in binds to that row rather than a second talk entity. Eligibility is a field on the Event (`none` | `once` | `ratio` of Oturum check-ins, with a decimal the organizers set). A Certificate is a stored row, public verify URL, PDF, and skymail; templates key off Event / Owner team, not EventType. The earlier decision to issue immediately after a settled Check-in is superseded by Attendance finalization and durable issuance jobs in ADR 0039. The 2026-09-17 lock that Yusuf’s “oturum” was EventDay is **retracted**. Rejected: email tallies; counting EventDays; a club-wide 70/80 or a magical 0.75 default; porting the Java WIP; the Java WIP’s manual recipient list as the source of truth. Edge locks (staff bind, ratio denominator, zero-Oturum events): ADR 0027.

## Ek: "N oturumdan en az M", sayılan ve zorunlu oturumlar (2026-11-24)

Karar (Yusuf, 2026-11-23). Kural tamamen özelleştirilir: hangi oturumların sayıldığı, hangilerinin zorunlu olduğu ve eşik seçilir.

- **Yeni kural türü `count`.** Etkinliğin sayılan oturumlarından (N) en az M'sine Check-in. M tam sayıdır; panel yanında yüzdeyi gösterir: "8 oturumdan en az 6 (%75)". Ondalık oran girilmez, böylece 0,67 ile 0,66 arasındaki yuvarlama tuzağı kalkar.
- **Sayılan oturum** (Counted Oturum). Her Oturum'un "Sayılır" işareti vardır; eşik yalnız sayılanlara uygulanır. Networking ya da ara gibi oturumlar sayımdan çıkarılabilir. Var olan oturumlar sayılır; yeni `NETWORKING` oturumu varsayılan olarak sayılmaz (Yusuf, S1).
- **Zorunlu oturum** (Required Oturum). "Zorunlu" işaretli oturumlara Check-in şarttır: eşiği tutturan ama zorunlu bir oturumu kaçıran sertifika almaz. Zorunlu oturum her zaman sayılır (veritabanında CHECK).
- **Varsayılan %75.** M girilmemişse M = ⌈3N/4⌉, tam sayıyla `(3N + 3) / 4` (N=8 → 6, N=4 → 3, N=3 → 3). **Bu, yukarıdaki kararın "sihirli 0,75 varsayılanı yok" reddini bilerek değiştirir.** Gerekçe Yusuf'un 2026-11-23 kararıdır ("varsayılan genelde %75"). Varsayılan etkinlik başına bir başlangıç değeridir, kilit değildir: düzenleyen M'yi değiştirir, kural `none` iken sertifika yoktur. Reddedilen "kulüp geneli 70/80" (herkese dayatılan tek eşik) reddedilmiş kalır.
- **`ratio` eski tür olarak kalır.** Var olan `ratio` etkinlikleri bugünkü hesapla değerlendirilir; yeni yazımda `ratio` kabul edilmez (400). Panel böyle bir etkinliği açınca `count`'a çevirmeyi önerir.
- Payda, iptal ve sıfır oturum ayrıntıları ADR-0027'nin ekinde.
- Uygulama: core-backend #399 (kural modeli), #401 (uygunluk); panel core-frontend #163.

## Ek: oturumsuz etkinlikte alana giriş katılımdır (2026-11-25)

Karar (Yusuf, 2026-11-25): canlı oturumu olmayan etkinlikte etkinliğin kendisi tek sayılan birimdir (N = 1) ve Venue entry katılım sayılır; "alana giriş sertifikada sayılmaz" kuralı (kapı postaları K3) yalnız oturumlu etkinlik için geçerlidir. Bütün oturumlar iptal edilirse kapı girişleri ölçüt olur. Uygulama: core-backend #422.

### Endüstri uygulamasıyla karşılaştırma

Kaynak: `sky_lab_genel/notes/sertifika-oturum/01-arastirma.md` §3 (ürünlerin kendi belgeleri).

**Uyanlar:**
- **Moodle kurs tamamlama.** Seçili etkinliklerin "hepsi" ölçütü bizim zorunlu oturumumuza denk düşer; yüzde eşiği Moodle'da eklentiyle gelir (availability_courseprogress), bizde `count` eşiğidir.
- **Accredible.** Kurala bağlı verme ile elle verme yan yanadır; bizde de öyle.

**Sapmalar:**
1. **Accelevents** seçili oturumların hepsini zorunlu sayar, "N'den M" seçeneği yoktur. Bizde eşik ve zorunlu oturum birlikte vardır.
2. **Cvent**'te "6 oturumdan 5'i" için otomatik sertifika yoktur; katılım raporu dökülüp uygunlara elle posta atılır. Bizde kural otomatik uygulanır.
3. **Süre yok.** Webex Events ve PheedLoop süreyi check-out ya da çevrim içi izlemeyle ölçer; biz yalnız tek Check-in sayarız.
4. **Eşik sayıyla girilir,** yüzdeyle değil; yüzde yalnız gösterilir.
