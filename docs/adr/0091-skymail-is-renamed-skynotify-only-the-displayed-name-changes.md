---
status: accepted
---

# SkyMail'in adı SkyNotify olur; yalnız görünen ad değişir, teknik kimlikler (`skymail` istemcisi, `skymail:*` rolleri, imajlar, ortam değişkenleri, veritabanı) kalır

ADR-0070 SkyMail'i kanaldan bağımsız bir iletişim servisine genişletti (e-posta, uygulama içi kutu, push, SMS) ve arayüzün ürün adını "İletişim" koydu. ADR-0090 arayüzü `notify.yildizskylab.com`'a taşıdı. "SkyMail" adı artık servisin işini anlatmıyor. Ayrıca `mail.yildizskylab.com` adresinde ayrı bir ürün, kulübün ortak posta kutusu gelecek; ikisinin adı karışmamalı.

Karar (Yusuf, 2026-11-24):

1. **Ürünün resmi adı SkyNotify'dır.** Kullanıcının, üyenin ya da yöneticinin gördüğü her yerde "SkyMail" yerine SkyNotify yazılır. ADR-0070 karar 8'deki "İletişim" ürün adının yerine de SkyNotify geçer; "iletişim servisi" belgelerde servisin işini anlatan genel bir ad olarak kalabilir.
2. **Görünen ad şu yerlerde değişir:** konsolun marka alanı ve sayfa başlıkları; her postanın alt bilgisindeki ürün satırı; konsolun hata, uyarı ve onay metinleri; postaların konu ve önizleme metinleri; yönetim panelindeki uygulama adı ve konsol değiştiricisi; rol gruplarının görünen ad ve açıklamaları; Hesap Merkezi'ndeki izin, uygulama tercihi ve bildirim metinleri; Keycloak karşılama sayfası ile istemcilerin görünen ad ve açıklamaları; durum sayfasındaki hizmet adı; Forms'taki aktarım metinleri. Forms Fatih'in deposudur, ona not gider.
3. **Teknik kimlikler değişmez:**
   - Keycloak istemci kimliği `skymail` ve token'lardaki `aud=skymail` (sky-app sözleşmesi dahil).
   - `skymail:*` istemci rolleri, `/ROLLER/SKYMAIL-*` rol grubu adları ve `skymail-api-audience` gibi kapsam adları.
   - `SKYMAIL_*` ortam değişkenleri ve OpenBao yolları.
   - GHCR imajları (`ghcr.io/skylab-kulubu/skymail-*`) ve Dokploy uygulama adları.
   - `skymail` veritabanı ve tablo adları, `/api/skymail` yolu, `X-SkyMail-Queue-Id` başlığı, `skylab_skymail_*` metrikleri ve `skylab-skymail-*` sunucu birimleri.
   - Microsoft 365 uygulama kaydı `skymail-posta` ve gönderen işareti `CustomAttribute10=skymail-gonderen`.
   - Template key'ler, Go modül yolu ve koddaki `skymail`/`SkyMail` tanımlayıcıları. Yeni kod da bu adları sürdürür; tanımlayıcılar toplu olarak yeniden adlandırılmaz.
4. **Rol ve izinlerin görünen adı ayrıdır.** Kişinin gördüğü ad rol değerinden değil, görünen addan gelir (Hesap Merkezi izin kataloğu, rol gruplarının `display_name_tr`'si). Bu yüzden ad değişikliği için rol değerine dokunmak gerekmez.
5. **Belgeler.** Yeni yazılan belge, README ve CONTEXT.md ürünü SkyNotify diye anar. Kabul edilmiş ADR'lerin metni değiştirilmez: eski ADR'lerdeki "SkyMail" bugünkü SkyNotify'dır.
6. **Sıra.** Görünen ad değişikliği `notify.` geçişinden (ADR-0090) sonra yapılır. İkisi aynı dosyalara dokunuyor: Keycloak karşılama kartı ve core-frontend'deki konsol bağlantıları.
7. **Açık: depo adları.** `skymail-backend` ve `skymail-frontend` depolarının adı bu kararla değişmez. Yeniden adlandırma ayrı bir karardır. Yapılırsa önce imaj adı iş akışlarında `skymail-*` olarak sabitlenir. Bugün imaj adı `github.repository`'den türüyor; depo adı değişince imajlar yeni bir pakete basılır, Dokploy ise eskisini çekmeye devam eder.

## Consequences

- Daha önce gönderilmiş postaların alt bilgisinde eski ad kalır.
- Kodda, logda ve ortam değişkenlerinde "skymail" yazmaya devam eder. Yeni katılan biri depo adıyla ürün adını eşleştirmeli. Bunun için her iki deponun README'si ilk satırda bu depoların SkyNotify olduğunu söyler.
- Görünen ad birkaç depoda değişir: skymail-frontend, core-frontend, account-center, e-skylab-keycloak, durum sayfası ve Forms. Her biri kendi yayınıyla çıkar. Bir süre bazı ekranlarda eski ad, bazılarında yeni ad görünebilir.
- Sistem şablonlarının alt bilgisi depodaki şablonlardan gelir (`emails/`, Template seed). Seed, operatörün değiştirdiği şablonun üstüne yazmaz (ADR-0047). O şablonlarda ad elle ya da seed'in zorlama kipiyle güncellenir.

## Endüstri uygulamasıyla karşılaştırma

**Uyanlar:**
- Ürün yeniden adlandırmalarında genelde yalnız görünen ad değişir, teknik kimlikler kalır. Azure Active Directory'nin adı Microsoft Entra ID olduğunda API'ler, uç noktalar, PowerShell modülleri ve kimlikler değişmedi. Amazon Elasticsearch Service'in adı Amazon OpenSearch Service olduğunda `es:` IAM eylemleri ve API ad alanı kaldı.
- Görünen adın rol değerinden ayrı tutulması, kimlik sağlayıcılarda yaygındır. Keycloak'ta istemcinin ve rolün görünen adı ile açıklaması kimliğinden ayrıdır.

**Sapma:**
1. **Yeni kod da eski tanımlayıcıyı kullanır.** Microsoft ve AWS yeni yüzeylerde zamanla yeni adı kullanmaya başladı. Bizde depo, istemci, rol ve kod adı birlikte `skymail` kalır. Gerekçe: tek bir tutarlı teknik ad, yarısı eski yarısı yeni adlı bir koddan daha kolay okunur.

## Considered Options

- **Her şeyi yeniden adlandırmak** (istemci kimliği, roller, ortam değişkenleri, imajlar, veritabanı). Seçilmedi. Rol değerleri altı depoda ~1.800 yerde geçiyor ve token'larda taşınıyor. İstemci kimliği `aud` ile sky-app sözleşmesinde, Forms'un servis hesabında, Hesap Merkezi'nde ve core'da duruyor. Değişiklik eski ve yeni adın birlikte kabul edildiği bir geçiş dönemi, Mobile Lab'in uygulama yayını ve Fatih'in Forms yayınını gerektirir. Kullanıcıya görünen bir kazancı yok.
- **"İletişim" adını sürdürmek.** Türkçe ve genel bir ad. Ortak posta kutusu da "iletişim" işidir. Seçilmedi.
- **Depo adlarını şimdi değiştirmek.** GitHub eski adı yönlendirir, ama imaj adı, Dokploy ve sihirbazlardaki sabit adlar yüzünden ayrı bir pencere ister. Açık bırakıldı (karar 7).

## Kaynaklar

- Microsoft Learn, New name for Azure Active Directory: https://learn.microsoft.com/en-us/entra/fundamentals/new-name
- AWS News Blog, Amazon Elasticsearch Service Is Now Amazon OpenSearch Service: https://aws.amazon.com/blogs/aws/amazon-elasticsearch-service-is-now-amazon-opensearch-service-and-supports-opensearch-10/
- GitHub Docs, Renaming a repository: https://docs.github.com/en/repositories/creating-and-managing-repositories/renaming-a-repository
- ADR-0047 (şablonların iki yazarı), ADR-0070 (iletişim servisi), ADR-0090 (ürün alt alan adları).
