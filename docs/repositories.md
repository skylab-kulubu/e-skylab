# Repository catalog

Bu katalog SKY LAB organizasyonundaki tüm eğitim, yarışma ve dönemsel etkinlik
depolarını değil, ortak kulüp platformunu oluşturan ürünleri kapsar. Diğer
çalışmalar [GitHub organizasyonunda](https://github.com/skylab-kulubu) bulunur.

## Aktif platform

| Depo | Sorumluluk | Ana yüzey |
| --- | --- | --- |
| [`e-skylab`](https://github.com/skylab-kulubu/e-skylab) | Platform mimarisi, depo kataloğu, ortak alan dili ve ADR'ler | Bu hub |
| [`e-skylab-keycloak`](https://github.com/skylab-kulubu/e-skylab-keycloak) | Keycloak imajı, login teması, SPI'lar ve realm uzlaştırması | `e.yildizskylab.com` |
| [`account-center`](https://github.com/skylab-kulubu/account-center) | Hesap, güvenlik, oturum ve self-servis BFF/UI | `my.yildizskylab.com` |
| [`core-backend`](https://github.com/skylab-kulubu/core-backend) | Kulüp, etkinlik, bilet, katılım, sertifika, SkyPass ve kısa link alanı | `api.yildizskylab.com` |
| [`core-frontend`](https://github.com/skylab-kulubu/core-frontend) | Kulüp yönetim ve etkinlik operasyon paneli | `admin.yildizskylab.com` |
| [`sky-app`](https://github.com/skylab-kulubu/sky-app) | Üye ve personel mobil uygulaması | iOS / Android |
| [`skylab-site`](https://github.com/skylab-kulubu/skylab-site) | Genel kulüp sitesi ve insan dostu sertifika doğrulama sayfaları | `yildizskylab.com`, `/c/*` |
| [`cms-backend`](https://github.com/skylab-kulubu/cms-backend) | Site içeriği ve yayın API'si | CMS API |
| [`forms-backend`](https://github.com/skylab-kulubu/forms-backend) | Form, şablon ve yanıt alanı | Forms API |
| [`forms-frontend`](https://github.com/skylab-kulubu/forms-frontend) | Form oluşturma, doldurma ve yönetim arayüzü | `forms.yildizskylab.com` |
| [`skymail-backend`](https://github.com/skylab-kulubu/skymail-backend) | Posta taslağı, liste, onay ve gönderim API'si | Mail API |
| [`skymail-frontend`](https://github.com/skylab-kulubu/skymail-frontend) | Posta operasyon arayüzü | `mail.yildizskylab.com` |
| [`skylcn-ui`](https://github.com/skylab-kulubu/skylcn-ui) | Paylaşılan tasarım sistemi; hazırlanıyor (ADR 0055) | Paket (`@skylab-kulubu/skylcn-ui`, henüz yayımlanmadı) |
| [`inscribed-auth`](https://github.com/skylab-kulubu/inscribed-auth) | Paylaşılan kimlik doğrulama SDK'sı | Paket (`@skylab-kulubu/inscribed-auth`) |
| [`skylab-assets`](https://github.com/skylab-kulubu/skylab-assets) | Resmî logo ve marka varlıkları | Varlık deposu |

## Bağımsız veya bitişik ürünler

Bu depolar platform kataloğunda görünür, fakat ana servis ağacının parçası
sayılmaz. Kendi yaşam döngülerini korurlar.

| Depo | Konum |
| --- | --- |
| [`arge`](https://github.com/skylab-kulubu/arge) | AR-GE web yüzeyi |
| [`skylab-yildizjam`](https://github.com/skylab-kulubu/skylab-yildizjam) | YıldızJam etkinlik sitesi |
| [`yildizplace-backend`](https://github.com/skylab-kulubu/yildizplace-backend) | YıldızPlace API'si |
| [`yildizplace-frontend`](https://github.com/skylab-kulubu/yildizplace-frontend) | YıldızPlace arayüzü* |

\* Org içindeki depo tek commit'lik bir şablon; gerçek YıldızPlace arayüzü şu an
org dışında [`egehanavcu/rplace-frontend`](https://github.com/egehanavcu/rplace-frontend)
deposunda çalışıyor, org'a transferi istendi.

## Eski veya yerine yenisi gelen depolar

| Depo / bileşen | Durum | Yerine geçen sınır |
| --- | --- | --- |
| `e-skylab` içindeki `keycloak/` | Taşındı | `e-skylab-keycloak` |
| `e-skylab` içindeki Eureka ve Gateway | Kullanılmıyor | Açık servis adresleri ve ters vekil |
| `e-skylab` içindeki LDAP | Kullanılmıyor | Keycloak grup ve kullanıcı modeli |
| [`super-skylab`](https://github.com/skylab-kulubu/super-skylab) | Arşivlendi | `core-backend` ve ayrık servisler |
| [`skyl-app-backend`](https://github.com/skylab-kulubu/skyl-app-backend) | Arşivlendi | `core-backend` içine taşındı |
| [`skyl-app-frontend`](https://github.com/skylab-kulubu/skyl-app-frontend) | Arşivlendi | `core-backend` içine taşındı |
| [`skyticket-backend`](https://github.com/skylab-kulubu/skyticket-backend) | Arşivlendi | Bilet alanı `core-backend` içinde |
| [`superadmin`](https://github.com/skylab-kulubu/superadmin) | Arşivlendi | `core-frontend` |
| [`components`](https://github.com/skylab-kulubu/components) | Arşivlendi | `skylcn-ui` |
| [`oda-skyl-app`](https://github.com/skylab-kulubu/oda-skyl-app) | Arşivlendi | Bağımsız ürün değildi, tek günlük deneme |

Bir depo yeniden etkinleştirilecekse önce bu tablo ve ilgili ADR güncellenir;
aynı alan için ikinci bir doğruluk kaynağı oluşturulmaz.

### Arşivlenen diğer depolar

2026-09 temizliğinde, yukarıdaki platform kataloğunun hiç parçası olmamış
eğitim, yarışma ve dönemsel etkinlik depoları da arşivlendi:

| Depo | Not |
| --- | --- |
| [`yildizskylab`](https://github.com/skylab-kulubu/yildizskylab) | 2022 düz HTML kulüp sitesi → `skylab-site` |
| [`yildizskylab.github.io`](https://github.com/skylab-kulubu/yildizskylab.github.io) | 2023 kulüp sitesi → `skylab-site` |
| [`yildizskylab_frontend`](https://github.com/skylab-kulubu/yildizskylab_frontend) | CRA → `skylab-site` |
| [`yildizskylab-public-nextjs`](https://github.com/skylab-kulubu/yildizskylab-public-nextjs) | Next 13 → `skylab-site` |
| [`yildizskylab-public-reactjs`](https://github.com/skylab-kulubu/yildizskylab-public-reactjs) | CRA → `skylab-site` |
| [`yildizskylab-panel-frontend`](https://github.com/skylab-kulubu/yildizskylab-panel-frontend) | Eski panel → `core-frontend` |
| [`yildizskylab-admin-panel`](https://github.com/skylab-kulubu/yildizskylab-admin-panel) | CRA panel → `core-frontend` |
| [`super-admin`](https://github.com/skylab-kulubu/super-admin) | 2025 panel taslağı → `core-frontend` |
| [`YildizSkyLabBackend`](https://github.com/skylab-kulubu/YildizSkyLabBackend) | Go backend → `core-backend` |
| [`skyticket`](https://github.com/skylab-kulubu/skyticket) | → `core-backend` |
| [`skyl-app-old-repository-2023`](https://github.com/skylab-kulubu/skyl-app-old-repository-2023) | → `core-backend` |
| [`skyform`](https://github.com/skylab-kulubu/skyform) | Java → `forms-backend` |
| [`skyform-frontend`](https://github.com/skylab-kulubu/skyform-frontend) | Tek commit'lik şablon → `forms-frontend` |
| [`skyjam`](https://github.com/skylab-kulubu/skyjam) | → `skylab-yildizjam` |
| [`artlab`](https://github.com/skylab-kulubu/artlab) | → `artlab-site` |
| [`Artlab-skylab`](https://github.com/skylab-kulubu/Artlab-skylab) | → `artlab-site` |
| [`artlab-yeni`](https://github.com/skylab-kulubu/artlab-yeni) | → `artlab-site` |
| [`agc`](https://github.com/skylab-kulubu/agc) | → `agc-website-new` |
| [`skylite`](https://github.com/skylab-kulubu/skylite) | Skylite bitti |
| [`skylab-skylite`](https://github.com/skylab-kulubu/skylab-skylite) | Skylite bitti |
| [`skydays`](https://github.com/skylab-kulubu/skydays) | 2022 SkyDays, içinde AGC sayfası var |
| [`maintenance`](https://github.com/skylab-kulubu/maintenance) | Eski bakım sayfası |
| [`mail-sender`](https://github.com/skylab-kulubu/mail-sender) | → `skymail` |
| [`bulk-mail-sender`](https://github.com/skylab-kulubu/bulk-mail-sender) | → `skymail` |
| [`skydays-2025`](https://github.com/skylab-kulubu/skydays-2025) | 2025 etkinlik sitesi |
| [`skydays-2024`](https://github.com/skylab-kulubu/skydays-2024) | 2024 etkinlik sitesi |
| [`skydays-2023`](https://github.com/skylab-kulubu/skydays-2023) | 2023 etkinlik sitesi |
| [`yilbasi-26`](https://github.com/skylab-kulubu/yilbasi-26) | Yılbaşı weblab projesi |
| [`gecekodu-backend`](https://github.com/skylab-kulubu/gecekodu-backend) | Gece Kodu (Java) |
| [`gecekodu-backend-old`](https://github.com/skylab-kulubu/gecekodu-backend-old) | Gece Kodu (.NET) |
| [`gecekodu-frontend`](https://github.com/skylab-kulubu/gecekodu-frontend) | Gece Kodu arayüzü |
| [`yildizlar-yarisiyor`](https://github.com/skylab-kulubu/yildizlar-yarisiyor) | YTÜMK için |
| [`stand-site`](https://github.com/skylab-kulubu/stand-site) | Stand sitesi |
| [`weblab-project-management`](https://github.com/skylab-kulubu/weblab-project-management) | İki haftada bırakılmış |
| [`Skylab-Coders-Backend`](https://github.com/skylab-kulubu/Skylab-Coders-Backend) | Tek commit |
| [`Skylab-Coders-Mobile`](https://github.com/skylab-kulubu/Skylab-Coders-Mobile) | İki günde bırakılmış |
| [`bizbize-backend`](https://github.com/skylab-kulubu/bizbize-backend) | Sadece README |
| [`gecekodu`](https://github.com/skylab-kulubu/gecekodu) | Tek dosya |
| [`skyflix`](https://github.com/skylab-kulubu/skyflix) | Express denemesi |
| [`microsoft_forms_bot`](https://github.com/skylab-kulubu/microsoft_forms_bot) | Gece Kodu form betiği |
| [`skylab-bootcamp2024-web101`](https://github.com/skylab-kulubu/skylab-bootcamp2024-web101) | Bootcamp |
| [`webcookies`](https://github.com/skylab-kulubu/webcookies) | Cookies ekibi görevleri |
| [`WEBLAB-TEST-TOOLS`](https://github.com/skylab-kulubu/WEBLAB-TEST-TOOLS) | Eğitim |
| [`FlexBox-Using`](https://github.com/skylab-kulubu/FlexBox-Using) | Eğitim |
| [`React-ile-Front-End`](https://github.com/skylab-kulubu/React-ile-Front-End) | Akademi dersi |
