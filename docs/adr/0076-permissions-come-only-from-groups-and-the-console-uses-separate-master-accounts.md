---
status: accepted
---

# Yetki yalnız gruplardan gelir: kişiye ve realm'e rol verilmez, roller üç yerde eşlenir; Keycloak konsolu master'daki kişi başına ayrı hesaplarla kullanılır

ADR-0006 realm rollerinin kalkacağını, ADR-0059 yetkinin Microsoft modelinde olacağını yazdı. Production'daki rol ölçümü (2026-10-12) bunun yarıda kaldığını gösterdi:

- **Kişiye doğrudan rol.** 19 insan hesabında doğrudan client rolü vardı (25 rol, 36 atama). Panel kişiye "ekstra rol" vermeye izin veriyordu. Kimin neden bir yetkisi olduğu gruptan okunamıyordu.
- **Java döneminin realm rolleri.** `ADMIN`, `YK`, `DK`, `USER`, ekip adlı roller ve `<EKİP>_LEADER` hem gruplarda hem kişilerde duruyordu. Çoğunu okuyan yoktu. `/UYELER`'deki `USER` ekip devrini bütün ağaçta kapatıyordu (ADR-0065'in 2026-10-12 eki).
- **Keycloak konsolu.** master realm'de yedi insan `admin` taşıyordu; bu rol bütün realm'lere yazar.
- **Yükseltme yolu.** Keycloak'ta `manage-users` taşıyan biri, realm yönetim rolü eşlenmiş bir gruba istediği kişiyi ekleyebiliyor; ekleyenin o rolleri taşıması gerekmiyor. core'un service account'u `manage-users` taşıyor. e-skylab realm'inde konsol yetkisi taşıyan bir grup olsaydı panel, ya da core'un sırrını ele geçiren biri, herkese Keycloak yöneticiliği verebilirdi. Entra'da bunu role-assignable grupların genel grup yöneticilerine kapalı olması önler; Keycloak'ta realm içinde böyle bir katman yok, tek sınır ayrı realm.

Karar (Yusuf, 2026-10-12: "her şeyi sana bıraktım, Microsoft gibi"; aynı gece soruların cevapları S1–S8; konsol listesi 2026-10-13):

1. **Kişiye rol yok (K1).** İnsan hesaplarında doğrudan client ya da realm rolü eşlemesi olmaz. Her izin bir gruptan gelir. Bugün kişiye verilmiş roller aynı (client, rol) çiftini taşıyan rol gruplarına taşınır; etkin rol değişmez. Servis hesapları (client'ların service account'ları) bunun dışındadır: kendi servis rollerini doğrudan taşırlar.
2. **Realm rolü yok (K2).** e-skylab realm'inde yalnız `default-roles-e-skylab` ve Keycloak'ın yerleşik rolleri (`offline_access`, `uma_authorization`) kalır. Uygulama izni client rolüdür. Java dönemi realm rolleri önce gruplardan, sonra kişilerden kaldırılır; bir hafta gözlenir, sonra tanımları silinir. Silmeden önce tanımları ve composite'leri saklanır. İşlevi olan iki composite (`<EKİP>_LEADER`'in Forms koltuğu ve SkyCloud erişimi) önce en üst ekiplerin Leader gruplarına client rolü olarak taşınır. Yeni realm rolü açılmaz (N6).
3. **e-skylab'da Keycloak yönetim rolü insanda ve grupta yok (K3).** `realm-management` rolleri e-skylab'da yalnız servis hesaplarındadır. Konsol hesapları master'dadır (karar 9).
4. **Rol yalnız üç yerde eşlenir (K4).**
   1. Privileged kökler (Entra'nın role-assignable gruplarının karşılığı);
   2. en üst ekiplerin (`/UYELER/<alan>/<ekip>`) Leader grupları (`LIDERLER`, `KOORDINATORLER`): konumdan gelen uygulama rolü;
   3. `/ROLLER` altındaki yapraklar (uygulama rolü grupları).

   `/UYELER`'in kendisinde, alan gruplarında, ekip ve alt ekip gruplarında, YK görev alt gruplarında ve `/ROLLER`'in kendisinde rol olmaz. Keycloak'ta rol eşlemesi alt gruplara akar, Entra'da akmaz; yaprak kuralı bu farkı kapatır. Bir rol grubu tek bir client'a aittir (K5). Rol grubu üyeliği panelden, core üzerinden değişir; böylece denetim kaydına ve postaya girer (K6).
5. **`/ROLLER` ve ad kuralı.**
   - **N1, dil.** İnsanın gördüğü ad Türkçedir ve grubun görünen ad alanında durur. Kodun anahtar olarak okuduğu ad (grup kodu, client rol değeri) ASCII'dir. Grup kodları Türkçe sözcük ya da marka olabilir (`UYELER`, `LIDERLER`, `ROLLER`, `WEBLAB`); client rol değerleri İngilizce `kaynak:eylem` biçimindedir.
   - **N2.** Her yeni grup ekip kodu kuralına uyar (ADR-0065 karar 7); rol grupları ve YK görev grupları dahil.
   - **N3, rol grubu.** `/ROLLER/<UYGULAMA>-<ROL>`. `<UYGULAMA>` client'ın kısa kodudur (`FORMS`, `SKYMAIL`, `PLACE`, `CF`). `<ROL>` rol değerinden mekanik türetilir: client öneki atılır, `:` tire olur, `*` `ALL` olur, büyük harf yazılır (`skymail:mails:approve` → `SKYMAIL-MAILS-APPROVE`, `skyforms:*` → `FORMS-ALL`). Yaprak grup, tek client, tek (client, rol) çifti. Adında ekip kodu geçmez. Tek kat olmasının nedeni kodun realm'de tek olması; mekanik olmasının nedeni göçün etkin rolü değiştirmediğinin kanıtlanabilmesi. Birkaç rolü bir arada veren kişi paketleri ("SkyMail gönderici" gibi) ayrı karardır ve uygulamanın sahibiyle verilir.
   - **N4, konsol grupları** (master): `/KONSOL/<REALM>-<YETKİ>` (`E-SKYLAB-YAZICILAR`, `SANDBOX-YAZICILAR`).
   - **N5, yeni client rolü.** `kaynak:eylem[:kapsam]`, küçük harf ASCII, sözcük içinde tire (Microsoft Graph'ın `{resource}.{operation}.{constraint}` deseni, ayırıcı `:`). Bir client'ta önek gelenekse (`skymail:`, `skyforms:`, `place:`) korunur; yeni client önek almaz. Yeni `*` rolü açılmaz; gerekiyorsa adlandırılmış bir composite açılır. Kişi rolü (`admin`, `moderator`) yalnız küçük uygulamalarda kullanılır.
   - **N6.** Yeni realm rolü açılmaz.
6. **Forms koltuğu Leader gruplarındadır (S7).** `forms` client'ının `skyforms:access` rolü en üst ekiplerin Leader gruplarına eşlenir. Bu rolü ya da `skyforms:*`'ı doğrudan taşıyanlar `/ROLLER/FORMS-ACCESS` ve `/ROLLER/FORMS-ALL` gruplarına geçer. Forms'ta okuyanı olmayan roller, Forms'un sahibinin teyidiyle kalkar.
7. **Kullanılmayan uygulamaların rolleri kalkar (S8).** SkyLapp ve SkyAutomate emekli edilir: rolleri kalkar, giriş ve servis client'ları önce devre dışı bırakılır, 14 gün izlenir, sonra ayrı bir adımla silinir. Cloudflare Zero Trust ve SkyCloud kullanımdadır, kalır; rolleri `/ROLLER`'e taşınır. Okuyanı olmayan `skymail:apps:read` kalkar. Eski `skycms` client'ındaki `cms:access`, o client'la giriş yapan site kalmadığı kanıtlanınca kaldırma planına girer; sıfır giriş olayı bu kanıt sayılmaz.
8. **Realm rolleri her zaman korunur.** core'un rol sınıflamasında realm rolleri için ad ya da konum istisnası yoktur; her realm rolü yönetici rolü sayılır (ADR-0065'in 2026-10-12 eki). Karar 2'den sonra korunacak realm rolü kalmaz.
9. **Konsol modeli (S1–S3).**
   - **Ayrı hesap.** Keycloak konsoluna giren her kişinin master realm'de kendine ait ayrı bir yönetici hesabı olur. Günlük e-skylab hesabı konsolda kullanılmaz. Konsol girişinde passkey zorunludur; Cookie adımı olmayan ayrı bir giriş akışı kullanılır.
   - **Yetki grupta.** Yetki master'daki `/KONSOL/E-SKYLAB-YAZICILAR` ve `/KONSOL/SANDBOX-YAZICILAR` gruplarından gelir. Bu gruplar ilgili realm'in bütün yönetim rollerini taşır, `impersonation` hariç.
   - **Herkes yazar.** Okuyucu grubu açılmaz; konsola girenlerin hepsi yazar. Bugün altı kişidir (S2, Yusuf 2026-10-12 "hepsi!", liste 2026-10-13). Kimin girdiği bu public depoya yazılmaz.
   - **master `admin`.** Yalnız işletme hesabında ve kişiye bağlı olmayan iki acil hesapta kalır. Kalan master yöneticileri önce devre dışı bırakılır, sonra silinir.
   - **Konsol grubunu core ve panel değiştiremez** (ayrı realm). Liste master yöneticisi tarafından değiştirilir.
   - Konsolun ne için kullanılacağı ve acil erişim ADR-0079'dadır.
10. **Büyük yeniden adlandırma yok (S6).** Kural yalnız yeni adlara uygulanır; kuraldan önceki adlar kalır (ADR-0065'in "kuraldan önceki ad kalır" ilkesi).
    - Ekip kodları, `LIDERLER`/`KOORDINATORLER`, `UYELER` ve alan adları değişmez. Hepsi Owner team kayıtlarında, CMS'te, Forms eşleşmesinde ve SkyApp'te anahtardır; faydası yalnız dil birliği olurdu.
    - YK görev gruplarının adı değişmez (`BASKAN_YARDIMCISI`'ndaki alt çizgi kalır); yalnız görünen ad konur.
    - Var olan client rolleri yeniden adlandırılmaz (önek birliği, `*`'ın kalkması).
    - Java dönemi realm rolleri adlandırılmaz, silinir (karar 2).
    - Eski bir erişim grubu varsa üyeleri ve eşlemesi karşılığı olan `/ROLLER` grubuna taşınır ve grup silinir.
11. **Hiyerarşi kalır; yetki yerleri ayrılır.** Ağaç doğrudur. Karışık olan örgüt ağacı ile yetki grubuydu: realm rolleri ekip gruplarına konmuştu, kişiye özel istisnalar kişiye rol olarak verilmişti. Microsoft ve Google'ın "örgüt grubu ayrı, erişim grubu ayrı" ayrımı iki ekle sağlanır: K4 ve `/ROLLER`.
    - `/ADMIN` kökte kalır: platform yöneticisi kulüp üyesi olmak zorunda değildir.
    - `/UYELER` ve alanlar kalır, rolsüz.
    - `/UYELER/YK` ve görev alt grupları kalır. Rol yalnız `/UYELER/YK`'dadır, görev gruplarında rol olmaz.
    - `/UYELER/DK` kalır.
    - Ekip, alt ekip ve Leader grupları kalır (GitHub'ın iç içe takım modeli, ADR-0065). Ekip grubunda rol olmaz.
    - `/ROLLER` eklenir.
    - Her en üst ekipte bir Leader grubu bulunur; eksik olanlar açılır.
    - core'un Privileged kök listesi bugün var olan üç köke (`/ADMIN`, `/UYELER/YK`, `/UYELER/DK`) indirilir. Böylece listedeki öbür üç yol (`/YK`, `/DK`, `/UYELER/ADMIN`) sonradan açılırsa kendiliğinden Privileged olmaz.

Kaynaklar:
- **Yusuf'un:** K1 ve K2'nin ilkesi (R1–R3), konsola girecek kişiler ve hepsinin yazması (R4, S2, 2026-10-13 listesi), lidersiz ekiplerin tamamlanması (R5), ad ve hiyerarşinin gözden geçirilmesi (R6), kullanımdaki ve emekli uygulamalar (S8; SkyCloud'un kalması 2026-10-13 düzeltmesi).
- **Spec önerisi, Yusuf'un "her şeyi sana bıraktım" yetkisiyle kabul (2026-10-12):** K3, K4, ayrı master hesabı (S1), acil hesaplar (S3), `/ROLLER` adı (S4), rol yerleşimi (S5), yeniden adlandırma politikası (S6), Forms koltuğu (S7; Forms'un sahibi 2026-10-15'te teyit etti), realm rol istisnasının kalkması, hiyerarşi hükmü.
- Sektör karşılaştırması hub'daki rol temizliği spec'inde ve grup yönetimi değerlendirmesinde.

**Uygulama durumu (2026-10-30).** `/ROLLER` grupları, en üst ekiplerin Leader gruplarındaki uygulama rolleri, core'un kişiye yeni doğrudan rolü reddetmesi ve realm rollerinin her zaman korunması uygulandı. Master konsol yapılandırması main'de, yayında değil. Konsol hesaplarının göçü, doğrudan rollerin `/ROLLER`'e taşınmasının kalanı, realm rollerinin kaldırılması, eski client'ların silinmesi ve Privileged kök listesinin üçe inmesi sırada.

## Consequences

- **ADR-0006 tamamlanır ve sıkılaşır.** "Realm roles go away" cümlesi K2 ile uygulanır. "Extra per-user client roles" kalkar (K1). "Keycloak's own console is only for IdP and OAuth2/client/token setup" cümlesi master'daki ayrı hesaplarla ve ADR-0079'daki politikayla uygulanır.
- **ADR-0059 sıkılaşır.** Uygulama geneli izin yine client rolüdür, ama yalnız K4'teki üç yerde eşlenir. Kişiye doğrudan rol kalmaz. Hiçbir uygulama realm rolünden yetki okumaz.
- **ADR-0065 sıkılaşır.** Realm rolü kuralı fail-closed kalır (karar 8). `/ROLLER` yaprakları uygulama rolü taşıdığı için devredilebilir; yönetici rolü taşıyan bir `/ROLLER` grubu korunan gruptur. core, bir gruba realm yönetim rolü eşlenmişse o gruba üye eklemeyi reddeder. Bu, K3'ün savunma derinliğidir.
- **ADR-0056 sıkılaşır.** Leader gruplarındaki konumdan gelen uygulama rolleri (Forms koltuğu, SkyCloud erişimi, site editörlüğü) yalnız en üst ekiplerin Leader gruplarındadır; ADR-0065'in eki `cms:access` için bunu zaten yazdı.
- **Panelde "ekstra rol" kalkar.** Kişiye özel bir uygulama izni gerekiyorsa kişi ilgili `/ROLLER` grubuna eklenir. Bu da denetim kaydına ve bildirime girer (ADR-0080).
- **Token.** `/ROLLER` yolları token'ın `groups` claim'inde görünür. İleride grup mapper'ına bir önek süzgeci eklenebilir (Entra'nın "groups assigned to the application" karşılığı).
- **Forms etiketi.** Forms giriş client'ı `realm_access`'i yalnız etiket için okuyor. Realm rolleri kalkınca Forms kenar çubuğundaki rol etiketi değişir; yetki değişmez. Forms'un sahibine bildirildi.
- **SkyApp.** SkyApp realm rollerini yalnız bilgi amaçlı tutuyor. Değişiklik ona sözleşme notuyla bildirilir; uygulamaya dokunulmaz.
- **Konsol hesaplarının bedeli.** Keycloak'ın belgesi master'da kullanıcı açmaktan kaçınmayı öneriyor. Bu bilinçli bir sapmadır: tek sınır ayrı realm. Her konsol hesabı ilk girişte passkey kaydetmelidir; kaydetmeyen konsola giremez. e-skylab'ın kendi konsolu kullanılmaz: kimse orada yönetim rolü taşımadığı için açılmaz.
- **Keycloak'ın sunucu yöneticisi** (`kc.sh bootstrap-admin` ile kurtarma) bu kararın dışındadır; ADR-0079'dadır.
- **Göç sırası.** Konsol (master hesapları), doğrudan rollerin `/ROLLER`'e taşınması, realm rollerinin kaldırılması, eski client'ların kapatılması, lidersiz ekiplerin tamamlanması. Her adım önce sandbox realm'inde denenir ve geri alınabilir. Tek istisna eski client'ların silinmesidir: 14 günlük izlemeden sonra ayrı bir adımla yapılır.
- **CONTEXT.md'de değişenler:**
  - Realm role: yalnız varsayılan roller kalır.
  - Client role: kişi başı ek yetki kalkar; N5 ad kuralı eklenir.
  - Yeni terim: Role group.
  - Certificate manager: açıkça verilen ek yetki yerine rol grubu üyeliği.
  - Privileged: master konsol grupları bu tanımın dışındadır.

## Açık

- **Başka kullanılan uygulama var mı?** S8'de "başka bir şey" seçeneği işaretlendi, açıklaması yazılmadı. Cevap gelene kadar hiçbir client silinmez; yalnız devre dışı bırakma ve 14 günlük izleme yapılır.
- *Not:* Ekip liderinin sertifika yetkisini (rol grubu üyeliği) kendi ekibinden birine nasıl vereceği ayrı bir karardır; bu ADR yazmaz.

## Endüstri uygulamasıyla karşılaştırma

**Uyanlar:**
- **Entra app roles.** Uygulama izinleri client rolleridir; kodun okuduğu değer boşluksuz bir dizedir, görünen ad ayrıdır (N1).
- **Rolü kişiye değil gruba ata.** Microsoft'un Cloud Adoption Framework'ü bunu önerir.
- **Role-assignable gruplar.** Yönetici rolü taşıyan grubu yalnız ayrıcalıklı yönetici değiştirir (Privileged kökler, ADR-0065). Konsol grubunu core ve panel değiştiremez; yalnız master yöneticisi değiştirir. Bu, Entra'da role-assignable grubu yalnız ayrıcalıklı rol yöneticisinin (ya da grubun atanmış sahibinin) yönetmesinin karşılığıdır.
- **Ayrı yönetici hesabı.** Microsoft, Global Administrator işleri için ayrı hesap ister; Cloud Adoption Framework ayrıcalıklı yönetimde günlük hesabın kullanılmamasını söyler. Google da süper yöneticiye ayrı bir hesap önerir.
- **Yöneticiye oltalamaya dayanıklı MFA.** Entra'nın Conditional Access şablonunun karşılığı, konsol girişinde passkey zorunluluğudur.
- **Acil erişim hesapları kişiye bağlı değildir ve en az ikidir** (ayrıntı ADR-0079).
- **İzin adı.** Yeni rol adları Microsoft Graph'ın `{resource}.{operation}.{constraint}` desenini izler (N5).
- **Örgüt grubu ile erişim grubunun ayrılması.** Google Cloud'un `org.` ve `access.` grupları ile Google Workspace'in OU ve erişim grubu ayrımının karşılığı K4 ve `/ROLLER`'dir.
- **Servis kimliğine doğrudan uygulama izni.** Entra'da service principal'a izin doğrudan verilir; bizde servis hesapları da öyle.

**Sapmalar (hepsi):**
1. **İki düzlem.** Entra'da tek dizin var. Bizde Keycloak ve core iki ayrı yetki düzlemi. Keycloak'ta realm içinde ayrıcalıklı katman olmadığı için yönetici hesapları ayrı realm'dedir.
2. **Master'da kullanıcı.** Keycloak master'da kullanıcı açmamayı öneriyor; biz konsol hesaplarını orada açıyoruz. Gerekçe yukarıdaki yükseltme yolu.
3. **Rol eşlemesi alt gruplara akar.** Entra'da uygulama ataması iç içe gruba akmaz, Keycloak'ta akar. Bunu yaprak kuralı (K4) kapatır.
4. **Role-assignable gruplar iç içe olmaz.** Bizde YK'nın görev alt grupları var ve YK'nın yetkisini alırlar. Privileged olmak bir bayrakla değil, sabit köklerle belirlenir.
5. **Örgüt şeması.** Entra'da örgüt şeması kullanıcı özniteliklerindedir, gruplar düzdür. Bizde örgüt şeması grup ağacıdır, YK görevleri birer alt gruptur (GitHub'ın iç içe takımları ve Google Cloud'un iç içe `org.` grupları gibi). Yetkinin durabildiği yerler K4 ile sınırlıdır.
6. **Yönetici sayısı.** Microsoft beşten az Global Administrator ve ondan az ayrıcalıklı rol ataması önerir. Bizde e-skylab'ı tam yöneten altı konsol yazıcısı var, ayrıca master `admin` taşıyan işletme hesabı ve iki acil hesap (S2). Telafi: kişi başına ayrı hesap, passkey, konsolun önündeki ek erişim denetimi, konsol değişikliklerinin core'un denetim kaydına girmesi (ADR-0079).
7. **PIM yok.** Entra'da ayrıcalıklı rol tam zamanında ve süreli verilir. Bizde konsol üyeliği kalıcıdır (lisans ve kulüp ölçeği). Süreli yönetim üyeliği yalnız YK, DK ve Leader gruplarındadır ve yalnız işaret koyar (ADR-0078).
8. **Grup süzgeci yok.** Entra token'a yalnız uygulamaya atanmış grupları koyabilir. Bizde `/ROLLER` yolları her token'ın `groups`'unda görünür.
9. **Ad ayırıcısı ve önekler.** Graph `.` kullanır, biz `:` kullanıyoruz. Bazı client'larda tarihsel önek var (`skymail:`, `skyforms:`, `place:`); yeniden adlandırılmıyor (karar 10).
10. **Ad politikası yetki içindir.** Entra'nın adlandırma politikası yalnız Microsoft 365 gruplarında var ve önek ya da sonek ekler. Bizde ad bir yetki anahtarı olduğu için kural daha sıkıdır (ADR-0065 karar 7, N2, N3).
11. **Kişiye doğrudan uygulama rolü yasak** (K1). Entra uygulama rolünü kişiye doğrudan atamaya izin verir; biz hiç izin vermiyoruz, yani daha sıkıyız.

## Considered Options

- **Konsol yetkisini e-skylab'da kişinin kendi hesabıyla `/ADMIN/KONSOL` grubundan vermek.** Reddedildi: `manage-users` taşıyan core ya da onun sırrını ele geçiren biri gruba istediği kişiyi ekleyip Keycloak yöneticiliği verebilirdi. Ayrıca tam kapsamlı bir giriş client'ının token'ı (ör. tarayıcıda duran Forms token'ı) Keycloak Admin REST anahtarı olurdu.
- **e-skylab'da ayrı yönetici hesapları.** Aynı yükseltme yolu açık kalırdı.
- **Tam düzleştirme** (her rol `/ROLLER`'de, Privileged kökler ve Leader grupları rolsüz). Önerilmedi: core'un `groups` kipi Privileged'ı yoldan okuyor; her dönem devrinde üyelik iki yerde tutulurdu; her uygulamanın yol okuması değişirdi. Kazanç küçük: K4 aynı riski kapatıyor.
- **Büyük yeniden adlandırma** (ekip kodları, `LIDERLER`'in İngilizceye çevrilmesi, client rol öneklerinin birleştirilmesi, `*`'ın kalkması). Reddedildi: Owner team kayıtlarını, CMS slug'larını, Forms eşleşmesini, SkyApp'in sabit listesini ve token yollarını kırar; fayda dil birliğiyle sınırlı.
- **Rol grubunun iki katlı olması** (`/ROLLER/SKYMAIL/ACCESS`). Reddedildi: `ACCESS` gibi adlar her uygulamada tekrar eder; ekip kodu realm'de tek olduğu için panelden açılamaz.
- **Realm rollerine ad ya da konum istisnası** (ör. ekip adlı rolleri uygulama rolü saymak). Reddedildi: karar 2'den sonra ölü kod olurdu; core realm rollerinin composite'lerini okuyamadığı için içlerine eklenen bir yönetici rolü görünmez kalırdı.
- **Konsol girişinde koşullu rol akışı.** Reddedildi: rol adı değişirse ikinci faktör sessizce atlanır. Konsol client'ı için ayrı bir akış kullanılır.

## Kaynaklar

- Microsoft Entra, uygulamaya kullanıcı ya da grup atama ("The assignment doesn't cascade to nested groups."): https://learn.microsoft.com/en-us/entra/identity/enterprise-apps/assign-user-or-group-access-portal
- Microsoft Entra, uygulamaya rol ekleme (app roles): https://learn.microsoft.com/en-us/entra/identity-platform/howto-add-app-roles-in-apps
- Microsoft Entra, grup claim'leri: https://learn.microsoft.com/en-us/entra/identity/hybrid/connect/how-to-connect-fed-group-claims
- Microsoft Entra, yönetim birimleri: https://learn.microsoft.com/en-us/entra/identity/role-based-access-control/administrative-units
- Microsoft Entra, rol atanabilir gruplar: https://learn.microsoft.com/en-us/entra/identity/role-based-access-control/groups-concept
- Microsoft Entra, grup adlandırma politikası: https://learn.microsoft.com/en-us/entra/identity/users/groups-naming-policy
- Microsoft Entra, PIM for Groups: https://learn.microsoft.com/en-us/entra/id-governance/privileged-identity-management/concept-pim-for-groups
- Microsoft Entra, acil erişim hesapları: https://learn.microsoft.com/en-us/entra/identity/role-based-access-control/security-emergency-access
- Microsoft Entra, rol en iyi uygulamaları (beşten az Global Administrator): https://learn.microsoft.com/en-us/entra/identity/role-based-access-control/best-practices
- Microsoft Entra, ayrıcalıklı erişimin güvenliği (ayrı yönetici hesabı): https://learn.microsoft.com/en-us/entra/identity/role-based-access-control/security-planning
- Microsoft Cloud Adoption Framework, kimlik ve erişim yönetimi: https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/landing-zone/design-area/identity-access-landing-zones
- Microsoft Entra, yöneticiler için oltalamaya dayanıklı MFA: https://learn.microsoft.com/en-us/entra/identity/conditional-access/policy-admin-phish-resistant-mfa
- Microsoft Graph, izin adları: https://learn.microsoft.com/en-us/graph/permissions-overview
- Google Workspace, yönetici hesapları için güvenlik önerileri: https://knowledge.workspace.google.com/admin/users/security-best-practices-for-administrator-accounts
- Google Cloud, grup en iyi uygulamaları: https://docs.cloud.google.com/iam/docs/groups-best-practices
- Google Workspace, erişim grupları: https://knowledge.workspace.google.com/admin/users/advanced/customize-service-access-using-access-groups
- Okta, grup kuralları: https://help.okta.com/en-us/Content/Topics/users-groups-profiles/usgp-about-group-rules.htm
- Okta, yönetici sayısını sınırlama: https://help.okta.com/en-us/content/topics/security/healthinsight/limit-admins.htm
- GitHub, takımlar: https://docs.github.com/en/organizations/organizing-members-into-teams/about-teams
- Keycloak, master realm ve kullanıcı açma: https://www.keycloak.org/docs/latest/server_admin/index.html
- Keycloak, yönetici kurtarma: https://www.keycloak.org/server/bootstrap-admin-recovery
- Hub'daki rol temizliği spec'i (2026-10-12) ve grup yönetimi değerlendirmesi (2026-10-12).
