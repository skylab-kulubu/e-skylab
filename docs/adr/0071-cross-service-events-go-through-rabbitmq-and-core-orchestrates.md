---
status: accepted
---

# Servisler arası olaylar RabbitMQ'dan geçer; core orkestratördür, öteki servisler core'u bilmez

Bugün servisler arasında tek kalıp, OAuth client credentials'lı HTTP. Forms her cevabı kendi giden kutusundan core'a `POST /v1/forms/{formId}/responses` ile bildiriyor ve core'un yanıt koduna göre yeniden deniyor. Yani Forms core'un bilet alanını biliyor. Fatih'in ilkesi bunun tersi: core orkestratör ve ana mikroservis; Forms ve öteki servisler core'u bilmez, core onları bilir. Yakın istekler de aynı yöne itiyor:
- geri bildirim formu, form kapanınca core'un haberdar olmasını istiyor (ADR-0069);
- e-postayla kayıt core'a haber vermiyor, core 5 dakikalık eşitlemeyle yakalıyor;
- Forms'a "form kapandı" için core'a özel bir uç yazdırmak ilkeye aykırı.

RabbitMQ Java döneminde vardı (`super-skylab-rabbitmq`). Tek tüketicisi Java'nın kullanıcı eşitlemesiydi. Go core'a geçişte eşitleme JIT'e döndü (ADR-0008), broker cutover'da durduruldu. Keycloak imajında `keycloak-to-rabbitmq` sağlayıcısı (exchange `keycloak.events`) kaldı. ADR-0045 ve ADR-0051 broker'ı "production'da yok, tüketicisi yok" gerekçesiyle reddetti. Eski kurulumun sorunları: elle compose, yönetim arayüzü herkese açık bir alan adında, varsayılan parola git'te, olaylarda IP ve e-posta.

Karar (Yusuf, 2026-10-20):

1. **Servisler arası olaylar RabbitMQ'dan geçer.** Olay "şu oldu" der ve cevap beklemez. Yayıncı tüketiciyi bilmez. Her yayıncının kendi topic exchange'i var (`forms.events`, `keycloak.events`; sonra `core.events`, `skymail.events`). Routing key olay türüdür (`forms.response.created`).
2. **Komutlar HTTP kalır.** Sonucunu bekleyen istekler olay değildir: Erasure command (ADR-0051), posta ve bildirim gönderimi (ADR-0045, ADR-0070), Forms'ta Okuyucu kaldırma. core bunları çağırmaya devam eder.
3. **core orkestratördür.** Forms, SkyMail ve öteki servisler core'un uçlarını, rollerini ve yanıt kodlarını bilmez. Ortak platform hizmetleri (kullanıcı okuma, media, kısa link, hesap erişim kapısı) bu kuralın dışındadır.
4. **Kurulum.** Her ortamda (production, sandbox) ayrı, tek düğüm RabbitMQ 4.x. Dokploy uygulaması, digest'li imaj, kalıcı volume, bellek sınırı. Ortama ait `internal` bir ağda (ADR-0061), dışarı port ve Traefik rotası yok. Yönetim arayüzü yalnız SSH tüneliyle. Kuyruklar tek düğümde de quorum: teslim sınırı ve at-least-once dead-letter için. Exchange, kuyruk ve policy'leri ops bir dosyadan kurar, servisler kurmaz. Yedek alınmaz: kaynak, yayıncıların giden kutusu ve veritabanlarıdır.
5. **Zarf ve kişisel veri.**
   - Zarf CloudEvents 1.0, JSON yapılı mod: `id`, `source`, `type`, `time`, `dataschema` (şema sürümü) ve `data`.
   - Mesajda yalnız kimlikler ve tüketicinin karar vermesi için gereken alanlar. E-posta, ad, telefon, IP ve serbest metin yoktur. Gereken tüketici yayıncının API'sinden okur. Kuyruk ve DLQ kopyalarına silme isteği ulaşamaz.
   - Olay o anki durumu ve bir `version` taşır. Sıra garanti değildir.
6. **Güvenilirlik.**
   - Yayıncı olayı iş kaydıyla aynı işlemde giden kutusuna (transactional outbox) yazar, publisher confirms ile yayımlar, onay gelince siler.
   - Tüketici elle ack verir ve olay kimliğini yan etkiyle aynı işlemde kaydedip tekrarları eler. Birkaç denemeden sonra mesaj DLQ'ya gider.
   - Kaçan olaylar için core günde bir yayıncıdan çeker. Keycloak için core-backend #270'in eşitlemesi kalır, olay onu yalnız uyandırır.
7. **Güvenlik.**
   - Her servisin kendi RabbitMQ kullanıcısı var: yalnız kendi exchange'ine kendi önekiyle yazar ya da yalnız kendi kuyruğunu okur, hiçbir şey kuramaz.
   - Parolalar OpenBao'da (ADR-0049) ve gece döner (ADR-0050'ye yeni sınıf: veritabanı gibi iki kullanıcı dönüşümlü; Keycloak'unki pazar gecesi).
   - İç ağda TLS ilk sürümde yok. İkinci sunucu gelirse açılır.
8. **Keycloak.** Mevcut sağlayıcı kullanılır, biçimi korunur. Fork, IP'yi, `details`'i ve admin temsilini yayımlamayacak ve yalnız seçilen olay türlerini gönderecek şekilde değişir. Realm dinleyicisini reconciler yönetir.
9. **Servis içi iş kuyrukları Postgres'te kalır.** SkyMail'in `mail_queue`'su ve core'un işçileri RabbitMQ'ya taşınmaz. RabbitMQ yalnız servisler arası olay dağıtımı içindir.

## Consequences

- **ADR-0051'in "message broker" reddinin dayanağı değişti:** artık production'da bir broker var. Kararın kendisi değişmez. Silme bir komuttur, her servisin onayını bekler, adresleri yalnız çağrı süresince taşır. Bu yüzden HTTP kalır. Aynısı ADR-0045'in RabbitMQ'lu posta reddi için geçerli. Posta gönderimi bir komut olarak SkyMail'e HTTP ile gider.
- **Forms:**
  - Cevap bildirimi giden kutusu genelleşir ve RabbitMQ'ya yayımlar: `forms.response.created`, `forms.response.status_changed`, `forms.form.updated`.
  - Genel "gizli alan" gelir (davet kodu bunlardan biri).
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
  - Eski `super-skylab-rabbitmq` konteyneri ve volume'u yeniden kullanılmaz, temiz kurulum çalışınca silinir.
- **Keycloak:** sağlayıcı süzgeci. `KK_TO_RMQ_*` ortam referansları. `eventsListeners` reconciler'a girer, bugünkü "dinleyiciler elle kalır" testi değişir.
- **Forms issue'ları:**
  - forms-backend#37 kapanır.
  - #38'in "form kapanınca haber" maddesi `forms.form.updated`'e, davet kodu gizli alana döner.
  - #36 HTTP komutu olarak kalır ama YK'yı bilmeyen bir adla.
  - forms-frontend#34 `purpose=feedback` yerine Forms'un kendi handoff seçeneklerini kullanır.
- **Yeni durumlu servis.** Volume kaybında topoloji dosyadan, kullanıcılar OpenBao'dan yeniden kurulur. Aradaki olayları giden kutuları ve günlük çekme kapatır.

## Endüstri uygulamasıyla karşılaştırma

**Uyanlar:**
- RabbitMQ belgesinin veri güvenliği tarifi: kalıcı mesaj, durable kuyruk, publisher confirms, elle ack ve idempotent tüketici, sınırlı prefetch.
- Quorum kuyruğun teslim sınırı ve at-least-once dead-lettering (`overflow: reject-publish`).
- Erişim kontrolü: vhost başına configure, write ve read; topic exchange'de routing key izni; `guest` yok.
- CloudEvents 1.0 zorunlu öznitelikleri ve `source`+`id` tekilliği.
- Transactional outbox ve idempotent consumer kalıpları (microservices.io).
- Azure Service Bus topic ve subscription, `MaxDeliveryCount` ve dead-letter alt kuyruğu bizim exchange, kuyruk, `delivery-limit` ve DLQ'muzla aynı kalıp. Event Grid CloudEvents 1.0'ı doğrudan kullanır.

**Sapmalar (hepsi):**
1. **Tek düğümde quorum kuyruk.** Belge üçten az düğümün tam güvence vermediğini söyler. Çoğaltma için değil, teslim sınırı ve at-least-once DLQ için seçildi.
2. **CloudEvents'in AMQP bağlaması AMQP 1.0 içindir.** İstemcilerimiz AMQP 0-9-1, yalnız yapılı mod kullanılır.
3. **Tür adlarında ters DNS öneki yok.** Platform içi.
4. **Keycloak olayları CloudEvents değil, giden kutusuz ve confirms'süz.** Kayıp periyodik eşitlemeyle kapanır.
5. **İç ağda TLS yok** (tek sunucu, `internal` ağ, mesajda yalnız kimlik).
6. **Gecikmeli yeniden deneme kuyruğu yok.** Süreç içinde birkaç deneme, sonra DLQ ve elle geri alma.
7. **Broker tarafında tekrar eleme yok** (Service Bus'ta var). Tekrar eleme tüketicide.
8. **Topolojiyi ops kurar, kütüphaneler kurmaz.** Servis kullanıcılarına configure izni verilmez.

## Considered Options

- **Forms'tan genel, imzalı webhook** (Standard Webhooks, HMAC-SHA256; Typeform, Tally ve Jotform'un kalıbı): yeni servis gerektirmez, giden kutusu iskeleti hazır. Ama her yeni tüketici için yayıncıda abonelik yönetimi gerekir, Keycloak olaylarını kapsamaz, teslim kuralı ve yeniden deneme her yayıncıda yeniden yazılır. Yusuf olayların tek yerden geçmesini seçti.
- **Bugünkü durum (Forms core'a özel çağrı yapar):** ilkeye aykırı. Forms core'un yanıt kodlarını yorumlar (#37).
- **Tek RabbitMQ örneği, iki vhost:** daha az bellek. Ama sandbox ve production uygulamaları aynı ağa girer (ADR-0061). RabbitMQ'nun bellek ve disk alarmı düğümün bütün yayıncılarını durdurur.
- **Eski `super-skylab-rabbitmq`'yu yeniden açmak:** 3.x, Dokploy dışı, eski ağ, git'te parola, içinde IP'li eski Keycloak olayları. Taşınacak veri yok.
- **Classic kuyruk:** daha hafif. Ama zehirli mesaj sınırı ve at-least-once dead-letter yok.
- **SkyMail'in iş kuyruğunu da RabbitMQ'ya taşımak:** kira, bütçe, alıcı durumu ve rapor SQL'de ve aynı işlemde. Servis içi iş kuyruğu için yerleşik kalıp Postgres kuyruklarıdır (River, Oban, GoodJob; `SKIP LOCKED`).
- **Kafka ya da NATS JetStream:** tek sunucuda daha ağır ya da ekipte deneyimi yok. Keycloak sağlayıcısı RabbitMQ için hazır.
- **MassTransit'i platform standardı yapmak:** v9 ticari lisanslı. Kütüphane seçimi servis sahibine bırakıldı.
