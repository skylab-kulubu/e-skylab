---
status: accepted
---

# Forms kendi postasını kendisi gönderir, core araya girmez; form yanıtlayanlarına toplu gönderimde SkyMail kitleyi Forms'tan okur (ADR-0075'in posta bölümünün yerine)

ADR-0075 karar 5, 6 ve 8, Forms'un kendiliğinden giden postalarını ve form yanıtlayanlarına toplu gönderimi core'a taşıyordu: Forms olay yayımlayacak, core posta kararını verip kendi kuyruğundan SkyMail'e gönderecek, 36 saatlik hatırlatmayı core zamanlayacak, toplu gönderimin kitlesini core'un `form_respondents` türü çözecekti. Bunların hiçbiri production'a çıkmadı.

ADR-0075'in en somut gerekçesi "Forms yeniden başlarsa kuyruktaki posta kaybolur" idi. Bu gerekçe kapandı: Forms postayı artık bellek içi kuyruk yerine kendi veritabanındaki giden kutusuna yazıyor ve bir gün boyunca yeniden deniyor (forms-backend `OutboxMailDispatcher.cs`, `MailOutboxHandler`). Kalan gerekçe "bildirim kararı tek yerde olsun" idi; sektör araştırması bunun karşılığını bulmadı (aşağıda).

Karar (Yusuf, 2026-11-24):

1. **Forms'un kendiliğinden giden postaları Forms'ta kalır.** Cevap alındı, onay, ret, düzeltme istendi, yeniden açıldı, misafire form kopyası, deneme güncellendi ve değerlendiricilere bekleyen yanıt hatırlatması: tetikleyiciye, alıcıya ve zamanlamaya Forms karar verir.
   - Forms bugünkü gibi kendi giden kutusundan SkyMail'e HTTP komutuyla gönderir: `POST /v1/mail_tasks/single`. SkyMail bu uçta isteğe bağlı `Idempotency-Key` okur (skymail-backend #133); belirsiz yanıtta aynı anahtarla yeniden denemek Forms'un işidir.
   - Misafir sınırı (form başına bir kopya, adres başına günde üç) ve 36 saatlik hatırlatma Forms'ta kalır.
   - Postalar `islem` akışındadır (ADR-0072 karar 8, aynen).
2. **core araya girmez.** core'da Forms posta tüketicisi ve kuyruğu (`formsmail`), hatırlatma işi ve `form_respondents` kitle türü yazılmaz.
3. **Form yanıtlayanlarına toplu gönderim bugünkü gibidir.** Forms gönderenin yetkisini kendi kuralıyla denetler, alıcıları toplar ve SkyMail'e kısa ömürlü bir kaynak olarak verir (`POST /v1/form_mail_sources`); SkyMail gönderimi o kaynaktan yapar. SkyMail her toplu gönderimde olduğu gibi alıcı başına core'un tercih ve rıza kontrol noktasına sorar (ADR-0072); bu yolda bugün de soruyor.
   - Gönderen alıcı listesini görmez, yalnız toplu sayıları görür (ADR-0075 2026-11-08 eki madde 10, ADR-0074 eki). Bu SkyMail'in genel kuralıdır ve kalır.
   - Yanıt durumuna ya da akış adımına göre süzgeç ve sahip ekibin Leader'ı yolu istenirse Forms'un kaynağına eklenir; kural Fatih'indir.
4. **Forms olaylarından yalnız core'un kendi işi için gerekenler RabbitMQ'ya taşınır:** `forms.response.created`, `forms.response.status_changed` ve `forms.form.updated`, bir de Forms'un iç okuma uçları (yanıt listesi, tek yanıt). ADR-0071 ve bilet akışı aynen sürer. `forms.workflow_run.*` ve `forms.attempt.*` olayları ve bunların topoloji bağları yazılmaz.
5. **ADR-0075 karar 3'e iki yazılı istisna.** Forms SkyMail'in `/single` ucunu ve `form_mail_sources` ucunu bilir; SkyMail toplu gönderimde Forms'un kaynağını okur. İkisi de bugün çalışan yoldur. Alan servisleri arasında başka bir doğrudan çağrı açılmaz.
6. **Kötüye kullanım kaygısı yerinde çözülür.** Forms'un gönderim ve kaynak yetkisi Forms'taki yetki düzeltmesiyle, toplu hacim SkyMail'de kaynak başına gönderim sınırıyla sınırlanır. Bunun için core'un araya girmesi gerekmez.

ADR-0075 karar 1, 2, 4 ve 7 (core'un orkestrasyon işi, okuma vekilliği sınırı, iletişim servisinin üreticiyi bilmemesi) Forms postası dışında aynen geçerlidir. Karar 4'teki "`forms.*` sözleşmesinin sahibi core olur" cümlesi geri çekilir: dört `forms.*` şablonunun anahtarı ve değişkenleri Forms'la SkyMail arasındaki sözleşmedir.

## Consequences

- **Geri çekilen işler** (forms-posta-core): 05 core `formsmail` tüketici, kuyruk ve işçi; 06 core bekleyen yanıt hatırlatması; 07 core `form_respondents` kitle türü; 08 SkyMail kitleyi core'dan çözme; 09 skymail-frontend "Form yanıtlayanları" ekranı; 12 sandbox uçtan uca; 13 şablon şablon production geçişi; 14 Forms posta kodunun silinmesi; 15 `form_mail_sources` ve Forms gönderim yetkisinin kaldırılması. RabbitMQ'da `forms.workflow_run.*` ve `forms.attempt.*` için B2 bağları kurulmaz. core'daki iki taslak dal (`feat/formsmail-posta-kuyrugu`, `feat/form-respondents-kitle`) birleştirilmez.
- **Aynen kalanlar.** ADR-0071 ve Forms → core olay akışı (yukarıdaki üç olay), Forms'un iç okuma uçları ve core'un `skyforms:responses:read-service` rolü, bilet akışı; SkyMail `/single` `Idempotency-Key` desteği; dört `forms.*` şablonu ve Bildirim türü bilgisi; ADR-0072 akış sınıfları ve kontrol noktası; gönderenin alıcı listesini görmemesi; core'un kişinin ekipleri ucu (ADR-0067 eki de kullanıyor).
- **Forms (Fatih).** Posta kodu silinmez; `status_changed`'e ADR-0075'in posta için istediği ek alanlar ve iç uçlara posta için istenen bilgiler (cevaplar, `reviewNote`, misafir, `guestCopyEligible`, gecikmiş değerlendirmeler, yanıtlayanlar) gerekmez. Yeni bir posta kuralı yalnız Forms'ta değişir.
- **ADR-0070, 0071 ve 0072'nin 2026-10-25 ekleri.** Bu eklerin Forms postasını core'a taşıyan kısımları bu ADR'la geçersizdir: ADR-0070'teki "Keycloak, Forms ve core `/single` ile göndermeye devam eder" cümlesi yeniden geçerlidir; ADR-0072 karar 8'in "Forms bunları kendi servis hesabıyla gönderir" cümlesi ve toplu gönderimin Forms kaynağı yolu geri gelir; ADR-0071'in olay listesi iki yeni türle genişlemez.
- **Kazanç kaybı.** ADR-0075'in vaat ettiği "üye alıcıya giden form postası Bildirimlerim kutusuna ve push'a da düşer" kendiliğinden gelmez. İstenirse Forms `/v1/notifications`'a `sub` ile gönderir; bu yine Forms'un çağrısıdır, core araya girmez.
- **CONTEXT.md'de değişenler:** Form respondents audience (kitleyi Forms çözer), Message stream ve Integration event (Forms'un kendi postası yazılı istisna), Tracked send (Forms'un onay postaları).

## Endüstri uygulamasıyla karşılaştırma

**Uyanlar:**
- **Ürün kendi postasının tetikleyicisine ve alıcısına karar verir, posta platformu şablonu, gönderimi, yeniden denemeyi ve abonelik çıkışını yönetir.** LinkedIn'in Air Traffic Controller'ı, ürün ekiplerinin ürettiği bildirimleri alıp teslim kararını merkezde verir; üreticiyle platform arasında üçüncü bir iş servisi yoktur. Knock ve Courier'de uygulama olay anında platformu doğrudan tetikler (karar 1 ve 2).
- **Form ürünlerinde onay postası formun kendi ayarıdır.** Tally'nin yanıtlayana bildirimi ve Jotform'un otomatik yanıtı formun içinde kurulur (karar 1).
- **Jira bildirim şemaları.** Hangi olayda kime posta gideceğini ürünün kendi şeması söyler (karar 1).
- **Nick Tune'un "mapper context" uyarısı.** Yalnız veriyi bir bağlamdan ötekine taşıyan ara servis ek bağ ve iki yerde değişiklik demektir. core burada kendi kaydından karar eklemiyordu; Fatih'in her posta değişikliği iki depoda değişiklik isterdi (karar 2).
- **Transactional outbox.** Forms'un posta kaydı kendi veritabanındadır ve kayıpsız yeniden denenir.

**Sapmalar (hepsi):**
1. **Tercih ve rıza tek yerde değil, iki yerde uygulanır.** `islem` postası tercihe bakmaz (ADR-0072), bu yüzden kendiliğinden giden postalar için fark yoktur. Toplu gönderimde kontrol noktası yine core'dadır; yalnız kitle Forms'ta çözülür.
2. **Alan servisi teslim servisini doğrudan çağırır** (ADR-0075 karar 3'e istisna). Sektörde de üretici platformu doğrudan tetikler; bizdeki sapma kendi ilkemizden.
3. **Toplu gönderimde kitle anlık görüntüdür** (30 dakika). Dynamics 365, HubSpot ve Customer.io kitleyi gönderim anında çözer; onayda bekleyen gönderim, hazırlandığı anın yanıtlayanlarına gider.

## Considered Options

- **ADR-0075'i olduğu gibi uygulamak** (core posta kararını verir). Kod yazılmıştı, ama araya bir iş servisi girer, her posta değişikliği iki depoya dağılır ve Forms'un olay listesi yalnız posta için büyür.
- **SkyMail'in Forms olaylarını dinlemesi.** Teslim servisi alan olaylarını yorumlar; ADR-0075'in reddettiği gerekçe aynen geçerlidir.
- **Yalnız kendiliğinden giden postaları Forms'ta bırakıp toplu gönderimi core'a taşımak.** Kitle kuralı (ortak çalışan, yönetici rolü, arşiv) Forms'un iş kuralıdır; core onu Forms'tan okuyup aynen geri verirdi, ADR-0075 karar 2'nin ölçütüne göre araya girmemesi gereken durum.

## Kaynaklar

- LinkedIn, Air Traffic Controller: member-first notifications: https://engineering.linkedin.com/blog/2018/03/air-traffic-controller--member-first-notifications-at-linkedin
- Knock, how to choose a notification infrastructure platform: https://knock.app/manuals/notification-infrastructure/how-to-choose-a-notification-infrastructure-platform
- Tally, respondent e-mail notifications: https://tally.so/help/respondent-email-notifications
- Jotform, setting up an autoresponder e-mail: https://www.jotform.com/help/26-setting-up-an-autoresponder-email-2
- Atlassian, configure notification schemes: https://support.atlassian.com/jira-cloud-administration/docs/configure-notification-schemes/
- Nick Tune, bounded context türleri arasında "mapper context" (ikincil aktarım; kaynak bu ADR için yeniden okunmadı).
- forms-backend `origin/main` 86e2b5a: `src/Forms.Infrastructure/Mail/OutboxMailDispatcher.cs`, `src/Forms.Infrastructure/Integrations/SkyMail/SkyMailClient.cs`.
- skymail-backend `origin/main`: `internal/handlers/form_mail_source.go` (form kaynağı gönderiminde core'un tercih kontrol noktası).
