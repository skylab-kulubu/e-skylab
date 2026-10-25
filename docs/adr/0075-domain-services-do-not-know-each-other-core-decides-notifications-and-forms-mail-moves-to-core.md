---
status: accepted
---

# Alan servisleri birbirini bilmez; bildirim kararını ve servisler arası koordinasyonu core verir, teslimi iletişim servisi yapar; Forms'un postaları ve form yanıtlayanlarına toplu gönderim core'a geçer

Bugün Forms kendi postalarını SkyMail'e doğrudan gönderiyor. ADR-0070 karar 3 ve ADR-0072 karar 8 bunu yazılı olarak bıraktı. Bunlar beş posta:

- form kopyası (`forms.form-copy`);
- durum değişti (`forms.status-changed`);
- akış yeniden açıldı (`forms.status-changed`, `status=reopened`);
- deneme güncellendi (`forms.attempt-update`);
- değerlendiricilere bekleyen yanıt hatırlatması (`forms.pending-reminder`, 36 saat kuralı).

Hepsi Forms'un bellek içi kuyruğundan (`ChannelMailDispatcher`, `MailWorker`) SkyMail'in `POST /v1/mail_tasks/single` ucuna gidiyor. Süreç yeniden başlarsa kuyruktaki postalar kayboluyor. Hatırlatma "gönderildi" işaretini posta gitmeden koyuyor.

Form sahibinin yanıtlayanlara toplu gönderiminde de alıcı listesini Forms hazırlıyor ve SkyMail'e kendisi veriyor: `POST /v1/form_mail_sources`, 30 dakikalık bir anlık görüntü. Bu yolda gönderen değişmez, Forms ve SkyMail birbirinin ucunu ve sözleşmesini biliyor.

Bildirimin dayandığı kayıtlar ise core'da: İletişim tercihi (ADR-0067, ADR-0070 karar 6), Davet onayı ve tanıtım izni (ADR-0062 ve ekleri), kitle (ADR-0067, ADR-0071 karar 14). Forms'un postaları bu kararların dışında kalıyor.

Yusuf ve Fatih'in ilkesi (2026-10-25): Forms ve SkyMail gibi servisler birbirini bilmez, core orkestre eder. Yusuf aynı gün kuralı sınırlarıyla onayladı: servisler birbirini bilmez, ama core her şeyin aracısı olmaz. Form yanıtlayanlarına toplu gönderim de ilk aşamaya girer, ikinci aşamaya kalmaz.

Karar (Yusuf, 2026-10-25):

1. **core orkestre eder.** Üç iş core'dadır:
   - servisler arası koordinasyon ve sonucu beklenen çok adımlı iş: hesap silme (ADR-0051), bilet yazma, başvuru kapanışı (ADR-0066);
   - **bildirim kararı:** ne oldu, kime gidecek, hangi Bildirim türüyle, ne zaman tetiklenecek. Tercih, rıza, kitle, misafir sınırı ve hatırlatma eşiği bu karara dahildir;
   - paylaşılan kayıtlar: kimlik okuma, rıza ve İletişim tercihi, kitle, ekip ağacı, media, kısa link (ADR-0071 karar 3'teki platform hizmetleri).
2. **core'a girmez.** Bunlar sınırdır:
   - **Bir servisin kendi iş kuralı ve iç kuyruğu.** Forms'un form, yanıt, akış ve "formu kim görür" kuralı Forms'ta kalır. SkyMail'in kuyruğu, bastırması ve şablon içeriği SkyMail'de kalır. inscribed'ın içeriği inscribed'da kalır.
   - **Okuma vekilliği.** Bir ön yüz ya da BFF kendi servisini doğrudan okur; core başka bir servisin önünde vekil olmaz.
   - **Kullanıcının beklediği, gecikmeye duyarlı platform yolları.** Keycloak'ın giriş ve doğrulama postası SkyMail'e doğrudan gider (ADR-0045). core kesintisi girişi durdurmamalı.
3. **Alan servisleri birbirini çağırmaz.** Forms, SkyMail ve inscribed birbirinin ucunu, rolünü ve yanıt kodunu bilmez.
   - "Şu oldu" bilgisini ADR-0071'e göre olay olarak yayımlarlar.
   - Alan servislerinin core'a yaptığı çağrılar ADR-0071 karar 3'teki platform hizmetleriyle ve karar 13–14'teki iki istisnayla sınırlıdır.
   - **Yazılı istisna:** SkyMail haber gönderiminde içeriği inscribed'dan okur (ADR-0067). Bu, insanın SkyMail ekranındaki eylemidir ve kalır.
4. **İletişim servisi üreticiyi bilmez.** SkyMail Bildirim türlerini ve alıcıyı bilir.
   - Türün anlamı ve değişkenleri, bildirim kararını veren tarafındır. İçerik SkyMail'de yazılır (ADR-0046, ADR-0047).
   - Tür adındaki önek kategoridir, çağıranı göstermez: `forms.*` "Formlar" demektir. Bu yüzden `forms.form-copy`, `forms.status-changed`, `forms.attempt-update` ve `forms.pending-reminder` anahtarları ve değişkenleri aynı kalır. Sözleşmenin sahibi core olur.
5. **Forms'un kendiliğinden giden postalarını core gönderir.**
   - **Olaylar.** Forms, ADR-0071'deki giden kutusuyla şu olayları yayımlar:
     - `forms.response.created`;
     - `forms.response.status_changed`, ek alanlarla: `nextFormId`, `returnedQuestionCount`, `reviewedAt`;
     - yeni `forms.workflow_run.reopened`: `workflowId`, `runId`, `userId`, `startFormId`, `voidedAt`, `version`;
     - yeni `forms.attempt.updated`: `formId`, `attemptId`, `userId`, `kind` (`extended`, `accepted`, `closed`, `expired`, `reminded`), `deadlineAt`, `timeLimitMinutes`, `nextFormId`, `version`.

     Olaylarda yalnız kimlikler ve karar alanları vardır (ADR-0071 karar 5). Adları Fatih kesinleştirir.
   - **İçerik okumayla gelir (claim check).** core'un posta işçisi göndermeden hemen önce Forms'un iç okuma uçlarından şunları okur:
     - formun başlığı;
     - cevaplar (soru ve cevap metni);
     - `reviewNote`;
     - misafirin adı ve adresi;
     - `guestCopyEligible`, yani bu adresin bu forma ilk yanıtı mı.

     Yanıt bu arada silindiyse okuma 404 döner ve posta düşer.
   - **Misafir sınırı core'a geçer.** Bugünkü kural aynen kalır: misafire form başına bir kopya gider, bir adrese günde en çok 3 kopya gider.
   - **Bekleyen yanıt hatırlatmasını core zamanlar.** Eşik bugünkü gibi 36 saattir. Her 30 dakikada bir iş, Forms'un iç ucundan gecikmiş değerlendirmeleri okur.
     - Kime hangi yanıt kimlikleri için hatırlattığını core kendi tablosunda tutar.
     - core Forms'un veritabanına yazmaz (ADR-0062 ilkesi).
     - Değerlendiricinin adresini core kendisi bilir.
   - **Gönderim.** core postayı kendi Postgres kuyruğundan, kira ve yeniden denemeyle, ADR-0070 karar 3'e göre SkyMail'e verir.
     - Hesabı olan alıcıya `POST /v1/notifications` ile gider; alıcı `sub`'dır, `Idempotency-Key` olayın kimliği ve türüdür.
     - Misafire `POST /v1/mail_tasks/single` ile gider.
     - Postalar `islem` akışında kalır (ADR-0072 karar 8). Tercihe bakmazlar, başlık ve çıkış bağlantısı taşımazlar.
   - **Posta kararı core'undur.** `reminded` bir olgudur, komut değildir: yönetici hatırlatma istedi ve Forms bunu kaydetti (12 saat kuralı Forms'ta kalır). Posta atılıp atılmayacağına core karar verir.
6. **Form sahibinin yanıtlayanlara toplu gönderimi de core'a geçer, ilk aşamada.** core'un kitle çözümleyicisine yeni bir kitle türü eklenir: **Form respondents audience** (`form_respondents`).
   - **Başlatma.** Forms ekranındaki düğme SkyMail'in gönderim ekranını formun kimliğiyle açar. Bu bir ön yüz bağlantısıdır; Forms backend SkyMail'i çağırmaz.
   - **SkyMail core'a sorar.** Mevcut `audience:read` rolüyle şunları gönderir: `type: form_respondents`, `formId`, gönderenin `sub`'ı, gönderimin amacı (`islem` | `duyuru`) ve kategorisi. Gönderenin `sub`'ını SkyMail kendi doğruladığı oturumdan alır.
   - **Yanıtlayanları core Forms'tan okur.** Forms'un iç ucu (`skyforms:responses:read-service`) gönderenin `sub`'ını alır ve iki şey döner:
     - yanıtlayanlar: hesabı olan için `userId`, misafir için ad ve adres; arşivlenmiş yanıt girmez;
     - gönderenin formdaki rolü.
   - **Gönderenin yetkisi.** Kuralı Forms koyar; bugünkü kural aynen geçerlidir. Gönderen ya formun ortak çalışanıdır (rolü `None` değildir) ya da form geneli yönetici rolü `skyforms:*`'ı taşır.
     - Ortak çalışanlığı Forms söyler.
     - Rol token'da taşındığı için core onu Keycloak'tan okur (`forms` istemcisinin etkin rolleri).
     - İkisi de yoksa core `403` döner ve kitle çözülmez.
   - **Kitle gönderim anında çözülür.** Anlık görüntü tutulmaz (ADR-0071 karar 14).
     - Mail onayında kitle onay anında çözülür, gönderenin yetkisi de o anda yeniden denetlenir.
     - Gönderim ekranındaki sayı `countOnly` ile gelir.
   - **Adres.** Hesabı olan yanıtlayana core'un Primary e-mail'i kullanılır, misafire Forms'taki adresi. Geçersiz adres ve aynı adres elenir ve sayılır.
   - **Amaç ve rıza.** Hangi yanıtlayana posta gideceğini amaç belirler:
     - **`islem`.** Gönderen, postanın yalnız alıcının kendi başvurusu ya da işlemi hakkında olduğunu beyan eder (ADR-0072 karar 2 ve 8). Posta bütün yanıtlayanlara gider. Tercih, çıkış kaydı ve Davet onayı aranmaz. Kalıcı ret bastırması uygulanır.
     - **`duyuru`.** Her alıcı ayrı süzgeçten geçer:
       - Member için kontrol noktası ADR-0072 karar 3'tür.
       - Member olmayan yanıtlayan (hesabı olsun olmasın) postayı yalnız etkin bir Davet onayıyla alır (ADR-0062, `davet-v2`). Bu kural bugün gönderenin beyanına kalmıştı; artık core uygular.
       - Asıl amacı tanıtım olan posta yalnız tanıtım izni verene gider (ADR-0062 eki, ADR-0072 eki).
       - Hesabı olmayan adres ayrıca SkyMail'in çıkış kaydına bakar (ADR-0072 karar 4).
   - **Kontrol noktası değişmez.** ADR-0072'nin kuyruğa alma kontrol noktası ve dağıtıcının her turdaki yeniden sorgusu bu gönderime de uygulanır.
7. **Yeni bir core sorumluluğu eklenirken** ADR'de neden core'da olduğu yazılır. Bu ADR'ın gerekçesi: tercih, rıza ve kitle core'da; bildirim kararı onlara dayanır.
8. **Geçiş kayıpsızdır ve geri alınabilir.**
   - **Kendiliğinden giden postalar şablon şablon geçer.** Production'da önce core'un o şablonu açılır, hemen ardından Forms'ta o şablonun `FormMail__*TemplateKey` ayarı boşaltılır; boş anahtarla Forms'un kodu postayı atmaz.
     - Aradaki dakikalarda kısa süreli çift posta kabul edilir, kayıp kabul edilmez.
     - Geri dönüş, Forms kodu duruyorken ayar düzeyindedir.
   - **Toplu gönderim.** SkyMail'de yeni kitle türü bayrakla açılır, Forms'un düğmesi yeni bağlantıya döner. Eski `form_mail_sources` yolu iki hafta kalır.
   - **İki hafta temiz geçerse** şunlar kaldırılır:
     - Forms'tan posta kodu: `MailWorker`, `ChannelMailDispatcher`, `FormMailNotifier`, `PendingResponseReminderWorker`, `SkyMailClient` ve `mail-source` ucu;
     - SkyMail'den `form_mail_sources` ve Forms kaynağı ayarları;
     - Keycloak'tan Forms'un SkyMail gönderim yetkisi.

Nasıl:

- **Forms'un iç okuma uçları.** ADR-0071'deki dar rolle (`skyforms:responses:read-service`), yalnız iç ağdan çalışırlar; kenardan gelen istek `404` alır. Biçimleri Fatih'indir. Gereken bilgiler:
  - form: başlık (ADR-0071'deki form durumu ucuna eklenir);
  - tek yanıt: cevaplar, `reviewNote`, misafirin adı ve adresi, `guestCopyEligible`;
  - akış koşusu: yeniden açılma notu;
  - gecikmiş değerlendirmeler: `olderThan` süresinden eski bekleyen yanıtlar; değerlendirici, form ve yanıt kimlikleriyle;
  - yanıtlayanlar: sayfalı, gönderenin `sub`'ıyla; gönderenin rolünü ve sayıları da döner.
- **core.**
  - `core.forms` tüketicisi, olaydan posta kuyruğu satırını olay kimliğiyle aynı işlemde yazar (ADR-0071 karar 6).
  - Posta işçisi `ticketnotify` kalıbındadır: kira, geri çekilme, vazgeçme süresi, `Idempotency-Key`.
  - Misafir sınırı Redis'tedir.
  - Hatırlatma işi kira ve advisory lock'la çalışır.
  - Kitle çözümleyicisine `form_respondents` türü eklenir; yanıtı mevcut kitle yanıtının biçimindedir, atlananlar nedenleriyle sayılır.
  - Bayrak, metrik ve belge eklenir.
- **SkyMail.** Gönderim ekranında "Form yanıtlayanları" kitlesi core'dan çözülür; onay akışı ve rapor mevcut kitlelerinkiyle aynıdır. Şablonlar ve gönderim uçları değişmez.
- **Keycloak.** core'un servis hesabına `skyforms:responses:read-service` verilir (ADR-0071'de zaten planlı). Geçiş bitince Forms'un SkyMail gönderim yetkisi kaldırılır.

## Consequences

- **ADR-0070 karar 3 ve Consequences.** "Keycloak, Forms ve core'un mevcut çağrıları değişmez" cümlesindeki Forms kısmı bu ADR'la değişir. Forms artık SkyMail'e göndermez, onun postalarını core gönderir. Keycloak'ın çağrısı değişmez. ADR-0070'e tarihli ek yazıldı.
- **ADR-0072 karar 8.** "Forms bunları kendi servis hesabıyla gönderir" cümlesi ve toplu gönderimin "Forms'un mail-source anlık görüntüsü" yolu bu ADR'la değişir. Akış sınıfları aynen kalır: kendiliğinden giden postalar `islem`, toplu gönderim beyan yoksa `duyuru` akışındadır. ADR-0072'ye tarihli ek yazıldı.
- **ADR-0071.** Forms'un olay listesi iki türle genişler, iç okuma uçları da beş bilgiyle genişler. Bunun dışında karar değişmez. ADR-0071'e tarihli ek yazıldı.
- **ADR-0062.** Var olan saklama satırları değişmez. "SkyMail: gönderilen posta içeriği, Forms yanıt kopyaları dahil, 1 yıl" satırı aynen geçerlidir; postayı yalnız artık core gönderir.
  - core'un posta kuyruğu satırı yalnız kimlik taşır. Satır, core'un öteki posta kuyruklarında olduğu gibi SkyMail kabul edince ya da vazgeçme süresi dolunca silinir.
  - Hatırlatma kaydının süresi, ADR-0062 tablosuna satır olarak eklenecek. Kayıt yalnız kimlik tutar ve yanıtın değerlendirilmesinden sonra gereksizdir.
  - ADR-0062 bu ADR'la değişmez.
- **Davranış değişiklikleri.**
  - Forms yeniden başlarken posta kaybolmaz.
  - Hatırlatma "gönderildi" işareti yalnız SkyMail kabul edince konur.
  - Toplu gönderimde Member olmayan yanıtlayana duyuru amaçlı posta yalnız Davet onayıyla gider; bugün herkese gidiyordu.
  - Onay bekleyen toplu gönderim, onaylandığı anın yanıtlayanlarına gider; bugün hazırlandığı anınkilere gidiyordu.
- **Bağımlılık değişir.** Forms postaları ve toplu gönderim core'a bağımlı olur. core kapalıyken postalar kaybolmaz, bekler: Forms'un giden kutusu, RabbitMQ kuyruğu ve core'un kuyruğu tutar. Toplu gönderim ekranı ise core ve Forms yanıt vermezse gönderim yazmaz.
- **Forms (Fatih).** İki yeni olay türü, `status_changed`'e üç alan, iç okuma uçlarına beş bilgi; geçişten sonra posta kodu kalkar. Kod azalır, yeni katman eklenmez.
- **core.** Forms posta tüketicisi ve kuyruğu, misafir sınırı, hatırlatma işi, `form_respondents` kitle türü.
- **SkyMail.** Yeni kitle türünün ekranı ve core çağrısı; geçişten sonra `form_mail_sources` kalkar.
- **Keycloak.** core'a Forms okuma rolü verilir; geçişten sonra Forms'un SkyMail gönderim yetkisi kalkar.
- **Kazanç.** Üye alıcılar `sub` ile bilindiği için bu postalar sonra "Bildirimlerim" kutusuna ve push'a da düşebilir (ADR-0070 karar 3 ve 5). Forms'un bunu ayrıca yapması gerekmez.
- **CONTEXT.md'de değişenler:**
  - yeni terim: Form respondents audience (Form yanıtlayanları kitlesi);
  - Message stream: Forms'un postalarını core gönderir;
  - Integration event: alan servisleri birbirini de çağırmaz;
  - Tracked send: servis postaları arasında Forms onayları, core'un gönderdiği postalar olarak sayılır.

## Açık

- **Olay ve uç adları, alan adları, sayfalama.** Fatih kesinleştirir; bu ADR yalnız taşınacak bilgiyi yazar.
- **Görüntüleyen rolü.** Formun yalnız görüntüleyeni (`Viewer`) toplu gönderim başlatabilir mi? Bugün başlatabiliyor ve bu ADR bunu değiştirmiyor. Kural Fatih'indir; değişirse yalnız Forms'un ucu değişir.
- **Yanıt durumuna göre kitle.** "Yalnız kabul edilenlere" gibi bir süzgeç ilk sürümde yoktur. Gerekirse Forms'un ucuna bir parametre olarak eklenir.
- **Misafir postasında tekrar anahtarı.** `POST /v1/mail_tasks/single` `Idempotency-Key` okumaz. Yanıtı belirsiz kalan misafir postası, bugünkü bilet postası gibi yeniden denenmez. SkyMail'e anahtar desteği ayrı bir iştir.

## Endüstri uygulamasıyla karşılaştırma

**Uyanlar:**
- **Microsoft Saga ve Choreography kalıpları.** Paylaşılan kuralı olan ve çok adımlı akışta merkezi orkestratör önerilir; bounded context'ler arası gevşek bağ için olay kullanılır (karar 1 ve 3).
- **Bildirim platformu kalıbı.** Üretici "ne oldu, kime" der; kanal, zaman ve metin platformundur. ADR-0070'teki Novu, Knock, Courier ve SuprSend incelemeleri bunu gösteriyor. Microsoft Teams etkinlik akışında da uygulama türü ve alıcıyı verir, Teams teslim eder (karar 4).
- **"Smart endpoints and dumb pipes" (Fowler ve Lewis).** İş kuralı servisinde kalır. Formu kimin görebileceğini Forms söyler, broker yalnız taşır (karar 2 ve 6).
- **Microsoft'un olay yükü önerisi ve Claim Check kalıbı.** Olayda yalnız anahtar taşınır, içerik kaynaktan okunur (karar 5).
- **Transactional outbox ve idempotent consumer** (microservices.io). Kaynak Forms'un giden kutusudur; core olay kimliğiyle tekrarı eler.
- **Microsoft Dynamics 365 Customer Insights – Journeys.** Kitle ve rıza gönderim anında, her postadan önce değerlendirilir (karar 6).
- **İşlem ve toplu posta ayrımı.** Google ve Postmark'ın tanımıyla, alıcının kendi eyleminin tetiklediği posta işlemdir; aynı içeriğin birçok alıcıya gitmesi toplu postadır (ADR-0072 karar 8 aynen).

**Sapmalar (hepsi):**
1. **Basit bildirimlerde bile araya core girer.** Sektörde üretici çoğu zaman bildirim platformunu doğrudan tetikler (Knock tetikleyicisi, Teams etkinlik akışı). Gerekçe: tercih, rıza, kitle ve misafir sınırı core'da. Bildirim kararı tek yerde toplanır.
2. **Orkestratör tek arıza noktasıdır** (Microsoft'un uyarısı). Giden kutusu, RabbitMQ ve core'un kuyruğu kaybı önler ama gecikmeyi engellemez. Toplu gönderim ekranı core ve Forms ayaktayken çalışır.
3. **Keycloak'ın sistem postası kuralın dışındadır** (karar 2). Sektörde de kimlik sağlayıcısı kendi doğrulama postasını kendisi atar.
4. **SkyMail haber postası için inscribed'ı okur** (karar 3). Teslim servisi bir alan servisini biliyor. Bu yazılı bir istisnadır, çünkü okuma insanın SkyMail ekranındaki eylemidir.
5. **Gönderenin kimliği güvenilir alt sistemle taşınır.** SkyMail gönderenin `sub`'ını core'a, core da Forms'a servis token'ıyla verir.
   - Microsoft'un on-behalf-of akışı (RFC 8693 token exchange) kullanılmaz; o akışta her adım kişinin token'ını yeni bir kitle için değiştirirdi.
   - Gerekçe: bugünkü `form_mail_sources` aynı güvenle çalışıyor (Forms `owner_sub` veriyor). Token değiştirme zinciri üç serviste yeni Keycloak izinleri ister.
6. **Form geneli yönetici rolünü core okur.** Forms'un yetki kuralının bu yarısı (`skyforms:*`) token'dan okunuyor; servis token'ıyla gelen istekte Forms onu göremez. Bu yüzden rolü core Keycloak'tan okur. Ortak çalışanlığı yine Forms söyler.
7. **Hatırlatma için core Forms'u yoklar.** Saf olay mimarisinde core bekleyen yanıtların kopyasını olaylardan kurardı (event-carried state transfer). Bu ölçekte 30 dakikalık okuma daha basittir ve kopya durum tutmaz.
8. **Geçişte kısa süreli çift posta kabul edilir.** Kalıp tam bir kez teslim ister; şablon başına birkaç dakikalık çakışma kayıptan iyidir.

## Considered Options

- **Forms'ta giden kutusu ile SkyMail'e doğrudan gönderim** (bugünkünün güvenilir hâli). En küçük farktır, ama ilkeye aykırıdır: tercih, rıza ve kitle kararı dışarıda kalır, Forms SkyMail'i bilmeye devam eder.
- **SkyMail'in Forms olaylarını kendisinin dinlemesi.** Teslim servisi alan olaylarını yorumlar ve bildirim kararı iki yere bölünür. Tercih ve rıza yine core'da olduğu için SkyMail her olayda core'a sorardı.
- **Cevapların olayla taşınması.** Serbest metin ve kişisel veri kuyruk ve DLQ kopyalarına girer, silme isteği oraya ulaşamaz (ADR-0071 karar 5).
- **Toplu gönderimi ikinci aşamaya bırakmak.** Araştırmanın ilk önerisiydi. Forms ile SkyMail arasındaki bağ bir süre daha kalır ve geçiş iki kez yapılırdı. Yusuf ilk aşamayı seçti.
- **Yanıtlayanların kopyasını core'da olaylardan tutmak.** Misafirin adresi core'da ikinci bir kayıt olurdu. Formun sahiplik kuralı da kopyalanırdı.
- **Gönderenin forma erişimine core'un kendisinin karar vermesi** (ortak çalışan listesini okuyup). Forms'un iş kuralı core'a taşınırdı (karar 2).
- **Her şeyin core'dan geçmesi, okuma vekilliği dahil.** core darboğaz ve tek arıza noktası olurdu, mantık servislerden orkestratöre kayardı. Sam Newman'ın "merkezi beyin" uyarısı buna denk düşer.

## Kaynaklar

- Microsoft, Saga design pattern: https://learn.microsoft.com/en-us/azure/architecture/patterns/saga
- Microsoft, Choreography pattern: https://learn.microsoft.com/en-us/azure/architecture/patterns/choreography
- Microsoft, Claim Check pattern: https://learn.microsoft.com/en-us/azure/architecture/patterns/claim-check
- Microsoft Graph, Teams activity feed notifications: https://learn.microsoft.com/en-us/graph/teams-send-activityfeednotifications
- Microsoft identity platform, on-behalf-of flow: https://learn.microsoft.com/en-us/entra/identity-platform/v2-oauth2-on-behalf-of-flow
- microservices.io, Saga ve Transactional outbox: https://microservices.io/patterns/data/saga.html
- Martin Fowler ve James Lewis, Microservices ("Smart endpoints and dumb pipes"): https://martinfowler.com/articles/microservices.html
- Araştırma notu: sky_lab_genel `notes/rabbitmq-olay-adaylari-arastirma-20261025.md`, Ek C, D ve E.
