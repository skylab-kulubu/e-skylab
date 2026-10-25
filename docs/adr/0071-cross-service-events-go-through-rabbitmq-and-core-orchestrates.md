---
status: accepted
---

# Servisler arası olaylar RabbitMQ'dan geçer; core orkestratördür, alan servisleri core'u bilmez

Bugün servisler arasında tek kalıp, OAuth client credentials'lı HTTP. Forms her cevabı kendi giden kutusundan core'a `POST /v1/forms/{formId}/responses` ile bildiriyor ve core'un yanıt koduna göre yeniden deniyor. Yani Forms core'un bilet alanını biliyor. Fatih'in ilkesi bunun tersi: core orkestratör ve ana mikroservis; Forms ve öteki servisler core'u bilmez, core onları bilir. Yakın istekler de aynı yöne itiyor:
- geri bildirim formu, form kapanınca core'un haberdar olmasını istiyor (ADR-0069);
- e-postayla kayıt core'a haber vermiyor, core 5 dakikalık eşitlemeyle yakalıyor (core-backend #270);
- Forms'a "form kapandı" için core'a özel bir uç yazdırmak ilkeye aykırı.

RabbitMQ Java döneminde vardı (`super-skylab-rabbitmq`). Tek tüketicisi Java'nın kullanıcı eşitlemesiydi. Go core'a geçişte eşitleme JIT'e döndü (ADR-0008), broker cutover'da durduruldu. Keycloak imajında `keycloak-to-rabbitmq` sağlayıcısı (exchange `keycloak.events`) kaldı. ADR-0045 ve ADR-0051 broker'ı "production'da yok, tüketicisi yok" gerekçesiyle reddetti. Eski kurulumun sorunları: elle compose, yönetim arayüzü herkese açık bir alan adında, varsayılan parola git'te, olaylarda IP ve e-posta.

Karar (Yusuf, 2026-10-20: RabbitMQ kurulur; Fatih'in ilkesiyle core orkestratördür. Karar 9 orkestratörün, 2026-10-20. Karar 10–16 Yusuf'un, 2026-10-21: ilk sürümdeki açık sorular kapandı, her biri önerilen seçenekle):

1. **Servisler arası olaylar RabbitMQ'dan geçer.** Olay "şu oldu" der ve cevap beklemez. Yayıncı tüketiciyi bilmez. Her yayıncının kendi topic exchange'i var (`forms.events`, `keycloak.events`; sonra `core.events`, `skymail.events`). Routing key olay türüdür (`forms.response.created`).
2. **Komutlar HTTP kalır.** Sonucunu bekleyen istekler olay değildir: Erasure command (ADR-0051), posta ve bildirim gönderimi (ADR-0045, ADR-0070), Forms'ta Okuyucu kaldırma. core bunları çağırmaya devam eder.
3. **core orkestratördür; alan servisleri core'u bilmez.**
   - Kural alan servisleri içindir: Forms, SkyMail, inscribed. Bunlar core'un alan uçlarını, rollerini ve yanıt kodlarını bilmez.
   - core'un istemcileri kuralın dışındadır: ön yüzler ve BFF'ler (Account center, admin paneli, sky-app, siteler) ile etkinlik uygulamaları (Place, Guessr).
   - Ortak platform hizmetleri istisnadır: kullanıcı okuma, media, kısa link, hesap erişim kapısı.
   - core'un sahip olduğu iki ortak kayıt istisnadır (karar 13 ve 14): Davet onayı yazımı (ADR-0062) ve kitle okuma (ADR-0067, ADR-0070).
4. **Kurulum.**
   - Her ortamda (production, sandbox) ayrı, tek düğüm RabbitMQ 4.x (karar 10).
   - Dokploy uygulaması, digest'li imaj, kalıcı volume, bellek sınırı.
   - Ağ: ortama ait `sky-lab-<ortam>-events` (`internal`; rotator, topoloji ve izleme yan konteyneri için `attachable`), ADR-0061'in ağ tablosuna bir satır. Dışarı port ve Traefik rotası yok. Yönetim arayüzü yalnız SSH tüneliyle.
   - Kuyruklar tek düğümde de quorum: teslim sınırı ve at-least-once dead-letter için.
   - Exchange, kuyruk ve policy'leri ops bir dosyadan kurar, servisler kurmaz.
   - Yedek alınmaz: kaynak, yayıncıların giden kutusu ve veritabanlarıdır.
5. **Zarf ve kişisel veri.**
   - Zarf CloudEvents 1.0, JSON yapılı mod (`application/cloudevents+json`): `specversion` (`1.0`), `id`, `source`, `type`, `time`, `datacontenttype`, `dataschema` (şema sürümü) ve `data`. Mesaj kalıcıdır (`delivery-mode 2`).
   - `id`, yayıncının giden kutusu satırının kimliğidir ve yeniden yayımda değişmez. Tüketicinin tekrar elemesi buna dayanır.
   - Mesajda yalnız kimlikler (ör. Keycloak `sub`; takma adlı kişisel veridir) ve tüketicinin karar vermesi için gereken alanlar var. E-posta, ad, telefon, IP ve serbest metin yoktur. Gereken tüketici yayıncının API'sinden okur (misafirin iletişim bilgisi için karar 11). Kuyruk ve DLQ kopyalarına silme isteği ulaşamaz.
   - **Gizli alan değerleri kısa koddur:** olaya yalnız `[A-Za-z0-9_-]{1,100}` biçimine uyan değer girer. Uymayan değer (e-posta, ad, boşluklu metin) olaya konmaz, cevapta kalır. Forms bunu biçim süzgeciyle ya da formda alan başına "olayda gider" işaretiyle uygular; hangisi olduğu Fatih'in seçimi, biçim kuralı ikisinde de geçerli.
   - Olay o anki durumu ve bir `version` taşır. Sıra garanti değildir.
6. **Güvenilirlik.**
   - Yayıncı olayı iş kaydıyla aynı işlemde giden kutusuna (transactional outbox) yazar, publisher confirms ile yayımlar, onay gelince siler.
   - Tüketici elle ack verir ve olay kimliğini yan etkiyle aynı işlemde kaydedip tekrarları eler. Birkaç denemeden sonra mesaj DLQ'ya gider.
   - Kaçan olaylar için core günde bir yayıncıdan çeker. Keycloak için core-backend #270'in eşitlemesi kalır, olay onu yalnız uyandırır.
   - **Saklama:**
     - Ana kuyrukta TTL yok. Uzunluk sınırı dolunca yayın reddedilir, olay giden kutusunda bekler.
     - DLQ 14 gün, `unrouted` 1 gün.
     - Tüketicinin olay kimliği kaydı 30 gün.
     - Giden kutusu satırı onayda silinir, onaysız kalırsa 7 gün sonra bırakılır.
     - DLQ'daki kimlikler KVKK'nın 30 günlük silme süresi içinde düşer. Bu satırlar ADR-0062'nin saklama tablosuna eklenecek (ADR-0062 bu ADR'la değişmez).
7. **Güvenlik.**
   - Her servisin kendi RabbitMQ kullanıcısı var: yalnız kendi exchange'ine kendi önekiyle yazar ya da yalnız kendi kuyruğunu okur, hiçbir şey kuramaz.
   - Parolalar OpenBao'da (ADR-0049) ve gece döner. Bu ADR, ADR-0050'yi yeni bir `rabbitmq` sınıfıyla genişletir: veritabanı gibi iki kullanıcı dönüşümlü, Keycloak'unki pazar gecesi.
   - İç ağda TLS ilk sürümde yok. İkinci sunucu gelirse açılır.
8. **Keycloak.**
   - Mevcut sağlayıcı kullanılır, biçimi korunur.
   - Fork, IP'yi, `sessionId`'yi, `details`'i ve admin temsilini yayımlamayacak ve yalnız seçilen olay türlerini gönderecek şekilde değişir.
   - Realm dinleyicisini reconciler yönetir.
9. **Servis içi iş kuyrukları Postgres'te kalır** (orkestratör, 2026-10-20). SkyMail'in `mail_queue`'su ve core'un işçileri RabbitMQ'ya taşınmaz. RabbitMQ yalnız servisler arası olay dağıtımı içindir.
10. **Ortam başına ayrı örnek** (Yusuf, 2026-10-21). Production ve sandbox'ın kendi RabbitMQ'su var, tek örnekte iki vhost yok. ADR-0061'in ortam ayrımına uyar. RabbitMQ'nun bellek ve disk alarmı düğümün bütün yayıncılarını durdurduğu için bir ortam ötekini durdurmaz.
11. **Misafirin adı ve e-postası olayda yok** (Yusuf, 2026-10-21). core misafir biletini yazarken bunları Forms'un tek cevap iç ucundan okur: ince olay, "claim check" kalıbı. Kişisel veri olay akışına, kuyruk ve DLQ kopyalarına girmez.
12. **Eski `super-skylab-rabbitmq` hemen silinir** (Yusuf, 2026-10-21). Yeni sandbox beklenmez, kurulum temiz yapılır. Silme salt okur envanterden (kimlik ve volume adı) sonra, konteyner ve volume adıyla yapılır. Genel `prune` yok.
13. **Davet onayı yazımı istisna kalır** (Yusuf, 2026-10-21). Forms, Place ve Guessr rızayı core'un kaydına `POST /v1/consents` ile eşzamanlı yazar (ADR-0062). core rıza merkezidir. Rızanın ispat yükü merkezde olduğu için yazım eşzamanlıdır. Rızadan doğan olayları gerekirse merkez yayımlar.
14. **Kitle okuma istisna kalır** (Yusuf, 2026-10-21). SkyMail kitleyi ve kişi başına izinli kanalları gönderim anında core'dan okur (ADR-0067, ADR-0070). Kopya tutulmaz, liste her zaman günceldir.
15. **ADR-0066 eki karar 10'daki 409 `registration_closed` adımı düşer** (Yusuf, 2026-10-21). Forms core'a sormaz ve core'un yanıt kodunu tanımaz. Cevap olayını yayımlar, karar core'undur.
16. **Kapalı başvuruya gelen Forms cevabı `submittedAt`'e göre ayrılır** (Yusuf, 2026-10-21).
    - Cevap kapanıştan **önce** gönderilmişse bilet yazılır, onayı kapanıştan sonra gelse bile.
    - Kapanıştan **sonra** gönderilmişse bilet yazılmaz. Cevap Forms'ta kalır, düzenleyen kişiyi panelden elle ekleyebilir.
    - `submittedAt` yoksa ya da ayrıştırılamıyorsa bilet yazılır. Bu durum geçiş dönemindeki HTTP raporu için; Fatih'e forms-backend#37'de böyle söylendi.
    - Ayrıntı ADR-0066'nın 2026-10-21 ekinde.

## Consequences

- **ADR-0051'in "message broker" reddinin dayanağı**, ADR-0071'in broker'ı production'da çalışmaya başlayınca geçerliliğini yitirir. Kararın kendisi değişmez: silme bir komuttur, her servisin onayını bekler, adresleri yalnız çağrı süresince taşır. Bu yüzden HTTP kalır. Aynısı ADR-0045'in RabbitMQ'lu posta reddi için geçerli: posta gönderimi bir komut olarak SkyMail'e HTTP ile gider.
- **ADR-0008:** Keycloak olayı kimlik verisi taşımaz. Yalnız core-backend #270'in periyodik turunu uyandırır, veri yine Keycloak'tan okunur. Kimlik eşitlemesi RabbitMQ'ya dayanmaz.
- **ADR-0069:** Forms'un cevap bildirimi (davet kodu dahil) ve "form kapandı" haberi olayla gelir: `forms.response.created` (gizli alanlar) ve `forms.form.updated`.
- **ADR-0066 eki karar 10** karar 15 ve 16 ile değişir: 409 adımı düşer, kapalı başvuruya gelen cevap `submittedAt`'e göre ayrılır. ADR-0066'ya 2026-10-21 eki yazıldı, CONTEXT Registration closure buna göre düzeltildi.
- **ADR-0070:** bildirim isteği bir komuttur, `Idempotency-Key`'li HTTP ile gider; broker yalnız olaylar içindir. ADR-0070'teki eski "Broker yoktur" cümlesi buna göre düzeltildi.
- **Forms:**
  - Cevap bildirimi giden kutusu genelleşir ve RabbitMQ'ya yayımlar: `forms.response.created`, `forms.response.status_changed`, `forms.form.updated`.
  - Genel "gizli alan" gelir (davet kodu bunlardan biri), karar 5'teki biçim kuralıyla.
  - Dar bir okuma rolüyle iç okuma uçları gelir: form durumu, sayfalı cevaplar, tek cevap.
  - Olay ve alan adlarını Fatih kesinleştirir. Kütüphane (RabbitMQ.Client ya da MassTransit) onun seçimi.
- **core:**
  - Yeni tüketici paketi (amqp091-go), olay kimliği tablosu, metrikler.
  - Keycloak olaylarıyla eşitlemeyi uyandırır. Forms olaylarıyla bilet ve geri bildirim kurallarını işletir. Günlük çekme işçisi.
  - İkili dönemden sonra `POST /v1/forms/{formId}/responses` ve `ticket:forms` kalkar.
- **ops:**
  - Ortam başına kurulum wizard'ı ve topoloji dosyası.
  - Rotatorda `rabbitmq` sınıfı.
  - İzleme zamanlayıcısı: DLQ ve `unrouted` > 0, kuyruk derinliği ya da yaşı, tüketicisiz kuyruk, kaynak alarmı. Uyarılar rotatorun uyarı yolundan gider.
  - Eski `super-skylab-rabbitmq` yeniden kullanılmaz, salt okur envanterden sonra adıyla silinir (karar 12).
- **Keycloak:** sağlayıcı süzgeci. `KK_TO_RMQ_*` ortam referansları. `eventsListeners` reconciler'a girer, bugünkü "dinleyiciler elle kalır" testi değişir.
- **Forms issue'ları:**
  - #38'in "form kapanınca haber" maddesi `forms.form.updated`'e, davet kodu gizli alana döner.
  - #36 HTTP komutu olarak kalır ama YK'yı bilmeyen bir adla.
  - forms-frontend#34, `purpose=feedback` yerine panelden Skyforms'a form açılışındaki Forms'un kendi seçeneklerini kullanır.
  - #37 kapanır: Forms core'un yanıt kodlarına bakmaz, 409 önerisi geri çekilir, Forms'ta değişiklik gerekmez (karar 15).
- **Yeni durumlu servis.** Volume kaybında topoloji dosyadan, kullanıcılar OpenBao'dan yeniden kurulur. Aradaki olayları giden kutuları ve günlük çekme kapatır.

## Endüstri uygulamasıyla karşılaştırma

**Uyanlar:**
- RabbitMQ belgesinin veri güvenliği tarifi: kalıcı mesaj, durable kuyruk, publisher confirms, elle ack ve idempotent tüketici, sınırlı prefetch.
- Quorum kuyruğun teslim sınırı ve at-least-once dead-lettering (`overflow: reject-publish`).
- Erişim kontrolü: vhost başına configure, write ve read; topic exchange'de routing key izni; `guest` yok.
- CloudEvents 1.0 zorunlu öznitelikleri (`id`, `source`, `specversion`, `type`) ve `source`+`id` tekilliği.
- Transactional outbox ve idempotent consumer kalıpları (microservices.io).
- Microsoft'un .NET mikroservis rehberindeki ayrım: integration event yayımlanır ve cevap beklemez, sonucu beklenen istek ayrı tutulur.
- Entra'nın kullanıcı eşitlemesi periyodiktir, olay onu hızlandırır (core-backend #270 aynı modeli izler).
- İnce olay ve "claim check": kişisel veri olayda değil, tüketici kaynaktan okur (karar 11).
- Rıza merkezi: rıza merkeze eşzamanlı yazılır, çünkü ispat yükü merkezdedir; olayları merkez yayımlar (karar 13).
- Microsoft Customer Insights Journeys: kitle gönderim anında okunur, kopya tutulmaz (karar 14).
- Azure Service Bus topic ve subscription, `MaxDeliveryCount` ve dead-letter alt kuyruğu bizim exchange, kuyruk, `delivery-limit` ve DLQ'muzla aynı kalıp. Event Grid CloudEvents 1.0'ı doğrudan kullanır.

**Sapmalar (hepsi):**
1. **Tek düğümde quorum kuyruk.** Belge üçten az düğümün tam güvence vermediğini söyler. Çoğaltma için değil, teslim sınırı ve at-least-once DLQ için seçildi.
2. **CloudEvents'in AMQP bağlaması AMQP 1.0 içindir.** İstemcilerimiz AMQP 0-9-1, yalnız yapılı mod kullanılır.
3. **Tür adlarında ters DNS öneki yok.** Platform içi.
4. **Keycloak olayları CloudEvents değil, giden kutusuz ve confirms'süz.** Kayıp periyodik eşitlemeyle kapanır.
5. **İç ağda TLS yok** (tek sunucu, `internal` ağ, mesajda yalnız kimlik). Kapı Redis'inde TLS var.
6. **Gecikmeli yeniden deneme kuyruğu yok.** Süreç içinde birkaç deneme, sonra DLQ ve elle geri alma.
7. **Broker tarafında tekrar eleme yok** (Service Bus'ta var). Tekrar eleme tüketicide.
8. **Topolojiyi ops kurar, kütüphaneler kurmaz.** Servis kullanıcılarına configure izni verilmez.
9. **Giden kutusu 7 gün sonra vazgeçer** (Forms'un bugünkü davranışı). Kalıpta aktarıcı başarıya kadar dener. Arayı günlük çekme kapatır.
10. **Komutlar broker'dan geçmez.** Microsoft rehberi zamansal bağımlılığı azaltmak için asenkron komut mesajlarını da önerir. Bizde komutun sonucu bekleniyor, silme komutundaki adres kalıcı bir kopyaya (kuyruk, DLQ) yazılmamalı (ADR-0051).
11. **Şema kaydı ve AsyncAPI kataloğu yok.** Sözleşme bu ADR'da, SPEC'te ve kodda. Makinece okunur katalog sonraki adım.
12. **Tek broker örneği tek arıza noktası.** Kesintide yayın giden kutusunda bekler, tüketiciler yeniden bağlanır, Keycloak olayları kaybolur ve eşitleme turu yakalar.
13. **İki alan servisi çağrısı core'a gider** (karar 13 ve 14): Forms'un rıza yazımı ve SkyMail'in kitle okuması. Saf olay mimarisinde ikisi de olayla yapılırdı (rıza olayı, kitlenin olayla beslenen kopyası). Rızada ispat yükü, kitlede güncellik için eşzamanlı çağrı seçildi.

## Considered Options

- **Forms'tan genel, imzalı webhook** (Standard Webhooks, HMAC-SHA256; Typeform, Tally ve Jotform'un kalıbı): yeni servis gerektirmez, giden kutusu iskeleti hazır. Ama her yeni tüketici için yayıncıda abonelik yönetimi gerekir, Keycloak olaylarını kapsamaz, teslim kuralı ve yeniden deneme her yayıncıda yeniden yazılır. Yusuf olayların tek yerden geçmesini seçti.
- **Bugünkü durum (Forms core'a özel çağrı yapar):** ilkeye aykırı. Forms core'un yanıt kodlarını yorumlar (#37).
- **Tek RabbitMQ örneği, iki vhost:** daha az bellek. Ama sandbox ve production uygulamaları aynı ağa girer (ADR-0061). RabbitMQ'nun bellek ve disk alarmı düğümün bütün yayıncılarını durdurur.
- **Eski `super-skylab-rabbitmq`'yu yeniden açmak:** 3.x, Dokploy dışı, eski ağ, git'te parola, içinde IP'li eski Keycloak olayları. Taşınacak veri yok.
- **Classic kuyruk:** daha hafif. Ama zehirli mesaj sınırı ve at-least-once dead-letter yok.
- **SkyMail'in iş kuyruğunu da RabbitMQ'ya taşımak:** kira, bütçe, alıcı durumu ve rapor SQL'de ve aynı işlemde. Servis içi iş kuyruğu için yerleşik kalıp Postgres kuyruklarıdır (River, Oban, GoodJob; `SKIP LOCKED`).
- **Kafka ya da NATS JetStream:** tek sunucuda daha ağır ya da ekipte deneyimi yok. Keycloak sağlayıcısı RabbitMQ için hazır.
- **MassTransit'i platform standardı yapmak:** v9 ticari lisanslı. Kütüphane seçimi servis sahibine bırakıldı.
- **Misafirin iletişim bilgisini olayda taşımak:** Fatih'e bir uç daha az. Ama adres 14 güne kadar DLQ kopyasında kalır ve silme isteği oraya ulaşamaz.
- **Eski konteyneri sandbox kurulana kadar tutmak:** geri dönülecek bir şey yok, içinde IP'li eski olaylar ve git'teki parolayla açılan bir yönetici var.
- **Rızayı ve kitleyi olaya çevirmek:** rıza olayının kaybı ya da gecikmesi ispatı zayıflatır. Kitlenin SkyMail'de kopyası tercihi ve ekip ağacını iki yerde tutar.
- **Kapalı başvuruda her Forms cevabını reddetmek (ADR-0066 eki karar 10'un ilk hâli):** kapanıştan önce gönderilip sonra onaylanan cevabın bileti sessizce kaybolurdu.
- **Kapalı başvuruda her Forms cevabına bilet yazmak:** kapanış Forms'tan gelenler için anlamını yitirirdi.

## Ek (2026-10-25): Forms'un postaları ve iki yeni olay (ADR-0075)

ADR-0075 karar 3'ü alan servislerinin birbirine de uygular: Forms SkyMail'i, SkyMail Forms'u bilmez. Forms'un postaları core'un bildirim kararına geçtiği için:

- **Olay listesi genişler.** `forms.response.status_changed` `nextFormId`, `returnedQuestionCount` ve `reviewedAt` alanlarını da taşır. İki yeni tür gelir: `forms.workflow_run.reopened` ve `forms.attempt.updated`. Karar 5 aynen geçerlidir: olaylarda yalnız kimlik ve karar alanları vardır.
- **İç okuma uçları genişler.** Aynı dar rolle uçlar şunları da verir: formun başlığı, yanıtın cevapları, `reviewNote`, `guestCopyEligible`, akış koşusunun yeniden açılma notu, gecikmiş değerlendirmeler ve gönderenin rolüyle yanıtlayanlar (karar 11'deki claim check).
- **Kitle okuma istisnası (karar 14)** form yanıtlayanlarını da kapsar. SkyMail kitleyi core'dan okur, core yanıtlayanları Forms'tan okur.
