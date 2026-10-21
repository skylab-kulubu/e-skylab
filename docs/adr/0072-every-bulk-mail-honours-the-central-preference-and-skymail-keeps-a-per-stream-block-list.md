---
status: accepted
---

# Her toplu posta gönderim anında merkezi tercihe uyar; SkyMail duyuru akışında adres başına çıkış kaydı tutar ve kimliği olmayan adresin tek tık çıkışını kendisi barındırır

ADR-0067 tercihi core'a koydu (`communication_preferences`, ekranı Hesap Merkezi'nde) ve her haber postasına kategoriye özel tek tık çıkış verdi; ADR-0070 tercihi kanal boyutuyla core'da tuttu. Toplu postada tek tık çıkış başlığı 2026-10-21'de SkyMail'e girdi (skymail-backend #93, skymail-frontend #116; bayrak `SKYMAIL_LIST_UNSUBSCRIBE` varsayılan kapalı). Başlık yalnız satırında core'un imzaladığı bağlantı olan postaya konuyor.

Bugünkü boşluk:

- **Operatör postaları tercihe bakmıyor.** SkyMail panelinden yapılan liste, Keycloak grubu, Forms yanıtlayanları ve onaylı gönderimler duyuru kutusundan (`duyuru@bildirim.yildizskylab.com`) çıkıyor. Ama core'a sorulmuyorlar ve çıkış bağlantıları yok.
- **Alıcıların çoğu yalnız adres.** Liste ve Forms alıcısının çoğunun hesabı yok. Bu postalara core'un bağlantısını koymak onurlandırılmayan bir çıkış olurdu: core kategoriyi kapatır, bir sonraki operatör postası yine gelir. Gmail ve Yahoo çıkışın iki gün içinde uygulanmasını istiyor.
- **Hesabı olmayan adresin çıkabileceği bir yer yok.** core'un tercihi kişiye bağlı; adresin tercihi yok.

Yusuf'un kararı (2026-10-21): abonelikten çıkış "sektörde tam olarak nasılsa tam olarak aynısı" olmalı.

İncelenen ürünlerde iki katman var:

- **Kimliğe bağlı merkezi tercih.** Microsoft Dynamics 365 Customer Insights – Journeys (contact point consent, preference center), HubSpot (subscription types), Amazon SES (contact list ve topic), Mailchimp (audience). Her toplu gönderim bu tercihe uyar, konu bazındadır, tek tık çıkış kayda işler.
- **Gönderim sistemi düzeyinde akış başına engel listesi.** Postmark'ta broadcast stream başına suppression var ve işlem akışını etkilemiyor. SendGrid'de unsubscribe group ve global unsubscribe var; uygulama unutsa da ESP göndermiyor. SES'te hesap düzeyinde suppression list var. Hesabı olmayan adresin çıkışını ESP'nin barındırdığı tek tık uç kaydeder.

Karar (Yusuf, 2026-10-21: ilke; aşağıdaki ayrıntılar bu kaydın önerisidir, sorular "Açık"ta):

1. **İki katman, iki kayıt, iki anlam.**
   - Kimliği olan kişinin tercihi core'dadır. ADR-0067 ve ADR-0070 değişmez.
   - SkyMail, gönderim sistemi olarak, duyuru akışında adres başına bir **çıkış kaydı** tutar. Bu, Suppression'ın `unsubscribed` nedenidir. Kimliği olmayan adresin tek kaydıdır; her duyuru postası göndermeden önce ona da bakar.
   - **Çıkış kaydı tercih değildir.** Kategori, ekip, kanal ya da varsayılan taşımaz. Yalnız "bu adrese duyuru akışından posta gitmez" der.
   - ADR-0067'nin reddettiği "tercihi SkyMail'de tutmak" seçeneği aynen reddedilmiş kalır.
2. **Her posta bir gönderim akışındadır; akışı gönderimin amacı belirler.** Akışı kuyruk önceliği belirlemez.
   - **`islem` akışı:** `hesap@` ve `bilgi@` kutuları. Giriş kodu, doğrulama, Forms ve başvuru durumu, Mail onayı, sertifika, bilet bu akıştadır. Tercihe ve çıkış kaydına bakmaz, çıkış başlığı taşımaz, takip edilmez. Kalıcı ret bastırması bugünkü gibi uygulanır, hesap postası muafiyetiyle.
   - **`duyuru` akışı:** `duyuru@` kutusu. Her posta bir **kategori** taşır: core'un kategorilerinden biri, yani kulüp geneli ya da bir ekip, duyuru ya da haber. Posta tercihe ve çıkış kaydına uyar. RFC 8058 tek tık başlıklarını ve gövdede görünür bir çıkış bağlantısı taşır.
   - **Ticari amaç yoktur** (karar 9).
   - **Operatör postasının amacı:**
     - Liste ve Keycloak grubu gönderimi her zaman duyurudur.
     - Kişilere tek tek gönderimde ve Forms yanıtlayanlarına gönderimde amacı gönderen seçer. İşlem amacı yalnız bu iki hedefte ve "bu posta alıcının kendi başvurusu ya da işlemi hakkındadır" beyanıyla seçilir.
     - Takip isteyen posta duyurudur.
     - Kategoriyi gönderen seçer. Keycloak grubu bir ekipse o ekibin kategorisi önerilir.
3. **Kimliği olan alıcıya core gönderim anında karar verir.**
   - **Kontrol noktası.** Duyuru akışına giren her alıcı, kuyruğa yazılmadan önce core'a sorulur. Kontrol noktası SkyMail'in kuyruğa alma katmanıdır, yani alıcı hangi ekrandan gelirse gelsin aynı yerden geçer.
   - **Eşleme.** Alıcı bir hesabın doğrulanmış adresiyse ya da `sub`'ı biliniyorsa core iki şey döner: posta gidebilir mi, ve kişiye ve kategoriye özel imzalı çıkış bağlantısı. Doğrulanmış adres birincil, okul ya da kişisel adres olabilir (ADR-0044). İki hesaba birden uyan bir adrese posta gitmez.
   - **Posta şu üç durumda gitmez:**
     - hesap devre dışıdır ya da siliniyordur;
     - kanalın ana anahtarı kapalıdır;
     - o kategoride kişinin kendi "kapalı" seçimi geçerlidir. Bu seçim doğrudan o kategoride ya da üst ekipte yapılmış olabilir (ADR-0067 kalıtımı).
   - **Varsayılan tek başına engellemez.** Kitleyi listeyi gönderen seçmiştir; core yalnız çıkışı uygular. Haber gönderiminin kitlesi (ADR-0067) bundan ayrıdır: core'un varsayılanlarıyla çözülür ve değişmez.
   - **Adres.** Posta listedeki adrese gider. Ama kişiye eşleşen adreste tercih kişinindir.
   - **core yanıt vermezse gönderim yazılmaz.** Operatör ya da onaylayan yeniden dener. Onaylı gönderimde soru onay anında sorulur.
   - **48 saat.** Bir gönderim 48 saatten uzun bekletilirse (duraklatma) kalan alıcılar göndermeden önce yeniden sorulur.
4. **Kimliği olmayan alıcı SkyMail'in kaydına ve bağlantısına bağlıdır.**
   - core'un tanımadığı adres, SkyMail'in imzaladığı bir çıkış bağlantısı alır.
   - Tek tık (`POST`, `List-Unsubscribe=One-Click`) ve sayfadaki düğme adresi duyuru akışından çıkarır.
   - `GET` yalnız sayfayı gösterir, hiçbir şeyi değiştirmez: postayı tarayan yazılımlar bağlantıyı açar.
   - Çerez, oturum ve yönlendirme yoktur; yanıt `no-store`'dur.
   - Belirteç adresi açık taşımaz ve süresizdir. Anahtarı OpenBao'dadır ve döndürülmez (ADR-0049).
   - Davet onayıyla giden davet postası (ADR-0062) kendi geri alma bağlantısını taşır; bu karar onu değiştirmez.
5. **Çıkış kaydı yalnız duyuru akışını durdurur.**
   - `unsubscribed` kaydı işlem akışına dokunmaz: giriş kodu ve Forms onayı gitmeye devam eder.
   - Kayıt kuyruğa alırken ve göndermeden hemen önce okunur.
   - Kalıcı ret bastırması (bounce) bütün akışlarda kalır, hesap postası muafiyetiyle (skymail-backend, mevcut).
   - Bir adres sonradan bir hesabın adresi olursa iki kayıt birlikte geçerlidir ve en sıkı olan kazanır.
6. **SkyMail'in kaydı yalnız SkyMail'e gelen çıkışla yazılır.**
   - Kaydı SkyMail'in kendi bağlantısı yazar: tek tık ya da sayfa. İleride alıcı başına şikâyet bildirimi gelirse o da aynı akış kapsamlı kaydı yazar.
   - Kimliği olan kişinin core'daki çıkışı SkyMail'e kopyalanmaz. Tek kayıt core'dadır ve SkyMail her gönderimde sorar (ADR-0071 karar 14: kopya tutulmaz).
   - **Güvenlik ağı kopyada değil, kontrol noktasındadır.** Duyuru akışına giden her satır SkyMail'in kuyruğa alma katmanından geçer. core'a sorulmamış ya da çıkış bağlantısı olmayan satır gönderilmez.
7. **Yeniden abone olmayı yalnız kişinin kendisi yapar.**
   - Kimliği olan kişi bunu Hesap Merkezi'nde yapar (core).
   - Kimliği olmayan adres, aynı bağlantının sayfasındaki "Yeniden abone ol" düğmesini kullanır.
   - Operatör kişinin kendi çıkışını geri alamaz. Panel `unsubscribed` kaydını silemez; bounce kaydını bugünkü gibi silebilir. core'un `admin` kaynağı da kişinin kapattığı kategoriyi açamaz.
8. **Forms postası işlem postasıdır; operatörün Forms yanıtlayanlarına yazdığı posta içeriğine göre ayrılır.**
   - Forms'un kendiliğinden giden postaları işlem postasıdır: başvuru alındı, kabul, ret, iade, yeniden açıldı. Bunları alıcının kendi başvurusu tetikler.
     - Google'ın verdiği işlem postası örneklerinden biri form gönderimi onayıdır.
     - FTC'nin tanımında işlem postası, alıcının kabul ettiği bir işlemi tamamlayan ya da onaylayan iletidir.
     - Bu postalar bugünkü gibi `bilgi@`'dan, başlıksız ve tercihe bakmadan gider.
   - Operatörün Forms yanıtlayanlarına yazdığı posta başvurunun kendisi hakkındaysa işlem postasıdır: yer ya da saat değişikliği, eksik belge, sonuç.
   - Genel duyuru, davet ya da başka bir etkinlik duyurudur. Belirsizse duyurudur.
9. **KVKK ve 6563.**
   - Kulüp postası ticari elektronik ileti değildir: sponsor tanıtımı, ücretli bilet, şirket iş ilanı ya da çekiliş içermez. Gönderen bunu her duyuru gönderiminde beyan eder (ADR-0062, ADR-0067).
   - Ticari içerik olsaydı 6563 sayılı Kanun'un onayı, İYS kaydı ve ret bildiriminin üç iş günü içinde uygulanması gerekirdi. Kulüp tüzel kişi olmadığı için İYS'ye kaydolamaz, bu yüzden ticari amaç yoktur.
   - Duyuru postası Member'a meşru menfaatle gider (ADR-0062). KVKK md. 11'de GDPR'ın doğrudan pazarlamaya itirazı gibi genel bir itiraz hakkı yoktur. Tek tık çıkış meşru menfaat dengesinin önlemidir.
   - Çıkış kaydının amacı adrese yeniden göndermemektir (md. 5/2-f). Kayıt kişi yeniden abone olana ya da hesap silinene kadar tutulur.
   - Hesap silme kişinin adreslerindeki kayıtları da siler; ADR-0051 karar 4 aynen geçerlidir.

Nasıl:

- **core.** Kitleyi kendisi çözen ADR-0067 kitle ucunun yanına, gönderenin seçtiği alıcıları tek tek soran bir iç uç eklenir: `POST /internal/v1/audiences/recipients:resolve`.
  - Uç yalnız SkyMail'in servis hesabına açıktır ve `audience:read` rolünü ister. SkyMail'in servis hesabı bu rolü zaten taşıyor.
  - Gövde: bir kategori, bir kanal ve en çok 1000 alıcı; her alıcı ya adres ya `sub`'dır.
  - Yanıt sorulan sıradadır: kişiye eşleşti mi, gidebilir mi, gitmiyorsa nedeni, ve kişinin bağlantısı.
  - Uç kenardan (`X-Forwarded-*`) `404` döner; log yalnız sayı yazar.
  - Keycloak ya da core yanıt vermezse `503` döner ve SkyMail gönderimi yazmaz.
- **SkyMail.**
  - **Kayıt.** Gönderime `purpose` (`islem` | `duyuru`) ve duyuruda `category` yazılır; gönderen kutusunu `LaneOf` bu alandan okur.
  - **Çıkış kaydı.** `mail_suppressions`'a `unsubscribed` nedeni ve `duyuru` akışı olarak girer. Bu şema expand/contract'a uymazsa aynı denetimi ve aynı panel listesini paylaşan bir kardeş tablo kullanılır.
  - **Tek tık ucu.** SkyMail'in herkese açık yolundadır (`/api/skymail/u/{belirteç}`) ve takip uçlarının (`/t/`) kurallarına uyar: IP saklanmaz, belirteç ve yol loglanmaz.
  - **Satırın bağlantısı.** Satırın `list_unsubscribe_url`'i (skymail-backend #93) ya core'un bağlantısıdır ya SkyMail'inki. Gövdede `.UnsubscribeUrl` olarak durur. Şablon bağlantıyı kullanmıyorsa SkyMail künyeye standart bir çıkış satırı ekler (Postmark gibi).
  - **Bağlantıyı zaten taşıyan satır.** Haber gönderimi (ADR-0067) ve core'un toplu Bildirim'i (ADR-0070) bağlantıyı aynı istekte core'dan alır, bu yüzden yeniden sorulmaz. Ama çıkış kaydı onlara da uygulanır.
  - **Açılış.** Bayrak varsayılan kapalıdır. Açıkken anahtar ve core adresi zorunludur, eksikse açılış durur.
- **Rapor.** Atlananlar nedenleriyle sayılır: kişinin core'daki çıkışı, adresin SkyMail'deki çıkış kaydı, devre dışı hesap, iki hesaba uyan adres. Atlanan alıcı gönderimi "Başarısız" yapmaz. Adres hiçbir loga yazılmaz.

## Consequences

- **Davranış değişir.** Operatörün listesinde ya da grubunda olup çıkış yapmış kişiler artık atlanır ve sayılır. Operatör postaları tek tık başlığı ve görünür çıkış bağlantısı alır; skymail-bounce-isleme 11'in açılış runbook'u bu postalarda da uygulanır.
- **core.** Yeni iç uç ve belgesi (`docs/communication-preferences.md`, `docs/news-audience.md`). Tercih kaydı, belirteci ve tek tık ucu değişmez.
- **SkyMail (skymail-backend).** Şunlar eklenir:
  - gönderim amacı ve kategori;
  - tek kontrol noktası;
  - çıkış kaydı ve herkese açık uç;
  - anahtar;
  - 48 saat kuralı;
  - panel API'sinde neden ve akış;
  - hesap silmede çıkış kayıtlarının silinmesi;
  - belgeler (`README`, `docs/data-lifecycle.md`).
- **Arayüz (skymail-frontend).**
  - Gönderim ekranlarında amaç, kategori ve beyan.
  - Raporda atlanma nedenleri.
  - Bastırma listesinde neden ve akış; çıkış kaydı için "kaldır" düğmesi yok.
  - Künyede "Abonelikten çık".
- **Keycloak.** Değişiklik yok.
- **Ops.** SkyMail çıkış anahtarı OpenBao'ya bir wizard ile girer. Dokploy'da yalnız referans tutulur. Kenarın erişim logu `/api/skymail/u/` yolunu tutmamalıdır.
- **Metinler.** KVKK Aydınlatma Metni'ne "abonelikten çıkış kaydı" girer: amacı, dayanağı ve süresi.
- **Saklama.** ADR-0062'ye şu satır eklenecek: "SkyMail: duyuru akışından çıkış kaydı (adres, akış, zaman, kaynak) | kişi yeniden abone olana ya da hesap silinene kadar | meşru menfaat". ADR-0062 bu kayıtla değişmez.
- **ADR-0067 ve ADR-0051'e tarihli ek** yazılır: çıkış kaydı tercih değildir; karar 4 silmeden sonrası içindir.
- **Bilinen sınırlar.**
  - Hesap silinince çıkış kaydı da silinir, adres elle bir listeye yeniden girebilir. Bu ADR-0051'in kabul ettiği sınırdır; adresin özetini tutmak orada reddedildi.
  - core kapalıyken operatörün duyuru postası gitmez.
- **CONTEXT.md'de değişenler:**
  - Yeni terimler: Message stream (Gönderim akışı), Suppression (Bastırma).
  - Communication preference'a gönderim anında sorulduğu ve SkyMail'e kopyalanmadığı eklenir.

## Açık

- **DKIM kapsamı** (skymail-bounce-isleme 11, S2). Exchange Online, MIME `sendMail`'deki iki başlığı DKIM imzasının `h=` listesine alıyor mu? Belgelerde yazmıyor; ilk başlıklı postada okunacak. Almıyorsa Gmail tek tık düğmesini göstermeyebilir; o zaman ayrı bir gönderen ya da relay kararı gerekir.
- **İşlem amacı.** Operatöre işlem amacının açılması (karar 2) Yusuf'a soruldu. Öneri: yalnız kişilere tek tek gönderimde ve Forms yanıtlayanlarına gönderimde, beyanla.
- **Çıkışın geri alınması.** Panelin kimliği olmayan adresin kendi çıkışını geri alamaması (karar 7) Yusuf'a soruldu. Öneri: alamaz.
- **Member olmayan hesaplar.** Listeye konmuş, Member olmayan hesaplara (konuk, Place kullanıcısı) çıkış yapmadılarsa duyuru gider (karar 3, varsayılan engellemez). Yusuf'a soruldu. Listenin hukuki dayanağı gönderenindir (ADR-0062).

## Endüstri uygulamasıyla karşılaştırma

**Uyanlar (bileşen bileşen):**

1. **Kimliğe bağlı merkezi tercih; gönderimden hemen önce denetim.**
   - Dynamics Customer Insights – Journeys gönderimden hemen önce amaç, konu ve rıza kaydını uygular. Kişi bir segmente yanlışlıkla girmiş olsa da çıkmış kişiye posta gitmez.
   - HubSpot'ta subscription type, SES'te contact list ve topic, Mailchimp'te audience aynı işi görür.
   - Karar 3.
2. **Her toplu postanın bir konusu var; tek tık yalnız o konudan çıkarır.**
   - Örnekler: Dynamics'in purpose ve topic'i, SES'in topic'i, SendGrid'in unsubscribe group'u.
   - Google'ın SSS'sine göre alıcı yalnız postanın ait olduğu listeden çıkarılabilir.
   - Karar 2.
3. **"Kapalı" seçmemiş adrese gönderim.** Dynamics'te varsayılan Commercial amaç nonrestrictive'dir: adres çıkmadıkça gönderir. Karar 3.
4. **İşlem postası tercihe bakmaz ve çıkış başlığı taşımaz.**
   - Dynamics'in varsayılan Transactional amacında denetim kapalıdır ve tek tık başlığı yoktur.
   - SES işlem postasında `ListManagementOptions`'ın verilmemesini söylüyor.
   - Postmark'ın transactional stream'i çıkış bağlantısı istemez.
   - Google tek tık kuralından işlem postasını hariç tutar.
   - Karar 2 ve 8.
5. **Gönderen, postanın amacını her gönderimde seçer.** Dynamics'te amaç ve konu e-postanın ayarıdır. Karar 2.
6. **Gönderim sistemi düzeyinde akış başına engel kaydı; işlem akışı etkilenmez.**
   - Postmark'ta suppression message stream başınadır.
   - Postmark broadcast postasına çıkış bağlantısını kendisi ekler; tıklayan o akışın listesine "Unsubscribed" nedeniyle girer.
   - Karar 1 ve 5.
7. **Kimliği olmayan adresin tek tık ucu gönderim sisteminde barınır.** Postmark, SendGrid ve SES'in barındırdığı çıkış sayfası ve ucu böyledir. Karar 4.
8. **Uygulama unutsa da gönderim sistemi göndermez.**
   - SendGrid, bypass filtresi verilmedikçe suppression listelerini uygular.
   - SES, konudan çıkmış kişiye o konuda gönderime izin vermez.
   - Karar 6: kontrol noktası.
9. **RFC 8058 uygulanır.**
   - `POST` ve tek bir HTTPS adresi kullanılır.
   - Gövde yalnız `List-Unsubscribe=One-Click`'tir.
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
11. **Çıkış süresi.** Çıkış hemen uygulanır. Google 48 saat ister, Yahoo 2 gün, 6563 yönetmeliği 3 iş günü, CAN-SPAM 10 iş günü.
12. **Kişinin kendi çıkışını yalnız kişinin kendisi geri alır.**
    - HubSpot'ta kişinin kendi çıkışını kullanıcı geçersiz kılamaz.
    - Mailchimp'te kişinin audience'a yeniden abone olması gerekir.
    - Postmark'ta şikâyet kaydını gönderen geri alamaz.
    - Karar 7.
13. **Kalıcı ret bütün akışlarda bastırır.** SES'in hesap düzeyindeki suppression list'i (`BOUNCE`) böyle çalışır. Bu kural mevcuttur, bu kayıtla değişmez.

**Sapmalar (hepsi):**

1. **Tercih kişiye bağlı, adrese değil.**
   - Dynamics rızayı adres başına tutar (contact point consent), HubSpot'ta tercih e-posta adresine bağlıdır, SES'in contact'ı bir adrestir.
   - Bizde kişinin iki adresi var (ADR-0044). Çıkış ikisine de uyar, bu yüzden daha sıkıdır. Karar ADR-0067'den gelir.
   - Kimliği olmayan adreste SkyMail'in kaydı adrese bağlıdır, yani sektörle aynıdır.
2. **Kimliği olmayan adreste çıkış akış genelidir, konu bazında değil.**
   - Postmark'la aynıdır. SendGrid'in group'u, SES'in topic'i ve Dynamics'in topic'i konu başınadır.
   - Neden: hesabı olmayan adresin ekip ya da kategori ilişkisi yok, ve konu seçme ekranı yalnız hesabı olana var.
3. **Operatör, kimliği olmayan adresin kendi çıkışını geri alamaz.**
   - Postmark ve SES gönderene bunu bırakıyor; Postmark "yalnız istendiğinde ya da hata olduğunda" diyor.
   - Biz HubSpot ve Mailchimp gibi yaptık. Geri alma isteğinin kanıtı panelde tutulamaz; kişi aynı bağlantıdan bunu kendisi yapar.
4. **İşlem amacı yalnız iki hedefte ve beyanla seçilir.** Dynamics her e-postada her iki amacı da seçtiriyor ve yalnız uyarıyor. Neden: duyuru kutusunun itibarı işlem postasıyla aynı alan adını paylaşıyor (sapma 6), ve liste ile grup gönderiminin işlem diye gitmesi çıkışı atlatmanın en kısa yolu olurdu.
5. **Bağlantı süresizdir.** Dynamics çıkış bağlantılarını altı ayda geçersiz kılıyor. Neden: kulüp postası yıllar sonra açılabilir; core'un bağlantısı da süresiz.
6. **Toplu ve işlem postası aynı alt alan adından çıkıyor.**
   - İkisi de `bildirim.`'den çıkıyor, ayrı kutularla. Yahoo toplu postayı işlem postasından IP'yle ya da DKIM alanıyla ayırmayı öneriyor.
   - Tetik: giriş kodları Gmail ya da Outlook.com'da spama düşmeye başlarsa duyuru ayrı bir alt alana taşınır (skymail-bounce-isleme 11 notu).
7. **Kimliği olan kişinin çıkışı gönderim sisteminin listesine yazılmaz.**
   - SendGrid'de uygulama kendi kayıtlarını API'yle group listesine ekleyebiliyor.
   - Bizde kontrol noktası her gönderimde core'a soruyor (ADR-0071 karar 14).
   - Sonuç: core kapalıyken duyuru postası hiç gitmez. SendGrid'de liste ESP'de durduğu için uygulama kapalıyken de uygulanır.

## Considered Options

- **Bütün operatör postalarını yalnız core'dan geçirmek** (skymail-bounce-isleme 11, S1-A). Kimliği olmayan adresler (dış liste, misafir Forms alıcısı) hiçbir yolla çıkamazdı. Sektörde gönderim sistemi katmanı tam bunun için var.
- **Tercihi SkyMail'de, liste ya da adres başına tutmak** (S1-B, ADR-0067'nin reddi). Kişinin tercihi iki yerde dururdu ve Hesap Merkezi birini görmezdi. Kategori ve ekip kalıtımı SkyMail'e kopyalanırdı.
- **core'un e-posta ana anahtarına tek bir core bağlantısı** (S1-C). Kategoriye özel çıkış (ADR-0067 karar 6) kaybolurdu, ve hesabı olmayan adres yine çıkamazdı.
- **core'daki çıkışları SkyMail'in listesine kopyalamak.** Bu SendGrid'in API ile listeye yazma yoludur. İki kayıt zamanla ayrışırdı, yeniden abone olma iki yerde yapılırdı, ve ADR-0071 karar 14 kopyayı reddediyor.
- **Kimliği olmayan adresin çıkışını core'un Davet onayı kaydına yazmak.** Davet onayı bir onay kaydıdır ve varsayılanı kapalıdır. Rızası olmayan adres için "geri alınan rıza" anlamsızdır. core'un adres anahtarlı ikinci bir "gönderme" kaydı tutması gerekirdi.
- **Kimliği olmayan adreste konu başına çıkış** (SendGrid group, SES topic). Hesabı olmayana bir konu seçme ekranı ve konu kataloğu gerekirdi.
- **Başlığı yalnız core bağlantısı olan postaya koymak** (skymail-backend #93'ün bugünkü sınırı). Operatör postaları çıkışsız kalırdı; bu Gmail ve Yahoo'nun toplu gönderici kuralına uymaz.
- **core yanıt vermezse yine göndermek** (fail open). Bu, onurlandırılmamış bir çıkış olurdu. Takipte (core `tracking:resolve`) core yanıt vermezse kimse takip edilmez ve posta yine gider; orada güvenli yön budur. Çıkışta güvenli yön göndermemektir.
- **Varsayılanı da engel saymak** (Dynamics'in restrictive modeli). Listeye konan ve üyesi olmadığı ekibin kategorisindeki herkes atlanırdı; operatörün seçtiği kitle sessizce boşalırdı.

## Kaynaklar

- Postmark: [Suppressions API](https://postmarkapp.com/developer/api/suppressions-api), [broadcast'te çıkış bağlantısı](https://postmarkapp.com/support/article/1217-why-broadcasts-require-an-unsubscribe-link), [kendi çıkış süreciniz](https://postmarkapp.com/support/article/managing-your-own-unsubscribe-process), [yeniden etkinleştirme](https://postmarkapp.com/updates/reactivate-suppressed-subscribers)
- SendGrid: [suppression türleri ve bypass](https://www.twilio.com/docs/sendgrid/ui/sending-email/index-suppressions), [unsubscribe groups](https://www.twilio.com/docs/sendgrid/ui/sending-email/unsubscribe-groups), [global unsubscribes](https://www.twilio.com/docs/sendgrid/ui/sending-email/global-unsubscribes), [List-Unsubscribe](https://www.twilio.com/docs/sendgrid/ui/sending-email/list-unsubscribe)
- Amazon SES: [list management](https://docs.aws.amazon.com/ses/latest/dg/sending-email-list-management.html), [subscription management](https://docs.aws.amazon.com/ses/latest/dg/sending-email-subscription-management.html), [account-level suppression list](https://docs.aws.amazon.com/ses/latest/dg/sending-email-suppression-list.html)
- Microsoft Dynamics 365 Customer Insights – Journeys: [rıza (contact point consent, enforcement model)](https://learn.microsoft.com/en-us/dynamics365/customer-insights/journeys/real-time-marketing-email-text-consent), [tek tık çıkış](https://learn.microsoft.com/en-us/dynamics365/customer-insights/journeys/one-click-unsubscribe)
- HubSpot: [abonelik tercihleri](https://knowledge.hubspot.com/contacts/manage-your-subscription-preferences-and-types), [kendi çıkışını yapan kişi geçersiz kılınamaz](https://community.hubspot.com/t5/Releases-and-Updates/Easily-resubscribe-contacts-you-manually-opted-out-of/ba-p/418347)
- Mailchimp: [About Unsubscribes](https://mailchimp.com/help/about-unsubscribes/)
- [RFC 8058](https://www.rfc-editor.org/rfc/rfc8058) (tek tık), RFC 2369 (`List-Unsubscribe`)
- Google: [gönderici kuralları](https://support.google.com/a/answer/81126), [SSS: işlem postası, 48 saat, liste](https://support.google.com/a/answer/14229414)
- Yahoo: [Sender Best Practices](https://senders.yahooinc.com/best-practices/)
- Microsoft Outlook.com: [yüksek hacimli göndericiler](https://techcommunity.microsoft.com/blog/outlook/strengthening-email-ecosystem-outlook%E2%80%99s-new-requirements-for-high%E2%80%90volume-senders/4399730) (SPF, DKIM, DMARC zorunlu; görünür çıkış bağlantısı öneri)
- FTC: [CAN-SPAM uyum rehberi](https://www.ftc.gov/business-guidance/resources/can-spam-act-compliance-guide-business) (işlem ya da ilişki iletisinin tanımı)
- Ticari İletişim ve Ticari Elektronik İletiler Hakkında Yönetmelik md. 9 (ret bildirimi, üç iş günü; [RG 04.01.2020, 30998](https://www.turmob.org.tr/arsiv/mbs/resmigazete/30998-30998-1.pdf) değişikliği)
