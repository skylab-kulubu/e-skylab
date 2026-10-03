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

## Ek: etkinlik siteleri de tenant (2026-10-03)

ARTLAB, YıldızJam ve SkyDays sitelerinin de editörle düzenlenebilmesi istendi. Karar değişmedi, kapsamı genişledi: bu siteler de aynı inscribed'ı kullanır.

- **Backend aynı.** Her site canlıdaki inscribed'da kendi tenant'ıdır; tenant sitenin Site client'ıdır (`frontend-artlab`, `frontend-yildizjam`, `frontend-skydays`). Yeni backend, fork ya da site başına ikinci bir CMS yoktur. cms-backend emekli kalır ve yeniden kurulmaz; 2026-10-05 temizliği (eski uygulamanın kaldırılması, reponun arşivlenmesi) planlandığı gibi yapılır, çünkü bu yol eski CMS'ten hiçbir şey kullanmaz.
- **Yeni site kod istemez.** Gerekenler: Keycloak'ta bir Site client'ı (yapılandırma betiğiyle, elle değil), inscribed'da tenant kaydı (yayınlanmış içerik anonim okunur), CORS'ta sitenin origin'i ve sitenin kendi Dokploy uygulaması. Bu siteler veri tutmadığı için ana siteyle birlikte "SKY LAB Production"da durur (ADR-0057).
- **Site client'ının biçimi** ana site ve arge ile aynıdır, şu farklarla: sunucu tarafındaki hesap yalnız okur (`content:read` + `schema:sync`, `cms:access` yok); Full scope kapalıdır, yoksa token başka sitenin `cms:access`'ini taşır ve o sitenin editörü açılır (ADR-0058/0059); redirect adresi birebir eşleşir ve production client'ında yerel adres yoktur. `skycms` audience'ı ortak bir scope'tan, görsel yüklemesi için core audience'ı site başına bir scope'tan gelir.
- **Editörler mevcut grup ağacından gelir.** Bir etkinlik sitesinde `cms:access` Privileged gruplara (ADMIN, YK, DK), siteye sahip lab takımının Leader gruplarına ve etkinliğin organizasyon takımının (`/UYELER/ORGANIZASYON/<ETKİNLİK>`) Leader gruplarına verilir: ARTLAB → AIRLAB + ORGANIZASYON/ARTLAB, YıldızJam → GAMELAB + ORGANIZASYON/YILDIZJAM, SkyDays → SKYSEC + ORGANIZASYON/SKYDAYS (Yusuf'un kararı, 2026-10-03). Leader grupları liderler ve koordinatörlerdir; takımın öbür üyeleri ve tek tek kişiler rol almaz. Organizasyon takımı realm'de yoksa yapılandırma betiği uyarır, öbür atamalar yine yapılır. Site başına ayrı bir editör grubu açılmaz; Group kulübün ağacıdır, ikinci bir üyelik bayrağı değildir. Yazma site geneli olduğu için etkinlik sitesi bütün Leader gruplarına verilmez. `client:admin` yine yalnız ADMIN'dedir. Hangi takımın hangi siteye sahip olduğu atamalarla, yönetim panelinden kaydedilir.
- **Sırlar elle dolaşmaz** (ADR-0049). Client sırrı Keycloak'tan doğrudan sır deposuna yazılır, uygulama yalnız referansı tutar. Build sırasında sır gerekmez: siteler içeriği çalışma anında okur, yayınlanmış içerik token'sız okunur. Yerel geliştirmede sandbox CMS'i token'sız okunur, editör sandbox dağıtımında denenir; geliştiricinin makinesine sır verilmez.
- **Görseller core'a gider** (ADR-0052). Site, editörün token'ıyla core'a yükleyen kendi sunucu tarafı köprüsünü kullanır; ayrı bir CMS medya servisi yoktur. CMS'e özgü purpose, inscribed görseli kendine ekleyebildiğinde açılır.
- **Yönetim panelinde siteler.** İlk adımda panel düzenlenebilir sitelerin sabit listesini gösterir; "Düzenle" sitenin kendi giriş adresine gider, editörü site yalnız `cms:access` sahibine açar. Sonra core'un "yeteneklerim" yanıtı kişinin düzenleyebileceği siteleri (`editableSites`) döner; core bunu Keycloak'a sunucudan sorar (ADR-0059). Bu liste yetki kararı değil, arayüz ipucudur; yetkiyi inscribed verir. Hiçbir client'ta Full scope bunun için açılmaz.
- **Sıra.** Önce ARTLAB (önce sandbox, sonra production). Sonra YıldızJam: statik export'tan sunuculu Next'e geçer ve Dokploy'a taşınır. SkyDays Vite'tan Next'e geçince, geliştiricinin zamanına göre gelir. inscribed'ın SDK'sı ve giriş paketi sunuculu Next istediği için statik ya da Vite sitesi önce geçirilir.
- **Koleksiyon yok, başta.** Etkinlik siteleri ilk aşamada yalnız sayfa blokları kullanır. inscribed'da koleksiyonlar tenant'a bağlı değil, bütün sitelerde ortaktır; etkinlik sitesine koleksiyon gerekirse ayrı karar verilir.

Değerlendirilen ve seçilmeyenler:

- **cms-backend'i yeniden kurmak:** bu ADR'nin kararıyla çelişir; istenen uçların hepsi inscribed'da zaten var.
- **Site başına editör grubu ağacı:** grup ağacına rol yerine ikinci bir üyelik bayrağı ekler.
- **Yalnız sahip lab takımı:** etkinliğin içeriğini çoğunlukla organizasyon takımı hazırlar; dışarıda kalırsa her değişiklik bir lab liderinden geçerdi.
- **Organizasyon takımının bütün üyeleri:** yazma site geneli olduğu için yetki takımın liderleri ve koordinatörleriyle sınırlı kalır.
- **Paneldeki liste için Full scope açmak:** token büyür ve istemci token okumuş olur; ADR-0058/0059 tam tersini ister.
- **Yeni ADR:** karar ("CMS stok inscribed'dır") aynı kaldı, yalnız tenant sayısı arttı.

## Ek: hesap silme (2026-10-03)

Yukarıdaki "Hesap silme ve erişim kapısı" maddesi daraldı: inscribed'a erişim kapısı gelmez, tam silme ucu da gerekmez (ayrıntı ve gerekçe ADR-0051'in 2026-10-03 ekinde).

- **Küçük uç, sahibinden.** Fatih inscribed'a core'un silme komutunu karşılayan küçük bir uç ekler. Uç düzenleyen kolonlarındaki (`UpdatedBy`) kişinin `sub`'ını herkes için aynı "Silinmiş kullanıcı" yer tutucusuna çevirir; içerik, sürüm ve tarih değişmez. Makbuz tablosu ve tenant çözümü yoktur; token `core-erasure`'ın, rol `skycms` üzerindeki `cms:account:erase`'tir.
- **Kapı yok.** inscribed hesap tutmaz; eski token bir hesabı diriltemez. Kalan risk, kişi kapatılmadan önce alınmış access token'ın ömrü (300 sn + 30 sn skew) içinde yapılan bir düzenlemedir. Core CMS adımını kimlik kapandıktan 6 dk sonra gönderir; o düzenleme de temizlenir.
- **Eski `ArchivedBy` kolonları** (cms-backend kopyası) bir kez, herkes için boşaltılır.

## Ek: SkyApp'ten haber ve takım düzenleme (2026-10-03)

SkyApp'te (Mobile Lab'in uygulaması) haber ve takım sayfası düzenlenebilsin istendi. Yusuf'un kararı: düzenleyebilenler sitedeki kuralla aynıdır (Site editor), yazılanlar ana sitenin içeriğine gider, SkyApp için ayrı bir tenant açılmaz.

- **Uygulama doğrudan inscribed'a yazar.** Kişi SkyApp'e nasıl giriyorsa öyle kalır (public client `skyapp`, PKCE); uygulama haberi ve takım sayfasını kendi token'ıyla `api.yildizskylab.com/api/cms/collections/{news,teams}` uçlarına yazar. Arada köprü sunucu yoktur, inscribed'da değişiklik yoktur. Bu mümkün, çünkü News ve Teams koleksiyonları tenant'a bağlı değildir: sitenin okuduğu kayıtlar aynı kayıtlardır, uygulamadan yazılan haber ana sitede görünür. `skyapp` inscribed'da tenant olarak kaydedilmez; bu yüzden SkyApp sitenin sayfa bloklarına (`/cms/content`) yazamaz. Yetki burada sitedekinden dardır: yalnız koleksiyonlar.
- **Kim düzenler, tek yerden.** `skyapp` client'ında `content:read`, `content:write`, `cms:access` (ilk ikisinin composite'i) ve `client:admin` rolleri vardır, ama bunlar hiçbir gruba ya da kişiye verilmez. Ana sitenin `cms:access`'i SkyApp'in `cms:access`'ini, ana sitenin `client:admin`'i SkyApp'in `client:admin`'ini içerir. Yönetim panelinde bir gruba `frontend-main` `cms:access` vermek, o grubu hem sitede hem uygulamada editör yapar; almak ikisinden de alır. Koleksiyonların kendi kuralları aynen geçerlidir: News'i Privileged gruplar yazar, her Teams kaydını takımın Leader grubu (liderler ve koordinatörler), herhangi bir takımı `client:admin` (ADMIN).
- **Token.** SkyApp'in access token'ı ortak `skycms-audience` scope'uyla `aud`'a `skycms` alır ve `inscribed-roles` mapper'ıyla kendi rollerini düz `roles` claim'ine yazar; tam yollu `groups` zaten vardı. Uygulamanın düzenleme düğmeleri bugün de `resource_access.skyapp.roles` içinde `cms:access`'e bakıyor; değişiklikten sonraki ilk token yenilemesinde (en çok 5 dk) gelir, yeniden giriş gerekmez. Değişiklik `e-skylab-keycloak`'taki `config/skyapp-cms-editor.sh` betiğiyle yapılır, elle yapılmaz; `--revoke` iki composite bağını alır ve SkyApp'ten düzenlemeyi bir sonraki yenilemede kapatır.
- **Görseller** bugünkü gibi core'a gider (ADR-0052): uygulama core'a kendi token'ıyla yükler, dönen adresi alana yazar; CMS'e özgü purpose, inscribed görseli kendine ekleyebildiğinde açılır.

Değerlendirilen ve seçilmeyenler:

- **Token exchange (uygulama `skyapp` token'ını `frontend-main` token'ına çevirir):** Keycloak'ın Standard Token Exchange'i gizli istemci ister, public bir mobil istemci exchange yapamaz (RFC 8252: uygulamaya secret gömülmez). Ayrıca çıkan token'ın `azp`'si isteyen istemcidir; uygulama başka bir istemci "olamaz". Exchange'i site sunucusunun yapması aşağıdaki köprüdür.
- **Köprü sunucu (skylab-site ya da core, kişinin token'ıyla inscribed'a iletir):** fazladan bir atlama, `frontend-main`'de exchange açmak ve sitenin sunucusunu mobil için bir CMS vekiline çevirmek demektir; kazandırdığı tek şey `azp=frontend-main`'dir, koleksiyonlar için bu gerekmez. Mobil istemcinin kaynak sunucuyu audience'ı kısıtlı token'la doğrudan çağırması standart yoldur (RFC 8252, Microsoft identity platform'da mobil uygulama → API); BFF tarayıcı uygulamaları için önerilir.
- **inscribed'da `skyapp`'in `frontend-main` tenant'ına yazabilmesi (Fatih'te değişiklik):** koleksiyonlar tenant'a bağlı olmadığı için gerekmez; sayfa bloklarını uygulamaya açmak da istenmiyor.
- **SkyApp'in rollerini gruplara ayrıca vermek:** iki atama yeri olur, site ile uygulama zamanla ayrışır.

Microsoft modeliyle (ADR-0059) farklar: rol kaynak API'de (`skycms`) değil istemcilerde tanımlı, çünkü inscribed rolleri token'ın istemcisinden okuyor; tek atama yeri composite ile korunuyor. `skycms` audience'ı uygulamanın her token'ında var (Microsoft API başına ayrı token verir; Keycloak'ta tek token birden çok audience taşır). `skyapp`'te Full scope hâlâ açık; daraltılması admin-token-authz işinin konusudur.

Bilinen risk: inscribed ileride koleksiyonları tenant'a bağlarsa (koleksiyon tanımında `clients`, ya da kayıtların tenant'a göre bölünmesi) SkyApp'in yazması kırılır. News ve Teams tanımları bizde; böyle bir değişiklikte `skyapp` listeye eklenir ya da bu ek yeniden açılır. Fatih'ten bunu önceden haber vermesi istenir.
