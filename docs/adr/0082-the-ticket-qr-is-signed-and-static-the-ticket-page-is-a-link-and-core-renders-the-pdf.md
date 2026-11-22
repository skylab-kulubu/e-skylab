---
status: accepted
---

# Bilet QR'ı imzalı ve statiktir; bilet sayfası girişsiz bir bağlantıdır; PDF bileti core üretir ve SkyMail ek olarak gönderir

"Biletin hazır" postası (`event.ticket-created`, core `docs/ticket-created-notification.md`) bugün yalnız etkinliğin adını, tarihini ve yerini taşıyor. Şablonda QR görseli, bilet kodu ve etkinlik bağlantısı için koşullu bloklar hazır, ama core onları dolduramıyor: biletin QR'ı da kodu da yok. Kapıda üye SkyPass QR'ını gösteriyor. Misafir kapıdaki ekranın QR'ını kendi telefonuyla okutup e-postasını yazıyor, ya da masada adıyla bulunuyor. CONTEXT "Ticket QR"ı tanımlıyor (görevli tarayıcısı onu SkyPass QR'la aynı kamerada tanır; imzalıysa cihazda doğrulama ve Queued check-in), ama nasıl üretildiğini söylemiyor ve onu "per-User" diye anlatıyor; misafirin User'ı yok. ADR-0022 de "Ticket QR if signed" diyerek kararı açık bırakıyor.

Yusuf'un isteği (2026-11-22): bilet, Biletix ve Obilet'teki gibi posta ekinde PDF olarak gelsin; ayrıca QR'ı gösteren bir bilet sayfası açılsın.

Karar (Yusuf, 2026-11-22; on sorunun hepsinde önerilen şık, 5. soruda ek olarak belge görünümü):

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

Kaynaklar:
- **Yusuf'un:** istek (PDF ek ve bilet sayfası) ve on sorunun cevabı (2026-11-22). 5. soruda ad soyad yazar, belge kurumsal ve resmî görünür.
- **Tasarım önerisi:** 1–7'nin ayrıntıları (hub'daki `.scratch/bilet-qr-ve-pdf/SPEC.md`).

## Consequences

- **core.** Bilette `access_key`, `code` ve `qr_version` alanları. Bilet imzalayıcısı ve JWKS'te ikinci anahtar. Kapı ucunda `kid`'e göre ayırma ve kanonik `check-in/scan` adı (`/skypass` takma ad olarak kalır, yayındaki sky-app değişmeden çalışır). `/v1/public/tickets/{key}` (JSON, `qr.png`, `pdf`). `/v1/tickets/me`'de `code`, `ticketUrl`, `qrToken`. Yeniden gönder ve yenile uçları. `TICKET_PAGE_URL`, `TICKET_PAGE_GRACE`, `TICKET_PDF_ATTACHMENT`.
- **İletişim servisi (skymail-backend).** Ek alanı, `mail_attachments` tablosu, SMTP ve Graph eki, maskeleme ve silme kapsamı.
- **Şablon (skymail-frontend).** "Biletini aç" düğmesi, QR'lı metin, `TicketUrl` hassas değişken.
- **Site.** `/bilet/[key]`, PDF ile aynı belge görünümünde.
- **Panel.** Katılımcı satırında kod, yeniden gönder, yenile; masada kodla arama.
- **sky-app (Mobile Lab).** Bugünkü tarayıcı Ticket QR'ı değişmeden okur. Sözleşme: metinler, 410, JWKS ile cihazda doğrulama, "etkinliklerim"de QR.
- **Saklama (ADR-0062).** Yeni bir kişisel veri kategorisi yok. Anahtar ve kod biletle yaşar ve silinir; PDF saklanmaz; ek gönderilince silinir.
- **Walk-in.** Walk-in biletinin de kodu ve anahtarı olur, ama bilet postası gitmez (ADR-0032).
- **CONTEXT.md'de değişenler.** Ticket QR "per-Ticket" olur. Yeni terimler: Ticket page (Bilet sayfası), Ticket code (Bilet kodu), Mail attachment (Posta eki). Desk check-in bilet koduyla da arar. Required variable örneği aynen kalır.

## Diğer ADR'lerle ilişki

- **ADR-0022.** Çelişki yok; açık bıraktığı "Ticket QR if signed" kapanır: Ticket QR imzalıdır (`kid=tk-e1`, aynı JWKS), bu yüzden cihazda doğrulanır ve core yokken Queued check-in olur. Panelden yenilenmiş eski bir kod çevrimdışı kapıda geçebilir; bu, ADR-0022'nin fail-open kuralının kabul edilen sonucudur. ADR-0022'deki `POST /v1/tickets/:ticketId/event-days/:eventDayId/check-in` adresi eskidir (giriş artık oturum başınadır); Ticket QR girişi oturumun kapı ucuna gider. ADR-0022'ye bu yönde bir ek yazıldı.
- **ADR-0032.** Çelişki yok. Kapı kimliği bilettir ve Ticket QR biletin kodudur; afiş QR'ı (Event QR) kapı kimliği değildir. Walk-in bilet postası almaz.
- **ADR-0066.** Çelişki yok. Taslak etkinliğin bileti herkese açık uçlarda `404`'tür. İptal edilen etkinlikte sayfa QR'ı gizler, iptal geri alınınca açılır; bilet geçerli kalır, kapı zaten reddeder. "Bitti" ADR-0066'daki gibi tarihten türer; tarihsiz etkinlik bitmediği için onun bilet sayfası 7 günlük kapanışa girmez.
- **ADR-0069.** Çelişki yok. Geri bildirim davetinin kişiye özel kodu da 128 bit rastgeledir ve düz saklanır; bilet sayfasının erişim anahtarı aynı kalıptadır. Fark: davet satırı 90 günde silinir, erişim anahtarı biletle yaşar ve bilet silinince gider.

## Endüstri uygulamasıyla karşılaştırma

İncelenenler: Eventbrite, Biletix, Obilet, Passo, Ticketmaster SafeTix, Apple Wallet ve Google Wallet etkinlik bileti, AB Dijital COVID Sertifikası.

**Uyanlar:**
- **Bağlantı ya da postayla PDF + QR.** Biletix onay postası ya da SMS bağlantısıyla PDF ve QR veriyor; en yakın olduğumuz kalıp bu.
- **Bilet başına statik QR, kapıda ilk okutma kazanır.** Eventbrite'ın varsayılanı.
- **İmzalı QR'ın yayımlanan anahtarlarla çevrimdışı doğrulanması.** AB Dijital COVID Sertifikası (COSE_Sign1, ES256).
- **Görseli engelleyen istemci için düz metin kod.** Erişilebilirlik rehberleri QR'ın yanında okunur metin öneriyor; Google Wallet'ın `alternateText`'i de bu iş için.
- **Wallet'ta dönen kod.** Google Wallet `rotatingBarcode`; Wallet bileti gelince biz de onu kullanırız.

**Sapmalar (hepsi):**
1. **Dönen kod yok.** Ticketmaster SafeTix 15 saniyede dönen kod kullanıyor ve PDF vermiyor. Biz PDF ve basılabilir bilet istiyoruz, etkinlikler ücretsiz ve kapı fail-open; önlemlerimiz ilk okutma, kapıda ad ve panelden yenileme.
2. **PDF postada.** Eventbrite 2024'te PDF'i postadan kaldırıp bileti girişli "My Tickets"a taşıdı. Misafirin hesabı ve uygulaması yok; çevrimdışı ve basılı kullanım için ek kalıyor. `TICKET_PDF_ATTACHMENT` ile kapatılabilir.
3. **Bilet sayfası girişsiz.** Eventbrite ve Biletix'te hesaplı kişi biletini hesabında görüyor. Bizde misafirin hesabı olmadığı için bağlantının kendisi yetkidir; 128 bit anahtar, hız sınırı, `no-referrer` ve 7 günlük kapanış bunu sınırlar.
4. **Bilet devri yok.** Ticketmaster iletme yerine devir yapıyor ve alıcıya yeni kod veriyor. Bizde yalnız panelden yenileme var.

## Considered Options

- **Dönen QR (SafeTix).** PDF'e ve baskıya konamaz, uygulama ister; misafirin uygulaması yok.
- **Bilet sayfası yalnız girişle (Hesap Merkezi ve sky-app).** Misafir bileti göremezdi.
- **Süresiz açık bilet sayfası.** Etkinlikten sonra kişisel veri gereksiz yere açık kalırdı.
- **PDF yalnız sayfadan.** Yusuf'un isteği posta eki; ek gelene kadar geçici yol olarak kalır.
- **Hiç ad yazmamak.** Belge kime ait olduğunu göstermezdi; ad soyad yazar, e-posta ve telefon yazmaz.
- **Ayrı bir imza anahtarı (OpenBao'da).** Yeni sır ve döndürme işi getirir; türetilmiş anahtar SkyPass'tan yine ayrıdır.
- **PDF'i SkyMail'in core'dan çekmesi.** ADR-0075 karar 3'e aykırı.
- **Base64 ya da CID QR görseli postada.** Base64 Gmail'de güvenilmez, CID ek ister ve webmail'de tutarsız.
