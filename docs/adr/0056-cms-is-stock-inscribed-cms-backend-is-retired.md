---
status: accepted
---

# CMS, Fatih'in inscribed imajıdır; cms-backend emekli edilir

SKY LAB'in CMS'i artık Fatih Naz'ın `fatiihnaz/inscribed-dotnet` reposundan çıkan stok `ghcr.io/fatiihnaz/inscribed:latest` imajıdır. Kulüp fork, sarmalayıcı repo ya da ikinci bir kod tabanı tutmaz. inscribed ile cms-backend 2026-05-30'da (`v1.0.0`) ayrıldı; o günden beri inscribed çok daha ileri gitti. İki repoyu birlikte yaşatmak her güncellemede iki kez iş demekti.

`skylab-kulubu/cms-backend` 2026-09-27'de donduruldu. İçeriği kopyalanır ve inscribed'a devredilir (CMS veritabanının kopyasında ilk migration uygulanmış işaretlenir). Bütün tüketiciler aynı gece geçer, çünkü News ve Teams sitelere değil herkese ait ortak listelerdir. Eski uygulama aynı gece kapatılır. Eski CMS veritabanı ve yedeği yerinde kalır; sorun çıkarsa ileri düzeltme yapılır.

Adres değişmez: kalıcı yer bugünkü `api.yildizskylab.com/api` yoludur. Eskisiyle yan yana çalıştığı dönemde inscribed `/api/inscribed` altında durur.

## Consequences

- **Keycloak.** inscribed'ın rol modeli kullanılır: her Site client'ında `content:read` / `content:write` / `schema:sync` rolleri ve bunları `roles` claim'ine yazan bir mapper vardır. Tenant `azp`'dir, audience `skycms` kalır. `cms:access` geçişten sonra emekli olur.
- **Kod sahipliği.** Kod ve npm yayını (inscribed, `@skylab-kulubu/inscribed-auth`, site SDK yükseltmeleri) Fatih'tedir. Kulüp; Keycloak'ı, Dokploy'u, veri taşımayı ve kendi repolarındaki küçük ayarları yapar.
- **`:latest` bilinçli bir risktir.** Her redeploy yeni sürüm çeker. Fatih'ten, kırıcı değişiklikleri yalnız major sürümde ve önceden haber vererek yapması istendi.
- **Hesap silme ve erişim kapısı.** inscribed'da erişim kapısı ve silme ucu yoktur. Hesap silmeyi açmak (ADR-0051), bu ikisi inscribed'a genel ve opsiyonel özellik olarak gelene kadar bekler. Sözleşme Fatih'le paylaşılan raporda tanımlıdır.

## Considered Options

- **cms-backend'i inscribed koduyla güncellemek:** iki repo, her değişiklik iki kez yapılır. Fatih reddetti.
- **Kulüp reposunda ince sarmalayıcı imaj:** Yusuf doğrudan stok imajı seçti.
- **Yeni kalıcı host (`cms.yildizskylab.com`):** URL'ler build'lere gömülü olduğu için her istemcinin ikinci kez taşınmasını gerektirir. Bugünkü yolu korumak geçiş gecesini küçültür.
