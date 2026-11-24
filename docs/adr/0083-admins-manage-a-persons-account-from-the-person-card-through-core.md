---
status: accepted
---

# Yönetici kişinin Keycloak hesabını kişi kartından, core üzerinden yönetir; Privileged kişinin hesabını yalnız ADMIN değiştirir; geçici parola bir kez gösterilir; kişi kendi hesabını Hesap merkezinde değiştirir

_Güncelleme (2026-11-24): Karar 2'deki "Kişiye doğrudan rol yok (ADR-0076 K1)" cümlesi ADR-0076'nın 2026-11-24 ekiyle daralır: kişi kartı kişiye rol yazmaz, ama uygulama rolü panelin Uygulamalar sayfasından kişiye atanabilir. Yönetici rolü yine yalnız Privileged kökte, `/ROLLER`'de ve en üst ekiplerin Leader gruplarında._

Panelin kişi kartı bugüne kadar yalnız kulüp profilini, grupları ve oturum kapatmayı gösteriyordu. Bir kişinin e-postasını değiştirmek, onaylı saymak, parolasını sıfırlatmak, hesabını kapatmak ya da bir passkey'ini silmek için Keycloak konsoluna gidiliyordu; konsolda yapılan değişiklik core'un denetim kaydına girmiyor (ADR-0079) ve kişiye kim, ne zaman dokundu okunamıyor. CONTEXT "User" maddesi "resetting password on the admin card"ı kaçınılacaklar arasında sayıyordu.

Karar (Yusuf, 2026-11-22: "kullanıcının her detayını burdan da güncelleyebilmeliyiz … Keycloak'taki tüm özellikleri burdan da yönetebilmeliyiz"; 2026-11-23 sabahı soruların cevapları):

1. **Kapsam.** Kişi kartı, core üzerinden, kişinin Keycloak hesabını okur ve değiştirir: hesabı etkin ya da devre dışı yapmak (devre dışı bırakınca oturumlar kapanır), e-posta değiştirmek, onaylı işaretlemek, doğrulama postası göndermek, birincil adresi seçmek, parola sıfırlama postası göndermek, geçici parola belirlemek, gerekli eylemler (parolasını değiştirsin, doğrulama uygulaması kursun, passkey eklesin, e-postasını doğrulasın), kimlik bilgilerini (parola, passkey, doğrulama uygulaması) tek tek kaldırmak, bağlı kimlik sağlayıcıyı ayırmak, kaba kuvvet kilidini açmak. Okunan: kimlik bilgileri (gizli verisi değil), bağlı hesaplar, oturumlar (IP değil), kilit, son 30 günün giriş olayları. Yalnız core'un service account'u Keycloak'a yazar (ADR-0065); panel token'ı Keycloak'a gitmez.
2. **Yapılmayanlar.** Kimliğe bürünme yok (ADR-0076 konsola da vermez). Kalıcı silme yok: silme kişinin başvurusu ve Account erasure'dır (ADR-0051). Kişiye doğrudan rol yok (ADR-0076 K1). Kullanıcı adı değişmez: realm `editUsernameAllowed=false`, yalnız sky-account kişinin kendi isteğiyle değiştirir. Okul e-postası yalnız YTÜ bağlantısından gelir, yazılmaz (ADR-0044).
3. **Yetki (Entra'nın ayrımı).** Okuma: `users:manage` ve Privileged reader (DK, `global:read`). Yazma: `users:manage` (ADMIN ve YK; DK yazmaz, ADR-0077). Hedef kişi bir Privileged kökte ya da altındaysa (ADMIN, YK, DK) hesabını yalnız ADMIN kökündeki biri değiştirir: Entra'da Authentication Administrator sıradan kişinin, yalnız Privileged Authentication Administrator yöneticinin kimlik bilgisini sıfırlar. Entra gibi yalnız yönetim kökleri değil, bütün yönetici rolleri korunur: kişinin etkin rolleri (üst gruplardan, realm ve client bileşiklerinden ve varsayılan rolden gelenler dahil; Keycloak çözer) arasında core'un Protected sınıflamasında uygulama rolü olmayan bir rol (`/ROLLER/FORMS-ALL`, SkyMail'in gönderme, onay ve okuma rolleri, `place:admin`, `skycloud/admin`, sınıflanmamış bir rol) ya da herkesinkiler (`USER` ve varsayılan realm rolleri) dışında bir realm rolü varsa hesabı da yalnız ADMIN'indir. Ad yazımı da aynı kurala tabidir: kişi kartından değişen ad kendi hesabında yapılmaz, yönetici rolü sahibinin adını yalnız ADMIN değiştirir, ret denetim kaydına girer. Servis hesabı ve silinmekte olan kişi değişmez. Karar core'dadır; panel düğmeleri core'un yanıtındaki `can` alanından gösterir (ADR-0059).
4. **Kendi hesabı.** Kimse kendi hesabını kişi kartından değiştirmez; Hesap merkezi Sudo mode ister (ADR-0043). Kart Hesap merkezine bağlantı gösterir.
5. **Denetim kaydı.** Her yazma ve yetkiyle reddedilen her yazma Team audit record'a `user.*` satırı olarak girer: hedef kişidir, grup yoktur; satır yalnız bayrak ve kimlik taşır (etkin, geçici, onaylı, birincil türü, gerekli eylem adları, kimlik bilgisinin kimliği ve türü, sağlayıcı, değişen alan adları), adres, ad ya da parola taşımaz. Satır açılamazsa değişiklik yapılmaz.
6. **Geçici parola.** Yönetici yazar ya da core üretir. Üretilen parola yanıtta bir kez döner (`Cache-Control: no-store`), panel bir kez gösterir; hiçbir günlüğe, kayda ya da hataya girmez. Parola her zaman geçicidir (kişi ilk girişte değiştirir) ve belirlenince bütün oturumlar kapanır.
7. **ADR-0044'e yönetici istisnası.** Yöneticinin koyduğu adres kişisel e-posta olur, istenirse birincil. Yönetici "onaylı say" ile kanıtı kendisi verebilir (kanıt damgası yazılır) ya da doğrulama postası gönderir. Yöneticinin koyduğu onaysız adres birincil olabilir ve doğrulama bağlantısı birincil adrese gider; ADR-0044'ün reddettiği "kişinin kendi beyan ettiği onaysız adres birincil olmaz" kuralının yalnız yöneticiye özgü istisnasıdır. Yönetici başlattığında doğrulama **bağlantıdır**; ADR-0044 ekindeki kod yalnız kişinin kendi başlattığı akışta kalır. Bağlantıyı yalnız o posta kutusu açar ve bağlantı adresi başka bir hesaba bağlayamaz (adresi yönetici koydu); ADR-0044 ekinin kapattığı saldırı yolu yoktur. Okul alanındaki ve başka bir hesapta duran adres reddedilir.

## Consequences

- CONTEXT "User": "resetting password on the admin card" kaçınılacaklardan çıkar; hesap işleri bu ADR'ye bağlanır.
- core'un service account'u Keycloak'ın `view-events` rolünü alır (ADR-0079 karar 6'nın olay okuma rolü); rol yokken kart girişleri "okunamıyor" diye gösterir.
- Yönetici bağlantısıyla doğrulanan kişisel adres Keycloak'ta onaylı olur ama sky-account'un kanıt damgası yazılmaz; Hesap merkezi onu doğrulanmamış kişisel adres sayar. Bağlantı tamamlanınca damganın da yazılması e-skylab-keycloak'ta ayrı iştir.
- YTÜ bağlı hesapta panelden yazılan ad kalır: YTÜ sağlayıcısı `LEGACY` senkronlar ve adı sonraki girişlerde yazmaz; ad yalnız yeni bir YTÜ bağlamasında Microsoft'unkine döner.
- Konsol yine ayarlar ve acil durum içindir (ADR-0079); sıradan hesap işi panelden yapılır.

## Endüstri uygulamasıyla karşılaştırma

**Uyanlar:**
- **Entra:** kullanıcı özellikleri, oturum açmayı engelleme, oturumları iptal, kimlik doğrulama yöntemlerini görme ve silme, bir kez gösterilen ve ilk girişte değiştirilen geçici parola; yönetici hesabının kimlik bilgisini yalnız Privileged Authentication Administrator sıfırlar.
- **Google Workspace:** askıya alma, parola sıfırlama (üret ya da yaz, ilk girişte değiştir), oturumları kapatma, güvenlik anahtarlarını silme.
- **Okta, Auth0:** yönetici başlattığında parola sıfırlama ve e-posta doğrulama bağlantıyla gider.
- **Clerk:** yönetici e-postayı doğrulanmış olarak ekleyebilir, birincil seçer, kilidi açar, bağlı hesabı ayırır.

**Sapmalar (hepsi):**
1. **İki düzlem:** kurallar core'da, dizin Keycloak'ta; Keycloak konsolu bu kuralları bilmez (ADR-0079 ile aynı sapma).
2. **YK de yazar:** sıradan kişinin hesabını ADMIN gibi YK de değiştirir (yazma rolleri ADMIN ve YK'dadır, ADR-0077); Entra'da bu ayrı bir rol olurdu.
3. **Kendi hesabı panelde salt okur:** Entra ve Google yöneticinin kendi hesabını konsoldan değiştirmesine izin verir; biz Sudo mode'lu Hesap merkezine gönderiyoruz.
4. **Kimliğe bürünme yok:** Clerk ve Auth0'da var.

## Considered Options

- **Keycloak konsolu yeterlidir:** Denetim kaydı ve Privileged ayrımı yok; günlük iş konsola taşınırdı (ADR-0079'un tersi).
- **Hassas işler yalnız ADMIN:** Kulübün günlük üye desteğini YK yürütüyor; Privileged ayrımı yöneticinin hesabını zaten ADMIN'e bırakıyor.
- **Yönetici e-postasında yalnız kod:** Kod kişinin oturumunda girilir; yönetici başlattığında kişi oturumda olmayabilir. Okta ve Auth0 yönetici akışında bağlantı kullanır.
- **Geçici parola yerine yalnız sıfırlama postası:** Posta kutusuna ulaşamayan kişiyi açamaz; Entra ve Google ikisini de sunar.

## Kaynaklar

- Microsoft Entra, kullanıcının parolasını sıfırlama: https://learn.microsoft.com/en-us/entra/fundamentals/users-reset-password-azure-portal
- Microsoft Entra, yönetici rolleri (Authentication Administrator, Privileged Authentication Administrator): https://learn.microsoft.com/en-us/entra/identity/role-based-access-control/permissions-reference
- Microsoft Entra, kimlik doğrulama yöntemlerini yönetme: https://learn.microsoft.com/en-us/entra/identity/authentication/howto-mfa-userdevicesettings
- Google Workspace, kullanıcının parolasını sıfırlama: https://support.google.com/a/answer/33319
- Auth0, doğrulama postası gönderme (Management API): https://auth0.com/docs/manage-users/user-accounts/verify-emails
- Keycloak, Admin REST API: https://www.keycloak.org/docs-api/latest/rest-api/index.html
- core `docs/user-accounts.md`; hub `notes/panel-yenileme-2026-11-22/p7-keycloak-envanter.md`.
