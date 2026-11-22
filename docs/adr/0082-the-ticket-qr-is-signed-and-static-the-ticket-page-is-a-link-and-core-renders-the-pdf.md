---
status: accepted
---

# Bilet QR'ı imzalı ve statiktir; bilet sayfası girişsiz bir bağlantıdır; PDF bileti core üretir ve SkyMail ek olarak gönderir; etkinlik iki kapı düzeniyle işler, yoklama ekrandaki dönen QR'la alınır

"Biletin hazır" postası (`event.ticket-created`, core `docs/ticket-created-notification.md`) bugün yalnız etkinliğin adını, tarihini ve yerini taşıyor. Şablonda QR görseli, bilet kodu ve etkinlik bağlantısı için koşullu bloklar hazır, ama core onları dolduramıyor: biletin QR'ı da kodu da yok. Kapıda üye SkyPass QR'ını gösteriyor. Misafir kapıdaki ekranın QR'ını kendi telefonuyla okutup e-postasını yazıyor, ya da masada adıyla bulunuyor. CONTEXT "Ticket QR"ı tanımlıyor (görevli tarayıcısı onu SkyPass QR'la aynı kamerada tanır; imzalıysa cihazda doğrulama ve Queued check-in), ama nasıl üretildiğini söylemiyor ve onu "per-User" diye anlatıyor; misafirin User'ı yok. ADR-0022 de "Ticket QR if signed" diyerek kararı açık bırakıyor.

Yusuf'un isteği (2026-11-22): bilet, Biletix ve Obilet'teki gibi posta ekinde PDF olarak gelsin; ayrıca QR'ı gösteren bir bilet sayfası açılsın. Bilet, Forms'taki form teması gibi etkinliğe göre temalansın.

Aynı gün ikinci istek: "Her etkinlik oturum başına kapıdan giriş gibi işlemiyor." ARTLAB'de herkes içeri girerken biletini bir kez okutuyor, sonra aynı alanda oturumlar arasında dolaşıyor; oturum yoklaması için QR OBS ile projeksiyona veriliyor. Bugün CONTEXT ve core oturum başına kapıyı varsayıyor. Görevlinin okutması her zaman oturuma Check-in yazıyor. Oturum QR'ı statik bir adres: fotoğrafı evden de yoklama yazdırıyor. Projeksiyondaki kapı QR'ı da panelde giriş yapmış bir görevli istiyor; OBS'de bu pratik değil.

Karar (Yusuf, 2026-11-22; 1–16. soruların hepsinde önerilen şık, 5. soruda ek olarak belge görünümü; model B'de girişte okutulmamış kişinin yoklaması reddedilmez):

1. **Ticket QR biletin imzalı, statik kodudur.**
   - Her biletin (üye ve misafir) bir kodu vardır: ES256 JWT, `kid=tk-e1`, yükte `sub` (bilet), `evt` (etkinlik), `qv` (QR sürümü) ve `exp`.
   - `exp` etkinliğin bitişi + 1 gündür. Bitiş ADR-0066'daki gibidir (bitiş tarihi, yoksa başlangıç + 1 gün). Tarihsiz etkinlik bitmez; onun biletinde `exp` biletin oluşturulmasından 1 yıldır.
   - Ad, e-posta ya da telefon taşımaz.
   - Posta, PDF, bilet sayfası ve sky-app aynı kodu gösterir; kod dönmez. `qv` ve etkinliğin tarihleri değişmedikçe kod değişmez.
   - İmza anahtarı SkyPass anahtarından HKDF ile türetilir; yeni sır ya da OpenBao yolu yoktur. Açık anahtar SkyPass'ınkiyle aynı JWKS'te yayımlanır.
   - Kapıda SkyPass QR'ıyla aynı kural geçerlidir (ADR-0022): kimlik doğrulaması cihazda, giriş çevrimiçi, core yokken Queued check-in.
   - Üyenin postasında da bilet QR'ı vardır; üyenin SkyPass'ı kapıda geçerli kalır. İki yol aynı bilet × oturum girişini yazar, ikincisi "zaten girdi" alır.
2. **İletilen kod kabul edilen bir risktir.**
   - Oturum başına ilk okutma kazanır ve tarayıcı girenin adını gösterir.
   - Panel "Bağlantıyı yenile" ile `qv`'yi artırır, eski kod çevrimiçi `410 ticket_qr_superseded` alır.
   - Dönen kod (SafeTix) yoktur: PDF'e ve baskıya konamaz, kulüp kapısı fail-open'dır, etkinlikler ücretsizdir.
   - Wallet bileti gelirse orada platformun dönen kodu kullanılır (ADR-0023 kalıbı). Wallet bileti sonraya kalır.
3. **Bilet kodu masada okunan kısa koddur.**
   - 8 karakter Crockford Base32, `XXXX-XXXX` biçiminde.
   - Masa araması onu adın ve e-postanın yanında tanır.
   - Kimlik bilgisi değildir: tek başına kapıyı açmaz ve kendi kendine giriş yazmaz.
4. **Bilet sayfası kulüp sitesindedir ve girişsizdir.**
   - Adres: `yildizskylab.com/bilet/{erişim anahtarı}`. Anahtar 128 bitlik rastgele bir değerdir; adres `TICKET_PAGE_URL` ile taşınabilir.
   - Misafirin hesabı yoktur (ADR-0029), bu yüzden bağlantının kendisi yetkidir. Kalıp ADR-0040 (sertifika) ve kapı sayfasıyla aynı: arayüz sitede, minimal herkese açık uç core'da, `noindex` ve `no-referrer`.
   - Sayfa ad soyad, etkinlik, QR, kod ve PDF indirme gösterir; e-posta ve telefon göstermez.
   - Etkinlik bittikten 7 gün sonra sayfa ve uçları kişisel veri vermeden `410` döner. Taslak etkinliğin bileti `404` alır (ADR-0066).
   - Etkinlik iptal edilince sayfa "iptal edildi" der ve QR'ı gizler; iptal geri alınınca yeniden açılır (ADR-0066 eki).
   - Üye aynı bileti sky-app'te `/v1/tickets/me` ile görür.
   - Panelde katılımcı satırında "Bileti yeniden gönder" ve "Bağlantıyı yenile" vardır. Misafirin kendi "biletimi tekrar gönder" sayfası sonraya kalır.
5. **PDF bileti core üretir, saklamaz.**
   - Sertifikanın Gotenberg ve `internal/qr` kalıbıyla, isteğe göre üretilir.
   - İçerik: etkinlik, tarih, yer, düzenleyen, ad soyad, QR ve kod. E-posta, telefon, skyNumber ve bilet türü yazmaz.
   - Görünüm kurumsal ve resmî bir belge gibidir (devlet biletleri ve resmî belgeler örnek alınır). Aynı görünüm bilet sayfasında da kullanılır.
   - Etiketli PDF; Türkçe dil; QR için alt metin, kod gerçek metin.
   - SkyMail bileti bilmez (ADR-0075 karar 4); PDF'in baytları core'dan gelir.
6. **İletişim servisi e-postada ek taşır.**
   - `POST /v1/mail_tasks/single` ve tek alıcılı `POST /v1/notifications` isteğe bağlı `attachments` alır: PDF ya da PNG, toplam 512 KB, en çok 2.
   - Ek yalnız e-posta kanalına gider ve yalnız gönderilene kadar saklanır; maskeleme ve hesap silme adımına dahildir.
   - Toplu gönderim ek almaz.
   - SkyMail'in core'dan dosya çekmesi yoktur (ADR-0075 karar 3).
   - Ek desteği gelene kadar PDF yalnız bilet sayfasından indirilir; gelince bilet postasına eklenir.
7. **Postada QR görseli, bağlantı, kod ve ek birlikte bulunur.**
   - Görsel uzak bir PNG'dir; klasik Outlook gibi görseli engelleyen istemcide kod, "Biletini aç" düğmesi ve ek işi görür.
   - Base64 ve CID görsel kullanılmaz.
   - `TicketUrl` ve `TicketCode` core yayınlandıktan sonra core'un sözleşmesindeki zorunlu değişkenlerdir (Required variable); o zamana kadar şablonda koşullu kalırlar.

8. **Bilet, etkinliğe göre temalanır.**
   - Varsayılan tema "Kurumsal"dır (Yusuf, 11. soru). Resmî belge görünümündedir: güvenlik deseni (guilloche, bilet kodundan tohumlanır), seri no olarak bilet kodu, mühür olarak SKY LAB ve ekip logosu, koçan.
   - Bunlar süstür; asıl kanıt QR'daki imzadır. Metinlerde "güvenlik özelliği" denmez.
   - Etkinlik iki şey seçer: `ticketBrand` ve `ticketAccentColor`.
     - `ticketBrand`, Forms'un `brand` anahtarıyla aynı sözlüğü ve kuralı kullanır (`^[a-z0-9-]{1,32}$`; `null` = Kurumsal). Bilinmeyen anahtar Kurumsal'a döner.
     - Vurgu rengi boşsa kapağın ilk rengi, o da yoksa temanın rengi kullanılır.
   - Logo ekibin logosudur; ayrı logo alanı yoktur. Kapak görseli yalnız bilet sayfasında görünür, PDF'e girmez.
   - Temanın tanımı core'da küçük bir katalogda durur, çünkü PDF'i core çizer; site aynı değişkenleri uygular.
   - Core Forms'un formundaki `brand`'i okumaz (ADR-0075). Panel formun herkese açık bilgisinden "bilete de uygula" önerisi gösterebilir.
   - Sertifikanın serbest yerleşimli şablonu bilete uygulanmaz: QR'ın yeri ve boyutu sabit kalmalı.
   - Panelde etkinliğin İçerik sekmesinde "Bilet görünümü" kartı ve PDF önizlemesi vardır; etkinliği düzenleyebilen herkes değiştirir.
9. **Etkinlik iki kapı düzeniyle işler** (Yusuf, 12. soru). Etkinlik ayarı `entryMode` iki değer alır:
   - `per_session` (varsayılan, bugünkü davranış): görevlinin okutması o oturuma Check-in yazar.
   - `venue`: görevlinin okutması o güne **Alana giriş** yazar. Yanıt yine 201'dir, gövdede `kind: "entry"` vardır; aynı gün ikinci okutma 409 alır.
   - Alana giriş, bilet × EventDay başına bir kayıttır ve kaynağını taşır (`scan`, `desk`, `attendance`). Yoklama değildir, sertifikada ve geri bildirim kitlesinde sayılmaz.
   - Her oturum Check-in'i, eksikse o günün Alana giriş kaydını da yazar (kaynak `attendance`). Girişte okutulmamış birinin yoklaması reddedilmez (Yusuf, model B kararı). Bu kural iki düzende de geçerlidir.
   - Masa iki düzende de oturuma Check-in yazar; `venue` düzeninde ayrıca "Alana giriş" düğmesi vardır.
   - Ekrandaki yoklama QR'ı iki düzende de açıktır: `per_session`'da yedek, `venue`'de asıl yoldur.
   - Yoklama QR'ı bilet yazmaz. Biletsiz kişi `/kapi` sayfasında "Bu etkinlikte biletin yok" ve başvuru açıksa kayıt bağlantısını görür (Yusuf, 14. soru). Anında bilet Walk-in'in (Event QR) kararıdır, bu ADR'ın değil.
10. **Oturum QR'ı döner ve imzalıdır.** Tek yoklama QR'ı bugünkü kapı QR'ının genellemesidir: aynı jeton ve anahtar, 60 saniye ömür, 15 saniye yenileme, oturum penceresi, aynı `/kapi/{oturum}?dq=…` adresi. Hem üyeye hem misafire hizmet eder:
    - Misafir telefon kamerasıyla `/kapi` sayfasından bilet anahtarı ya da e-postayla girer.
    - Üye aynı sayfadan bilet anahtarı ya da hesap e-postasıyla girer. Sitede Keycloak girişi yoktur (Yusuf, 15. soru; ADR-0064).
    - Üye sky-app "QR Okut" ile `check-in/me` + jeton kullanabilir.
    - Projeksiyondaki jetonun kullanım sınırı kapıdakinden ayrıdır (`ATTENDANCE_QR_MAX_USES`).
    - Statik oturum QR'ı `SESSION_QR_MODE=qr` ile kapanır; jetonu okuyan sky-app sürümü mağazaya çıkınca geçilir (Yusuf, 13. soru). Böylece evden yoklama açığı biter. Basılı statik QR o andan sonra yoklama yazmaz.
    - Kod 15 saniyede bir dönse de salondan anlık paylaşım kısa süre işler; bu kabul edilen bir risktir. Konum ya da cihaz bağlama yoktur.
11. **Yoklama ekranı bağlantısı görevli girişi istemez** (Yusuf, 16. soru: ekran sitede).
    - Kapı QR'ını basabilen biri, oturuma sabit ya da saate göre o anki oturumu bulan (ADR-0027) bir bağlantı açar. Bağlantı etkinliğin bitişi + 12 saatte ölür ve panelden iptal edilebilir.
    - Bağlantının anahtarı 128 bittir, yalnız özeti saklanır ve bir kez gösterilir.
    - Sitedeki ekran sayfası (`/ekran/{anahtar}`, OBS Browser Source ya da projeksiyon) bu anahtarla güncel QR'ı çeker. QR beyaz zeminde, siyah modüllüdür; tema QR'a uygulanmaz.
    - Bağlantıyı açan herkes QR'ı görür, bu yüzden bağlantı canlı yayın sahnesine konmaz; panel ve sayfa bunu söyler.
12. **Kapıda misafir bilet anahtarıyla da eşleşir.** `/kapi` aynı cihazda bilet anahtarını ya da e-postayı hatırlar ve "Ad S. olarak giriş yap" düğmesi gösterir; kapı jetonu yine şarttır, anahtar tek başına giriş yazmaz. Anahtar yolu üye ve misafir bütün biletlere açıktır.

Kaynaklar:
- **Yusuf'un:** istekler (PDF ek, bilet sayfası, etkinliğe göre tema, iki kapı düzeni) ve 1–16. soruların cevabı (2026-11-22). 5. soruda ad soyad yazar, belge kurumsal ve resmî görünür. Model B'de girişte okutulmamış kişinin yoklaması reddedilmez.
- **Tasarım önerisi:** 1–12'nin ayrıntıları (hub'daki `.scratch/bilet-qr-ve-pdf/SPEC.md`, §8 tema, §9–10 kapı ve yoklama).

## Consequences

- **core.** Bilette `access_key`, `code` ve `qr_version` alanları. Bilet imzalayıcısı ve JWKS'te ikinci anahtar. Kapı ucunda `kid`'e göre ayırma ve kanonik `check-in/scan` adı (`/skypass` takma ad olarak kalır, yayındaki sky-app değişmeden çalışır). `/v1/public/tickets/{key}` (JSON, `qr.png`, `pdf`). `/v1/tickets/me`'de `code`, `ticketUrl`, `qrToken`. Yeniden gönder ve yenile uçları. `TICKET_PAGE_URL`, `TICKET_PAGE_GRACE`, `TICKET_PDF_ATTACHMENT`.
- **İletişim servisi (skymail-backend).** Ek alanı, `mail_attachments` tablosu, SMTP ve Graph eki, maskeleme ve silme kapsamı.
- **Şablon (skymail-frontend).** "Biletini aç" düğmesi, QR'lı metin, `TicketUrl` hassas değişken.
- **core (tema ve kapı).** `events.ticket_brand`, `events.ticket_accent_color`, `events.entry_mode`; tema kataloğu ve `ticket-preview`; `venue_entries`, `attendance_displays`; `check-in/me` jeton alır; misafir girişi bilet anahtarı da alır; `SESSION_QR_MODE`, `ATTENDANCE_QR_MAX_USES`, `ATTENDANCE_DISPLAY_URL`.
- **Site.** `/bilet/[key]`, PDF ile aynı belge görünümünde ve etkinliğin temasıyla. `/ekran/[key]`. `/kapi` "Oturum yoklaması" olur, bilet anahtarını ve e-postayı hatırlar.
- **Panel.** Katılımcı satırında kod, yeniden gönder, yenile; masada kodla arama. "Bilet görünümü" kartı, kapı düzeni ayarı, yoklama ekranı bağlantıları, "kapıda okutulmadan girdi" sayısı; statik "Oturum QR indir" `qr` kipinde yoklama ekranı bağlantısına döner.
- **sky-app (Mobile Lab).** Bugünkü tarayıcı Ticket QR'ı değişmeden okur. Sözleşme: metinler, 410, JWKS ile cihazda doğrulama, "etkinliklerim"de QR; "QR Okut" `/kapi/{id}?dq=` biçimini tanır; tarayıcı `kind: entry` yanıtını alır.
- **Sertifika.** Attendance rule yalnız oturum Check-in'lerini sayar. `venue` düzeninde yalnız kapıdan girip hiçbir yoklamaya katılmayan kişi `once` ile de sertifika almaz; panelin kural metni bunu söyler.
- **Etkinlik kopyası (ADR-0066).** `ticketBrand`, `ticketAccentColor` ve `entryMode` yapıdır, kopyaya gelir.
- **Saklama (ADR-0062).** Yeni bir kişisel veri kategorisi yok. Anahtar ve kod biletle yaşar ve silinir; PDF saklanmaz; ek gönderilince silinir.
- **Walk-in.** Walk-in biletinin de kodu ve anahtarı olur, ama bilet postası gitmez (ADR-0032).
- **CONTEXT.md'de değişenler.** Ticket QR "per-Ticket" olur. Oturum QR dönen ve imzalı olur. Staff scanner, Check-in, Event QR, Walk-in, Event copy ve Desk check-in buna göre düzeltilir. Yeni terimler: Ticket page (Bilet sayfası), Ticket code (Bilet kodu), Ticket theme (Bilet teması), Mail attachment (Posta eki), Entry mode (Kapı düzeni), Venue entry (Alana giriş), Attendance display link (Yoklama ekranı bağlantısı). Required variable örneği aynen kalır.

## Diğer ADR'lerle ilişki

- **ADR-0022.** Çelişki yok; açık bıraktığı "Ticket QR if signed" kapanır: Ticket QR imzalıdır (`kid=tk-e1`, aynı JWKS), bu yüzden cihazda doğrulanır ve core yokken Queued check-in olur. Panelden yenilenmiş eski bir kod çevrimdışı kapıda geçebilir; bu, ADR-0022'nin fail-open kuralının kabul edilen sonucudur. ADR-0022'deki `POST /v1/tickets/:ticketId/event-days/:eventDayId/check-in` adresi eskidir (giriş artık oturum başınadır); Ticket QR girişi oturumun kapı ucuna gider. ADR-0022'ye bu yönde bir ek yazıldı.
- **ADR-0032.** Kapı kimliği bilettir ve Ticket QR biletin kodudur; afiş QR'ı (Event QR) kapı kimliği değildir. Walk-in bilet postası almaz. Bir yer daralır: ADR-0032 "Check-in is still Oturum QR or staff SkyPass / Ticket QR" diyor. `venue` düzeninde görevlinin okutması Check-in değil Alana giriş yazar; Check-in orada yalnız Oturum QR'ı ve masayla gelir. `per_session` düzeninde ADR-0032 aynen geçerlidir. Yoklama QR'ı Walk-in değildir, bilet yazmaz.
- **ADR-0066.** Çelişki yok. Kopyanın "gelir" listesine `ticketBrand`, `ticketAccentColor` ve `entryMode` eklenir. Taslak etkinliğin bileti herkese açık uçlarda `404`'tür. İptal edilen etkinlikte sayfa QR'ı gizler, iptal geri alınınca açılır; bilet geçerli kalır, kapı zaten reddeder. "Bitti" ADR-0066'daki gibi tarihten türer; tarihsiz etkinlik bitmediği için onun bilet sayfası 7 günlük kapanışa girmez.
- **ADR-0069.** Çelişki yok. Geri bildirim davetinin kişiye özel kodu da 128 bit rastgeledir ve düz saklanır; bilet sayfasının erişim anahtarı aynı kalıptadır. Fark: davet satırı 90 günde silinir, erişim anahtarı biletle yaşar ve bilet silinince gider. Geri bildirim kitlesi Check-in'den gelir; Alana giriş onu genişletmez.
- **ADR-0027 ve ADR-0039.** Çelişki yok. Saatle bulunan oturum yoklama ekranında da kullanılır; çakışmada ekran QR göstermez ve oturuma sabit bağlantı ister. Sertifika yine yalnız oturum Check-in'lerinden gelir.

## Endüstri uygulamasıyla karşılaştırma

İncelenenler: Eventbrite, Biletix, Obilet, Passo, Ticketmaster SafeTix, Apple Wallet ve Google Wallet etkinlik bileti, AB Dijital COVID Sertifikası; yoklama için Slido, Whova, Cvent, Webex Events, Poll Everywhere.

**Uyanlar:**
- **Bağlantı ya da postayla PDF + QR.** Biletix onay postası ya da SMS bağlantısıyla PDF ve QR veriyor; en yakın olduğumuz kalıp bu.
- **Bilet başına statik QR, kapıda ilk okutma kazanır.** Eventbrite'ın varsayılanı.
- **İmzalı QR'ın yayımlanan anahtarlarla çevrimdışı doğrulanması.** AB Dijital COVID Sertifikası (COSE_Sign1, ES256).
- **Görseli engelleyen istemci için düz metin kod.** Erişilebilirlik rehberleri QR'ın yanında okunur metin öneriyor; Google Wallet'ın `alternateText`'i de bu iş için.
- **Wallet'ta dönen kod.** Google Wallet `rotatingBarcode`; Wallet bileti gelince biz de onu kullanırız.
- **Ekran için girişsiz bağlantı.** Slido sunucu ekranı için girişsiz bir "present mode" bağlantısı veriyor ve OBS Browser Source'a konuyor.
- **Yoklamada kısa ömürlü dönen kod.** Poll Everywhere 20 saniyelik dönen kod kullanıyor; asıl savunma kısa geçerlilik.
- **Alan girişi ile oturum yoklamasının ayrı olması.** Cvent ve Webex Events oturum girişini alan girişinden ayrı, görevli ya da kiosk ile alıyor.

**Sapmalar (hepsi):**
1. **Dönen kod yok.** Ticketmaster SafeTix 15 saniyede dönen kod kullanıyor ve PDF vermiyor. Biz PDF ve basılabilir bilet istiyoruz, etkinlikler ücretsiz ve kapı fail-open; önlemlerimiz ilk okutma, kapıda ad ve panelden yenileme.
2. **PDF postada.** Eventbrite 2024'te PDF'i postadan kaldırıp bileti girişli "My Tickets"a taşıdı. Misafirin hesabı ve uygulaması yok; çevrimdışı ve basılı kullanım için ek kalıyor. `TICKET_PDF_ATTACHMENT` ile kapatılabilir.
3. **Bilet sayfası girişsiz.** Eventbrite ve Biletix'te hesaplı kişi biletini hesabında görüyor. Bizde misafirin hesabı olmadığı için bağlantının kendisi yetkidir; 128 bit anahtar, hız sınırı, `no-referrer` ve 7 günlük kapanış bunu sınırlar.
4. **Bilet devri yok.** Ticketmaster iletme yerine devir yapıyor ve alıcıya yeni kod veriyor. Bizde yalnız panelden yenileme var.
5. **Basılı statik oturum QR'ı yok.** Whova katılımcının okuttuğu basılı, statik oturum QR'ı kullanıyor. Bizde statik kodun fotoğrafı evden yoklama yazdırıyordu ve sertifika ona bağlı; kod döner.
6. **Tema tanımı core'da.** Forms'ta tema yalnız ön yüzün kodunda yaşıyor. Bilet PDF'ini core çizdiği için tanım core'da, site yalnız uygular; anahtar sözlüğü ortak. Yeni bir tema iki repoda (core ve site) çıkar.
7. **Girişte okutulmamış kişinin yoklaması kabul edilir.** Alan girişini oturum girişinin önkoşulu yapan bir düzen de kurulabilirdi; incelenen ürünlerde bu konuda açık bir kural bulunamadı. Bizde kapı fail-open, kalabalıkta okutma kaçabilir ve yoklama QR'ı zaten varlık kanıtı; eksik giriş yoklamadan türetilir ve panelde sayı olarak görünür.

## Considered Options

- **Dönen QR (SafeTix).** PDF'e ve baskıya konamaz, uygulama ister; misafirin uygulaması yok.
- **Bilet sayfası yalnız girişle (Hesap Merkezi ve sky-app).** Misafir bileti göremezdi.
- **Süresiz açık bilet sayfası.** Etkinlikten sonra kişisel veri gereksiz yere açık kalırdı.
- **PDF yalnız sayfadan.** Yusuf'un isteği posta eki; ek gelene kadar geçici yol olarak kalır.
- **Hiç ad yazmamak.** Belge kime ait olduğunu göstermezdi; ad soyad yazar, e-posta ve telefon yazmaz.
- **Ayrı bir imza anahtarı (OpenBao'da).** Yeni sır ve döndürme işi getirir; türetilmiş anahtar SkyPass'tan yine ayrıdır.
- **PDF'i SkyMail'in core'dan çekmesi.** ADR-0075 karar 3'e aykırı.
- **Base64 ya da CID QR görseli postada.** Base64 Gmail'de güvenilmez, CID ek ister ve webmail'de tutarsız.
- **Bilete sertifika şablonunu (serbest yerleşim) uygulamak.** QR'ı ve kodu yanlış yere ya da çok küçük koyabilir, kapıda okumayı bozar.
- **Temayı yalnız sitede tutmak (Forms gibi).** PDF'i core çizdiği için core da bilmek zorunda.
- **Tek kapı düzeni.** Ya ARTLAB'in alan girişini ya da oturum başına kapıyı dışarıda bırakırdı.
- **Alana girişi yoklama saymak.** Fuayede gezen kişi oturuma girmeden sertifika alırdı; EventDay yoklama birimi olmaktan 2026-09-17'de çıkarıldı.
- **Girişte okutulmamış kişinin yoklamasını reddetmek.** Fail-open kapıya aykırı; kaçan bir okutma sertifikayı kaybettirirdi.
- **Yoklama QR'ının bilet de yazması.** Walk-in'in (Event QR) kararıdır, ayrı yazılır.
- **Siteye Keycloak girişi.** ADR-0064'e aykırı; bilet anahtarı ve hesap e-postası yeter.
- **Yoklama ekranını panelde görevli girişiyle açmak.** OBS'de giriş ve oturum çerezi pratik değil.
