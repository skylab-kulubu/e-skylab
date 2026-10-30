---
status: accepted
---

# Ekip liderleri kendi ekiplerini ve alt ekiplerini core üzerinden yönetir; Privileged sabit köklerden okunur, ekip kodu tektir

Bugün grup açmayı, grubun adını değiştirmeyi ve üye eklemeyi yalnız Privileged kişiler yapabiliyor. Bir ekip lideri kendi alt ekibine üye bile ekleyemiyor; her değişiklik YK'ya ya da ADMIN'e gidiyor. core'un yetki kuralları ise grup **adına** bakıyor:

- Yolun herhangi bir yerinde `ADMIN`, `YK` ya da `DK` adlı bir segment varsa kişi Privileged sayılıyor.
- Owner team bir grup adı (`WEBLAB`). Ağaçta aynı adı taşıyan her grup o ekibin üyesi ya da lideri sayılıyor.
- Leader, yolda `/LIDERLER` alt dizesinin geçmesiyle tanınıyor.

Lider alt ekip açıp adlandırabilseydi şunları yapabilirdi:

- alt ekibine `ADMIN` adını verip tam yetki almak;
- başka bir ekibin adını alıp o ekibin etkinliklerine ve başvuru listelerine erişmek;
- `LIDERLER` adlı bir grup açıp kendini lider yapmak.

CVE-2026-9099 Keycloak'ta aynı hata sınıfını gösterdi: değiştirilebilir bir hiyerarşiden türetilen yetki.

Karar (Yusuf, 2026-10-12; sektör karşılaştırması hub'daki admin paneli araştırmasında):

1. **Leader kendi ekibini ve altını yönetir.** Yapabildikleri: üye eklemek ve çıkarmak; alt ekip açmak, adlandırmak, silmek ve taşımak; alt ekibe lider atamak; ekip bilgisini düzenlemek. Üst ekibin Leader'ı bütün alt ağacı yönetir, alt ekibin Leader'ı yalnız kendi alt ağacını. Onay beklenmez.
2. **Kalıtım etkinliklere de geçer.** Üst ekibin Leader'ı alt ekiplerin etkinliklerini ve başvuru listelerini de yönetir. Owner team denetimi, Owner team'in atalarındaki Leader'ları da Leader sayar.
3. **Yönetim core'dadır.** Keycloak'a yalnız core'un service account'u gider; kişinin token'ı Admin REST'e açılmaz (ADR-0058). Keycloak'ın fine-grained admin permissions özelliği açılmaz. Karar core'un yetki modülünde verilir (ADR-0005). Hedef grup Keycloak grup kimliğiyle seçilir. Kişinin hangi ekiplerin Leader'ı olduğu token'daki yoldan değil, Keycloak'taki güncel üyelikten okunur; böylece liderlikten çıkarılan kişi token'ının süresi dolana kadar yönetmeye devam edemez.
4. **Kimse kendi liderliğini değiştiremez; eş lider yoktur.** Bir ekibin Leader grubunu (`LIDERLER`, `KOORDINATORLER`) yalnız üst ekibin Leader'ı ya da Privileged değiştirir. Leader yalnız alt ekiplerine lider atar; kendini lider yapamaz, kendini liderlikten çıkaramaz. Son lider kalmasa da ekibi üst ekip yönetmeye devam eder. En üst ekiplerin (`/UYELER/<alan>/<ekip>`) liderlerini yalnız Privileged atar; bu ekipleri yalnız Privileged açar, siler ve taşır.
5. **Taşıma iki tarafı yönetmeyi ister.** Bir alt ekibi taşıyan kişi hem ekibin şimdiki üst ekibini hem hedef ekibi yönetmelidir (GitHub'ın iç içe takım kuralı). Ekip kendi altına taşınamaz. Privileged kökler ve altları hiçbir çağıran için kaynak ya da hedef olamaz.
6. **Privileged addan değil sabit köklerden okunur.**
   - Yalnız altı kök yol ve altları Privileged'dır: `/ADMIN`, `/YK`, `/DK`, `/UYELER/ADMIN`, `/UYELER/YK`, `/UYELER/DK`. Eşleşme bu yollara çapalıdır; başka yerde aynı adı taşıyan grup Privileged değildir.
   - Hedef yine ADR-0059'daki yalnız rol kipidir. Devrin açılması o kipi beklemez.
   - Leader ve Owner team kararları alt dize yerine tam segment eşleşmesine geçer.
   - Altı kökün dışında `ADMIN`/`YK`/`DK` adlı gruplar yayından önceki rapordan sonra tek tek ele alınır.
7. **Ekip kodu tektir, ayrılmış adlar alınamaz.**
   - Ekip kodu, grubun Keycloak adıdır. Owner team, CMS'teki Teams kaydının anahtarı ve Forms şablon eşleşmesi bu koda bakar.
   - Yeni kodlar ASCII büyük harf, rakam ve tireden oluşur, en çok 24 karakterdir.
   - Kod büyük-küçük harf ayrımı yapılmadan bütün sistemde tektir: realm'deki gruplarda, core'un adla tuttuğu kayıtlarda ve emekli kodlarda. Silinen ya da adı değiştirilen kod bir daha kullanılmaz.
   - Ayrılmış adlar: `ADMIN`, `YK`, `DK`, `UYELER`, `LIDERLER`, `KOORDINATORLER` ve core'un kurallarında adı geçen kodlar. Bu adlarla grubu yalnız Privileged (kök konumunda) ya da core'un lider atama işlemi açar.
   - Kodu üst ekibin Leader'ı değiştirir, o koda bağlı core kaydı yoksa. Alt ekip yalnız boşken silinir: üyesi, alt ekibi ve koda bağlı kaydı yoksa.
8. **Ekip bilgisi: kimlik core'da, sayfa içeriği CMS'te.**
   - Ekibin sitede görünen adı, kısa açıklaması ve logosu core'da, grup özniteliği olarak durur ve `GET /v1/teams` ile yayımlanır. Ekibi yöneten herkes bunları değiştirir. Görünen ad ekip kodundan ayrı bir alandır.
   - Sayfa içeriği CMS'teki Teams kaydında kalır.
   - Lider siteyi açıp site editöründen (inscribed) core'daki bu değerleri de değiştirebilmelidir.
   - `public_listing`, `public_leaders` ve `team_door_scan` Privileged'da kalır: ilk ikisi üyelerin adını herkese açar, üçüncüsü kapı yetkisi verir.
9. **Her değişiklik denetim kaydına yazılır** (kim, ne zaman, ne; eski ve yeni değer). Reddedilen yazmalar da yazılır.
   - Kayıt yazılamazsa değişiklik yapılmaz.
   - Kayıtta kişinin yalnız kimliği durur; ad ve e-posta okunurken çözülür.
   - Kayıt 3 yıl tutulur.
   - Kaydı core'un `audit:read` rolü olanlar görür; rol ADMIN ve YK köklerine verilir. *(Değişti: DK'ya da verilir, bkz. ADR-0077.)*
10. **Rol taşıyan grup devredilmez.** core'un Privileged izin rollerinden, `audit:read`'den, bir client'ın `client:admin`'inden ya da Keycloak yönetim rollerinden birini doğrudan ya da atasından taşıyan grubun üyeliğini yalnız Privileged değiştirir (Entra'nın role-assignable gruplarının karşılığı). Grup rol eşlemeleri yalnız Privileged'dadır.
   *(2026-10-12: liste yerine rol sınıfları geldi; yönetici rolü taşıyan grup devredilmez, uygulama rolü taşıyan devredilir; bkz. aşağıdaki ek.)*

Kaynaklar:
- **Yusuf'un:** 1, 2, 4, 8'in ilk üç maddesi, 9'un ana kuralı (her değişiklik kayda, YK ve ADMIN görür, 3 yıl) ve "devirden önce yetki ad eşleşmesinden çıkar, ayrılmış adlar alınamaz" önkoşulu.
- **Önkoşulun spec'teki uygulaması:** 6, 7 ve 10.
- **Spec önerisi:** 3 ve 5. 5'teki taşıma kuralı Yusuf'a söylendi.
- **Spec önerisi, Yusuf'a bildirildi, itiraz ederse değişir:** 7'deki kod değiştirme ve silme kuralı, 8'deki öznitelik kuralı, 6'daki rapor sonrası tek tek ele alma ve Leader'ın her etkin hesabı ekleyebilmesi (Consequences).

## Consequences

- **ADR-0059 daralır.** "Takım izinleri grup yoludur" cümlesi Owner team kararları için geçerli kalır. Ekip yönetimi kararları ise Keycloak'taki güncel üyelikten, grup kimliğiyle verilir; bu, Group overage'daki Admin REST okumasıyla aynı yoldur. ADR-0006'daki "core yetkiyi JWT'deki grup yollarından verir" cümlesi de buna göre daralır.
- **Davranış değişikliği.** Altı kökün dışında `ADMIN`/`YK`/`DK` adı taşıyan bir grubun üyeleri Privileged'lığını kaybeder. Yayından önce production'daki ağaç bir raporla listelenir; her biri ya yeniden adlandırılır ya da rolleri admin panelinden eşlenir.
- **Etkinliklerde kalıtım (karar 2).** Üst ekip Leader'ı alt ekibin etkinliklerinde, başvuru listelerinde ve katılımcı verisinde Leader olur; katılımcı kişisel verisine erişen kişi sayısı artar. Etkinlik durumu ve kopyası (ADR-0066) ile yarışma yönetimi (ADR-0068) bu kuralı `allowEvent`'ten okur, ayrı bir kural yazmaz.
- **Taşımanın etkisi.**
  - Ekip kodu taşımada değişmez. Owner team, CMS Teams kaydı ve Forms eşleşmesi kırılmaz.
  - Taşınan ekibin üyeleri yeni ataların üyesi sayılır ve onların client rollerini miras alır; eski atalarınkini kaybeder. Bu, kişinin token'ı yenilenince geçerli olur. Onay ekranı bu farkı gösterir.
  - Kod değişikliği ise Owner team kayıtlarını, CMS slug'ını ve Forms eşleşmesini kırar. Bu yüzden ancak koda bağlı kayıt yokken yapılır.
  - Ekibe özel haber ve duyuruların ekip yolunu ekip adlandırılınca ya da taşınınca core günceller (ADR-0067).
- **Token boyutu.** Her yeni üyelik token'a bir tam yol ekler ve Group overage henüz hiçbir client'ta açık değil. Alt ekip derinliği, yol uzunluğu, alt ekip sayısı ve kişi başı grup sayısı sınırlanır. Alt ekipler çoğalırsa overage'ın açılması öne alınır.
- **Denetim kaydı yeni bir kişisel veri işleme amacıdır** (meşru menfaat, KVKK md. 5/2-f). ADR-0062'nin saklama tablosuna "ekip ve grup yönetimi kaydı: 3 yıl" satırı eklenir, aydınlatma metni güncellenir. Account erasure kaydı silmez. Hesap silinince kişinin kimliği kimseye çözülmez; özel dosya erişim kaydıyla aynı ilke.
- **Leader herhangi bir etkin hesabı ekibine ekleyebilir**, yani onu Member yapabilir (Promote). Bu karar ADR-0063'teki "üyelik yönetici kararıdır" cümlesini ekip liderlerini de kapsayacak biçimde genişletir. Kişiye ekip üyelik maili gider.
- **Ekip bilgisi.** Sitedeki kodda sabit ekip adları ve logolar core'dan okunmaya başlar; değer yoksa koddaki değere düşer. CMS Teams kaydının kuralı ve SkyApp'in yazma yolu değişmez (ADR-0056).
- **Admin paneli.** Menü ve düğmeler core'un "yeteneklerim" yanıtından gelir (ADR-0059). Panelde grup adına bakan kural kalmaz.
- **Açma anahtarı.** Devir core'da bir ortam anahtarıyla açılır ve güvenlik önkoşulu (karar 6, 7) production'da olmadan açılmaz. Kapatmak devri durdurur; yapılmış değişiklikler Keycloak'ta, izleri denetimde kalır.
- **CONTEXT.md'de değişenler:**
  - Yeni terimler: Team code, Team manager, Protected group, Team audit record.
  - Privileged: altı kök ve altları; başka yerdeki aynı ad Privileged değildir.
  - Leader: kalıtımla yönetim, kendi liderliğini değiştirememe.
  - Owner team: ekip kodudur ve tektir; atalardaki Leader'lar da Leader sayılır.
  - Promote: Leader'lar da yapar.
  - Permissions view: değişiklik admin panelinde, ekip yöneticisi tarafından da yapılır.

## Açık

- **Site editöründen core'daki ekip bilgisini düzenlemenin yolu** (karar 8): inscribed ile core arasında bir köprü mü, site editöründe core alanları mı? inscribed tarafı Fatih'in, site tarafı Kaan'ın kararıdır.
- **Etkinliklerdeki kalıtımın denetim kaydına nasıl gireceği** (karar 2): ekip yönetimi kaydı bugün yalnız grup ve üyelik değişikliklerini kapsıyor.

## Endüstri uygulamasıyla karşılaştırma

**Uyanlar:**
- Microsoft Entra grup sahibi (owner): yönetici rolü olmadan kendi grubunun üyeliğini yönetir.
- Entra role-assignable groups ve Okta Group Admin: rol taşıyan grubun üyeliğini yalnız ayrıcalıklı yönetici değiştirir.
- GitHub iç içe takımlar: alt takım üst takımın erişimini miras alır. Team maintainer üyeliği, takım adını, açıklamasını ve resmini yönetir.
- GitHub takım taşıma: maintainer ancak hem alt hem üst takımın bakımcısıysa taşır.
- Google Groups Manager: grubu yönetir, sahip atayamaz.
- Entra denetim kaydı: aktör, hedef, eski ve yeni değer; nesne sayfasında süzülü açılır.

**Sapmalar (hepsi):**
1. **Kalıtım.** Entra yönetim birimleri iç içe olmaz ve üst gruba verilen hak alt gruba akmaz. Bizde üst ekip Leader'ı bütün alt ağacı ve alt ekiplerin etkinliklerini yönetir, roller miras alınır (ADR-0059). GitHub'a yakınız.
2. **Owner owner ekleyemez.** Entra'da sahip sahip ekler, GitHub'da maintainer maintainer atar. Bizde liderliği üst ekip ya da Privileged değiştirir, çünkü Leader grubu ana sitenin CMS yazma yetkisini ve etkinlik liderliğini taşır.
3. **Delege alt ekip açar ve siler.** Entra sahibi alt grup açamaz, Google Manager grubu silemez, GitHub maintainer alt takımı yalnız ister. Bizde Leader alt ekip açar, boşsa siler.
4. **Ad politikası yetki için.** Entra'nın adlandırma politikası yalnız M365 gruplarında var ve önek/sonek ekler. Bizde kod bir yetki anahtarı olduğu için ayrılmış adlar, ASCII ve sistem genelinde tekillik zorunlu.
5. **Dizin görünürlüğü dar.** Entra'da her üye dizini okur. Bizde Leader yalnız kendi üyelerini ve maskeli bir aday aramasını görür.
6. **Saklama uzun.** Entra P1/P2 30 gün, GitHub ve Microsoft 365 Standard 180 gün tutar. Biz 3 yıl tutuyoruz; ADR-0062'deki erişim kaydıyla aynı süre.
7. **Onay yok.** GitHub'da iki tarafın maintainer'ı aynı kişi değilse taşıma istek ve onayla yapılır. Bizde böyle bir istek akışı yok; taşıyan iki tarafı da yönetmelidir.
8. **Dinamik gruplar, PIM, süreli roller yok.** Keycloak'ta yoklar ve kulüp ölçeğinde gereksizler. *(Daraldı: yönetim üyeliklerinin dönem sonunda bir bitişi var, ama yalnız işaret koyar; bkz. ADR-0078.)*

## Considered Options

- **Keycloak fine-grained admin permissions (grup başına `manage-members`):** ikinci bir yetki düzlemi açar ve kişi token'larını Admin REST'e açmayı gerektirir (ADR-0058'e aykırı). Denetim Keycloak olaylarında 30 gün kalırdı. CVE-2026-9099 bu yolun hata sınıfını gösterdi.
- **Privileged'ı sabit grup kimliğiyle okumak** (ortamda kimlik listesi, core kimliği yola çözer): Privileged bir kökün adını değiştirdiğinde de çalışır. Ama token yol taşıyor; her açılış ve önbellek yenilemesi Keycloak'a bağlanır. Keycloak düşükken bütün adminler yetkisini kaybeder ya da eski yolla devam edilir. Delegeler o yolları zaten üretemediği için çapalı kökler yetiyor; hedef rol kipi.
- **Privileged'ı bir grup özniteliğiyle işaretlemek:** öznitelikleri `groups:manage` sahibi bugün serbestçe yazıyor; işaretin kendisi ayrıca korunmalı.
- **Yalnız rol kipine geçip devri sonra açmak:** asıl hedef bu, ama önkoşulları (giriş client'larının daraltılması, kip gözlemi) açık ve takvimi belirsiz. Owner team ve Leader ad eşleşmesi rol kipinde de kalıyor; tek kod kuralı yine gerekiyor.
- **Owner team'i addan grup kimliğine taşımak:** doğru uzun vadeli adım, ama etkinlik, sertifika, CMS, Forms ve sitelerin anahtarını birlikte değiştirir. Tek kod kuralı bugün aynı güvenliği veriyor.
- **Liderlerin yalnız üyelik değiştirmesi (alt ekip açma, adlandırma ve taşıma Privileged'da):** CVE notunun ilk önerisi. Yusuf alt ekip yönetimini istedi; ad kuralları ve kimlikle karar bu yüzden zorunlu.
- **Kalıtımın yalnız ekip yönetiminde kalması** (spec'in önerisi): Yusuf etkinliklere de geçmesini seçti (karar 2).
- **Ekip bilgisinin hepsi CMS'te ya da hepsi core'da:** hepsi CMS'te olunca kalıtım ve alt ekip kaydı inscribed kuralına takılır; hepsi core'da olunca CMS Teams emekli olur, SkyApp ve iki site değişir. Yusuf kimliği core'da, sayfa içeriğini CMS'te seçti (karar 8).
- **Lider kendi ekibine eş lider ekleyebilir** (Entra ve GitHub gibi): Yusuf reddetti; Leader grubu ana sitenin CMS yazma yetkisini taşıyor.
- **Onay akışı** (lider ister, YK onaylar): Yusuf "onay beklenmez" dedi; denetim kaydı hesap verebilirliği sağlar.
- **Değişiklikleri Keycloak olaylarından izlemek:** aktör hep core'un service account'u görünür, süre 30 gün.

## Ek: rol sınıfları ve site editörlüğü (2026-10-12)

Kaan sordu: liderler alt ekip açıp lider atadıkça ana sitenin tamamını düzenleyen kişi sayısı artar mı; alt ekip liderlerine `cms:access` verilmesin mi? Hub'daki güvenlik incelemesinin (2026-10-12) cevabı: kendiliğinden artmaz, hiçbir betik ya da core işlemi yeni bir gruba client rolü eşlemez. Ama `cms:access` karar 10'un listesinde yoktu. Bir admin bir alt ekibin Leader grubuna `cms:access` eşlerse grup devredilebilir kalıyordu; üst ekibin Leader'ı oraya istediği etkin hesabı ekleyip site geneli yazma verebiliyordu. ADR-0056'daki "bütün takımların Leader grupları" ifadesi ve Keycloak runbook'u adminleri tam bu eşlemeye yönlendiriyordu. Karar 10'un liste yöntemi bir rolü böyle kaçırdı; yeni roller de aynı yoldan kaçabilirdi.

Karar (Yusuf, 2026-10-12: "sektör nasılsa öyle", Microsoft Entra modeli; site editörlüğü Kaan'ın önerisi):

- **Roller iki sınıftır (karar 10'un yerine).**
  - **Yönetici rolleri** Entra'nın directory role'lerinin karşılığıdır. Bunlardan birini taşıyan grubun ve onu atasında taşıyan her grubun üyeliğini yalnız Privileged değiştirir (Entra'nın role-assignable grupları).
  - **Uygulama rolleri** verdiği yetki kişinin kendisiyle ya da üyesi olduğu ekiplerle sınırlı rollerdir. Lider bunları devredebilir: rolü taşıyan grubun üyeliğini değiştirebilir.
  - **Sınıflandırılmamış her rol yönetici rolü sayılır** (fail-closed). Yeni bir rol, biri onu uygulama rolü listesine alana kadar korunur. core böyle bir rolü gördüğünde loglar ve sayar (yalnız rol adı, kişi yok).
  - Sınıf **(client, rol) çiftiyle** tanımlanır, yalnız rol adıyla değil: aynı ad başka bir client'ta başka bir roldür.
  - Composite bir uygulama rolü, ancak içindeki her rol de uygulama rolüyse devredilir.
  - **Realm rolleri her zaman korunur** (karar 10'daki gibi, fail-closed). Production ölçümü (2026-10-12 22:42) Java döneminden kalan realm rollerinin gruplarda durduğunu gösterdi: `/UYELER`'de `USER`, her en üst takımda takımın adında bir rol (`WEBLAB`) ve Leader gruplarında `<EKİP>_LEADER`. Bu yüzden devir bugün `/UYELER` altında hiçbir yerde çalışmaz. **Eski realm rolleri rol temizliği F3 ile kalkar** (hub `.scratch/rol-temizligi`): önce gruplardan, sonra kişilerden kaldırılırlar, sonra tanımları silinir. `_LEADER`'ın composite'indeki Forms koltuğu, en üst takımların Leader gruplarına client rolü (`skyforms:access`) olarak taşınır. O zamana kadar `/UYELER`'deki `USER` devri kapalı tutar; **devrin açılış ön koşulu F3'tür**. Realm rolleri için ad ya da konum istisnası tanımlanmaz (Yusuf, 2026-10-12: "her şeyi sana bıraktım, Microsoft gibi"; orkestratör kararı, aynı gün): F3'ten sonra ölü kod olurdu, ayrıca core realm rollerinin composite'lerini okuyamadığı için içlerine eklenen bir yönetici rolü görünmez kalırdı.
  - İlk uygulama rolleri: core'da `certificate:issue`, `certificate:revoke`, `certificate:template:manage`, `certificate:binding:manage` (yalnız kişinin ekiplerinin etkinlikleri); core'da `url:create`, `url:get`, `url:update`, `url:delete`, `url:access` (yalnız kendi kısa linkleri); Forms'ta `skyforms:access` (koltuk) ile `skyforms:form:manage`, `skyforms:response:manage` ve `skyforms:feedback:manage` (yalnız ekran açar; forms-backend her formu iş birlikçiye ya da yönetici rolü `skyforms:*`'a göre karar verir); `broker`'da `read-token` (kişinin kendi kimlik sağlayıcı token'ı); SkyMail'de `skymail:access` ve `skymail:templates:read`; her Site client'ında `content:read`. Planlı `news:read` geldiğinde listeye girer. Liste core'da ve core'un `docs/team-delegation.md` belgesinde durur; değişikliğini Yusuf onaylar.
  - Bilinen yönetici rollerinden bazıları: core'un Privileged izin rolleri, `audit:read`, `users:read`; her client'ın `client:admin`'i; `realm-management`'ın her rolü; herhangi bir client'taki `content:write` ve `cms:access` (Site client'ları, yönetim paneli `admin`, SkyApp); Forms'ta `skyforms:*`; SkyMail'de şablon yazma, listeler, gönderim, onay ve sistem postaları; Place'te `place:admin` ve `place:moderator`.
- **Site editörlüğü yönetici rolüdür.** Herhangi bir client'taki `content:write`'ı (inscribed'ın site geneli yazması) ya da `cms:access`'i taşıyan grubun ve onun altındaki her grubun üyeliğini yalnız Privileged değiştirir. `cms:access` kendi adıyla da yönetici rolüdür; böylece koruma Keycloak'ın composite yanıtına bağlı kalmaz. `content:read` tek başına okumadır, uygulama rolüdür.
- **`cms:access` yalnız en üst takımların Leader gruplarına verilir.** Ana sitede, arge'de ve etkinlik sitelerinde editörlük Privileged gruplarda ve en üst takımların (`/UYELER/<alan>/<ekip>`) `LIDERLER`/`KOORDINATORLER` gruplarındadır. Alt ekiplerin Leader gruplarına ve takım ya da alan gruplarının kendisine verilmez. Bu kural, inscribed'a koleksiyon ve kayıt bazında yazma gelene kadar geçerlidir (Fatih, F2-yazma). O gelince alt ekip liderlerinin kendi Teams kaydını yazması ayrıca kararlaştırılır.
- **Araçlar kurala uyar.** `e-skylab-keycloak`'taki `config/site-editor-grants.sh --team` alt ekip yolunu reddeder. Runbook "her `…/LIDERLER`" yerine "yalnız en üst takımlar" der.

Sonuçlar:

- En üst takımın Leader grubundaki `cms:access` devri değiştirmez. O grubu zaten yalnız Privileged değiştirir (karar 4). Alt ekipler o grubun altında değil, kardeşidir; yönetimleri devredilmeye devam eder.
- Bir takım ya da alan grubuna yönetici rolü, sınıflandırılmamış bir rol ya da bir realm rolü eşlenirse o ağacın tamamı devirden çıkar ve yalnız Privileged'ca yönetilir. Bu bilinçlidir: Keycloak'ta rol aşağı doğru miras alınır. Rolü ayrı bir yaprak gruba taşımak ekibi devre geri getirir.
- Alt ekip liderleri site editörü değildir. Bugün alt ekibin Teams kaydını yalnız `client:admin` sahipleri (ADMIN, YK) yazabilir. `teams` koleksiyonunun kuralı kaydı yalnız takımın kendi Leader grubuyla eşleştirir; üst takımın lideri alt ekibin kaydına yazamaz. Üst takım liderinin yazabilmesi koleksiyon kuralının değişmesini ister.
- Devir açılmadan önce, karar 6'daki production ağaç raporu en üst takımlar dışındaki her Leader grubunun ve her takım ya da alan grubunun client rol eşlemelerini sınıflarıyla (yönetici, uygulama, sınıflandırılmamış) ve realm rol eşlemelerini, bu realm rollerinin composite'leriyle birlikte listeler (core realm composite'lerini okuyamaz, rapor okur). Realm rolü eşlemesi F3'ten sonra sıfır olmalıdır. Her satırı Yusuf görür; liste temiz olmadan devir açılmaz.

Endüstri uygulamasıyla karşılaştırma:

- **Uyan:** iki sınıf Entra'nınkiyle aynıdır. Entra'da dizin rolü yalnız role-assignable gruba verilir ve bu grubun üyeliğini genel grup yazma izni değiştiremez; uygulama rolleri sıradan gruplara verilir ve grup sahibi üye ekleyerek dağıtabilir. Okta'da admin rolü taşıyan grubu yalnız süper admin yönetir. Google Workspace'te admin rolü yalnız güvenlik grubuna atanır. Site editörlüğü ve `client:admin` yönetici sınıfındadır.
- **Sapma 1, miras:** Keycloak'ta roller alt gruplara geçer, Entra'nın uygulama rolleri iç içe gruplara geçmez. Bu yüzden ata denetimi var: atasında yönetici rolü bulunan grup da korunur.
- **Sapma 2, sınıflandırılmamış rol:** Entra'da sınıf rolün türünden gelir. Bizde rolün türü yok, sınıf bir listeden gelir; listede olmayan rol yönetici rolü sayılır. Realm rollerini sınıflamıyoruz, hepsi korur; kulübün eski realm rolleri rol temizliği F3 ile kalkar.
- **Sapma 3, geniş tanım:** liderler alt ekip açıp alt ekibe lider atayabildiği için (Entra sahibi alt grup açamaz) korunan grup tanımı Entra'dakinden geniştir.
- **Sapma 4, site editörlüğü:** `cms:access` ve `content:write` uygulama rolleridir; Entra'da sıradan gruplarla dağıtılabilirdi. Biz onları yönetici sınıfına alıyoruz, yani Entra'dan daha sıkıyız. Gerekçe: inscribed'da yazma site genelidir ve kaynak başına yetki yoktur; rol fiilen site yöneticisidir.

## Ek: ekip ayarları (2026-10-25)

Yusuf (2026-10-25, core-frontend #94 incelemesi B1): ekip üyeleri etkinliklerin yarışmacılarını ekleyip düzenleyebilir, ama bunu ekibin lideri seçer.

- **Ekip ayarı** ekibin kendi grubunun özniteliğidir; core'un `PUT /v1/groups/{id}/settings` ucu yazar. İlki `members_manage_competitors`: `false` iken ekibin etkinliklerinde yarışmacı ekleme, düzenleme ve silme yalnız Leader'larda (karar 2'deki üst ekip Leader'ları dahil) ve Privileged'dadır. Okuma ve kişinin kendini kaydetmesi değişmez.
- **Liderin yazdığı ilk yetki özniteliğidir.** Karar 8 ekip bilgisini yönetenlere, `public_listing`, `public_leaders` ve `team_door_scan`'i Privileged'a bırakır; o üçü yetkiyi genişletir (üye adını açar, kapı yetkisi verir). Ekip ayarı **yalnız daraltır**: varsayılanı bugünkü kuraldır, lider kendi yetkisinin üstüne çıkamaz, yalnız kendi ekibinin üyelerinin bir yazmasını kapatabilir. Bu yüzden ekibi yöneten (`Manages`: ekibin ya da üst ekibin Leader'ı) yazar; korumalı grupta yalnız Privileged. Sonraki ekip ayarları da bu kurala bağlıdır: yalnız daraltan ayar lidere açılır, genişleten Privileged'da kalır.
- Değer yoksa, okunamazsa ya da ad tek bir grubun değilse varsayılan geçerlidir (açık). Her değişiklik karar 9'daki denetim kaydına eski ve yeni değerle yazılır.
- `TEAM_DELEGATION` kapalıyken ayarı yalnız Privileged yazar; açılınca liderler de yazar.
