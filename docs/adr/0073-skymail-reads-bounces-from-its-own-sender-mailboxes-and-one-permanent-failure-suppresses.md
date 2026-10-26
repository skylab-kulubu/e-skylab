---
status: accepted
---

# SkyMail geri dönen postayı kendi gönderen kutularından Graph ile okur; tek kalıcı ret adresi bütün akışlarda bastırır, hesap postası muaftır ama işaretlenir, bastırma kendiliğinden düşmez

SkyMail postayı Exchange Online'dan gönderiyor. Exchange dış alıcıyı `RCPT TO`'da reddetmiyor: postayı kabul ediyor, alıcı yoksa gönderen kutusuna sonradan bir teslim raporu (NDR, RFC 3464) yolluyor. Relay'in senkron kalıcı reddi (skymail-backend #82, #83) bu yüzden dış alıcıda neredeyse hiç tetiklenmiyor.

Bugünkü boşluk:

- **Raporları kimse okumuyor.** NDR'ler gönderen kutusunun Gelen Kutusu'na düşüyor; kodda, ops'ta ya da bir insanda bunları işleyen bir şey yok.
- **Ulaşmayan adrese posta gitmeye devam ediyor.** Microsoft, geri dönen adresleri temizlemeyen göndericiyi daha sıkı denetliyor; sınırı aşan gönderici kısıtlanıyor (restricted entities, `5.1.8` / `5.1.90`). O zaman giriş kodları da gitmez.
- **Bounce oranı ölçülemiyor.** Giriş akışının "bounce %5'i aşarsa" eşiği bir ölçüme dayanmıyor.

Kayıt tabloları, ayrıştırıcı ve kuyruğa alırken bastırma 2026-10-20 ve 21'de SkyMail'e girdi (skymail-backend #86, #87, #89; hepsi production'da). Raporu kutudan çeken okuyucu henüz yok (hub bileti skymail-bounce-isleme 04). Bu kayıt okuyucunun ve bugün uygulanan kuralların dayanağıdır.

Gönderen kutuları ADR-0072'de belirlendi: işlem akışı `hesap@` ve `bilgi@` (`bildirim.yildizskylab.com`), duyuru akışı kendi alt alanındaki kutu (karar 10). Kutuların hepsi paylaşılan kutudur; kimse onları okumaz. Kutuya gelen insan postası bir posta akışı kuralıyla `info@`'ya yönlendirilecek; teslim raporları, otomatik yanıtlar ve OOF yönlendirilmez. Kural 2026-10-25 itibarıyla Audit kipindedir: henüz yönlendirmez, yalnız eşleşmeleri kaydeder. Enforce'a geçiş hub bileti 02'dedir.

Karar (2026-10-20, Yusuf: K1–K4; ayrıntılar hub SPEC skymail-bounce-isleme ve bu kayıt):

1. **Raporun kaynağı yalnız SkyMail'in kendi gönderen kutularıdır.**
   - Okuyucu yalnız bu kutuların Gelen Kutusu'nu okur. İnsanların kullandığı kutular (`info@` dahil) okunmaz.
   - Rotator'un alarm postası ya da Keycloak'un kendi SMTP yedeği başka bir kutudan çıkar; onların raporları eşleşmez (karar 4), beklenen budur.

2. **Okuma yolu: Microsoft Graph, uygulama kimliği, Exchange RBAC for Applications.**
   - Uygulama kaydı yalnız sertifikayla kimlik doğrular (client credentials, RFC 7523 client assertion). Client secret oluşturulmaz. Özel anahtar sır deposundadır; servis yalnız referansını tutar (ADR-0049).
   - Yetki Entra'dan değil Exchange'ten gelir: `Application Mail.Read`, yalnız gönderen kutularını kapsayan bir yönetim kapsamıyla. Entra'da kiracı geneli `Mail.Read` ve admin consent verilmez; verilirse kapsam etkisizleşir.
   - Okuyucuya `Mail.ReadWrite` verilmez. Rapor kutudan silinmez ya da taşınmaz; Gelen Kutusu'ndaki öğeleri Exchange'in saklama etiketi (MRM) 30 günde siler.
   - Aynı uygulama kaydı gönderimde de kullanılır (Graph `sendMail` ve SMTP XOAUTH2; skymail-backend #90). İşlem kutuları Graph ile `saveToSentItems: false` gönderir; Gönderilmiş Öğeler'e kopya düşmez.

3. **Okuyucu kutuyu yoklar.**
   - Her 5 dakikada Graph delta sorgusu (`mailFolders/inbox/messages/delta`); her yeni öğenin MIME'ı (`$value`) bellekte ayrıştırılır. Ham MIME SkyMail'de saklanmaz; yalnız delta bağlantısı saklanır.
   - Aynı anda tek okuyucu koşar (Postgres advisory lock); replika sayısı fark etmez.
   - Bayrak `SKYMAIL_BOUNCE_READER=off|dry-run|on`, varsayılan `off`. `dry-run` okur ve sayar; ret ve bastırma yazmaz, yalnız kutudaki yerini (delta bağlantısı) ve sayıları tutar. Production'da `on` aydınlatma metninin teslim durumu satırını bekler (hub bileti 07).

4. **Yalnız standart rapor işlenir, ve yalnız SkyMail'in postasına bağlanabiliyorsa.**
   - Üst tür `multipart/report; report-type=delivery-status` (RFC 6522) olmalı. Yalnız `message/delivery-status` bölümü ve geri dönen postanın başlıkları okunur. Konu, insan metni ve HTML hiç okunmaz; Exchange bunları kutunun diline göre yazar.
   - Eşleme için beş koşulun hepsi gerekir:
     1. rapor bir DSN'dir;
     2. geri dönen başlıklardaki `Message-ID`, o yoksa `X-SkyMail-Queue-Id` (Graph'la giden postanın `Message-ID`'si Exchange'indir), `<kuyruk id@SMTP_FQDN>` biçimindedir;
     3. kuyruk satırı vardır, e-postadır, gönderilmiştir ve rapor gönderimden sonra gelmiştir;
     4. rapor satırın adresini adlandırır (`Final-Recipient` ya da `Original-Recipient`);
     5. rapor daha önce kaydedilmemiştir (kimliğinin SHA-256'sı tekildir).
   - Kuyruk kimliği rastgele bir UUID'dir. Dışarıdan atılan sahte bir rapor, bir satırın kimliğini ve alıcısını birlikte bilmeden hiçbir adresi bastıramaz.
   - Başka bir adresi adlandıran rapor (yönlendirme, takma ad) kaydedilir ama bastırmaz.

5. **Tek kalıcı ret adresi bastırır; öteki retler yalnız kaydedilir.**

   | Rapor | Sonuç |
   |---|---|
   | `Action: failed` ve ek kod `5.1.0`–`5.1.6` ya da `5.1.10` | **kalıcı:** adres tek seferde bastırılır, kaynak `dsn` |
   | `Action: failed`, `5.4.1` ve Exchange'in `AS(201806281)` belirteci (Directory-Based Edge Blocking: alıcı yok) | **kalıcı** |
   | relay'in adrese özgü senkron kalıcı reddi | **kalıcı**, kaynak `smtp` |
   | öteki `failed` (`5.2.x` dolu kutu, `5.7.x` politika, `5.1.7`/`5.1.8`/`5.1.9x` gönderen tarafı, süre aşımı) | **yumuşak:** yalnız kayıt |
   | `Action: delayed`, `4.x.x` | **gecikme:** yalnız kayıt |

   - Yumuşak ret kendiliğinden bastırmaz. Panel "son 30 günde 3 ya da daha çok yumuşak ret" alan adresleri işaretler.
   - Bastırma bütün akışlarda geçerlidir (ADR-0072 karar 1 ve 5'teki `bounce` nedeni).

6. **Hesap postası muaftır ama işaretlenir.**
   - Muaf olan yalnız hesap postalarıdır: giriş ve kayıt kodu, e-posta doğrulama, şifre sıfırlama. Kural şablona bağlıdır: sistem şablonu ve anahtarı `keycloak.*` ya da `account.*`. Öncelik şeridi kural değildir; sistem şeridinde Forms ve Mail onayı postaları da var.
   - Muaf posta bastırılmış adrese yine gider; satır ve bastırma kaydı işaretlenir, panel bunu gösterir.
   - Forms, Mail onayı, listeler ve öteki her posta bastırılır.

7. **Bastırma kendiliğinden düşmez.**
   - Kaldırma yalnız panelden, `skymail` istemcisinin `skymail:suppressions:manage` rolüyle yapılır. Rol bir gruba verilir, kişiye verilmez.
   - Kaldırmanın denetim kaydı kim, ne zaman, kaynak, kod ve sayıdır; adres tutulmaz.
   - Account erasure kişinin bastırma kayıtlarını siler (ADR-0051 karar 4, ADR-0072'de daraltıldığı gibi).

8. **Kişisel veri en azdır.**
   - Ret kaydı adres ve metin tutmaz: kuyruk satırına bağlıdır (satırla birlikte silinir), tür, `Action`, ek kod, SMTP kodu, `AS` belirteci, zaman ve rapor kimliğinin özeti. Bir yıl saklanır.
   - Bastırma kaydı küçük harfli adres, varsa kişinin `sub`'ı, kaynak, kod, ilk ve son görülme, sayı ve son kuyruk satırıdır. Kaldırılana ya da hesap silinene kadar durur.
   - `Diagnostic-Code`'dan yalnız kodlar alınır; metin adresi ve sunucu adlarını tekrarladığı için saklanmaz. Günlükler adres ve rapor metni yazmaz.

9. **Uzak sunucudan yalnız başlık ve yalnız ret istenir.**
   - Sunucu `DSN` ilan ediyorsa SMTP gönderimi `RET=HDRS` ve `NOTIFY=FAILURE` ister (RFC 3461). `NOTIFY=SUCCESS` istenmez; her teslim için kutuya rapor yağardı. `NOTIFY=FAILURE` gecikme (`DELAY`) raporunu da istememek demektir; yine de gelen gecikme raporu (NOTIFY'ı yok sayan bir sunucudan) yalnız kaydedilir.

## Consequences

- **SkyMail (skymail-backend).** Okuyucu (hub bileti 04): bayrak, Graph istemcisi, delta bağlantısının saklandığı tablo, advisory lock, sayaçlar (işlenen, `dsn_degil`, `eslesmedi`, kalıcı, yumuşak, gecikme) ve bounce oranı için okunabilir bir uç. Tablolar, ayrıştırıcı, eşleme, kuyruğa alırken bastırma, muafiyet ve operatör uçları mevcuttur.
- **Arayüz (skymail-frontend).** Bastırma listesinde bounce satırını onaylı kaldırma, gönderim sayfasında "ulaşmadı" ve "bastırıldı" sayıları, hesap postası işareti, yumuşak ret etiketi (hub bileti 08).
- **Keycloak.** `skymail` istemcisine `skymail:suppressions:manage`, bir gruba; ADR-0072'nin `skymail:unsubscribes:reactivate` rolüyle aynı reconcile değişikliğinde (hub bileti 06). Rol verilene kadar listeyi kimse okuyamaz ve kaldıramaz.
- **Ops.** Uygulama kaydı, sertifika, yönetim kapsamı ve saklama etiketi bir wizard ile kuruldu (hub biletleri 02 ve 12). Yönlendirme kuralı Audit kipinde kuruldu; posta provası, Graph provası ve Enforce'a geçiş (`--posta-provasi`, `--prova`, `--kural-enforce`) henüz kayıtlı değil (bilet 02). Sertifika iki yıllıktır; bitişten önce yenileme aynı wizard'dadır. Okuyucunun açılması sandbox'ta gerçek bir NDR ile eşlemenin doğrulanmasını bekler.
- **Metinler.** KVKK Aydınlatma Metni'ne "e-posta teslim durumu" girer: amaç (ulaşmayan adrese yeniden göndermemek, hesap postalarının ulaşmasını korumak), dayanak (meşru menfaat), süreler ve Microsoft'un posta teslim eden veri işleyen olduğu (hub bileti 07).
- **Saklama.** ADR-0062'ye iki satır eklenecek: "SkyMail: ret kaydı (adressiz) | 1 yıl | meşru menfaat" ve "SkyMail: bastırma kaydı (adres) | kaldırılana ya da hesap silinene kadar | meşru menfaat". ADR-0062 bu kayıtla değişmez.
- **Bilinen sınırlar.**
  - Düz metin bounce işlenmez (sapma 2). Böyle bir rapor gönderen sunucunun alıcısı bastırılmaz; adrese posta gitmeye devam eder.
  - Yoklama yüzünden kalıcı ret ile bastırma arasında en çok bir yoklama aralığı geçer; o arada aynı adrese kuyruğa alınan posta gider.
  - Okuyucu kapalıyken ya da Graph erişilemezken raporlar kutuda bekler; saklama etiketinin 30 gününü geçen rapor kaybolur.

## Açık

- **Exchange'in istemci `Message-ID`'sini koruduğu** ve raporuna orijinal başlıkları eklediği sandbox'ta gerçek bir NDR ile doğrulanacak. Korumuyorsa eşleme `X-SkyMail-Queue-Id`'ye kalır (şeritler bu başlığı zaten yazıyor).
- **`smtp.office365.com`'un `DSN` ilan edip etmediği** doğrulanmadı. İlan etmiyorsa karar 9 uygulanmaz; uzak sunucular varsayılanlarına göre rapor yollar.
- **Elle bastırma.** Yumuşak ret etiketli bir adresi operatörün elle bastırması önerildi; bugün bunun bir ucu yok.

## Endüstri uygulamasıyla karşılaştırma

**Uyanlar:**

1. **Tek kalıcı ret bastırır.** Amazon SES'in hesap düzeyindeki suppression list'i ve Postmark'ın hard bounce'u böyle çalışır. Karar 5.
2. **Yumuşak ret bastırmaz.** SES ve Postmark yumuşak reddi bastırma listesine almaz. Karar 5.
3. **Bastırma kendiliğinden düşmez, açıkça kaldırılır.** Postmark'ta reactivate, SES'te listeden silme. Karar 7.
4. **Standart rapor ayrıştırılır.** RFC 3464 ve RFC 3463 ek kodları; sınıf ek koddan çıkar. Karar 4 ve 5.
5. **En dar yetki.** Microsoft'un önerdiği güncel model RBAC for Applications'tır; Application Access Policies'in yerine geçer. Karar 2.
6. **Uzak sunucudan başarı raporu istenmez.** RFC 3461 `NOTIFY=FAILURE`. Karar 9.

**Sapmalar (hepsi).** (a) bir ADR'ye ya da teknik kısıta dayanır; (b) sağlayıcılar arasında tek bir ortak yol olmadığı yerde yapılmış bir seçimdir.

1. **(a) Webhook yerine yoklama.** Sektörde bounce, gönderim sağlayıcısının webhook'undan ya da bildiriminden gelir (SES SNS, Postmark bounce webhook). Bizim gönderim sağlayıcımız Exchange Online'dır ve böyle bir olay vermez. Graph change notification herkese açık bir HTTPS uç ister; 5 dakikalık gecikme için gerekmez.
2. **(b) Düz metin bounce sezgisel ayrıştırılmaz.** ESP'ler RFC'ye uymayan raporu kalıplarla ayrıştırır. Biz yalnız RFC 3464 raporunu işleriz: yanlış eşleşen bir kalıp yanlış adresi bastırabilir, ve Exchange'in kendi raporları standarttır.
3. **(a) Hesap postası muaftır.** SES'in hesap düzeyindeki listesi bütün postaya uygulanır; Postmark akış başınadır, muafiyet yoktur. Bizde giriş kodu e-postayla gelir (ADR-0063). Yanlışlıkla bastırılan bir adresin sahibi giriş yapamaz, kaldırılmasını da panelden isteyemezdi. Bu yüzden hesap postası gider ve işaretlenir.
4. **(b) Exchange'in `5.4.1 AS(201806281)` kodu kalıcı sayılır.** RFC 3463'e göre `5.4.x` yönlendirme hatasıdır. Exchange bu kodu karşı kiracının dizininde olmayan alıcı için verir; pratikte "alıcı yok"tur. Yalnız belirteçle birlikte kalıcıdır.
5. **(b) Rapor adresi satırın adresi olmalıdır.** Bazı sağlayıcılar raporun adresini bastırır. Biz yönlendirilen ya da takma adlı adresi bastırmayız; kayıt düşeriz.
6. **(a) Şikâyet (FBL) bastırması yok.** ADR-0072 sapma 10.

## Considered Options

- **Gönderimi SES ya da Postmark'a taşımak.** Bounce ve şikâyeti sağlayıcı işlerdi. Yeni gönderici alan adı, DKIM, SPF, Return-Path, ödeme ve hesap sahibi, KVKK md. 9 kapsamında yeni bir yurt dışı aktarım gerekirdi. Bizim ölçekte gereksiz yük (Yusuf, K2).
- **IMAP ve OAuth.** `IMAP.AccessAsApp` kiracı geneli Entra izni ve kutuda `FullAccess` (okuma, yazma, silme) ister. Graph salt okur ve kapsamlıdır.
- **Posta akışı kuralıyla raporları dış bir ayrıştırma servisine yönlendirmek.** Adres ve orijinal başlıklar kiracının dışına akardı. Exchange'in kendi ürettiği NDR'lere kural uygulanıp uygulanmadığı belgede yok.
- **İnsanların da kullandığı eski gönderen kutusunu okumak.** İnsan postası ve SkyMail raporları aynı kutuda olurdu; okuyucunun yetkisi insanların postasını da kapsardı. Ayrı kutular açıldı (K1).
- **Okuyucuya `Mail.ReadWrite` vermek.** İşlenen raporu taşımak ya da silmek için. Saklama etiketi aynı işi yetkisiz yapıyor.
- **VERP.** Exchange Online'da zarf göndericisi kimliği doğrulanan kutu ya da onun adresi olmak zorunda. Her posta için ayrı adres açılamaz. `Message-ID` zaten kuyruk satırını adlandırıyor.
- **Yumuşak retlerde eşik** (ör. N yumuşak ret → bastır). İncelenen sağlayıcılar yumuşak reddi bastırmıyor; dolu kutu ve politika retleri geçicidir. Panel etiketi operatöre gösterir.
- **Bastırmayı bir süre sonra kendiliğinden düşürmek.** Kalıcı ret gerçekten "adres yok" demektir; süre dolunca adrese yeniden posta gider ve itibar yine düşer.
- **Hesap postasını da bastırmak.** Bkz. sapma 3.

## Kaynaklar

- RFC: [3461 (DSN uzantısı)](https://www.rfc-editor.org/rfc/rfc3461), [3463 (ek durum kodları)](https://www.rfc-editor.org/rfc/rfc3463), [3464 (delivery-status)](https://www.rfc-editor.org/rfc/rfc3464), [6522 (multipart/report)](https://www.rfc-editor.org/rfc/rfc6522), [7523 (JWT client assertion)](https://www.rfc-editor.org/rfc/rfc7523)
- Microsoft: [RBAC for Applications](https://learn.microsoft.com/en-us/exchange/permissions-exo/application-rbac), [Graph delta (mesajlar)](https://learn.microsoft.com/en-us/graph/delta-query-messages), [Graph MIME](https://learn.microsoft.com/en-us/graph/outlook-get-mime-message), [sertifika kimliği](https://learn.microsoft.com/en-us/entra/identity-platform/certificate-credentials), [Exchange Online NDR kodları](https://learn.microsoft.com/en-us/troubleshoot/exchange/email-delivery/ndr/non-delivery-reports-in-exchange-online), [outbound spam koruması](https://learn.microsoft.com/en-us/defender-office-365/outbound-spam-protection-about), [kısıtlanan kullanıcılar](https://learn.microsoft.com/en-us/defender-office-365/outbound-spam-restore-restricted-users), [saklama etiketleri](https://learn.microsoft.com/en-us/purview/retention-tags-and-retention-policies)
- Amazon SES: [account-level suppression list](https://docs.aws.amazon.com/ses/latest/dg/sending-email-suppression-list.html)
- Postmark: [bounce webhook](https://postmarkapp.com/developer/webhooks/bounce-webhook), [Suppressions API](https://postmarkapp.com/developer/api/suppressions-api)

## Ek (2026-10-26): kişi bastırılmış adresini Hesap Merkezi'nde görür (ADR-0075)

Karar (Yusuf, 2026-10-26). Karar 1–9 aynen geçerlidir.

- **Kişi görür.** Hesap Merkezi'nin e-posta sayfasında, bastırılmış adresin yanında "Bu adrese posta ulaşmıyor." yazar.
- **Hesap Merkezi SkyMail'in kişi ucundan okur.**
  - Uç `GET /v1/me/email-delivery`'dir. Hesap Merkezi onu kişinin kendi token'ıyla çağırır, `/v1/me/inbox`'ı çağırdığı gibi (ADR-0075 karar 2, ADR-0070 karar 7).
  - Rol yoktur. SkyMail yalnız token'ın `aud`'una (`skymail`) ve `sub`'ına bakar; hesap erişim kapısı geçerlidir.
- **Uç yalnız kişinin kendi satırlarını döner.**
  - Parametre almaz. Döndüğü bastırma kayıtları ya kişinin `sub`'ına bağlıdır ya da adresi token'daki kişinin kendi adreslerinden biridir (`email`; varsa `school_email`).
  - Başka adres ya da kişi sorgulanamaz.
  - Yanıtta adres ve ilk görülme zamanı vardır. Kaynak, kod ve kayıt kimliği yoktur.
  - Hesap Merkezi adresi kişinin birincil, okul ve kişisel adresleriyle sunucuda eşler. Tarayıcıya yalnız adresin türü gider.
- **Kişi bastırmayı kaldıramaz.** Karar 7 aynen geçerlidir: kaldırma yalnız panelden, `skymail:suppressions:manage` rolüyle yapılır. Hesap Merkezi yalnız gösterir.
- **Olay, core kaydı ve core ucu yoktur.** core bastırma bilgisini hiçbir kararında kullanmaz, bu yüzden araya girmez (ADR-0075 karar 2). Kişiye kendiliğinden bildirim istenirse yeniden değerlendirilir (ADR-0071 eki 2026-10-26).
- **Bilinen sınır.** Kişinin `sub`'ı bastırma kaydına yalnız gönderim kişiyi biliyorsa yazılır (karar 8). Keycloak'un giriş kodu ve bugün Forms'un postaları kişisiz gider. Kişisiz bastırılmış bir kişisel adres, token'da karşılığı yoksa görünmez. Birincil adres ve token'da varsa okul adresi, token'dan eşlendiği için görünür.
- **Aydınlatma.** Consequences'taki "e-posta teslim durumu" satırının amacına, bastırmanın kişiye Hesap Merkezi'nde gösterilmesi de girer (hub bileti skymail-bounce-isleme 07).
