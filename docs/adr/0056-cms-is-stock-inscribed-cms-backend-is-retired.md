---
status: accepted
---

# CMS, Fatih'in inscribed imajıdır; cms-backend emekli edilir

SKY LAB'in CMS'i artık Fatih Naz'ın `fatiihnaz/inscribed-dotnet` reposundan çıkan stok `ghcr.io/fatiihnaz/inscribed:latest` imajıdır. Kulüp fork, sarmalayıcı repo ya da ikinci bir kod tabanı tutmaz. inscribed ile cms-backend 2026-05-30'da (`v1.0.0`) ayrıldı; o günden beri inscribed çok daha ileri gitti. İki repoyu birlikte yaşatmak her güncellemede iki kez iş demekti.

`skylab-kulubu/cms-backend` 2026-09-27'de donduruldu. İçeriği kopyalanır ve inscribed'a devredilir (CMS veritabanının kopyasında ilk migration uygulanmış işaretlenir). Bütün tüketiciler aynı gece geçer, çünkü News ve Teams sitelere değil herkese ait ortak listelerdir. Eski uygulama aynı gece kapatılır. Eski CMS veritabanı ve yedeği yerinde kalır; sorun çıkarsa ileri düzeltme yapılır.

Adres değişmez: kalıcı yer bugünkü `api.yildizskylab.com/api` yoludur. Eskisiyle yan yana çalıştığı dönemde inscribed `/api/inscribed` altında durur.

## Consequences

- **Keycloak.** inscribed'ın rol modeli kullanılır: her Site client'ında `content:read` / `content:write` / `schema:sync` rolleri ve bunları `roles` claim'ine yazan bir mapper vardır. Tenant `azp`'dir, audience `skycms` kalır. ~~`cms:access` geçişten sonra emekli olur.~~ 2026-09-28'de değişti: `cms:access` kalır, aşağıdaki eke bakın.
- **Kod sahipliği.** Kod ve npm yayını (inscribed, `@skylab-kulubu/inscribed-auth`, site SDK yükseltmeleri) Fatih'tedir. Kulüp; Keycloak'ı, Dokploy'u, veri taşımayı ve kendi repolarındaki küçük ayarları yapar.
- **`:latest` bilinçli bir risktir.** Her redeploy yeni sürüm çeker. Fatih'ten, kırıcı değişiklikleri yalnız major sürümde ve önceden haber vererek yapması istendi.
- **Hesap silme ve erişim kapısı.** inscribed'da erişim kapısı ve silme ucu yoktur. Hesap silmeyi açmak (ADR-0051), bu ikisi inscribed'a genel ve opsiyonel özellik olarak gelene kadar bekler. Sözleşme Fatih'le paylaşılan raporda tanımlıdır.

## Considered Options

- **cms-backend'i inscribed koduyla güncellemek:** iki repo, her değişiklik iki kez yapılır. Fatih reddetti.
- **Kulüp reposunda ince sarmalayıcı imaj:** Yusuf doğrudan stok imajı seçti.
- **Yeni kalıcı host (`cms.yildizskylab.com`):** URL'ler build'lere gömülü olduğu için her istemcinin ikinci kez taşınmasını gerektirir. Bugünkü yolu korumak geçiş gecesini küçültür.

## Ek: geçişten sonra (2026-09-28)

Geçiş 2026-09-28'de yapıldı. Bütün tüketiciler aynı gün inscribed'a geçti; CMS eskisiyle aynı genel adresten hizmet veriyor. Eski CMS durduruldu, silinmedi; veritabanı ve yedeği yerinde duruyor.

Yetki tarafı ilk metinden şu noktalarda ayrıldı:

- **`cms:access` emekli edilmedi.** Her Site client'ında inscribed'ın `content:read` ve `content:write` rollerini bir arada veren editör composite'i olarak kalır. Siteler editörü yalnız `cms:access` sahibine gösteriyor; rolü kaldırmak editörü herkesten gizlerdi. inscribed yetkiyi kendisi Site client'ındaki `content:read`, `content:write` ve `schema:sync` rolleriyle verir; tenant, token'ın client'ıdır. Rolün ileride kaldırılması ayrı bir karardır.
- **Editör yetkisi kullanıcı → grup → client rolü yolunu izler.** Yetki Gruplara verilir; tek bir kişiye, bütün üyeler grubuna ya da varsayılan rollere verilmez. Atamalar SKY LAB yönetim panelinden yönetilir; ilk atamalar bir kez betikle yazıldı. Kimde ne var:
  - ana site (`cms:access`): ADMIN, YK, DK ve bütün takımların Leader grupları (liderler ve koordinatörler);
  - arge sitesi (`cms:access`): ADMIN, YK ve Leader grupları;
  - yönetim paneli, News için (`content:read` + `content:write`): ADMIN, YK, DK.
- **Sunucu tarafındaki site hesapları yalnız okur:** `content:read` + `schema:sync`.
- **Koleksiyon kuralları ayrıca daraltır.** News oluşturma ve düzenleme, News koleksiyonunun kendi kuralıyla Privileged gruplara sınırlıdır. Her Teams kaydı, eşleşen takımın Leader grubuna aittir.
- **`client:admin` şimdilik yalnız ADMIN'de.** Yeni takım açmak ve lideri ayrılmış bir takımın sayfasını düzeltmek bu rolü ister. Aynı rol sitenin CMS tenant ayarlarını da değiştirebiliyor. CMS, tenant ayarı yetkisini içerik yöneticiliğinden ayırana kadar bu rol yalnız ADMIN grubundadır.
- **Bilinen sınır.** inscribed'da yazma yetkisi site genelidir; bir takım lideri o sitenin bütün sayfalarını da düzenleyebilir. CMS'e yalnız koleksiyona yazma yetkisi gelene kadar bu kabul edildi. Bu yüzden ADR-0014'teki "ana site yalnız Privileged" kuralı şimdilik gevşemiş durumda.
