---
status: accepted
---

# Forms kendi postasını kendisi gönderir, core araya girmez; form yanıtlayanlarına toplu gönderimde Forms kitleyi SkyMail'e kaynak olarak verir (ADR-0075'in posta bölümünün yerine)

ADR-0075 karar 5, 6 ve 8, Forms'un kendiliğinden giden postalarını ve form yanıtlayanlarına toplu gönderimi core'a taşıyordu: Forms olay yayımlayacak, core posta kararını verip kendi kuyruğundan SkyMail'e gönderecek, 36 saatlik hatırlatmayı core zamanlayacak, toplu gönderimin kitlesini core'un `form_respondents` türü çözecekti. Bunların hiçbiri production'a çıkmadı.

ADR-0075'in en somut gerekçesi "Forms yeniden başlarsa kuyruktaki posta kaybolur" idi. Bu gerekçe kapandı: Forms postayı artık bellek içi kuyruk yerine kendi veritabanındaki giden kutusuna yazıyor ve bir gün boyunca yeniden deniyor (forms-backend `OutboxMailDispatcher.cs`, `MailOutboxHandler`). Kalan gerekçe "bildirim kararı tek yerde olsun" idi. LinkedIn'in Air Traffic Controller'ı merkezi bir kararı destekler; ama orada merkez bir bildirim platformudur, bizde SkyMail'e denk gelir. Nick Tune üretici ile bildirim platformu arasında böyle bir ara bağlam önerir; neden sapıldığı Sapma 1'de.

Karar (Yusuf, 2026-11-24):

1. **Forms'un kendiliğinden giden postaları Forms'ta kalır.** Cevap alındı, onay, ret, düzeltme istendi, yeniden açıldı, misafire form kopyası, deneme güncellendi ve değerlendiricilere bekleyen yanıt hatırlatması: tetikleyiciye, alıcıya ve zamanlamaya Forms karar verir.
   - Forms bugünkü gibi kendi giden kutusundan SkyMail'e HTTP komutuyla gönderir: `POST /v1/mail_tasks/single`. SkyMail bu uçta isteğe bağlı `Idempotency-Key` okur (skymail-backend #133). Forms bugün bu anahtarı göndermiyor; giden kutusu bir gün yeniden denediği için belirsiz yanıtta çift posta riski var. Anahtarı göndermek Forms'un işidir (Fatih'e not).
   - Misafir sınırı (form başına bir kopya, adres başına günde üç) ve 36 saatlik hatırlatma Forms'ta kalır.
   - Postalar `islem` akışındadır (ADR-0072 karar 8, aynen).
2. **core araya girmez.** core'da Forms posta tüketicisi ve kuyruğu (`formsmail`), hatırlatma işi ve `form_respondents` kitle türü yazılmaz.
3. **Form yanıtlayanlarına toplu gönderim bugünkü gibidir.** Forms gönderenin yetkisini kendi kuralıyla denetler, alıcıları toplar ve kitleyi SkyMail'e kısa ömürlü bir kaynak olarak verir (`POST /v1/form_mail_sources`); SkyMail gönderimi o kaynaktan yapar. SkyMail her toplu gönderimde olduğu gibi alıcı başına core'un İletişim tercihi kontrol noktasına sorar (ADR-0072; `SKYMAIL_BULK_PREFERENCE=on`, production'da açık).
   - **Rıza kuralı aynen kalır, SkyMail uygular.** ADR-0075 karar 6'daki kural geçerlidir: `duyuru` amaçlı gönderimde Member olmayan yanıtlayan, hesabı olsun olmasın, postayı yalnız etkin bir Davet onayıyla alır; tanıtım amaçlı posta yalnız tanıtım izni verene gider. Sektörde tercih ve rıza bildirim platformunun işidir; bizde SkyMail'in onay kapısında uygulanır. Bugün SkyMail'in kapısı (`internal/mailer/consent_gate.go`) Davet onayını yalnız hesabı olmayan adrese uygular; hesabı olan Member olmayana da uygulaması SkyMail'de yapılacak iştir.
   - Gönderen alıcı listesini görmez, yalnız toplu sayıları görür (ADR-0075 2026-11-08 eki madde 10, ADR-0074 eki). Bu SkyMail'in genel kuralıdır ve kalır.
   - Yanıt durumuna ya da akış adımına göre süzgeç ve sahip ekibin Leader'ı yolu istenirse Forms kaynağa ekler; kural Fatih'indir.
4. **Forms olaylarından yalnız core'un kendi işi için gerekenler RabbitMQ'ya taşınır:** `forms.response.created`, `forms.response.status_changed` ve `forms.form.updated`, bir de Forms'un iç okuma uçları (yanıt listesi, tek yanıt). ADR-0071 ve bilet akışı aynen sürer. `forms.workflow_run.*` ve `forms.attempt.*` olayları ve bunların topoloji bağları yazılmaz.
5. **ADR-0075 karar 3'e iki yazılı istisna.** Forms SkyMail'in `/single` ucunu ve `form_mail_sources` ucunu bilir ve çağırır; SkyMail'in Forms'a özel bir ucu vardır (`form_mail_sources`, karar 4'e de istisna). İkisi de bugün çalışan yoldur. Alan servisleri arasında başka bir doğrudan çağrı açılmaz.
6. **Kötüye kullanım kaygısı yerinde çözülür.** Forms'ta form açma yetkisinin backend'de denetlenmesi (Fatih'e iletildi) ve SkyMail'de kaynak başına gönderim sınırı. Bunun için core'un araya girmesi gerekmez.

ADR-0075'ten Forms postası dışında geçerli kalanlar: karar 1, 2, 4 ve 7. Şu cümleler adıyla geri çekilir:
- karar 1'in ikinci maddesi (bildirim kararı core'dadır): Forms'un postası için geçmez, kararı Forms verir;
- karar 2'nin ölçütü ("core araya yalnız kendi kaydıyla bir karar eklediğinde girer; tercih, rıza, kitle, misafir sınırı ve zamanlama böyle kararlardır"): Forms postasında misafir sınırı ve zamanlama Forms'undur, kitle Forms'ta çözülür, tercih ve rıza SkyMail'de uygulanır;
- karar 2'deki "kişiye kendiliğinden bir bildirim (kutu, push) gitmesi istenirse karar 1'e göre core'a girer": Forms'un postası için geçmez;
- karar 4'teki "`forms.*` sözleşmesinin sahibi core olur": dört `forms.*` şablonunun anahtarı ve değişkenleri Forms'la SkyMail arasındaki sözleşmedir; karar 4'e SkyMail'in Forms'a özel `form_mail_sources` ucu istisnası eklenir;
- karar 7'nin ikinci cümlesi (ADR-0075'in gerekçesi: tercih, rıza ve kitle core'da olduğu için bildirim kararı core'dadır).

## Consequences

- **Geri çekilen işler** (forms-posta-core): 02 iki yeni Forms olayı ve `status_changed` alanları; 03'ün 1–5. maddeleri (form başlığı, tek yanıtta posta bilgileri, akış koşusu, gecikmiş değerlendirmeler, yanıtlayanlar; form başlığını core ve bilet akışı okumuyor, panel Forms'un kendi API'sinden okuyor); 05 core `formsmail` tüketici, kuyruk ve işçi; 06 core bekleyen yanıt hatırlatması; 07 core `form_respondents` kitle türü; 08 SkyMail kitleyi core'dan çözme; 09 skymail-frontend "Form yanıtlayanları" ekranı; 10 Forms düğmesinin yeni bağlantısı; 12 sandbox uçtan uca; 13 şablon şablon production geçişi; 14 Forms posta kodunun silinmesi; 15 `form_mail_sources` ve Forms gönderim yetkisinin kaldırılması. RabbitMQ'da `forms.workflow_run.*` ve `forms.attempt.*` için B2 bağları kurulmaz. core'daki iki taslak dal (`feat/formsmail-posta-kuyrugu`, `feat/form-respondents-kitle`) birleştirilmez.
- **Aynen kalanlar.** ADR-0071 ve Forms → core olay akışı (yukarıdaki üç olay), Forms'un iç okuma uçları ve core'un `skyforms:responses:read-service` rolü, bilet akışı; SkyMail `/single` `Idempotency-Key` desteği; dört `forms.*` şablonu ve Bildirim türü bilgisi; ADR-0072 akış sınıfları ve kontrol noktası; Member olmayan yanıtlayana Davet onayı kuralı; gönderenin alıcı listesini görmemesi; core'un kişinin ekipleri ucu (ADR-0067 eki de kullanıyor).
- **SkyMail'de yapılacak iş.** Onay kapısı Davet onayını hesabı olan Member olmayan alıcıya da uygular (karar 3).
- **Forms (Fatih).** Posta kodu silinmez; ADR-0075'in posta için istediği olaylar ve uç bilgileri gerekmez. Yeni bir posta kuralı yalnız Forms'ta değişir. Fatih'e iki not: `/single` çağrısında `Idempotency-Key`; form açma yetkisinin backend'de denetlenmesi.
- **ADR-0070, 0071 ve 0072'nin 2026-10-25 ekleri.** Forms postasına ilişkin kısımları bu ADR'la geri çekildi; eklerin başına not düşüldü. ADR-0070'teki "Keycloak, Forms ve core `/single` ile göndermeye devam eder" cümlesi yeniden geçerlidir. ADR-0072 karar 8'in "Forms bunları kendi servis hesabıyla gönderir" cümlesi ve toplu gönderimin Forms kaynağı yolu geri gelir. ADR-0071 ekinde adıyla geri çekilenler: "Forms SkyMail'i, SkyMail Forms'u bilmez" cümlesi (ek girişi), olay listesinin iki yeni türle genişlemesi, iç okuma uçlarının posta için genişlemesi ve kitle okuma istisnasının form yanıtlayanlarını kapsaması (ek maddeleri), 2026-10-26 ekindeki "kişiye kendiliğinden bildirim (kutu, push) ADR-0075 karar 1'e göre core'a girer" cümlesi (Forms postası için).
- **Kazanç kaybı.** ADR-0075'in vaat ettiği "üye alıcıya giden form postası Bildirimlerim kutusuna ve push'a da düşer" kendiliğinden gelmez. İstenirse Forms `/v1/notifications`'a `sub` ile gönderir; bu yine Forms'un çağrısıdır, core araya girmez.
- **CONTEXT.md'de değişenler:** Form respondents audience (kitleyi Forms verir, rızayı SkyMail uygular), Contact consent, Owner team, Communication preference, Message stream, Integration event, Tracked send.

## Endüstri uygulamasıyla karşılaştırma

**Uyanlar:**
- **Ürün kendi postasının tetikleyicisine ve alıcısına karar verir; posta platformu şablonu, gönderimi, yeniden denemeyi, tercihi ve abonelik çıkışını yönetir.** LinkedIn'in Air Traffic Controller'ı ürün ekiplerinin ürettiği bildirimleri alıp teslim kararını merkezde verir; merkez bir bildirim platformudur, bizde SkyMail'e denk gelir. Knock'ta uygulama olay anında platformu doğrudan tetikler (karar 1 ve 2).
- **Tercih ve rıza bildirim platformunda uygulanır** (karar 3). Dynamics 365 Customer Insights – Journeys rızayı gönderim anında, gönderen platformda değerlendirir.
- **Form ürünlerinde onay postası formun kendi ayarıdır.** Tally'nin yanıtlayana bildirimi ve Jotform'un otomatik yanıtı formun içinde kurulur (karar 1).
- **Jira bildirim şemaları.** Hangi olayda kime posta gideceğini ürünün kendi şeması söyler (karar 1).
- **Transactional outbox.** Forms'un posta kaydı kendi veritabanındadır ve kayıpsız yeniden denenir.

**Sapmalar (hepsi):**
1. **Nick Tune'un mapper context önerisinden sapar.** Tune, alana özgü olayları genel bildirim komutlarına çeviren merkezi bir "mapper context" önerir; ADR-0075'in tasarımı buna yakındı. Bizde core'un bu çeviriye kendi kaydından ekleyeceği bir bilgi yok: Forms postasının tetikleyicisi, alıcısı, misafir sınırı ve zamanlaması saf Forms kuralıdır, tercih ve rıza da SkyMail'de uygulanır. Çeviriyi core tutsaydı Fatih'in her posta değişikliği iki depoda değişiklik isterdi.
2. **Alan servisi teslim servisini doğrudan çağırır ve SkyMail'in Forms'a özel bir ucu vardır** (ADR-0075 karar 3 ve 4'e istisna). Sektörde de üretici platformu doğrudan tetikler; bizdeki sapma kendi ilkemizden.
3. **Toplu gönderimde kitle anlık görüntüdür** (30 dakika). Dynamics 365, HubSpot ve Customer.io kitleyi gönderim anında çözer (kaynaklar ADR-0075 eki 2026-11-08'de); onayda bekleyen gönderim, hazırlandığı anın yanıtlayanlarına gider. Rıza yine gönderim anında, SkyMail'de denetlenir.

## Considered Options

- **ADR-0075'i olduğu gibi uygulamak** (core posta kararını verir). Kod yazılmıştı, ama araya bir iş servisi girer, her posta değişikliği iki depoya dağılır ve Forms'un olay listesi yalnız posta için büyür.
- **SkyMail'in Forms olaylarını dinlemesi.** Teslim servisi alan olaylarını yorumlar; ADR-0075'in reddettiği gerekçe aynen geçerlidir.
- **Yalnız kendiliğinden giden postaları Forms'ta bırakıp toplu gönderimi core'a taşımak.** Kitle kuralı (ortak çalışan, yönetici rolü, arşiv) Forms'un iş kuralıdır; core onu Forms'tan okuyup aynen geri verirdi. Rıza kuralı için core'a gerek yok, SkyMail'in kapısı uygular.

## Kaynaklar

- LinkedIn, Air Traffic Controller: member-first notifications: https://engineering.linkedin.com/blog/2018/03/air-traffic-controller--member-first-notifications-at-linkedin
- Knock, how to choose a notification infrastructure platform: https://knock.app/manuals/notification-infrastructure/how-to-choose-a-notification-infrastructure-platform
- Nick Tune, Mapper contexts and supercontexts: https://medium.com/nick-tune-tech-strategy-blog/mapper-contexts-supercontexts-decoupling-domain-specific-and-domain-generic-bounded-contexts-5eb6a1e7c5fc (sayfa 403 veriyor; özet arama sonucundan)
- Tally, respondent e-mail notifications: https://tally.so/help/respondent-email-notifications
- Jotform, setting up an autoresponder e-mail: https://www.jotform.com/help/26-setting-up-an-autoresponder-email-2
- Atlassian, configure notification schemes: https://support.atlassian.com/jira-cloud-administration/docs/configure-notification-schemes/
- Microsoft Dynamics 365 Customer Insights – Journeys, rıza uygulaması: https://learn.microsoft.com/en-us/dynamics365/customer-insights/journeys/real-time-marketing-email-text-consent
- forms-backend `origin/main` 86e2b5a: `src/Forms.Infrastructure/Mail/OutboxMailDispatcher.cs`, `src/Forms.Infrastructure/Integrations/SkyMail/SkyMailClient.cs`.
- skymail-backend `origin/main`: `internal/handlers/form_mail_source.go` (form kaynağı gönderiminde core'un tercih kontrol noktası), `internal/mailer/consent_gate.go` (Davet onayı kapısı).
