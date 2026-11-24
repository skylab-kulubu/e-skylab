---
status: accepted
---

# Bildirim servisinin adı SkyNotify olur, "SkyMail" adı `mail.`'deki ortak posta kutusu ürününe geçer; SkyNotify'ın görünen ve teknik bütün adları tek pencerede `skynotify`'a taşınır

ADR-0070 SkyMail'i kanaldan bağımsız bir iletişim servisine genişletti (e-posta, uygulama içi kutu, push, SMS) ve arayüzün ürün adını "İletişim" koydu. ADR-0090 arayüzü `notify.yildizskylab.com`'a taşıdı. "SkyMail" adı artık servisin işini anlatmıyor. `mail.yildizskylab.com`'a ise ayrı bir ürün geliyor: kulübün ortak posta kutusu, yani YK'nın kişisel kulüp adresleri ve `info@`. Bu ürünün de kendi istemcisi, depoları ve ortak Postgres'te kendi veritabanı olacak.

Karar (Yusuf, 2026-11-24):

1. **Bildirim servisinin adı SkyNotify'dır.** ADR-0070 karar 8'deki "İletişim" ürün adının yerine de SkyNotify geçer. "İletişim servisi" belgelerde servisin işini anlatan genel bir ad olarak kalabilir.
2. **"SkyMail" adı ortak posta kutusu ürününündür** (`mail.yildizskylab.com`). Bu ad ürünün hem görünen adı hem de teknik adlarıdır: depo, istemci, roller, veritabanı.
3. **SkyNotify'ın bütün adları `skynotify`'a taşınır.** Bu, ADR-0090 karar 4'teki "Yalnız adres değişir; depo, istemci ve rol adları kalır" cümlesinin yerine geçer. Kapsam:
   - **Görünen adlar:** konsol, posta alt bilgisi ve metinleri, panel, Hesap Merkezi, Keycloak karşılama sayfası, durum sayfası.
   - **Depolar:** `skymail-backend` ve `skymail-frontend` → `skynotify-backend` ve `skynotify-frontend`. Go modül yolu da değişir.
   - **İmajlar ve dağıtım:** GHCR paketleri `ghcr.io/skylab-kulubu/skynotify-*`; Dokploy uygulama adları ve iç servis adları.
   - **Keycloak:** istemci `skymail` → `skynotify`, rolleri `skymail:*` → `skynotify:*`, rol grupları `/ROLLER/SKYMAIL-*` → `/ROLLER/SKYNOTIFY-*`, istemci kapsamları ve audience eşleyicileri.
   - **Yapılandırma:** ortam değişkenleri `SKYMAIL_*` → `SKYNOTIFY_*`, bunu okuyan bütün servisler dahil (core'un `SKYMAIL_URL`'si gibi); OpenBao yolları.
   - **Veri ve işletim:** veritabanı ve giriş rolleri; `/api/skymail` yolu; `X-SkyMail-*` posta başlıkları; `skylab_skymail_*` metrikleri; `skylab-skymail-*` sunucu birimleri.
   - **Microsoft 365:** uygulama kaydı `skymail-posta` ve gönderen işareti `CustomAttribute10=skymail-gonderen`.
   - **Kod ve araçlar:** koddaki tanımlayıcılar; sihirbaz ve işletim betiklerindeki sabit adlar.
4. **Geçiş aşamasız ve tek penceredir.** Eski ve yeni adı birlikte kabul eden bir ara dönem yoktur. Pencere şöyle işler:
   - Önce kod PR'ları birleşir. Bunlar yalnız yeni adları bilir.
   - Sonra tek bir sihirbaz önce sandbox'ta, sonra production'da adlandırmaları sırayla yapar, yayınlar ve her şeyin yeni adla çalıştığını doğrular.
   - Eski adlar aynı pencerede silinir. Kısa bir kesinti kabul edilir.
   - Doğrulama tutmazsa sihirbazın geri alma yolu eski adları geri getirir.
5. **Forms Fatih'indir.** Forms'taki adlar için ona not gider. SkyNotify'ın Forms'un ayarında yazılı iç adresi, Fatih ayarını değiştirene kadar ağda eski adla da çözülür. Bu tek istisna Fatih'in geçişiyle kalkar.
6. **Eski adlar ortak posta kutusu ürününe ancak pencere bitince verilir.** Eski depo adları için GitHub bir yönlendirme tutar. Aynı adla yeni bir depo açılınca bu yönlendirme kalkar ve eski bağlantılar yeni ürünü gösterir. Bu yüzden yeni ürünün depoları açılmadan önce yerel klonların uzak adresleri, sihirbazlar ve iş akışları yeni ada geçmiş olur. Eski GHCR paketleri pencereden sonra silinir. Böylece yeni ürünün imajları SkyNotify'ın eski imajlarıyla aynı pakete düşmez.
7. **Belgeler.** Kabul edilmiş ADR'lerin metni değiştirilmez. 2026-11-24'ten önce yazılmış ADR'lerdeki "SkyMail" ve `skymail` bugünkü SkyNotify'dır. CONTEXT.md, README'ler ve depo kataloğu yeni adları kullanır.
8. **Açık (önerisi "kalsın"):**
   - Gönderilmiş postalardaki genel bağlantılar için `/api/skymail/t/` (açılma ve tıklama) ve `/api/skymail/u/` (tek tık çıkış) yolları, SkyNotify'a giden kalıcı bir yönlendirme olarak kalır. Bu iki yol silinirse takipli eski postalardaki her bağlantı ve eski toplu postalardaki tek tık çıkış bağlantısı çalışmaz (RFC 8058). Yeni ürün `/api/skymail` yolunu kullanmaz; o `mail.`'de durur.
   - Geri dönen posta okuyucusu, pencereden önce gönderilmiş postaların geri dönüşleri için eski `X-SkyMail-Queue-Id` başlığını da okur. Yeni postalar yalnız yeni başlıkla gider. Okunmazsa o adresler bastırılmaz.

## Consequences

- Kısa bir kesinti olur. Bu sürede postalar kuyrukta bekler, konsol ve bildirim kutusu açılmaz.
- Daha önce gönderilmiş postalardaki takip ve tek tık çıkış bağlantıları `/api/skymail/…` yolunu gösterir. Karar 8'deki yönlendirme kalmazsa bu bağlantılar çalışmaz.
- Eski yedekler `skymail` adlı veritabanını taşır. Geri yükleme ve silme tekrarı (ADR-0053) bu adı yeni adla eşler.
- 2026-11-24'ten önce yazılmış ADR'lerdeki depo bağlantıları, yeni ürün `skymail-*` adlı bir depo açtığında o ürünü gösterir.
- sky-app'e verilen sözleşme (Mobile Lab) yeni istemci adı ve yolla güncellenir.

## Endüstri uygulamasıyla karşılaştırma

**Uyanlar:**
- Ürünün tek bir adının olması ve teknik adın görünen adla aynı olması, yeni katılanın ürünü kodda bulmasını kolaylaştırır.

**Sapmalar:**
1. **Teknik kimlikler de değişir.** Sektörde ürün yeniden adlandırmalarında genelde yalnız görünen ad değişir, teknik kimlikler kalır. Azure Active Directory'nin adı Microsoft Entra ID olduğunda API'ler, uç noktalar ve kimlikler değişmedi. Amazon Elasticsearch Service OpenSearch Service olduğunda `es:` IAM eylemleri kaldı. Gerekçe: "SkyMail" adı ve `skymail` teknik adı yeni ürüne verilecek. İki ürünün aynı teknik adı paylaşması rol grubu adlarında (rol değerinden türer, realm genelinde tektir), loglarda ve aramada çakışır.
2. **Aşamasız geçiş.** Sektör kimlik ve yapılandırma adı değişikliklerinde eski ve yeni adın birlikte kabul edildiği expand/contract geçişini önerir. Gerekçe: servis kulüp içidir, kısa kesinti kabul edilebilir ve yeni ürün yazılana kadar zaman var. Ara dönem kodu yazmak ve sonra silmek gereksiz iştir. Bunun bedeli geri almanın tek bir adımda yapılmasıdır.
3. **Eski ad başka bir ürüne verilir.** Gerekçe: iki ürün de kulüp içidir ve "SkyMail" ortak posta kutusunu daha iyi anlatır.

## Considered Options

- **Yalnız görünen adı değiştirmek, teknik adları korumak.** Seçilmedi: `skymail` teknik adı yeni ürüne boşalmalı.
- **Yeni ürüne `skymail` dışında bir teknik ad vermek** (`clubmail-*`, `skymail-app-*`). Seçilmedi: Yusuf ürünün görünen ve teknik adının aynı olmasını istedi. `skymail-app` ayrıca SkyNotify'ın eski container adıdır.
- **Expand/contract** (bir süre iki ad birlikte). Seçilmedi (karar 4).
- **"İletişim" adını sürdürmek.** Seçilmedi.

## Kaynaklar

- Microsoft Learn, New name for Azure Active Directory: https://learn.microsoft.com/en-us/entra/fundamentals/new-name
- AWS News Blog, Amazon Elasticsearch Service Is Now Amazon OpenSearch Service: https://aws.amazon.com/blogs/aws/amazon-elasticsearch-service-is-now-amazon-opensearch-service-and-supports-opensearch-10/
- GitHub Docs, Renaming a repository: https://docs.github.com/en/repositories/creating-and-managing-repositories/renaming-a-repository
- PostgreSQL, ALTER DATABASE ve ALTER ROLE: https://www.postgresql.org/docs/current/sql-alterdatabase.html, https://www.postgresql.org/docs/current/sql-alterrole.html
- ADR-0050 (iki giriş rolü), ADR-0053 (geri yüklemede silme tekrarı), ADR-0070, ADR-0076 (rol grupları), ADR-0089 (yayın modeli), ADR-0090 (ürün alt alan adları).
