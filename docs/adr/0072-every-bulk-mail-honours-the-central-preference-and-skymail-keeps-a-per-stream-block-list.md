---
status: accepted
---

# Her toplu posta gönderim anında merkezi tercihe uyar; SkyMail duyuru akışında adres başına çıkış kaydı tutar ve kimliği olmayan adresin tek tık çıkışını kendisi barındırır

ADR-0067 tercihi core'a koydu (`communication_preferences`, ekranı Hesap Merkezi'nde) ve her haber postasına kategoriye özel tek tık çıkış verdi; ADR-0070 tercihi kanal boyutuyla core'da tuttu. Toplu postada tek tık çıkış başlığı 2026-10-21'de SkyMail'e girdi (skymail-backend #93, skymail-frontend #116; bayrak `SKYMAIL_LIST_UNSUBSCRIBE` varsayılan kapalı). Başlık yalnız satırında core'un imzaladığı bağlantı olan postaya konuyor.

Bugünkü boşluk:

- **Operatör postaları tercihe bakmıyor.** SkyMail panelinden yapılan liste, Keycloak grubu, Forms yanıtlayanları ve onaylı gönderimler duyuru kutusundan (`duyuru@bildirim.yildizskylab.com`) çıkıyor. Ama core'a sorulmuyorlar ve çıkış bağlantıları yok.
- **Alıcıların çoğu yalnız adres.** Liste ve Forms alıcısının çoğunun hesabı yok. Bu postalara core'un bağlantısını koymak onurlandırılmayan bir çıkış olurdu: core kategoriyi kapatır, bir sonraki operatör postası yine gelir. Google çıkışın 48 saat içinde uygulanmasını öneriyor, Yahoo 2 gün içinde uygulanmasını şart koşuyor.
- **Hesabı olmayan adresin çıkabileceği bir yer yok.** core'un tercihi kişiye bağlı; adresin tercihi yok.

Yusuf'un kararı (2026-10-21): abonelikten çıkış "sektörde tam olarak nasılsa tam olarak aynısı" olmalı.

İncelenen ürünlerde iki katman var:

- **Kimliğe bağlı merkezi tercih.** Microsoft Dynamics 365 Customer Insights – Journeys (contact point consent, preference center), HubSpot (subscription types), Amazon SES (contact list ve topic), Mailchimp (audience). Her toplu gönderim bu tercihe uyar, konu bazındadır, tek tık çıkış kayda işler.
- **Gönderim sistemi düzeyinde engel listesi.**
  - Postmark'ta suppression broadcast stream başınadır ve işlem akışını etkilemez.
  - SendGrid'de unsubscribe group ve global unsubscribe var; uygulama unutsa da ESP göndermez.
  - SES'in hesap düzeyindeki listesi yalnız kalıcı ret ve şikâyet tutar. Çıkışlar SES'te contact list'te, konu başınadır.
  - Hesabı olmayan adresin çıkışını ESP'nin barındırdığı tek tık uç kaydeder.

Karar (2026-10-21). İlke, S1–S3 cevapları ve karar 10 Yusuf'undur; öteki ayrıntılar bu kaydın ve orkestratörün kararıdır:

1. **İki katman, iki kayıt, iki anlam.**
   - Kimliği olan kişinin tercihi core'dadır. ADR-0067 ve ADR-0070 değişmez.
   - SkyMail, gönderim sistemi olarak, duyuru akışında adres başına bir **çıkış kaydı** tutar. Bu, Suppression'ın `unsubscribed` nedenidir. Kimliği olmayan adresin tek kaydıdır; her duyuru postası göndermeden önce ona da bakar.
   - **Çıkış kaydı tercih değildir.** Kategori, ekip, kanal ya da varsayılan taşımaz. Yalnız "bu adrese duyuru akışından posta gitmez" der.
   - ADR-0067'nin reddettiği "tercihi SkyMail'de tutmak" seçeneği aynen reddedilmiş kalır.
2. **Her posta bir gönderim akışındadır; akışı gönderimin amacı belirler.** Akışı kuyruk önceliği belirlemez.
   - **`islem` akışı:** `hesap@` ve `bilgi@` kutuları. Giriş kodu, doğrulama, Mail onayı, sertifika, bilet ve Forms'un yanıtla tetiklenen postaları bu akıştadır. İşlem postası abonelik tercihine takılmaz ve çıkış başlığı taşımaz. Takip akışa bağlı değildir: bütün postalar takiplidir (Yusuf, 2026-10-21); SkyMail'de `SKYMAIL_TRACKING_SYSTEM` ve `SKYMAIL_TRACKING_OPERATOR` bayraklarıyla, gizli bağlantı istisnasıyla. Takip kararı ayrı bir ADR ile yazılacak. Kalıcı ret bastırması bugünkü gibi uygulanır, hesap postası muafiyetiyle.
   - **`duyuru` akışı:** duyuru kutusu, `skylab@duyuru.yildizskylab.com` (karar 10). Her posta bir **kategori** taşır: core'un kategorilerinden biri, yani kulüp geneli ya da bir ekip, duyuru ya da haber. Posta tercihe ve çıkış kaydına uyar. RFC 8058 tek tık başlıklarını ve gövdede görünür bir çıkış bağlantısı taşır.
   - **Ticari akış yoktur** (karar 9).
   - **Operatör postasının amacı:**
     - Liste ve Keycloak grubu gönderimi her zaman duyurudur.
     - Kişilere tek tek gönderimde ve Forms yanıtlayanlarına gönderimde gönderen "işlem" amacını seçebilir. Bunun için "bu posta alıcının kendi başvurusu ya da işlemi hakkındadır" beyanı gerekir (Yusuf, 2026-10-21). Seçmezse posta duyurudur.
     - Takip amacı belirlemez: işlem amaçlı operatör postası da öteki operatör postaları gibi takiplidir (orkestratör, 2026-10-23).
     - Kategoriyi gönderen seçer. Keycloak grubu bir ekipse o ekibin kategorisi önerilir.
3. **Kimliği olan alıcıya core gönderim anında karar verir.**
   - **Kontrol noktası.** Duyuru akışına giren her alıcı, kuyruğa yazılmadan önce core'a sorulur. Kontrol noktası SkyMail'in kuyruğa alma katmanıdır, yani alıcı hangi ekrandan gelirse gelsin aynı yerden geçer.
   - **Her dağıtım turunda, göndermeden hemen önce yeniden sorulur.**
     - Dağıtıcı, bir turda göndereceği kimlikli duyuru satırlarının hepsini core'a tek bir toplu istekle yeniden sorar. Eşik yoktur.
     - core yanıt vermezse satırlar bekler, gönderilmez.
     - Dynamics her postayı göndermeden hemen önce denetler; biz aynı denetimi tur başına tek istekle yapıyoruz. Toplu şerit dakikada yaklaşık 17 posta gönderdiği için bu, dakikada birkaç küçük istek demektir.
     - Kuyruğa alırken sorulan soru da durur: bağlantıyı ve erken atlamayı o verir.
     - Google'ın 48 saatlik önerisi ve Yahoo'nun 2 günlük şartı dış sınırdır. Bu kuralla hükmün yaşı bir dağıtım turunu geçmez.
   - **Eşleme.** Alıcı bir hesabın doğrulanmış adresiyse ya da `sub`'ı biliniyorsa core iki şey döner: posta gidebilir mi, ve kişiye ve kategoriye özel imzalı çıkış bağlantısı.
     - Doğrulanmış adres şunlardan biri olabilir (ADR-0044): birincil adres (`emailVerified`); YTÜ bağlantısı olan hesabın okul adresi; `personalEmailVerifiedAt` damgalı kişisel adres. Bu, Keycloak giriş formunun kabul ettiği tanımlayıcıların kuralıyla aynıdır.
     - İki hesaba birden uyan bir adrese posta gitmez.
   - **Posta şu üç durumda gitmez:**
     - hesap devre dışıdır ya da siliniyordur;
     - kanalın ana anahtarı kapalıdır;
     - o kategoride kişinin kendi "kapalı" seçimi geçerlidir. Bu seçim doğrudan o kategoride ya da üst ekipte yapılmış olabilir (ADR-0067 kalıtımı).
   - **Varsayılan tek başına engellemez.** Kitleyi listeyi gönderen seçmiştir; core yalnız çıkışı uygular.
     - Bu yüzden listeye konmuş, Member olmayan bir hesap da (konuk, Place kullanıcısı) çıkış yapmadıysa postayı alır (Yusuf, 2026-10-21). Listenin hukuki dayanağı gönderenindir (ADR-0062).
     - Haber gönderiminin kitlesi (ADR-0067) bundan ayrıdır: core'un varsayılanlarıyla çözülür ve değişmez.
   - **Adres.** Posta listedeki adrese gider; kişiye eşleşen adreste tercih kişinindir. ADR-0070 karar 3 ("alıcı kişidir") yeni bildirim ucu içindir. Operatör postası adres tabanlı kalır ve Contact point kullanmaz.
   - **core yanıt vermezse gönderim yazılmaz.** Operatör ya da onaylayan yeniden dener. Onaylı gönderimde soru onay anında sorulur.
4. **Kimliği olmayan alıcı SkyMail'in kaydına ve bağlantısına bağlıdır.**
   - core'un tanımadığı adres, SkyMail'in imzaladığı bir çıkış bağlantısı alır.
   - Tek tık (`POST`, `List-Unsubscribe=One-Click`) ve sayfadaki düğme adresi duyuru akışından çıkarır.
   - `GET` yalnız sayfayı gösterir, hiçbir şeyi değiştirmez: postayı tarayan yazılımlar bağlantıyı açar.
   - Çerez, oturum ve yönlendirme yoktur; yanıt `no-store`'dur.
   - **Belirteç.** Adresi açık taşımaz ve süresizdir. Belirteç anahtarın sürümünü taşır: yeni belirteç geçerli anahtarla imzalanır, eski anahtarlar yalnız doğrulamada tutulur. Böylece anahtar değiştirilse de eski bağlantılar bozulmaz. Anahtarlar OpenBao'dadır (ADR-0049).
   - Davet onayıyla giden davet postası (ADR-0062) kendi geri alma bağlantısını taşır; bu karar onu değiştirmez.
5. **Çıkış kaydı yalnız duyuru akışını durdurur.**
   - `unsubscribed` kaydı işlem akışına dokunmaz: giriş kodu ve Forms onayı gitmeye devam eder.
   - Kayıt kuyruğa alırken ve göndermeden hemen önce okunur.
   - Kalıcı ret bastırması (bounce) bütün akışlarda kalır, hesap postası muafiyetiyle (skymail-backend, mevcut).
   - Bir adres sonradan bir hesabın adresi olursa iki kayıt birlikte geçerlidir ve en sıkı olan kazanır.
6. **SkyMail'in kaydı yalnız SkyMail'e gelen çıkışla yazılır.**
   - Kaydı SkyMail'in kendi bağlantısı yazar: tek tık ya da sayfa. Alıcı başına şikâyet bildirimi (Yahoo CFL) kurulursa o da aynı akış kapsamlı kaydı yazar.
   - Kimliği olan kişinin core'daki çıkışı SkyMail'e kopyalanmaz. Tek kayıt core'dadır ve SkyMail her gönderimde sorar (ADR-0071 karar 14: kopya tutulmaz).
   - **Güvenlik ağı kopyada değil, kontrol noktasındadır.** Duyuru akışına giden her satır SkyMail'in kuyruğa alma katmanından geçer. core'a sorulmamış ya da çıkış bağlantısı olmayan satır gönderilmez.
7. **Yeniden abone olma.**
   - **Kişinin kendisi.** Kimliği olan kişi Hesap Merkezi'nde yapar (core). Kimliği olmayan adres, aynı bağlantının sayfasındaki "Yeniden abone ol" düğmesini kullanır.
   - **Panel, kimliği olmayan adresin çıkışını geri alabilir,** ama yalnız kişi istediğinde ya da bir hata olduğunda (Yusuf, 2026-10-21; Postmark ve SES modeli). Bunun için:
     - ayrı bir yetki gerekir: `skymail:unsubscribes:reactivate` istemci rolü, bir gruba verilir;
     - onay ekranı "Yalnız kişi isterse ya da bir hata olduysa geri al" uyarısını gösterir;
     - gerekçe zorunludur;
     - denetim kaydı kimi, zamanı ve gerekçeyi yazar, adresi yazmaz.
   - **Bounce kaydı** bugünkü gibi `skymail:suppressions:manage` ile kaldırılır.
   - **Kimliği olan kişinin tercihini operatör değiştiremez.** core'da operatörün yazdığı bir yol yoktur.
8. **Forms: yanıtla tetiklenen posta işlemdir, form sahibinin toplu postası duyurudur.**
   - **Forms'un kendiliğinden giden postaları işlem postasıdır:** başvuru alındı, kabul, ret, iade, yeniden açıldı. Bunları alıcının kendi yanıtı tetikler. Forms bunları kendi servis hesabıyla `/v1/mail_tasks/single`'dan gönderir; bugünkü gibi `bilgi@`'dan, başlıksız ve tercihe bakmadan giderler.
     - Google işlem postasına örnek olarak form gönderimi onayını veriyor.
     - Postmark'a göre toplu posta aynı içeriğin birçok alıcıya gitmesidir, ve onu alıcının bir eylemi tetiklemez.
     - CAN-SPAM'in "işlem ya da ilişki iletisi" tanımı ticari işlemler içindir; burada yalnız benzetme olarak anılır.
   - **Form sahibinin yanıtlayanlara yaptığı toplu gönderim duyuru akışındadır.** Bu gönderim Forms'un "mail-source" anlık görüntüsü ve SkyMail'deki gönderim ya da onay yoluyla yapılır. Posta yalnız alıcının kendi başvurusu hakkındaysa gönderen beyanla işlem amacını seçebilir (karar 2): yer ya da saat değişikliği, eksik belge, sonuç. Genel duyuru, davet ya da başka bir etkinlik duyurudur. Belirsizse duyurudur.
9. **KVKK ve 6563.**
   - Kulüp postası ticari elektronik ileti değildir: sponsor tanıtımı, ücretli bilet, şirket iş ilanı ya da çekiliş içermez. Gönderen bunu her duyuru gönderiminde beyan eder (ADR-0062, ADR-0067).
   - Ticari içerik olsaydı 6563 sayılı Kanun'un onayı, İYS kaydı ve ret bildiriminin üç iş günü içinde uygulanması gerekirdi. Kulüp tüzel kişi olmadığı için İYS'ye kaydolamaz; bu yüzden ticari içerik gönderilmez ve ticari akış yoktur.
   - Duyuru postası Member'a meşru menfaatle gider (ADR-0062). KVKK md. 11'de GDPR'ın doğrudan pazarlamaya itirazı gibi genel bir itiraz hakkı yoktur. Tek tık çıkış meşru menfaat dengesinin önlemidir.
   - Çıkış kaydının amacı adrese yeniden göndermemektir (md. 5/2-f). Kayıt şu durumlardan biri olana kadar tutulur: kişi yeniden abone olur, panel kişinin isteğiyle kaydı geri alır, ya da hesap silinir.
   - Hesap silme kişinin adreslerindeki kayıtları da siler. ADR-0051 karar 4 silmeden sonrası için daraltılmış haliyle geçerlidir (ADR-0051 eki).
10. **Duyuru akışı kendi alt alan adından çıkar: `duyuru.yildizskylab.com`** (Yusuf, 2026-10-21).
    - **Önceki kararın yerine geçer.** Yusuf'un 2026-10-20 tarihli "tek alt alan `bildirim.yildizskylab.com`, `duyuru.` yok" kararı (hub SPEC skymail-bounce-isleme §0, "Kesin gönderen düzeni") bu kararla değişir.
    - **Kutu.** Yeni kutu açılmaz. Var olan duyuru kutusunun (`duyuru@bildirim.yildizskylab.com`) birincil adresi `skylab@duyuru.yildizskylab.com` olur, eski adres takma ad olarak kalır. Gönderen adı "SKY LAB Duyurular" değişmez.
    - **İşlem akışı.** `hesap@` ve `bilgi@` `bildirim.`'de kalır.
    - **Gerekçe (Yusuf).** İtibar alan adı başına tutulur; toplu postaya gelen şikâyet giriş kodlarının itibarına geçmemeli. `bildirim.` henüz bir günlük olduğu için taşımanın en ucuz zamanı şimdi.
    - **Sektör.** Postmark her gönderim akışı için ayrı bir alt alan önerir ve alt alanların kendi itibarını kurduğunu yazar. Yahoo toplu postayı IP'yle ya da DKIM alanıyla ayırmayı önerir.
    - **IP ayrımı** Exchange Online'da yapılamaz (Microsoft'un ortak havuzu, sapma 6); DKIM alanı ayrımı yapılır.
    - **Ad.** `haber.` adı reddedildi: Yusuf'a göre her duyuru bir haber değildir.
    - **DNS.** Alt alanın kendi MX, SPF ve DKIM kaydı olur; DMARC ana alandan devralınır.
    - **Isınma.** Yeni alt alanın itibarı sıfırdan başlar, bu yüzden ısınma planı onunla yeniden başlar.
    - **Açılış.** Duyuru akışının production'da açılması bu taşımayı bekler.

Nasıl:

- **core.** Kitleyi kendisi çözen ADR-0067 kitle ucunun yanına, gönderenin seçtiği alıcıları tek tek soran bir iç uç eklenir: `POST /internal/v1/audiences/recipients:resolve`.
  - Uç yalnız SkyMail'in servis hesabına açıktır ve `audience:read` rolünü ister. Rol reconcile betiğinde SkyMail'in servis hesabına zaten verilmiştir.
  - Gövde: bir kategori, bir kanal ve en çok 1000 alıcı; her alıcı ya adres ya `sub`'dır.
  - Yanıt sorulan sıradadır: kişiye eşleşti mi, gidebilir mi, gitmiyorsa nedeni, ve kişinin bağlantısı.
  - Hesabı olmayan adresin Keycloak'ta tek tek aranmaması için core doğrulanmış adreslerin dizinini toplu olarak okur ve kısa bir süre önbellekte tutar.
  - Uç kenardan (`X-Forwarded-*`) `404` döner; log yalnız sayı yazar.
  - Keycloak ya da core yanıt vermezse `503` döner ve SkyMail gönderimi yazmaz.
- **SkyMail.**
  - **Kayıt.** Gönderime `purpose` (`islem` | `duyuru`) ve duyuruda `category` yazılır; gönderen kutusunu `LaneOf` bu alandan okur.
  - **Çıkış kaydı.** Ayrı bir tabloda durur; `mail_suppressions`'a sütun eklenmez. Eski imaj yeni tabloyu bilmez, böylece imaj geri alındığında işlem postası durmaz. Panel iki tabloyu tek liste olarak gösterir.
  - **Tek tık ucu.** SkyMail'in herkese açık yolundadır (`/api/skymail/u/{belirteç}`) ve takip uçlarının (`/t/`) kurallarına uyar: IP saklanmaz, belirteç ve yol loglanmaz.
  - **Satırın bağlantısı.** Satırın `list_unsubscribe_url`'i (skymail-backend #93) ya core'un bağlantısıdır ya SkyMail'inki. Gövdede `.UnsubscribeUrl` olarak durur. Şablon bağlantıyı kullanmıyorsa SkyMail künyeye standart bir çıkış satırı ekler (Postmark gibi).
  - **Bağlantıyı zaten taşıyan satır.** Haber gönderimi (ADR-0067) ve core'un toplu Bildirim'i (ADR-0070) bağlantıyı aynı istekte core'dan alır, bu yüzden kuyruğa alırken yeniden sorulmaz. Dağıtıcının her turdaki yeniden sorgusu ve çıkış kaydı onlara da uygulanır.
  - **Açılış.** Bayrak varsayılan kapalıdır. Açıkken anahtar ve core adresi zorunludur, eksikse açılış durur.
- **Rapor.** Atlananlar nedenleriyle sayılır: kişinin core'daki çıkışı, adresin SkyMail'deki çıkış kaydı, devre dışı hesap, iki hesaba uyan adres. Atlanan alıcı gönderimi "Başarısız" yapmaz. Adres hiçbir loga yazılmaz.

## Consequences

- **Davranış değişir.** Operatörün listesinde ya da grubunda olup çıkış yapmış kişiler artık atlanır ve sayılır. Operatör postaları tek tık başlığı ve görünür çıkış bağlantısı alır; skymail-bounce-isleme 11'in açılış runbook'u bu postalarda da uygulanır.
- **core.** Yeni iç uç, adres dizini önbelleği ve belgesi (`docs/news-audience.md`, `docs/communication-preferences.md`). Tercih kaydı, belirteci ve tek tık ucu değişmez.
- **SkyMail (skymail-backend).** Şunlar eklenir:
  - gönderim amacı ve kategori;
  - tek kontrol noktası ve dağıtıcıda her turda yeniden sorgu;
  - çıkış kaydı tablosu ve herkese açık uç;
  - anahtar halkası;
  - panelin yetkili ve gerekçeli geri alması;
  - panel API'sinde neden ve akış;
  - hesap silmede çıkış kayıtlarının silinmesi;
  - belgeler (`README`, `docs/data-lifecycle.md`).
- **Arayüz (skymail-frontend).**
  - Gönderim ekranlarında amaç, kategori ve beyan.
  - Raporda atlanma nedenleri.
  - Bastırma listesinde neden ve akış; çıkış kaydı için uyarılı ve gerekçeli "geri al".
  - Künyede "Abonelikten çık".
- **Keycloak.** `skymail` istemcisine yeni rol: `skymail:unsubscribes:reactivate`, bir gruba verilir. Henüz kodlanmamış `skymail:suppressions:manage` ile aynı reconcile değişikliğinde girer.
- **Ops.**
  - Duyuru alt alanı (karar 10): DNS, M365'te kabul edilen alan adı, duyuru kutusunun adres değişikliği, Dokploy'da `SKYMAIL_FROM_DUYURU`, ısınma.
  - SkyMail çıkış anahtarı OpenBao'ya bir wizard ile girer; wizard yeni anahtar sürümü de ekler. Dokploy'da yalnız referans tutulur.
  - Kenarın erişim logu `/api/skymail/u/` yolunu tutmamalıdır.
- **Metinler.** KVKK Aydınlatma Metni'ne "abonelikten çıkış kaydı" girer: amacı, dayanağı ve süresi. Duyuru akışının production'da açılması bu metnin yayımlanmasını bekler.
- **Saklama.** ADR-0062'ye şu satır eklenecek: "SkyMail: duyuru akışından çıkış kaydı (adres, akış, zaman, kaynak) | kişi yeniden abone olana, kişinin isteğiyle geri alınana ya da hesap silinene kadar | meşru menfaat". ADR-0062 bu kayıtla değişmez.
- **ADR-0067 ve ADR-0051'e tarihli ek** yazılır: çıkış kaydı tercih değildir; ADR-0051 karar 4 silmeden sonrası için daraltılır.
- **core'un çıkış anahtarı** bugün "hiç döndürülmez" kuralında (`COMMUNICATION_PREFERENCE_KEY`). Aynı anahtar halkasına geçmesi ayrı bir iştir.
- **Bilinen sınırlar.**
  - Hesap silinince çıkış kaydı da silinir, adres elle bir listeye yeniden girebilir (sapma 9).
  - core kapalıyken operatörün duyuru postası gitmez.
  - SkyMail imajı geri alınırsa çıkış kaydı o süre uygulanmaz. Bu yüzden geri alma önce bayrakla yapılır.
- **CONTEXT.md'de değişenler:**
  - Yeni terimler: Message stream (Gönderim akışı), Suppression (Bastırma).
  - Communication preference'a gönderim anında sorulduğu ve SkyMail'e kopyalanmadığı eklenir.

## Açık

- **DKIM kapsamı** (skymail-bounce-isleme 11, S2). Exchange Online, MIME `sendMail`'deki iki başlığı DKIM imzasının `h=` listesine alıyor mu? Belgelerde yazmıyor; ilk başlıklı postada okunacak. Almıyorsa Gmail tek tık düğmesini göstermeyebilir; o zaman ayrı bir gönderen ya da relay kararı gerekir.
- **Kimliği olmayan adresin silme başvurusu.** Böyle bir kişi bilgi@'ya KVKK md. 11/e başvurusu yaparsa yol, karar 7'deki yetkili geri almadır; gerekçeye "silme başvurusu" yazılır. Ama kayıt silinince çıkış da kalkar. Adresin listelerden de silinmesi ve yeniden eklenmemesi elle yapılır. Bu, ADR-0051'in kabul ettiği sınırın aynısıdır.
- **Şikâyet geri bildirimi.** Yahoo CFL kulübün DKIM alanıyla kurulabilir mi? Ayrı bir takip bileti açıldı.

## Endüstri uygulamasıyla karşılaştırma

**Uyanlar (bileşen bileşen):**

1. **Kimliğe bağlı merkezi tercih; göndermeden önce denetim.**
   - Dynamics Customer Insights – Journeys gönderimden hemen önce amaç, konu ve rıza kaydını uygular. Kişi bir segmente yanlışlıkla girmiş olsa da çıkmış kişiye posta gitmez.
   - Bizde core hükmü her dağıtım turunda göndermeden hemen önce toplu olarak yeniden sorulur, SkyMail kaydı da göndermeden hemen önce okunur.
   - HubSpot'ta subscription type, SES'te contact list ve topic, Mailchimp'te audience aynı işi görür.
   - Karar 3 ve 5.
2. **Her toplu postanın bir konusu var; tek tık yalnız o konudan çıkarır.**
   - Örnekler: Dynamics'in purpose ve topic'i, SES'in topic'i, SendGrid'in unsubscribe group'u.
   - Google'ın SSS'sine göre alıcı yalnız postanın ait olduğu listeden çıkarılabilir. Bu bir alt sınırdır, daha geniş çıkarmak da kurala uyar.
   - Karar 2.
3. **"Kapalı" seçmemiş adrese gönderim.** Dynamics'te varsayılan Commercial amaç nonrestrictive'dir: adres çıkmadıkça gönderir. Karar 3.
4. **İşlem postası tercihe bakmaz ve çıkış başlığı taşımaz.**
   - Dynamics'in varsayılan Transactional amacında denetim kapalıdır ve tek tık başlığı yoktur.
   - SES'e göre işlem postasında `ListManagementOptions` verilmeyebilir.
   - Postmark'ın transactional stream'i çıkış bağlantısı istemez.
   - Google tek tık kuralından işlem postasını hariç tutar. Örnekleri arasında form gönderimi onayı var.
   - Karar 2 ve 8.
5. **Gönderen, postanın amacını her gönderimde seçer.** Dynamics'te amaç ve konu e-postanın ayarıdır. Karar 2.
6. **Gönderim sistemi düzeyinde akış başına engel kaydı; işlem akışı etkilenmez.**
   - Postmark'ta suppression message stream başınadır.
   - Postmark broadcast postasına çıkış bağlantısını kendisi ekler.
   - Postmark'ın Suppressions API'si nedeni ve kökeni ayrı tutar: `ManualSuppression` ve `Recipient`.
   - Karar 1 ve 5.
7. **Kimliği olmayan adresin tek tık ucu gönderim sisteminde barınır.** Postmark, SendGrid ve SES'in barındırdığı çıkış sayfası ve ucu böyledir. Karar 4.
8. **Uygulama unutsa da gönderim sistemi göndermez.**
   - SendGrid, bypass filtresi verilmedikçe suppression listelerini uygular.
   - SES, konudan çıkmış kişiye o konuda gönderime izin vermez.
   - Karar 6: kontrol noktası.
9. **RFC 8058 uygulanır.**
   - `POST` ve tek bir HTTPS adresi kullanılır.
   - Gövde yalnız `List-Unsubscribe=One-Click`'tir; multipart ve form-encoded ikisi de kabul edilir.
   - Yönlendirme, çerez ve kimlik doğrulama yoktur.
   - Belirteç opaktır ve alıcıyla listeyi tanıtır.
   - İki başlık DKIM imzasının `h=` listesindedir.
   - `GET` hiçbir şeyi değiştirmez: RFC, istenmeyen posta yazılımlarının başlıktaki adresleri kendiliğinden açtığını yazar.
   - Karar 4.
10. **Gövdede görünür çıkış bağlantısı.**
    - Google ve Yahoo bunu ister.
    - Dynamics künyeye tercih merkezi bağlantısını kendisi koyar.
    - Postmark bağlantıyı her broadcast postasına kendisi ekler.
    - SES bağlantıyı yer tutucuyla ekler.
11. **Çıkış süresi.**
    - SkyMail kaydı da core'daki çıkış da göndermeden hemen önce, bir sonraki dağıtım turunda uygulanır. Tek istisna yeni doğrulanmış bir adresin kişiye eşlenmesidir (sapma 1).
    - Dış sınırlar: Google 48 saat önerir, Yahoo 2 gün şart koşar, 6563 yönetmeliği 3 iş günü, CAN-SPAM 10 iş günü.
12. **Gönderen, kişinin çıkışını yalnız kişi isteyince ya da bir hata olunca geri alır.**
    - Postmark: "only reactivate email addresses when asked to do so, or when mistakes happen". SES contact tercihini API'yle değiştirtir. SendGrid global ve group çıkışlarını panelden kaldırtır. Dynamics rıza kaydını düzenletir ve denetim geçmişi tutar.
    - Bizde bu ayrı bir yetki, gerekçe ve denetim kaydı ister.
    - HubSpot ve Mailchimp gönderene izin vermez, kişi kendisi geri döner.
    - Karar 7.
13. **Kalıcı ret bütün akışlarda bastırır.** SES'in hesap düzeyindeki suppression list'i (`BOUNCE`) böyle çalışır. Bu kural mevcuttur, bu kayıtla değişmez.
14. **Duyuru akışı ayrı alt alan adından çıkar.** Postmark akış başına alt alan önerir; Yahoo DKIM alanıyla ayırmayı önerir. Karar 10.
15. **Bağlantı uzun ömürlüdür.**
    - RFC 8058 bir süre koymaz.
    - CAN-SPAM bağlantının gönderimden sonra en az 30 gün çalışmasını ister.
    - Google: çıkış bağlantısı uzun süre çalışmazsa postalar tek tık şartını karşılamamış sayılır. Spam işaretlenmezler, ama gönderen teslim sorunlarında Google'dan destek alamaz. Google bir süre belirtmiyor.
    - Anahtar halkası, anahtar değişse de bağlantıyı açık tutar.
    - Karar 4.

**Sapmalar (hepsi).** (a) bir ADR'ye ya da teknik kısıta dayanır; (b) sağlayıcılar arasında tek bir ortak yol olmadığı yerde yapılmış bir seçimdir.

1. **(a) Tercih kişiye bağlı, adrese değil.**
   - Dynamics rızayı adres başına tutar (contact point consent), HubSpot'ta tercih e-posta adresine bağlıdır, SES'in contact'ı bir adrestir.
   - Bizde kişinin iki adresi var (ADR-0044) ve tercih ADR-0067'den gelir. Çıkış iki adrese de uyar, bu yüzden daha sıkıdır.
   - Bunun bir sonucu daha var: iki hesaba uyan bir adrese posta gitmez. Adres anahtarlı ürünlerde böyle bir durum yoktur.
   - Kimliği olmayan adreste SkyMail'in kaydı adrese bağlıdır, yani sektörle aynıdır.
   - **Adres → kişi eşlemesi.** Kişiye bağlı tercih bir eşleme ister. Adres anahtarlı ürünlerde böyle bir adım yoktur. core bu eşlemeyi doğrulanmış adreslerin bir dizininden yapar. Dizin en çok 5 dakika, yenileme başarısızsa en çok 15 dakika eskidir.
     - O pencerede yeni doğrulanmış bir adres hesapsız sayılır. Kişi core'da önceden çıkmışsa ve bu adres bir operatör listesindeyse, posta gider. Kişi postadaki SkyMail bağlantısıyla çıkabilir.
     - Keycloak'ta devre dışı bırakma da en çok aynı süre içinde etkili olur.
     - Bu düşük riskli bir gecikmedir. Kişinin var olan adreslerindeki çıkışı ve silinmesi gecikmez: tercih ve silinme her soruda tazedir.
2. **(b) Kimliği olmayan adreste çıkış akış genelidir, konu bazında değil.**
   - Postmark'la birebir aynıdır.
   - SES, SendGrid ve Dynamics çıkışı konu ya da group başına tutar, hesabı olmayan adres için de.
   - Neden: adres × kategori kaydı SkyMail'de ikinci bir tercih ve kalıtımın bir kopyası olurdu. ADR-0067 bunu reddediyor, karar 1 de "çıkış kaydı tercih değildir" diyor.
3. **(b) Kimliği olan kişinin tercihini operatör değiştiremez.** Kimliği olmayan adreste ise panel, Postmark ve SES gibi, kişi isteyince geri alabilir (karar 7). İki katman ayrı olduğu için iki model de tutarlıdır.
   - Dynamics rıza kaydını kullanıcıya düzenletir. HubSpot kişinin kendi çıkışını kullanıcıya geçersiz kılmaz.
   - Bizde tercih ekranı Hesap Merkezi'ndedir (ADR-0067) ve core'da operatör yolu yoktur.
4. **(b) İşlem amacı yalnız iki hedefte ve beyanla seçilir.**
   - Dynamics amacı her e-postada seçtirir ve hedefe göre kısıt koymaz.
   - Postmark toplu postayı "aynı içerik birçok alıcıya, alıcının bir eylemiyle tetiklenmeden" diye tanımlar ve işlem trafiğini ayırmayı önerir. Bu tanıma göre operatörün Forms yanıtlayanlarına yazdığı posta toplu postadır.
   - Neden (Yusuf, 2026-10-21): başvurunun kendisi hakkındaki operatör postası (yer değişikliği, sonuç) alıcı açısından işlem postasıdır. Google da postanın türüne alıcının karar verdiğini söylüyor. İstisna dar ve beyana bağlı; liste ve grup bu yoldan gidemez.
5. **(b) Bağlantı süresizdir.** Dynamics çıkış bağlantılarını altı ayda geçersiz kılıyor. Postmark, SendGrid, SES, HubSpot ve Mailchimp bir süre belgelemiyor; core'un bağlantısı da süresiz.
6. **(a) Akışlar IP'yle ayrılmıyor.** Google, birden çok IP kullanılıyorsa her tür için ayrı IP önerir; Yahoo IP'yle ya da DKIM alanıyla ayırmayı önerir. Exchange Online'ın IP'leri Microsoft'un ortak havuzudur. DKIM alanı ayrılır (karar 10), yani Yahoo'nun önerisinin DKIM yarısı uygulanır.
7. **(a) Toplu posta Exchange Online'dan çıkıyor.**
   - **Microsoft ne diyor** (Exchange Online sınırları):
     - İleti hızı sınırının dipnotu genel ve "ticari" ile sınırlı değil: "Exchange Online isn't suited to accommodate bulk-mailing scenarios".
     - Toplu ticari posta (ör. bülten) için üçüncü taraf sağlayıcı öneriliyor.
     - Sınırları aşan dış gönderim için Azure Communication Services öneriliyor.
   - **Sınırlar:**
     - Kutu başına dakikada 30 ileti ve 24 saatte 10.000 alıcı.
     - Kiracı geneli TERRL (Tenant External Recipient Rate Limit): kiracının 24 saatlik kayan pencerede gönderebileceği en çok dış alıcı. Kabul edilen alan adı olmayan her adres dış alıcıdır. Sınır lisans sayısına bağlıdır, grup üyeleri tek tek sayılır.
     - Bizim kiracıda TERRL 10.000 (ölçüm 2026-10-20). İnsan kutularıyla ortaktır. SkyMail'in günlük bütçesi 9.000, toplu şeridin payı 6.300.
   - **Dayanak (a):** ADR-0070'in reddettiği seçenekler.
     - Self-host Novu (seçenek C): tek sunucuya sığmıyor.
     - SaaS (seçenek D: Knock, Courier, SuprSend, OneSignal): üye verisini yurt dışındaki bir işleyene taşıyor (KVKK md. 9).
     - Azure Communication Services: 2028-09-30'da emekliye ayrılıyor.
     - Bu yüzden kendi motorumuz Exchange Online kutularından gönderiyor. Duyuru ticari değil ve hacim bu sınırların altında tutuluyor.
     - Tetik: hacim TERRL'ye yaklaşırsa ya da Microsoft kısarsa, gönderim sağlayıcısı kararı yeniden açılır.
8. **(a) Kimliği olan kişinin çıkışı gönderim sisteminin listesine yazılmaz.**
   - SendGrid'de uygulama kendi kayıtlarını API'yle group listesine ekleyebiliyor. Bizde kontrol noktası her gönderimde core'a soruyor (ADR-0071 karar 14).
   - Sonuç: core kapalıyken duyuru postası gitmez. Dynamics ve HubSpot'ta da rıza ve gönderim aynı üründedir; rıza deposu yanıt vermezse gönderim de durur.
9. **(a) Hesap silinince çıkış hatırlanmaz.**
    - Dynamics ve HubSpot'ta kişi silinse de çıkış adreste kalır. Bizde adres elle bir listeye yeniden girebilir.
    - Neden: ADR-0051 karar 4 ve orada reddedilen "adresin özetini tutmak".
10. **(a) Şikâyet (FBL) bastırması yok.**
    - Postmark `SpamComplaint`, SES `COMPLAINT`, SendGrid spam report ile bastırır.
    - Gmail alıcı başına şikâyet bildirmiyor; Exchange Online kiracıya şikâyet geri bildirimi iletmiyor.
    - Yahoo CFL DKIM alanına göre kaydoluyor; kulübün alanıyla kurulması takip biletinde.

## Considered Options

- **Bütün operatör postalarını yalnız core'dan geçirmek** (skymail-bounce-isleme 11, S1-A). Kimliği olmayan adresler (dış liste, misafir Forms alıcısı) hiçbir yolla çıkamazdı. Sektörde gönderim sistemi katmanı tam bunun için var.
- **Tercihi SkyMail'de, liste ya da adres başına tutmak** (S1-B, ADR-0067'nin reddi). Kişinin tercihi iki yerde dururdu ve Hesap Merkezi birini görmezdi. Kategori ve ekip kalıtımı SkyMail'e kopyalanırdı.
- **core'un e-posta ana anahtarına tek bir core bağlantısı** (S1-C). Kategoriye özel çıkış (ADR-0067 karar 6) kaybolurdu, ve hesabı olmayan adres yine çıkamazdı.
- **core'daki çıkışları SkyMail'in listesine kopyalamak.** Bu SendGrid'in API ile listeye yazma yoludur. İki kayıt zamanla ayrışırdı, yeniden abone olma iki yerde yapılırdı, ve ADR-0071 karar 14 kopyayı reddediyor.
- **Kimliği olmayan adresin çıkışını core'un Davet onayı kaydına yazmak.** Davet onayı bir onay kaydıdır ve varsayılanı kapalıdır. Rızası olmayan adres için "geri alınan rıza" anlamsızdır. core'un adres anahtarlı ikinci bir "gönderme" kaydı tutması gerekirdi.
- **Kimliği olmayan adreste konu başına çıkış** (SendGrid group, SES topic). Sapma 2'ye bakın.
- **Panelin çıkışı hiç geri alamaması** (HubSpot, Mailchimp). Bu ilk öneriydi. Yusuf Postmark ve SES modelini seçti: yetkili, uyarılı ve gerekçeli geri alma.
- **core hükmünü 48 saate kadar kullanmak** (ilk taslak) ya da **5 dakikalık bir eşikle yeniden sormak** (ikinci taslak). 48 saat dış sınırdır, hedef değildir. İncelenen her sağlayıcı gönderim anında uyguluyor. Tur başına tek toplu istek zaten ucuz olduğu için eşik gerekmiyor. İkisi de ADR-0071 karar 14'ün "liste her zaman günceldir" kuralıyla gerilimdeydi.
- **Çıkış kaydını `mail_suppressions`'a sütun olarak eklemek.** Eski imaj nedene bakmadan bütün satırları okur. İmaj geri alınırsa çıkmış adrese Forms onayı da dahil bütün postalar dururdu.
- **Anahtarı hiç döndürmemek.** Bir sızıntıda ya bütün eski bağlantılar bozulurdu (Google'ın kuralı, CAN-SPAM'in 30 günü) ya da anahtar sızık kalırdı.
- **Duyuruyu `bildirim.`'de bırakıp ayrımı bir tetiğe bağlamak** (giriş kodları spama düşerse). Bu, Yusuf'un 2026-10-20 kararıydı; 2026-10-21'de karar 10 ile değişti. Tetik zararı ancak oluştuktan sonra ölçer; ayrım ise düşük maliyetli ve `bildirim.` henüz bir günlük.
- **Alt alan adı olarak `haber.`.** Reddedildi: her duyuru bir haber değil (Yusuf, 2026-10-21).
- **Duyuru için yeni bir kutu açmak.** Gerekmez. Exchange'de bir kutunun birden çok adresi olur (proxy addresses): birincil adres değişir, eski adres ikincil kalır. Eski adrese gelen yanıtlar ve NDR'ler aynı kutuya düşer; uygulama yetkisi (etikete bağlı kapsam) ve posta akışı kuralı kutuyla birlikte kalır.
- **Başlığı yalnız core bağlantısı olan postaya koymak** (skymail-backend #93'ün bugünkü sınırı). Operatör postaları çıkışsız kalırdı; bu Gmail ve Yahoo'nun toplu gönderici kuralına uymaz.
- **core yanıt vermezse yine göndermek** (fail open). Bu, onurlandırılmamış bir çıkış olurdu. Takipte (core `tracking:resolve`) core yanıt vermezse kimse takip edilmez ve posta yine gider; orada güvenli yön budur. Çıkışta güvenli yön göndermemektir.
- **Varsayılanı da engel saymak** (Dynamics'in restrictive modeli). Listeye konan ve üyesi olmadığı ekibin kategorisindeki herkes atlanırdı; operatörün seçtiği kitle sessizce boşalırdı.

## Kaynaklar

- Postmark: [Suppressions API](https://postmarkapp.com/developer/api/suppressions-api), [broadcast'te çıkış bağlantısı](https://postmarkapp.com/support/article/1217-why-broadcasts-require-an-unsubscribe-link), [kendi çıkış süreciniz](https://postmarkapp.com/support/article/managing-your-own-unsubscribe-process), [yeniden etkinleştirme](https://postmarkapp.com/updates/reactivate-suppressed-subscribers), [toplu posta tanımı](https://postmarkapp.com/support/article/can-i-send-bulk-emails), [akış başına alt alan](https://postmarkapp.com/guides/best-practices-for-broadcast-sending)
- SendGrid: [suppression türleri ve bypass](https://www.twilio.com/docs/sendgrid/ui/sending-email/index-suppressions), [unsubscribe groups](https://www.twilio.com/docs/sendgrid/ui/sending-email/unsubscribe-groups), [global unsubscribes](https://www.twilio.com/docs/sendgrid/ui/sending-email/global-unsubscribes), [List-Unsubscribe](https://www.twilio.com/docs/sendgrid/ui/sending-email/list-unsubscribe)
- Amazon SES: [list management](https://docs.aws.amazon.com/ses/latest/dg/sending-email-list-management.html), [subscription management](https://docs.aws.amazon.com/ses/latest/dg/sending-email-subscription-management.html), [account-level suppression list](https://docs.aws.amazon.com/ses/latest/dg/sending-email-suppression-list.html)
- Microsoft Dynamics 365 Customer Insights – Journeys: [rıza (contact point consent, enforcement model)](https://learn.microsoft.com/en-us/dynamics365/customer-insights/journeys/real-time-marketing-email-text-consent), [tek tık çıkış](https://learn.microsoft.com/en-us/dynamics365/customer-insights/journeys/one-click-unsubscribe)
- Microsoft Exchange Online: [sınırlar ve toplu posta önerisi](https://learn.microsoft.com/en-us/office365/servicedescriptions/exchange-online-service-description/exchange-online-limits)
- HubSpot: [abonelik tercihleri](https://knowledge.hubspot.com/contacts/manage-your-subscription-preferences-and-types), [kendi çıkışını yapan kişi geçersiz kılınamaz](https://community.hubspot.com/t5/Releases-and-Updates/Easily-resubscribe-contacts-you-manually-opted-out-of/ba-p/418347)
- Mailchimp: [About Unsubscribes](https://mailchimp.com/help/about-unsubscribes/)
- [RFC 8058](https://www.rfc-editor.org/rfc/rfc8058) (tek tık), RFC 2369 (`List-Unsubscribe`)
- Google: [gönderici kuralları](https://support.google.com/a/answer/81126) (tür başına From, birden çok IP varsa tür başına IP), [SSS: işlem postası, 48 saat önerisi, liste](https://support.google.com/a/answer/14229414)
- Yahoo: [Sender Best Practices](https://senders.yahooinc.com/best-practices/) (2 gün şartı, IP ya da DKIM alanıyla ayırma), [Complaint Feedback Loop](https://senders.yahooinc.com/complaint-feedback-loop/)
- Microsoft Outlook.com: [yüksek hacimli göndericiler](https://techcommunity.microsoft.com/blog/outlook/strengthening-email-ecosystem-outlook%E2%80%99s-new-requirements-for-high%E2%80%90volume-senders/4399730) (gövde okunamadı; ikincil özetlere göre SPF, DKIM ve DMARC zorunlu, görünür çıkış bağlantısı öneri)
- FTC: [CAN-SPAM uyum rehberi](https://www.ftc.gov/business-guidance/resources/can-spam-act-compliance-guide-business) (işlem ya da ilişki iletisinin tanımı, 10 iş günü, bağlantının en az 30 gün çalışması)
- Ticari İletişim ve Ticari Elektronik İletiler Hakkında Yönetmelik md. 9 (ret bildirimi, üç iş günü; [RG 04.01.2020, 30998](https://www.turmob.org.tr/arsiv/mbs/resmigazete/30998-30998-1.pdf) değişikliği)

## Ek (2026-10-24): karar 9, sponsor teşekkürü ve tanıtım izni (ADR-0062 eki)

Karar 9'un ilk iki maddesi ("sponsor tanıtımı, ücretli bilet, şirket iş ilanı ya da çekiliş içermez" ve "ticari içerik gönderilmez") şu kuralla değişir (avukat cevabı 13, Yusuf 2026-10-23; KVKK Aydınlatma Metni s6 §5.10). Karar 9'un öteki maddeleri değişmez.

- **Asıl amaç belirler.** Asıl amacı bilgilendirme olan duyurudaki kısa sponsor teşekkürü ya da sponsor logosu tanıtım sayılmaz. Bu posta duyuru akışından, tercihe göre bütün alıcılara gider.
- **Tanıtım yalnız izin verene gider.** Asıl amacı tanıtım olan içerik (indirim kodu, şirket iş ilanı, satış, çekiliş) yalnız tanıtım izni veren kişiye gider. Ayrı bir ticari akış açılmaz: tanıtım postası duyuru akışından çıkar. Kitle, karar 3'ün süzgecinden geçen alıcılar ile core'daki tanıtım izni listesinin gönderim anındaki kesişimidir. core yanıt vermezse tanıtım postası gönderilmez. Postadaki çıkış bağlantısı tanıtım iznini kapatır.
- **Tanıtım izni kişi başına tek bir izindir** ve işaretsiz kutuyla alınır (ADR-0062 eki).
- **Beyan değişir.** Gönderen artık "ticari içerik yok" değil, "postanın asıl amacı tanıtım değil" beyan eder. Kısa teşekkür ve logo bu beyana engel değildir.
- **İYS.** Kulüp İYS'ye kayıtlı bir hizmet sağlayıcı değildir. Tanıtım içeriği yalnız kulübün kendi tanıtım iznine dayanarak gider.
- **Açık:** karar 9'daki "ücretli bilet" örneği s6 §5.10'un listesinde yok. Kulübün kendi ücretli etkinliğinin duyurusu asıl amaç ölçüsüne göre değerlendirilir; ayrı bir kural gerekiyorsa Yusuf karar verir.
