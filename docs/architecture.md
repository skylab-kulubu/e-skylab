# Platform architecture

## İlkeler

1. **Her ürün kendi deposunda yaşar.** Derleme, test, sürüm ve dağıtım o depoda
   tanımlanır.
2. **Keycloak kimliğin kaynağıdır.** Uygulamalar ayrı kullanıcı dizinleri veya
   LDAP tabanlı ikinci bir üyelik modeli kurmaz.
3. **Core kulüp alanının kaynağıdır.** Etkinlik, bilet, katılım, sertifika,
   SkyPass ve kulüp profilinin uygulama verileri Core'da tutulur.
4. **Servisler açık sınırlarla konuşur.** Eureka veya merkezi Spring Gateway
   yoktur. Dış yönlendirme ters vekil üzerinden, servisler arası sözleşmeler
   belgelenmiş HTTP/API sınırları üzerinden yürür.
5. **Veri sahipliği paylaşılmaz.** Her servis kendi şemasını ve geçişlerini
   yönetir; başka bir servisin tablolarına doğrudan yazmaz.
6. **Silme geri alınabilir olmalıdır.** Ürün verilerinde varsayılan yaklaşım
   soft delete ve denetlenebilir yaşam döngüsüdür. Güvenlik, yasal saklama veya
   gizlilik nedeniyle fiziksel silme gerekiyorsa ürün deposunda açıkça
   belgelenir.

## Sınırlar

| Alan | Kaynak | Tüketiciler |
| --- | --- | --- |
| Kimlik, oturum, grup ve istemci rolleri | `e-skylab-keycloak` | Tüm giriş yapan uygulamalar |
| Etkinlik, kullanıcı gölgesi, bilet, katılım, sertifika, SkyPass | `core-backend` | Admin, mobil, ana site ve bağlı servisler |
| Genel site içeriği | `cms-backend` | `skylab-site` ve yetkili editörler |
| Formlar ve yanıtlar | `forms-backend` | `forms-frontend`, Core entegrasyonları |
| Posta taslağı, liste ve gönderim | `skymail-backend` | `skymail-frontend`, yetkili servisler |
| Kullanıcı self-servis işlemleri | `account-center` BFF | Tarayıcı; arkada Keycloak Account/Admin sözleşmeleri |

## Kimlik akışı

- `e.yildizskylab.com` üzerinde Keycloak çalışır.
- Login teması, SPI'lar, realm uzlaştırma betikleri ve Keycloak imajı yalnızca
  `e-skylab-keycloak` deposundadır.
- Uygulamalar Authorization Code akışı, PKCE/PAR ve kendi istemci rollerini
  kullanır.
- Grup üyeliği kulüp üyeliği ve ekip yapısının kaynağıdır. Aynı gerçeği ikinci
  bir realm rolü veya uygulama tablosuyla çoğaltmayız.
- `account-center`, Keycloak'ın yerine geçmez; kullanıcıya markalı self-servis
  deneyimi sunan BFF sınırıdır.

## Dağıtım modeli

- Her çalışan depo kendi imajını ve GitHub Actions iş akışını üretir.
- Üretim dağıtımları değişmez imaj digest'iyle sabitlenir; `latest`, `main` ve
  `production` yalnızca kolaylık etiketleridir.
- Ortam onayları yalnızca gerçek bir operasyonel ayrım gerektiğinde kullanılır.
  Keycloak sürümlerinde her koşuda manuel onay yoktur; fiziksel WebAuthn kanıtı
  commit'e bağlı otomatik bir yayın kapısıdır.
- Ortam değişkenleri ve sırlar bu hub'da tutulmaz.

## Emekliye ayrılan parçalar

- Eureka servis keşfi
- Spring Cloud Gateway katmanı
- LDAP tabanlı üye kaynağı
- `super-skylab` Java monoliti
- Hub içindeki ortak OPA, RabbitMQ ve gözlemlenebilirlik Compose yığınları

Bu parçaların geçmişi `legacy/e-skylab-monolith-2026-09-20` etiketindedir;
aktif mimarinin parçası olarak dağıtılmazlar.
