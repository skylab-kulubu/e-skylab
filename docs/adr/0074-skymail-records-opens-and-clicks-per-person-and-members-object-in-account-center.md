---
status: accepted
---

# SkyMail postaların açılmasını ve tıklanmasını kişi bazında kaydeder; dayanak meşru menfaattir, üye Hesap Merkezi'nden itiraz eder, gizli bağlantılar hiçbir zaman sayılmaz, her şey kapalı bayrakların arkasındadır

ADR-0067 haber ve duyuru postalarını SkyMail'e verdi, açılma izlemeyi açık soru olarak bıraktı (Sapmalar 5). ADR-0070 iletişimi tek servise topladı, açılma ve tıklama izlemeyi "ayrı bir kararla" diye kapsam dışında tuttu. ADR-0072 karar 2 "takip akışa bağlı değildir, bütün postalar takiplidir" dedi ve takip kararını ayrı bir ADR'a bıraktı. Bu ADR o karardır.

Kulübün bugün bir postanın hangi üyeye ulaştığını bilmesinin yolu yok. Uygulama içi kutu ve push gelince (ADR-0070) ulaşmayan üyeye başka kanaldan ulaşmak mümkün olacak; bunun için kime ulaşmadığını bilmek gerekiyor. Giriş kodu gibi hesap postalarının gereksiz klasörüne düşüp düşmediği de görünmüyor.

KVKK'da e-posta pikseline dair Kurul kararı ya da rehber yok. En yakın metin, Çerez Rehberi, pikselleri kapsamı dışında bırakıyor ama aynı işi gören analitik çerezleri açık rızaya bağlıyor. AB'de Fransa (CNIL, 2026-042) ve İtalya (Garante, n. 284) kişiye bağlanan açılma ölçümünü rızaya bağladı. Kulüp AB'de değil; bu metinler yön gösteriyor. Avukat aşağıdaki kapsamı ve KVKK Aydınlatma Metni'ndeki anlatımı (§5.9, faaliyet satırı 17) onayladı (2026-10-19, 2026-10-21, 2026-10-23).

Kararlar Yusuf'undur: 2026-10-12 (T1–T8), 2026-10-19 (hukuk onayı), 2026-10-20 (kişilere tek tek gönderim), 2026-10-21 (bütün postalar, gizli bağlantı istisnası, panel postalarında kutusuz takip), 2026-10-23 (90 gün ve anonimleşme), 2026-10-25 (kod tamamlanır, bayraklar kapalı kalır).

## Karar

1. **Ne kaydedilir.** Alıcıya özel, rastgele belirteçli 1×1 piksel ve SkyMail'den geçirilen bağlantılarla: açılma zamanı, tıklanan bağlantı ve zamanı, istemci sınıfı (`apple_proxy_likely`, `google_proxy`, `yahoo_proxy`, `microsoft`, `scanner_likely`, `mail_client`, `browser`, `unknown`) ve "muhtemelen otomatik" işareti. Sınıflandırma bellekte, yalnız user-agent ve zamandan yapılır. **IP adresi, Referer ve konum okunmaz ve saklanmaz; ham user-agent yalnız bellekte sınıflandırılır, saklanmaz.** Takip uçları istek günlüğüne yol, belirteç ve IP yazmaz.
2. **Dayanak ve kip (T1).** KVKK md. 5/2-f, meşru menfaat ve aydınlatma. core'da `COMMUNICATION_TRACKING_MODE=opt_out|opt_in`, varsayılan **`opt_out`**: tercih satırı yoksa izlenir. `opt_in` acil frendir: satırı olmayan herkes o anda takipten çıkar. Açık rıza gerekirse ayrı bir rıza tasarımı yapılır; ters anlamlı itiraz anahtarının işaretini kaldırmak açık rıza sayılmaz. "Herkesi izle, reddedeni de" kipi (Dynamics'in *Disabled*'ı) yoktur.
3. **Kim takip edilir.** Yalnız core'un izin verdiği kişi: Keycloak hesabı etkin, `/UYELER` ağacında (News audience'ın Member tanımı) ve itiraz etmemiş. Hesabı olmayan adres (liste ve Forms alıcılarının çoğu, konuk, davet listesi), servis hesabı ve Member olmayan **hiçbir zaman** takip edilmez. Adresle gelen alıcının hesabı, SkyMail'de yalnız doğrulanmış birincil e-postanın tam eşleşmesiyle bulunur; tek bir eşleşme yoksa hesapsız sayılır. core ya da Keycloak zamanında yanıt vermezse o gönderimde kimse takip edilmez, posta yine gider.
4. **Hangi postalar (Yusuf, 2026-10-21).** Takip gönderim akışına bağlı değildir (ADR-0072 karar 2). Her biri kendi bayrağıyla; iki bayrak da yalnız ana bayrak `SKYMAIL_TRACKING=on` iken çalışır, ana bayrak kapalıyken açık olmaları hiçbir şey yapmaz:
   - **Panel postaları** (liste, Keycloak grubu, kişilere tek tek, Forms yanıtlayanları, onaylanan Mail onayı; `islem` amaçlısı da): `SKYMAIL_TRACKING_OPERATOR=on` iken her zaman takiplidir, gönderim formunda kutu yoktur ve gönderen bir gönderimi kapatamaz. Bayrak kapalıyken gönderen gönderim başına işaretsiz bir kutuyla isteyebilir (T7).
   - **Servislerin postaları** (giriş ve kayıt kodu, doğrulama, şifre sıfırlama, Forms onayları, core'un bildirimleri, Mail onayı bildirimleri): `SKYMAIL_TRACKING_SYSTEM=on` iken takiplidir. Kişi panelden sistem şeridine takipli posta gönderemez.
5. **Gizli bağlantı hiçbir zaman sayılmaz (Yusuf, 2026-10-21).** Kodu ya da tek kullanımlık bağlantıyı taşıyan, ya da hassas işaretli içerikte **yalnız piksel** vardır; hiçbir bağlantı yeniden yazılmaz ve kaydedilmez. Servis postasında yalnız şablonun düz yazdığı bağlantı sayılır; değişkenin doldurduğu her bağlantı (sıfırlama, doğrulama, giriş, kişiye özel davet kodu) olduğu gibi gider. Panel postasında yalnız bütün alıcılara aynı giden bağlantı sayılır; alıcıdan gelen hiçbir değer (adres, ad, çıkış bağlantısı) taşıyan bağlantı sayılmaz. Çıkış ve tercih bağlantıları, `mailto:`, `tel:` ve gönderenin "Bu bağlantıyı sayma" diye işaretlediği bağlantı (`data-skymail-notrack`) her postada dokunulmaz. `List-Unsubscribe` başlığına dokunulmaz.
6. **Açık yönlendirme yok.** Tıklama yalnız gönderim anında kaydedilmiş adreslerden birine gider; istekteki hiçbir parça hedefe girmez. Adres `https://api.yildizskylab.com/api/skymail/t/…`; yeni alan adı ve sertifika yok (T6).
7. **Saklanan gövde temiz kalır.** Piksel ve takip bağlantıları SMTP anında eklenir; saklanan HTML değişmez, "gönderilen içeriği görüntüle" sahte açılma üretmez. Postaya "takibi kapat" satırı ya da bağlantısı eklenmez (T8).
8. **İtiraz (T8).** Üye Hesap Merkezi'nin iletişim tercihlerinde "Postalarımın açılmasını ve tıklamalarımı izleme" anahtarıyla itiraz eder; KVKK md. 11 başvurusu da bir yoldur. Tercih core'dadır (`communication_preferences`, `scope='tracking'`, `channel='email'`); Communication preference kategorisi değildir, ana anahtar ona dokunmaz. İtiraz **geçmişe etkilidir**: core tekrar denemeli bir işle SkyMail'e bildirir; SkyMail kişinin olaylarını siler ve önceden gönderilmiş postalarındaki belirteçleri kapatır. İtiraz hesap ve işlem postalarını da kapsar; postalar gitmeye devam eder.
9. **Kim görür (T2).** Toplu görünüm `skymail:mails:read`. Kişi bazında görünüm `skymail:mails:tracking:read` (ADMIN, YK, DK) ya da panel gönderiminin kendi göndereni. Sistemin gönderdiği postalarda (servis postaları, bir yetkilinin işlemi üzerine giden bildirimler) kişi bazında görünüm yalnız rolle açılır, gönderen sayılan kişi göremez. 10'dan az takipli alıcılı gönderimin sayıları yalnız kişi bazında okuyabilene gösterilir.
10. **Süreler (KVKK Aydınlatma Metni s6, 2026-10-23; ADR-0062 tablosu).** Kişi bazında olay alıcının postasının gidişinden **90 gün** sonra anonimleşir: SkyMail'in saklama işi önce gönderimin kişisiz toplamını yazar, sonra kişinin belirtecini kapatır ve olaylarını siler. Kişisiz toplam her gönderimde tutulur: 10 ve daha çok takipli alıcıda anonim ve süresiz, 10'dan azda kişisel veri sayılır ve gönderimden 1 yıl sonra içerikle birlikte silinir. Yönlendirilen bağlantılar 1 yıl çalışır, sonra "bağlantının süresi doldu" der; 90 günden sonraki tıklama kişiye yazılmaz. Hesap silme (ADR-0051) olayları, belirteçleri ve kişiyi adlandıran bağlantı adreslerini siler.
11. **Kısa link servisiyle ilişki (T5).** Postadaki bir `skyl.app` bağlantısı da SkyMail'den geçer, ama SkyMail hedefe kimlik, belirteç ya da sorgu parametresi eklemez. Kısa bağlantı kaydının kuralı ADR-0062'deki gibi kalır; posta tıklaması kısa link sayılarına kişi olarak girmez.
12. **Ekran dili.** "Okudu" denmez: "açılma görüldü", "açılma görülmedi", "muhtemelen otomatik". Açılmaya dayalı otomatik eylem ("açmayanlara yeniden gönder") yoktur. Açılmadığı görülen kişiye aynı içerik başka bir kanaldan iletilebilir; açılma bilgisine dayanılarak kişi hakkında değerlendirme yapılmaz.
13. **Açılış (Yusuf, 2026-10-25).** Kod bütün parçalarıyla yazılır; `SKYMAIL_TRACKING`, `SKYMAIL_TRACKING_SYSTEM` ve `SKYMAIL_TRACKING_OPERATOR` her ortamda kapalı başlar, saklama işi (`SKYMAIL_TRACKING_RETENTION`) de. Production açılışı, takibi anlatan aydınlatma metni yayımlandıktan sonra ayrı bir karardır. Açılmadan önce hesabı olan kişilere kapsamı ve itiraz yolunu anlatan bir bilgilendirme postası bir kez gider (aydınlatma metni §5.9).

## Consequences

- **SkyMail:** bayraklar ve okuma uçları; kimliksiz `GET|HEAD /t/o/{rt}` ve `/t/c/{rt}/{lt}` (HEAD tıklama kaydetmez, satır başına ve süreç başına sınırlar); `GET /v1/mail_tasks/{id}/tracking` ve `…/tracking/recipients`; iç uç `PUT /internal/v1/tracking-withdrawals/{sub}` (yalnız core'un servis hesabı); saklama işi `off|dry-run|apply|purge` (makbuz, advisory lock, fren). Kuyruk, bağlantı ve olay satırları her yolda aynı sırayla kilitlenir; hesap silme, itiraz ve saklama birbirini beklemez ve olay kaçırmaz.
- **core:** `scope='tracking'` satırı, `COMMUNICATION_TRACKING_MODE`, SkyMail'in sorduğu uygunluk ucu (`POST /internal/v1/communication-preferences/tracking:resolve`, yalnız SkyMail'in servis hesabı), itirazı SkyMail'e taşıyan outbox ve işçi (vazgeçmez), değişikliklerin denetim kaydı. Kenardan gelen istek iç uçlarda 404 alır.
- **Hesap Merkezi:** iletişim tercihlerinde tek anahtar; işaretli = takip yok. Takip edilmeyen ve itiraz etmemiş kişide bölüm görünmez.
- **Keycloak:** `skymail:mails:tracking:read` (ADMIN, YK, DK köklerine), `skymail:tracking:withdraw` (yalnız core'un servis hesabına; hiçbir gruba, bileşik role ya da varsayılan role girmez, uzlaştırma bunu denetler), core istemci rolü `communication-preferences:read` (yalnız SkyMail'in servis hesabına). İki token da `aud`'u mevcut audience çözümünden alır.
- **Hukuk:** KVKK Aydınlatma Metni §5.9 ve faaliyet satırı 17; iç denge testi notu. Takip açılmadan önce metin yayımlanır.
- **Ops:** sandbox'ta istemci ölçümü (Apple MPP, Gmail proxy, klasik ve yeni Outlook, YTÜ Microsoft 365); saklama işi önce `dry-run`, makbuz okununca `apply`. Kenar günlükleri aydınlatmadaki gibi: ham günlük en çok 90 gün, erişim kaydında yol maskelidir ve belirteç taşımaz; ikisi de takip kaydıyla birleştirilmez.
- **Açılma verisi zayıf bir sinyaldir.** Apple Mail Privacy Protection resimleri teslimde yükler, Gmail proxy'si önbellekler, klasik Outlook resimleri indirmez, güvenlik tarayıcıları bağlantılara tıklar. Ekran bunu söyler; tıklama daha güçlü işarettir.
- **Bilinen sınırlar.** core'a gönderim kuyruğa yazılmadan hemen önce sorulur; itiraz o birkaç saniyelik aralığa denk gelirse o gönderimde kişi yine takipli kuyruğa girebilir (bir sonraki itiraz ya da hesap silme onu da kapatır). Keycloak konsolundan silinen hesabın bekleyen itirazı SkyMail'e ulaşmaz; olayları 90 günlük saklamaya kadar kalır.
- **ADR-0067 "Sapmalar 5" bu kararla kapanır** (ADR-0067 eki). ADR-0072 karar 2'nin bıraktığı takip kararı burasıdır (ADR-0072 eki).

## Açık

- 10 kişilik anonimlik eşiği (ADR-0062'deki aynı soru); SkyMail takip toplamları için de geçerlidir.
- Mezun ve fahri üyeye giden postalarda takip: bugün yalnız `/UYELER` ağacındaki kişi takip edilir.
- "Haberden gönder" ekranı (ADR-0067) geldiğinde core'un kitle ucu kişi başına takip uygunluğunu da dönebilir; bugün SkyMail aynı kuralı uygunluk ucundan sorar.

## Endüstri uygulamasıyla karşılaştırma

**Microsoft karşılığı:** Dynamics 365 Customer Insights – Journeys her uyum profilinde ayrı bir *Tracking* amacı tutar ve üç kip sunar: *Restrictive* (yalnız onaylayan izlenir), *Nonrestrictive* (reddetmeyen izlenir), *Disabled* (herkes). "Will not track" alıcının postasına takip bağlantısı konmaz. *Transactional* amacı rıza denetimini kapatır, takibi kapatmaz. Bizim kipimiz *Nonrestrictive*'in karşılığıdır.

**Uyanlar:**
- Takip edilmeyen alıcıya piksel ve takip bağlantısı konmaz (Dynamics "Will not track").
- Kip bir ayardır, kod iki kipi de destekler (Dynamics *Restrictive*/*Nonrestrictive*; Customer.io açılma rızası kipi).
- İşlem postası da takip edilebilir (Dynamics *Transactional*; SendGrid ve Postmark takibi akış ya da posta türüne bağlamaz).
- Gizli bağlantı sayılmaz, bağlantı başına kapatma vardır (SendGrid parola sıfırlamada `clicktracking` kapatmayı önerir; Postmark `data-pm-no-track`, Mandrill `mc:disable-tracking`).
- Apple MPP ve proxy açılmaları ayrı işaretlenir (Bird `is_prefetched`, Brevo'nun MPP ve bot süzgeci).
- Belirteç adresten bağımsız, tahmin edilemez, sıralı değil (Garante'nin teknik önerisi).

**Sapmalar (hepsi):**
1. **Rıza yok, opt-out (T1).** CNIL kampanya performansı için kişi bazında açılma ölçümünü rızaya bağlıyor, Garante önceden opt-in istiyor, KVKK Çerez Rehberi analitik çerezi açık rızaya bağlıyor. Biz saati, kişiyi ve tıklanan bağlantıyı rızasız tutuyoruz; avukat bu kapsamı onayladı. Kurul 2023/938 duyurunun gönderilmesini meşru menfaatle kabul etti, açılmasının ölçülmesini değil.
2. **Postada geri alma bağlantısı yok (T8).** CNIL her postada kişiye özgü geri alma bağlantısı öneriyor. Bizde itiraz Hesap Merkezi'nden (giriş gerektirir) ya da md. 11 başvurusuyla.
3. **Saat tutuluyor.** CNIL'in teslim edilebilirlik istisnası yalnız son açılmanın gününü rızasız tutmaya izin veriyor; biz saati ve tıklamayı da tutuyoruz, 90 gün.
4. **Panel postasında gönderim başına kapatma yok (Yusuf, 2026-10-21).** Mailchimp, HubSpot, Dynamics ve SendGrid takibi varsayılan açık tutar ama kampanya ya da gönderim başına kapatmaya izin verir. Bizde kapatma alıcı tarafındadır (itiraz) ve gönderen yalnız tek bir bağlantıyı "sayma" diye işaretleyebilir.
5. **Hesap postalarında da piksel.** SendGrid ve Postmark bu postalarda takibi kapatmayı önerir. Biz yalnız bağlantıları dışarıda bırakıyoruz; piksel, giriş kodunun gereksiz klasörüne düşüp düşmediğini görmek içindir.
6. **Tek kip, kulüp geneli.** Dynamics'te kip uyum profili başına seçilir; bizde tek kip ve tek ayar.
7. **Posta başına sorulmuyor.** Outlook okundu bilgisinde alıcı her postada karar verir; bizde bir kez, Hesap Merkezi'nden.
8. **Kapsam Dynamics'ten dar:** web ve UTM izleme yok; hesabı olmayan alıcı hiç izlenmez.

## Considered Options

- **Hiç izleme yok (ADR-0067'nin bıraktığı durum):** KVKK'da en temiz; ama kime ulaşmadığı görünmez. Yusuf kişi bazında görmek istedi.
- **Toplu açılma pikseli (Ghost):** gönderim başına tek piksel, kişisiz sayı. Kime ulaşmadığı görünmez.
- **Opt-in, açık rıza (Dynamics *Restrictive*, CNIL ve Garante'yle uyumlu; önerimizdi):** az kişi açacağı için asıl amaç karşılanmaz; Yusuf "sormaya gerek yok" dedi. Fren olarak kodda kalır.
- **Kişi bazında yalnız onaylayanlar, ötekiler için kişisiz piksel:** iki yol kod demek; tekil açılma sayılamaz.
- **Yalnız duyuru postaları (2026-10-12'deki ilk karar):** hesap postalarının ulaşmama sorunu görünmez kalırdı; Yusuf 2026-10-21'de bütün postalara genişletti.
- **Panel postasında gönderim başına kutu (sektör uygulaması, 2026-10-21'e kadar bizde de):** Yusuf takibin gönderenin seçimine bağlı olmamasını istedi. Kutu yalnız `SKYMAIL_TRACKING_OPERATOR` kapalıyken kalır.
- **Postada "takibi kapat" satırı (CNIL'in geri alma bağlantısının karşılığı; önerimizdi):** Yusuf yalnız Hesap Merkezi ve aydınlatmayı seçti.
- **Tıklamayı yalnız toplu tutmak (kısa link kuralına hizalı):** kısa link herkese açık, e-posta alıcısı belirli bir üye ve itirazı ona bağlı; seçilmedi.
- **1 yıl kişi bazında saklama (2026-10-19 kararı):** avukatın onay tablosuyla 90 gün ve anonimleşmeye indi.
- **Ayrı takip alt alan adı:** DNS, Traefik ve sertifika işi; itibar ayrımı küçük hacimde gereksiz.
- **İmzalı (HMAC) belirteç:** anahtar döndürmede eski postaların bağlantıları ölür, geri alma yine satır bayrağı ister; rastgele belirteç seçildi.

## Kaynaklar

- Microsoft Dynamics 365 Customer Insights – Journeys: [e-posta ve metin rızası, Tracking amacı ve kipler](https://learn.microsoft.com/en-us/dynamics365/customer-insights/journeys/real-time-marketing-email-text-consent)
- CNIL: Délibération n° 2026-042 (e-postadaki takip pikselleri); Garante per la protezione dei dati personali: provvedimento n. 284 (2026)
- KVKK: Çerez Uygulamaları Hakkında Rehber; Kurul kararı 2023/938
- SendGrid (parola sıfırlamada `clicktracking` kapatma önerisi), Postmark (`data-pm-no-track`), Mandrill (`mc:disable-tracking`) belgeleri
