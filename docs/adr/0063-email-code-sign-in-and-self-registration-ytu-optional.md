---
status: accepted
---

# E-SKY LAB'e e-posta koduyla kayıt ve giriş; YTÜ hesabı isteğe bağlı, ilk YTÜ girişinde okul adresi birincil

Kişiler okul e-postası ve okul Microsoft şifresi istenince "bilgilerimizi çalıyorlar" hissine kapılıyor. Bir kısmı da okul şifresini bilmediği için vazgeçiyor. 128 hesabın 115'i YTÜ Microsoft'a bağlı, parolası olan tek kişi var. YTÜ'süz kendi kendine kayıt kapalı (`registrationAllowed=false`); mezun, personel ve başka üniversiteden gelen kişi hesap açamıyor. İlk YTÜ girişi altı ekran sürüyor: SKY LAB eşleyicisi Microsoft'tan gelen e-postayı her girişte siliyor, bu yüzden yeni kişiye bir profil formu ve bir doğrulama bağlantısı daha çıkıyor. 20 hesabın birincil adresi hiç yok. Araştırma ve spec hub'daki `eskylab-login-ux` çalışma notlarında (2026-10-04).

Karar (Yusuf, 2026-10-04; S1-S8 olduğu gibi onaylandı):

1. **YTÜ hesabı olmayan da kayıt olabilir (Self-registration).** Kayıt kişisel e-posta ve altı haneli bir kodla yapılır, parola istenmez. Kişi isterse sonra parola ve passkey ekler, isterse YTÜ hesabını bağlar. Kayıttan hemen sonra akışın içinde "Okul mailini bağlamak ister misin?" sorulur, passkey ve parola önerilir; hepsi atlanabilir. Hoş geldin postası da aynısını söyler.
2. **"E-postama kod gönder" ile giriş herkese açıktır (Login code).** TOTP'si olan kişiye koddan sonra TOTP yine sorulur.
3. **Giriş ekranında iki düğme vardır:** "YTÜ hesabınla devam et (Microsoft)" ve "E-postayla devam et". Altlarında şu satır durur: okul şifresini yalnız Microsoft görür, SKY LAB görmez; YTÜ hesabından yalnız ad, okul e-postası ve bölüm alınır. Açılır metin Microsoft hesabının değişmez kimlik numarasını da sayar.
4. **İlk YTÜ girişinde yeni hesap açılmadan önce** "Zaten bir SKY LAB hesabın var mı? Giriş yap ve bağla" sorulur.
5. İlk YTÜ girişinde Microsoft'un verdiği okul adresi, **yalnız yeni hesapta,** doğrulanmış Primary e-mail olur. Var olan ya da bağlanan hesabın birincil adresini hiçbir YTÜ girişi değiştirmez.
6. **Microsoft tarafında** uygulamanın adı, logosu ve bağlantıları düzeltilir, ucuz bir test yapılır. Kiracı genelinde yönetici onayı (admin consent) **yoktur:** YTÜ BİDB vermiyor (2026-10-04). Microsoft'un izin ekranı kalır; onu giriş ekranındaki güven satırı ve ilk girişte ne görüleceğini anlatan kısa açıklama karşılar. Yayıncı doğrulaması yapılmaz.
7. Google ile giriş şimdi eklenmez. Kodla giriş ve passkey çıktıktan 30 gün sonra sayılara bakılıp karar verilir.

Nasıl:

- **Kayıt ve kodla giriş tek kapıdır: "E-postayla devam et".**
  - Kişi adresini ya da kullanıcı adını yazar, kod gelir.
  - Kod doğruysa: hesap varsa giriş yapılır; yoksa ad ve soyad sorulur, hesap açılır.
  - Hesabın var olup olmadığı ancak kod doğrulandıktan sonra belli olur. Adres ekranı her durumda aynıdır, yanıt süresi de aynı tutulur; ekran adres sorgulamaya (enumeration) kapalıdır.
  - Giriş kodu, "Parolanı mı unuttun?" postası gibi birincil adrese gider; birincil yoksa okul adresine. Kayıt kodu yazılan adrese gider.
- **Kayıtla açılan hesabın adresi** hem Primary e-mail hem Personal e-mail olur; kanıtı kayıt kodudur. Personal e-mail'in kanıtı artık iki yerde yapılabilir: Account center'da ya da kayıt sırasında. İkisinde de kod yalnız onu isteyen oturumda çalışır. Kayıt hiçbir yetki vermez: gruplar ve roller realm varsayılanıdır, üyelik yöneticinin kararı olarak kalır.
- **Okul alan adlarıyla** (`std.yildiz.edu.tr`, `yildiz.edu.tr`) kodla hesap açılmaz; kişi YTÜ girişine yönlendirilir. School e-mail yalnız YTÜ bağlantısından gelir (ADR-0044).
- **Kod kuralları ADR-0044'teki gibidir:** altı hane, on dakika, beş yanlışta ölür, tek kullanım, yalnız onu isteyen giriş oturumunda (tarayıcı ve sekme) çalışır, yalnız tuzlu özeti saklanır. Kod konu satırında yer almaz. Gönderim hedef adres başına, giriş oturumu başına, IP sınıfı başına (IP'nin kendisi hiçbir yere yazılmaz) ve genel olarak sınırlıdır. Yanlış kod Keycloak'ın kaba kuvvet sayacına yazılır.
- **Keycloak'ın hazır olanları kullanılır:** passkey kaydı (`webauthn-register-passwordless`), `UPDATE_PASSWORD`, koşullu OTP, kaba kuvvet koruması, User Profile, first broker login'in bağlama adımları (`update.profile.on.first.login=missing` dahil) ve `idp_link`. Keycloak 26.x'te e-postaya kodla giriş ve kodla adres doğrulama **yoktur;** bu parçalar SKY LAB SPI'sinde yazılır (`sky-email-code`, `sky-after-login`, `sky-ytu-first-login`, `sky-existing-account-prompt`). Topluluk eklentisi kullanılmaz.
- **Keycloak'ın hazır kayıt sayfası kapalı kalır.** First broker login'de bağlantıyla doğrulayan "Verify Existing Account By Email" adımı kapatılır.
- **Sudo mode'a e-posta kodu eklenir:** yalnız parolası, passkey'i ve TOTP'si olmayan kişiye, kod o anki birincil adrese gider (sky-account SPI). YTÜ bağlantısı varsa Microsoft da sunulur. Bu olmadan kodla kayıt olan kişi Account center'da hiçbir hassas işlem yapamazdı. Kayıt bu adım ve çift hesap koruması (karar 4) hazır olmadan canlıda açılmaz.
- **Hoş geldin postasını core gönderir, tek gönderen o kalır.** YTÜ bağlantısı olmayan kişiye "okul hesabını bağla" bloğu ve giriş yolları satırı eklenir.
- **YıldızPlace,** okul adresi olmayan hesaba "YTÜ hesabını bağla" der. Mail ile giriş yedek yol olarak kalır.
- **Kayıtta CAPTCHA yoktur.** Hesap yalnız kod doğrulanınca açılır; sınırlar posta bombardımanını durdurur. Doğrulanmayan kod oranı, genel sınır ya da geri dönen posta eşiği aşarsa Cloudflare Turnstile eklenir (Cloudflare zaten bir alıcı).
- **Yayın:** Keycloak imajı sandbox ve canlı realm için ortaktır. Yeni adımlar önce sandbox realm'inde bağlanır, sonra canlıda. Geri almak için alt akışı kapatmak (DISABLED) yeter; parola ve passkey yolları değişmez.

## Consequences

- **E-posta kodu NIST SP 800-63B-4'te doğrulayıcı (authenticator) sayılmaz.** Bunu bilerek kabul ediyoruz: "Parolanı mı unuttun?" zaten posta kutusuna sahip olana hesabı veriyor, kod saldırı yüzeyini büyütmüyor. TOTP'si olanın hesabı posta kutusu ele geçirilse de korunur.
- **Kayıtla açılan hesap Verified YTÜ account değildir.** Adı kilitsiz, bölümü elle yazılır, Place'e giremez. Yönetici üye alırken rozete bakar. YTÜ bağlanınca kilit gelir.
- **Application Initiated Actions.** CONTEXT.md'deki "Application Initiated Actions as the product path" yasağı Account center'ın kimlik, kimlik bilgisi ve e-posta değişikliklerini kapsar; onlar yine yalnız sky-account SPI'sinden geçer. İki yer bu yasağın dışındadır ve yeni değildir:
  - Account center'ın gönderdiği tek eylem YTÜ bağlamadır (`kc_action=idp_link`), çünkü bağlantıyı yalnız kişinin Microsoft'taki girişi kanıtlar.
  - Kayıttan hemen sonraki öneriler `e.`'deki giriş akışının parçasıdır, Account center'ın self-service'i değildir. Orada Keycloak'ın hazır eylemleri (`idp_link`, `webauthn-register-passwordless`, `UPDATE_PASSWORD`) kullanılabilir. `idp_link`'in akış içinden tetiklenmesi prototipte doğrulanır; olmazsa kişi giriş bittikten sonra Account center'daki "YTÜ hesabımı bağla"ya gönderilir.
- **Kayıt yeni bir veri toplama noktasıdır** (ad, soyad, e-posta). Dayanağı sözleşmenin ifasıdır (KVKK md. 5/2-c), açık rıza ve onay kutusu yoktur; aydınlatma metnine veri kaynağı olarak eklenir. Giriş ekranındaki KVKK cümlesi "kabul ediyorsunuz" kalıbından çıkar, "okuyabilirsin" olur. Yeni alıcı yoktur (SkyMail, Microsoft, Cloudflare zaten listede). Saklama ADR-0062'dedir: hesap "üye hesabı ve profili" satırına girer; bekleyen kodlar on dakikada kendiliğinden silinir; tamamlanmayan kayıttan yalnız Keycloak olayı ve SkyMail gönderim kaydı kalır.
- **Microsoft izin ekranı ilk YTÜ girişinde kalır** (karar 6). Ekran sayısı hedefi bu ekranı saymaz.
- **ADR-0044 değişmez;** bu ADR onu genişletir: Personal e-mail'in kanıtı kayıtta da yapılabilir, kod kuralları aynıdır.
- **CONTEXT.md'de değişenler:**
  - Yeni terimler: Self-registration ve Login code.
  - Personal e-mail: kanıt kayıt sırasında da yapılabilir.
  - Primary e-mail: yeni YTÜ hesabında başlangıç değeri okul adresidir; YTÜ girişi var olan hesabın birincilini değiştirmez.
  - Sudo mode: parolası, passkey'i ve TOTP'si olmayan kişiye e-posta kodu.
  - Account center ve sky-account SPI: `e.`'nin görünür olduğu yerler ve Application Initiated Actions yasağının sınırı.

## Endüstri uygulamasıyla karşılaştırma

**Uyanlar:**
- Slack ve Notion: e-postaya giden kodla giriş; Notion'da hesap yoksa koddan sonra kayıt.
- CampusGroups: okul SSO'su ve okul dışı kişiye altı haneli kodla misafir hesabı (iki kapı).
- Discord Student Hubs: önce kişisel hesap, okul kanıtı sonra ve isteğe bağlı.
- Microsoft hesabı: yeni hesaplar parolasız, kayıtta passkey önerisi.
- OWASP Authentication Cheat Sheet: genel yanıtlar, adres sorgulamaya dayanıklı akış, oran sınırı.
- NIST SP 800-63B-4: kod ömrü, deneme ve oran sınırları; senkron passkey.

**Sapmalar (hepsi):**
1. **E-posta kodu birinci faktör** (NIST SP 800-63B-4 e-postayı doğrulayıcı saymaz). Gerekçe Consequences'ta.
2. **Kod doğrulandıktan sonra hesabın var olup olmadığını söylüyoruz** (OWASP genel yanıt ister). Kişi posta kutusunu kanıtladıktan sonra söylendiği için sızıntı yok sayılır.
3. **İlk ekran yöntem sorar, e-posta sormaz** (Microsoft ve Google identity-first). Yusuf iki düğmeyi seçti.
4. **Kayıtta parola yok** (CampusGroups misafir hesabı parola ister).
5. **Microsoft izin ekranı kalır** (kurumsal uygulamalarda yönetici onayıyla kalkar). YTÜ onay vermiyor.

## Considered Options

- **Keycloak'ın hazır kayıt formu** (parola ve doğrulama bağlantısı): parola şikâyetin kendisi. Bağlantıyı ADR-0044 reddetti. Hazır form ayrıca hesabı adres kanıtlanmadan açar.
- **Sihirli bağlantı:** ADR-0044'teki gerekçeyle reddedildi. Oturumsuz açılan bağlantı ya bozulur ya da başkasının adına tıklatılabilir.
- **Topluluk e-posta OTP eklentisi:** kod deposu, oran sınırı, SkyMail ve adres çözümleme bizde zaten var. Eklentiyi alsak da bakımı ve güvenlik incelemesi bize kalırdı.
- **Google reCAPTCHA** (Keycloak'ın hazır CAPTCHA'sı): yeni bir yurt dışı alıcı getirir, kullanıcıyı da yorar.
- **Tek e-posta kutusuyla alan adına göre yönlendirme** (Keycloak Organizations, identity-first): Yusuf iki düğmeyi seçti.
- **Kayıt anında parola istemek.**
- **Okul adresiyle kodla hesap açmak:** okul posta kutusunu okuyabilen aynı Microsoft hesabına da girebilir. Kodlu okul hesabı hem doğrulanmamış bir School e-mail hem de sonradan gelecek bir çift hesap demek.
- **Okul adresini bağlı hesaplarda da birincil yapmak:** kişinin seçtiği birincil adres değişirdi.
- **Hoş geldin postasını Keycloak'tan da göndermek:** iki gönderen, iki posta.
- **Kiracı genelinde yönetici onayı:** izin ekranını kaldırırdı, ama YTÜ BİDB vermiyor. Hiçbir adım ona bağlı değildir.
- **Microsoft yayıncı doğrulaması:** bir öğrenci kulübü için Microsoft Partner hesabı ve doğrulanmış kuruluş gerekir.
