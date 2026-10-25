---
status: accepted
---

# İletişim tek servistir: SkyMail kanaldan bağımsız bir iletişim servisine genişler; core ne olduğunu ve kime gideceğini, servis hangi kanaldan, ne zaman ve hangi metinle gideceğini belirler

Bugün kulübün kişilere giden bütün iletileri e-postadır ve SkyMail'den çıkar: Keycloak'ın hesap postaları (ADR-0045), core'un hoş geldin, sertifika, ekip üyeliği ve davet onayı postaları, Forms'un postaları ve SkyMail arayüzünden elle gönderimler. ADR-0067 duyuru ve haber postalarını da SkyMail'e verdi; kitleye ve tercihe core karar veriyor. SkyMail'in motoru (alıcı başına kuyruk satırı, kira, deneme, öncelik şeridi, gönderim bütçesi), Mail onayı (ADR-0031) ve şablon sürümleri (ADR-0046, ADR-0047) e-postaya özgü değil. E-postaya bağlı olanlar şunlar: alıcının adresle tanımlanması, içeriğin konu + HTML + düz metin olması, SMTP göndericisi ve çıkış başlıkları.

Gelecekte push (sky-app), SMS ve uygulama içi bildirim kutusu ("Bildirimlerim", sky-app ve Hesap Merkezi) gelecek. sky-app'te bildirim sayfası hazır ama boş; Mobile Lab'in istediği uçlar (liste, okunmamış sayısı, okundu, cihaz kaydı) sky-app#45'te yazılı. Hiçbir serviste cihaz kaydı, uygulama içi bildirim ya da doğrulanmış telefon yok. Telefon core'da yalnız admin'in yazdığı bir alan (ADR-0035). Şablonu olup göndericisi yazılmamış etkinlik bildirimleri var (bilet oluştu, hatırlatma, güncellendi, iptal).

Yusuf'un sorusu (2026-10-12): SMS ve push nasıl yönetilmeli; `mail.yildizskylab.com` başta genel düşünülmüştü, sadece mail olarak çıktı; sektörün yönelimi ne; gerekirse adres kalkar.

İncelenen ürün ve yazılarda ortak kalıp tek servis ve kanal adaptörleridir. Novu, Knock, Courier ve SuprSend'de tetikleyici, kanal adımları, kategori × kanal tercihi ve uygulama içi kutu var. LinkedIn, Uber ve Slack'in yazılarında üretici "ne oldu ve kime"yi söylüyor, platform kanal ve zamana karar veriyor. Microsoft Teams'te de uygulama etkinliği ve alıcıyı veriyor; afiş mi akış mı olacağına kişinin ayarına göre Teams karar veriyor. Microsoft'un bulut ürünleri bu kalıptan sapıyor: Azure Communication Services kanal kanal ayrı ve 2028-09-30'da emekliye ayrılıyor; push ayrı bir ürün (Notification Hubs).

Karar (Yusuf, 2026-10-12):

1. **Tek iletişim servisi.** SkyMail kanaldan bağımsız bir iletişim servisine genişler. Ayrı SMS ya da push servisi kurulmaz. Novu (self-host) ya da bir SaaS şimdi kullanılmaz: self-host Novu belgelenen boyutuyla (~12 GB RAM, MongoDB, Redis, S3) tek sunucumuza sığmıyor ve topluluk sürümü tek ekip üyesine izin veriyor; SaaS üye verisini yurt dışına taşıyor.
2. **Sorumluluk ayrımı.** core ne olduğunu ve kime gideceğini belirler: olay, kitle, isteğe bağlı bildirimlerde tercih süzgeci (ADR-0067). İletişim servisi hangi kanaldan, ne zaman ve hangi metinle gideceğini belirler: tür varsayılanı, izinli kanallar, kişinin iletişim adresleri, sessiz saat, hız ve bütçe. Zorunlu bildirimler (giriş kodu, hesap güvenliği, bilet, sertifika, Mail onayı) tercihe bakmaz.
3. **Alıcı kişidir.** Yeni gönderim ucunda alıcı Keycloak `sub`'ıdır; adres yalnız adrese bağlı sistem postalarında (ör. yeni adrese doğrulama) verilir. `POST /v1/mail_tasks/single` bugünkü sözleşmesiyle kalır; Keycloak, Forms ve core'un mevcut çağrıları değişmez.
4. **Bildirim türü.** Bugünkü Template key bir Bildirim türüne genişler: kategori, zorunlu olup olmadığı, varsayılan kanalları ve kanal başına içerik varyantı (e-posta bugünkü şablonlar; uygulama içi, push ve SMS düz metin).
5. **Kanallar ve sırası.** E-posta (bugün), uygulama içi kutu, push (FCM; iOS'a APNs üzerinden), SMS. Web push yok.
6. **Tercih core'da, kanal boyutuyla.** ADR-0067'nin Duyuru tercihi kanalı da taşır: kayıt kanal yansız adlanır (`communication_preferences`) ve `channel` sütunu taşır; ekranı Hesap Merkezi'nde kalır. Kategori satırlarında yalnız o kategori için anlamlı kanallar ve kanal ana anahtarları gösterilir; tam bir kategori × kanal matrisi gösterilmez. Varsayılan abonelik alt ekiplere geçer, alt ekip ayrıca kapatılabilir, en özel ayar kazanır (ADR-0067); kural her kanalda aynıdır. Uygulama içi kutu tercihten bağımsızdır; push ve e-posta tercihe bakar.
7. **Cihaz kaydı ve kutu iletişim servisindedir.** sky-app ve Hesap Merkezi kişinin kendi token'ıyla (`aud=skymail`) servise yazar ve okur. Hesap silmede servisin silme adımı cihazları, kutuyu ve teslim satırlarını da siler (ADR-0051). Uygulama içi bildirim 90 gün tutulur.
8. **Arayüz ayrı uygulama kalır: bugünkü skymail-frontend (`mail.yildizskylab.com`) iletişim arayüzüne dönüşür,** skylcn-ui geçişinin (ADR-0055) üstüne kurulur; ürün adı "İletişim" olur. **Alan adı şimdilik `mail.` kalır.** Yeni bir ada (`iletisim.` ya da `notification.`; ad o adımda seçilir) geçiş, eski adresin yol korunarak kalıcı 301'i ve Keycloak redirect URI'leri **sonraki ayrı adımdır.** Keycloak istemci kimliği `skymail`, `skymail:*` rolleri, depo ve imaj adları ve `/v1/mail_tasks` yolları değişmez. Panel (ADR-0058) derin bağlantı verir (ADR-0020, ADR-0031 ve ADR-0067 karar 4 aynen).
9. **SMS'in önkoşulu kimliktir.** İşlem SMS'i (giriş kodu, etkinlik iptali) 6563 onayı istemez ve İYS kontrolüne girmez. Ama SMS aboneliği ve başlık vergi numarası, MERSİS ya da kurum/STK belgesi ister; kulüp tüzel kişi değil. Abonelik YTÜ ya da bir dernek üzerinden olmadan SMS açılmaz. Sağlayıcı yerlidir. İlk SMS türleri yalnız işlem iletileridir; duyuru SMS'i yoktur; sponsor tanıtımı hiçbir kanalda yoktur (ADR-0067 ile aynı). Telefon kişinin kendisinin kodla doğruladığı bir adres olur (ADR-0035 bu noktada değişir).
10. **Push'un önkoşulları.** Bir Firebase projesi, sky-app'in App Store hesabında bir APNs anahtarı ve Mobile Lab'e verilen sözleşme. Firebase projesi ve Apple Developer hesabı kulüp adına açılır (kişi adına değil); cevap gelmeden ve hesaplar açılmadan push başlamaz.

Nasıl:

- **Veri.** `mail_tasks` ve `mail_queue` ilk sürümde yeniden adlandırılmaz (expand/contract): teslim satırına `channel` ve kişi kimliği (`recipient_sub`), görevlere Bildirim türü eklenir; kanal başına bütçe `mail_send_windows`'un genellemesidir. Yeni tablolar: Bildirim türleri, kanal içerik varyantları, `device_registrations`, `inbox_items`.
- **Uçlar.** `POST /v1/notifications` (tür, alıcılar ya da core'un kitle sonucu, değişkenler, `Idempotency-Key`); `/v1/me/inbox` (liste, sayılar, görüldü, okundu, arşiv, hepsini okundu); `/v1/me/devices` (her açılışta `PUT`, çıkışta `DELETE`). core'un kitle ucu (ADR-0067) kişi başına izinli kanalları da döner. Kişinin kendi uçları rol istemez: yalnız token'ın `aud`'u ve `sub`'ı; kişi yalnız kendi kayıtlarını görür, başkasınınki için "yok" (404) alır.
- **Kutu öğesi.** Asıl kaydın (bilet, sertifika, duyuru) kopyası değildir: Bildirim türünün `inbox` varyantından render edilen kısa başlık, özet ve uygulama içi bağlantı. Görüldü, okundu ve arşiv bilgisi sunucuda tutulur ve cihazlar arasında ortaktır. Kaynağı süreli ise (etkinlik bitti) öğe 90 günden önce silinebilir. Gerçek zamanlı akış ilk sürümde yoktur: uygulama açılışta ve push gelince çeker.
- **Adaptörler.** Her kanalın göndericisi ve hata sınıflandırması ayrıdır: SMTP 5xx kalıcı, 421/4.7.x kısma; FCM `UNREGISTERED` ve APNs 410 kaydı siler; SMS sağlayıcısının tekrar anahtarı kullanılır. Kutu adaptörü dış sağlayıcıya gitmez, öğeyi yazar.
- **Güvenilirlik.** core'un hoş geldin ve sertifika postasındaki "ateşle ve unut" çağrısı hatırlatma ve iptal gibi bildirimlere yetmez. Bu türler, ekip üyeliği postasının bugünkü kalıbıyla (core'un kuyruğu, servis alana kadar bekler) ve `Idempotency-Key` ile gider. Bildirim isteği bir komuttur ve `Idempotency-Key`'li HTTP ile gider; ADR-0071'deki RabbitMQ yalnız servisler arası olaylar içindir, gönderim kuyruğu SkyMail'in Postgres'inde kalır.
- **Sırlar.** FCM servis hesabı anahtarı ve SMS sağlayıcısının API anahtarı OpenBao'dadır (ADR-0049).

## Consequences

- **Mevcut çağıranlar değişmez.** Keycloak SPI, Forms ve core `/single` ile göndermeye devam eder; yeni bildirimler yeni uca yazılır.
- **core.** Duyuru tercihi tablosu ve uçları kanal yansız adlandırıldı (`communication_preferences`) ve `channel` sütunu aldı (core-backend #232, production'da satır yokken). Kitle ucu kanalları döner. Etkinlik bildirimleri (bilet oluştu, güncellendi, iptal, hatırlatma) için giden kutusu ya da zamanlanmış iş gerekir.
- **İletişim servisi (skymail-backend).** Bildirim türü, kişi alıcı, kanal adaptörleri, cihaz kaydı, kutu, kanal başına bütçe, silme adımının genişlemesi.
- **Arayüz (skymail-frontend).** Ürün adı "İletişim", Bildirim türleri ve kanal varyantları, kanal seçimi ve önizlemesi; Mail onayı ve rapor kanalı gösterir. Alan adı değişimi ayrı ve sonraki bir adım; o zamana kadar `mail.yildizskylab.com`.
- **Hesap Merkezi.** "Bildirimlerim" ve "İletişim tercihleri"nde kanal sütunları; cihazın bildirim izni durumu.
- **sky-app (Mobile Lab).** Kutu ve cihaz sözleşmesi (sky-app#45'in uçlarının yeni adları), Firebase entegrasyonu, izin istemi. Kutu öğesinin bağlantısı uygulama içi bir yoldur (`/events/<id>`, `/news/<slug>`).
- **Keycloak.** Hesap Merkezi ve sky-app token'larına `aud=skymail` mapper'ı; yeni roller (`skymail:notifications:send` gibi) aynı istemcide; arayüzün yeni redirect URI'leri (alan adı adımında, wizard ile).
- **Hukuk ve metinler.** Aydınlatma metnine push ve SMS eklenir. Push için Google ve Apple'a yurt dışı aktarım (KVKK m.9 standart sözleşme ve Kurul'a bildirim). SMS için yerli sağlayıcı ve doğrulanmış telefon; Kurul İlke Kararı 2025/1072'ye göre kodun amacı açıklanır, onaylar tek eylemde alınmaz. SMS'ten önce abonelik, başlık ve veri sorumlusu soruları YTÜ'ye ve avukata gider.
- **Saklama (ADR-0062'ye eklenecek satırlar; ADR-0062 bu ADR'la değişmez).** Uygulama içi bildirim (kutu öğesi) 90 gün, hesapla birlikte silinir; cihaz kaydı son görülmeden 270 gün sonra ya da çıkışta; SMS teslim satırı e-postanın kişiselleştirilmiş gövde süresiyle (1 yıl, öneri). Her biri SkyMail'in kendi imha işinde silinir (ADR-0062, Periodic destruction run).
- **Bilinçli olarak yapılmayanlar.** Web push, digest, dallanan iş akışları, tanıtım SMS'i, WhatsApp. Açılma ve tıklama izleme bu ADR'ın kapsamında değildir; ayrı bir kararla gelir.
- **CONTEXT.md'de değişenler:**
  - Yeni terimler: Notification (Bildirim), Notification type (Bildirim türü), Channel (Kanal), Delivery (Teslim), Contact point (İletişim adresi), Device registration (Cihaz kaydı), Inbox item (Kutu öğesi).
  - Announcement preference, Communication preference (İletişim tercihi) olur ve kanalı taşır.
  - Mail template, Bildirim türünün e-posta varyantı olarak tanımlanır; mevcut tanım bozulmaz. Template key aynı zamanda Bildirim türünün anahtarıdır.

## Açık

- **Firebase ve Apple Developer hesabı:** Mobile Lab cevap verdi (2026-10-13): sky-app henüz mağazalarda değil, Firebase projesi yok ve açılacak. Proje kulüp adına açılır, sahibi kulüp hesabı olur, Mobile Lab düzenleyicidir. Apple Developer hesabı yayın zamanında aynı kuralla açılır. Push bu hesaplar açılana kadar başlamaz.
- **Alan adı:** yeni ad (`iletisim.` ya da `notification.`) ve zamanı sonraki adımda seçilir.
- **SMS:** abonelik ve başlık YTÜ'ye mi bir derneğe mi; veri sorumlusu; ücretsiz kulüp duyurusunun 6563 kapsamı (avukata ve YTÜ'ye).
- **Bildirim türü kataloğu:** hangi türün hangi kategoride olduğu, hangisinin zorunlu olduğu ve varsayılan kanalları core'un kategorileriyle birlikte yazılır.

## Endüstri uygulamasıyla karşılaştırma

**Uyanlar:**
- Tek servis, kanal adaptörleri, iş akışı ve uygulama içi kutu (Novu, Knock, Courier, SuprSend).
- Üretici "ne ve kime", platform "kanal ve zaman" (LinkedIn Air Traffic Controller, Uber, Slack; Teams etkinlik akışı).
- Kapatılamayan zorunlu kategori (Novu critical, Knock override, Courier REQUIRED, SuprSend "Can't Unsubscribe", Viva Engage essential announcements).
- Kutuda görüldü, okundu ve arşiv ayrı durumlar; rozet görülmemişleri sayar (Knock, Novu).
- Cihaz kaydı backend'de, kalıcı depoda, zaman damgasıyla; `UNREGISTERED`'da silme (Firebase, Notification Hubs, Amazon SNS, Knock).
- Çok kanallı iç iletişimin gönderim ve onay ekranı ayrı uygulama (Microsoft Viva Amplify).
- Konu (topic) yerine cihaz hedefleme, özel içerik için (Firebase'in yönlendirmesi).

**Sapmalar (hepsi):**
1. **Tercih bildirim servisinde değil, core'da** (Novu, Knock, Courier tercihi kendinde tutar). Nedeni ADR-0067: "kime ulaşabiliriz" kararlarının hepsi (davet onayı, tercih) tek yerde; ekip ağacı kalıtımı core'da.
2. **Tam kategori × kanal matrisi yok;** Teams'e yakın sadeleştirme (ekip ağacı × tür × kanal kişi başına çok anahtar eder).
3. **Kendi motorumuz;** iş akışı yalnız kanal seçimi, gecikme, "görülmediyse" koşulu ve sessiz saat (digest ve dal yok).
4. **Cihaz kaydı uygulama backend'inde (core) değil iletişim servisinde** (Microsoft "backend yönetir" diyor; servis kimliği kendisi doğruladığı için ayrı kapı bekçisi yok).
5. **Web push yok** (Novu ve Knock sunuyor).
6. **Kanal başına ayrı Microsoft ürünü yok;** Microsoft'un bulut kalıbı (ACS + Notification Hubs) yerine tek servis.
7. **Kutu 90 gün tutulur;** Teams etkinlik akışı ve Google Classroom 30 gün, GitHub kaydedilmemiş bildirimde 3 ay, Knock süresiz. Etkinlik ve sertifika bildirimleri haftalar sonra açıldığı için 30 günden uzun seçildi.
8. **Kutuda gerçek zamanlı akış yok** (Knock ve Novu websocket sunuyor); ilk sürümde açılışta ve push gelince çekilir.

## Considered Options

- **A. Her kanal ayrı servis (SkyMail + SMS + push):** motor, onay, şablon, rapor ve silme iki kez daha kurulurdu; "bilet oluştu" için core üç servisi çağırıp kanalı kendisi seçerdi; kanallar arası kural koyacak yer olmazdı.
- **C. Self-host Novu + bizim kitle ve tercih katmanımız:** belgelenen tek VM boyutu ~12 GB RAM (kullanılabilir ~8,8 GiB, swap yok). MongoDB, AOF'lu Redis ve S3 yığına girerdi (ADR-0002'nin dışı). Topluluk sürümünde SSO ve RBAC yok, tek ekip üyesine izin var. Keycloak, Forms ve core'un çağrıları taşınır ya da iki sistem yaşardı; Türk SMS sağlayıcıları entegrasyon listesinde yok.
- **D. SaaS (Knock, Courier, SuprSend, OneSignal):** kurulum yok, iş akışı ve kutu hazır. Ama üyelerin adı, adresi, cihaz token'ı ve bildirim içeriği yurt dışındaki bir işleyene gider (KVKK m.9); ücretsiz katman sınırları ve fiyat satıcıya bağlı; Keycloak ve Forms SkyMail'de kalacağı için iki sistem olurdu.
- **Azure Communication Services ve Notification Hubs:** ACS 2028-09-30'da emekliye ayrılıyor ve Türkiye'ye doğrudan SMS göndermiyor; Notification Hubs FCM'nin üstüne ikinci bir dağıtıcı olurdu.
- **Yabancı SMS sağlayıcısı (Twilio):** Türkiye'ye pazarlama trafiğini 2021'den beri almıyor, 18.11.2026'dan sonra kayıtsız başlığı engelliyor, yerel tüzel kişiliği olmayan gönderenin URL'li mesajını göndermiyor; İYS'yi anmıyor; telefonlar yurt dışına aktarılır (KVKK m.9).
- **Gönderim ekranını admin paneline "İletişim" bölümü olarak taşımak:** ADR-0020, ADR-0031 ve ADR-0067 karar 4'ü değiştirmek, şablon editörünü, sürümleri, onayı ve raporu Kaan'ın deposunda yeniden yazmak demek; Microsoft'un karşılığı (Viva Amplify) da ayrı uygulama.
- **Cihaz kaydını core'da tutmak:** sky-app zaten core'la konuşuyor; ama token yalnız teslimde kullanılıyor ve `UNREGISTERED` silmesi servisler arası çağrıya dönerdi.
- **Kutuyu tercihe bağlamak:** kapalı kategori kutuda da görünmezdi; kişi e-postayı kapatınca bilet ya da etkinlik haberini hiçbir yerde göremezdi. Kutu sessizdir, kişiyi rahatsız etmez; push ve e-posta tercihe bakar.
- **`mail.` adresinde kalıcı olarak kalmak:** sıfır maliyet, ama ürün adı push ve SMS gelince yanıltıcı olur. İlk aşamalar için seçildi (karar 8); geçiş sonraki adım.
- **Alan adını hemen değiştirmek:** kullanıcıya ikinci kanal görünmeden faydası yok; skylcn-ui geçişi ve konsol işleriyle aynı anda Keycloak, Traefik ve DNS değişikliği riski toplar.

## Ek (2026-10-25): Forms'un postalarını core gönderir (ADR-0075)

Karar 3'teki "Keycloak, Forms ve core'un mevcut çağrıları değişmez" cümlesinin ve Consequences'taki "Keycloak SPI, Forms ve core `/single` ile göndermeye devam eder" cümlesinin Forms kısmı ADR-0075 ile değişir. Forms SkyMail'e göndermez. Forms olay yayımlar, postanın kime ve hangi Bildirim türüyle gideceğine core karar verir. core postayı kendi kuyruğundan gönderir: hesabı olan alıcıya `POST /v1/notifications` ile, misafire `/v1/mail_tasks/single` ile. Karar 2 bu yönü zaten söylüyordu. Keycloak'ın sistem postası SkyMail'e doğrudan gitmeye devam eder (ADR-0045). `forms.*` şablon anahtarları ve değişkenleri aynı kalır; sözleşmelerinin sahibi core olur.
