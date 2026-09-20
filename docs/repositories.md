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
| [`superadmin`](https://github.com/skylab-kulubu/superadmin) | Kulüp yönetim ve etkinlik operasyon paneli | `admin.yildizskylab.com` |
| [`sky-app`](https://github.com/skylab-kulubu/sky-app) | Üye ve personel mobil uygulaması | iOS / Android |
| [`skylab-site`](https://github.com/skylab-kulubu/skylab-site) | Genel kulüp sitesi ve insan dostu sertifika doğrulama sayfaları | `yildizskylab.com`, `/c/*` |
| [`cms-backend`](https://github.com/skylab-kulubu/cms-backend) | Site içeriği ve yayın API'si | CMS API |
| [`forms-backend`](https://github.com/skylab-kulubu/forms-backend) | Form, şablon ve yanıt alanı | Forms API |
| [`forms-frontend`](https://github.com/skylab-kulubu/forms-frontend) | Form oluşturma, doldurma ve yönetim arayüzü | `forms.yildizskylab.com` |
| [`skymail-backend`](https://github.com/skylab-kulubu/skymail-backend) | Posta taslağı, liste, onay ve gönderim API'si | Mail API |
| [`skymail-frontend`](https://github.com/skylab-kulubu/skymail-frontend) | Posta operasyon arayüzü | `mail.yildizskylab.com` |
| [`components`](https://github.com/skylab-kulubu/components) | Paylaşılan arayüz bileşenleri | Paket |
| [`skylab-assets`](https://github.com/skylab-kulubu/skylab-assets) | Resmî logo ve marka varlıkları | Varlık deposu |

## Bağımsız veya bitişik ürünler

Bu depolar platform kataloğunda görünür, fakat ana servis ağacının parçası
sayılmaz. Kendi yaşam döngülerini korurlar.

| Depo | Konum |
| --- | --- |
| [`arge`](https://github.com/skylab-kulubu/arge) | AR-GE web yüzeyi |
| [`oda-skyl-app`](https://github.com/skylab-kulubu/oda-skyl-app) | Oda uygulaması |
| [`skylab-yildizjam`](https://github.com/skylab-kulubu/skylab-yildizjam) | YıldızJam etkinlik sitesi |
| [`yildizplace-backend`](https://github.com/skylab-kulubu/yildizplace-backend) | YıldızPlace API'si |
| [`yildizplace-frontend`](https://github.com/skylab-kulubu/yildizplace-frontend) | YıldızPlace arayüzü |

## Eski veya yerine yenisi gelen depolar

| Depo / bileşen | Durum | Yerine geçen sınır |
| --- | --- | --- |
| `e-skylab` içindeki `keycloak/` | Taşındı | `e-skylab-keycloak` |
| `e-skylab` içindeki Eureka ve Gateway | Kullanılmıyor | Açık servis adresleri ve ters vekil |
| `e-skylab` içindeki LDAP | Kullanılmıyor | Keycloak grup ve kullanıcı modeli |
| [`super-skylab`](https://github.com/skylab-kulubu/super-skylab) | Eski Java monoliti | `core-backend` ve ayrık servisler |
| [`skyl-app-backend`](https://github.com/skylab-kulubu/skyl-app-backend) | Aktif backend değil | Kısa link ve sertifika sözleşmeleri `core-backend` içinde |
| [`skyl-app-frontend`](https://github.com/skylab-kulubu/skyl-app-frontend) | Aktif frontend değil | `/c/*` doğrulaması `skylab-site` içinde |
| [`inscribed-auth`](https://github.com/skylab-kulubu/inscribed-auth) | Eski/deneysel kimlik yüzeyi | `account-center` ve `e-skylab-keycloak` |
| [`skyticket-backend`](https://github.com/skylab-kulubu/skyticket-backend) | Eski bilet servisi | Bilet alanı `core-backend` içinde |

Bir depo yeniden etkinleştirilecekse önce bu tablo ve ilgili ADR güncellenir;
aynı alan için ikinci bir doğruluk kaynağı oluşturulmaz.
