---
status: accepted
---

# Ekibe davet, kişi kabul edene kadar bekler ve hesap açmaz; erişim talebi Hesap Merkezi'nden istenir, ekibi yöneten onaylar

Bugün hesabı olmayan birini ekibe almanın yolu iki adımlıdır: kişi my.yildizskylab.com'dan kaydolur (ADR-0063), en geç 5 dakika sonra core'a düşer, sonra lider ya da YK onu ekler (ADR-0065). Bir ekibe katılmak isteyen kişi de lidere kendisi yazar; bunun bir kaydı ve onay yolu yoktur.

Karar (Yusuf, 2026-11-11, karar 21: davet ve erişim talebi şimdi yapılır; 2026-11-23 01:01: davet 14 gün geçerlidir, davet ve talep production'da `TEAM_DELEGATION` ile birlikte açılır):

1. **Davet bekleyen davettir** (Invitation). Bir ekibi yöneten (Team manager, ADR-0065; `TEAM_DELEGATION` kapalıyken yalnız yazabilen Privileged (ADMIN, YK; ADR-0077)) bir e-posta adresini o ekibe ya da alt ekibine davet eder.
   - core yalnız bir davet kaydı açar. Keycloak'ta hesap açılmaz ve üyelik yazılmaz.
   - Kişi kendisi giriş yapar ya da kaydolur (ADR-0063) ve daveti Hesap Merkezi'nde kabul eder. Üyelik o an, davet edenin adına core'un denetimli yazıcısından yazılır.
   - Davet edenin yetkisi kabul anında Keycloak'tan yeniden okunur; yetkisi kalmamışsa davet geçersizdir. Kabul, davet edenin o an yapamayacağı bir ekleme yapamaz.
   - Hedef yalnız bir ekibin ya da alt ekibin kendi grubudur (sıradan üyelik). Leader grupları, Privileged kökler, `/ROLLER` ve Protected gruplar hedef olamaz. Liderlik ve yönetim üyeliği hesabı olan kişiye Dönem devri ekranından verilir (ADR-0078).
2. **Kabul için adresin sahibi olmak gerekir.** Davet adresi, kabul eden hesabın kanıtlanmış adreslerinden biriyle tam eşleşmelidir: doğrulanmış Primary e-mail, Verified YTÜ account'un School e-mail'i, kodla doğrulanmış Personal e-mail. Karşılaştırma küçük harf ve kırpılmış adresle yapılır; sağlayıcıya özel normalleştirme yapılmaz.
   - Davetin yanıtı, adresin bir hesabı olsa da olmasa da aynıdır; hesap varlığı sızmaz.
   - Bağlantı anahtar taşımaz; iletilen posta tek başına daveti kabul ettirmez.
   - Hesabı olduğu bilinen kişi bugünkü gibi aday aramasıyla doğrudan eklenir.
3. **Davet 14 gün geçerlidir** (Yusuf). Süre ortam ayarıdır. Davet postasında girişsiz ret bağlantısı vardır; ret anahtarının yalnız özeti tutulur ve anahtar yalnız reddetmeye yarar.
   - Adres yalnız davet beklerken tutulur. Kabul, ret, süre dolumu, geri çekme ya da geçersizlikte hemen silinir; kişisiz kayıt 90 gün sonra silinir.
   - Davet eden ya da o grubu yöneten biri daveti geri çekebilir. Posta 24 saatte en çok bir kez, toplamda en çok iki kez yeniden gönderilir; süre yenilenmez.
   - Sınırlar: davet eden başına günde 20, ekip başına 50 açık davet, aynı ekip ve adrese 1 açık davet, aynı adrese bütün kulüpte 30 günde 3 davet.
   - Posta SkyMail'den işlem postası olarak gider (`club.team-invitation`). Davet edenin bu ekibe tek seferlik işlem postasıdır ve Contact consent'in (Davet onayı, ADR-0062) kapsamına girmez: kişiyi başka etkinlik ya da duyurular için bir listeye almaz. Davetliye ad yazılmaz; posta gönderildikten sonra SkyMail'de tutulmaz, açılması ve tıklanması izlenmez. İletişim tercihi bu postaya uygulanmaz.
   - Posta gizlilik metni bağlantısını (`noticeUrl`) ve adresin silineceği tarihi taşır.
4. **Erişim talebi Hesap Merkezi'nden istenir** (Access request). Girmiş her etkin hesap, public listelenen bir ekibe ya da alt ekibine katılmak isteyebilir. Protected gruplar, Leader grupları, Privileged kökler ve `/ROLLER` hedef olamaz.
   - İsteğe bağlı gerekçe en çok 500 karakter düz metindir.
   - Kişi başına 3 açık talep ve günde 5 talep, hedef başına 1 açık talep olur. Reddedilen hedefe 30 gün sonra yeniden talep açılabilir.
5. **Talebi o ekibin üyeliğini değiştirebilen biri onaylar** (Team manager, ADR-0065). Posta önce ekibin kendi Leader'larına gider; yoksa en yakın üst ekibin Leader'larına, o da yoksa YK'ya.
   - 7. günde bir hatırlatma gider. 14 gün yanıtsız kalan talebin süresi dolar.
   - Onay, onaylayanın adına denetimli yazıcıdan yazılır ve olağan üyelik postasını üretir. Ayrı bir onay postası yoktur.
   - Ret ve süre dolumu talep edene bildirilir. Ret için serbest metin yoktur.
   - Gerekçe metni talep sonuçlanınca silinir; talep kaydı 1 yıl sonra silinir.
   - Yusuf onay zincirinde yoktur.
6. **Onaylanan ya da kabul edilen üyelik sıradan üyeliktir.** Bitişi yoktur (ADR-0078); yıllık erişim gözden geçirmesi kapsar (ADR-0085).
7. **Denetim kaydı.** Kabul ve onay, Team audit record'a `member.add` olarak girer. Yeni `via` alanı satırın nereden geldiğini söyler (`invitation`, `access_request`). Davetin açılması, geri çekilmesi ve talebin reddi grubu değiştirmediği için denetim kaydına girmez; kendi kayıtlarında durur.
8. **Açılış bayraklarla yapılır:** `TEAM_INVITATIONS` ve `ACCESS_REQUESTS`. Production'da ikisi birlikte, `TEAM_DELEGATION=on` ile aynı anda açılır (Yusuf); böylece liderler hem davet eder hem talepleri onaylar, YK her ekip talebiyle uğraşmaz.

Kaynaklar:
- **Yusuf'un:** davet ve talebin şimdi yapılması (2026-11-11, karar 21); 3'teki 14 gün ve 8'deki birlikte açılış (2026-11-23 01:01).
- **Spec önerisi:** geri kalanı (hub'daki davet, talep ve gözden geçirme spec'i §2–§3, §10).

## Consequences

- **CONTEXT.md:** iki yeni terim gelir: **Invitation** ve **Access request**. **Promote** ve **Self-registration**'a kabul ve onay yolları eklenir.
- **Gizlilik metni:** davet adresi, talep gerekçesi ve süreleri faaliyet tablosuna ve "Ekibe Davet" alt başlığına yazılır. Production'da açılıştan önce yayında olur.
- **Kabul edilmeyen davet hiçbir şey bırakmaz:** üyelik yok, hesap yok, adres yok. Bedeli: kişi kabul edene kadar ekip postası almaz ve uygulama ataması devralmaz.
- **ADR-0062 saklama tablosuna satırlar eklenir:** `team_invitations_age`, `access_requests_age` ve davet adres sayacı ("aynı adrese 30 günde 3 davet" sınırı için; yalnız sha256(adres) ve gün tutulur, 30 gün sonra silinir). Hesap silme saga'sı (ADR-0051) bu iki tablodaki kişiye ait satırları siler; davet edenin hesabı silinirse açık davetleri geçersiz olur.
- **Sunucuda yetki okuma.** Kabul anında yetki denetimi, davet edenin bugünkü gruplarını Keycloak'tan okur. Gözden geçirmenin kapanışı da aynı yardımcıyı kullanır (ADR-0085).
- **Panel rozeti:** bekleyen talep sayısı panelin yetki yanıtıyla döner.

## Endüstri uygulamasıyla karşılaştırma

**Uyanlar (aynen aldıklarımız):**
- **E-postayla davet ve kişinin kabulü.** GitHub organizasyon davetlerinde de kişi kabul eder ve davet bir süre sonra (orada 7 gün) geçersiz olur.
- **Self-servis erişim talebi ve sahibin onayı.** Entra'da My Access üzerinden erişim paketi isteği ve onayı; Google Groups'ta "Ask to join group" ve yöneticinin onayı.

**Sapmalar (hepsi):**
1. **Davette hesap açılmaz.** Entra B2B'de davette kullanıcı nesnesi oluşur ve kabulden önce gruplara eklenebilir. Bizde kişi kabul edene kadar üyelik yoktur.
2. **Davet yetkisi yalnız grubu değiştirebilende.** Entra'da varsayılan olarak üyeler de misafir davet edebilir.
3. **Misafir hesap türü yok.** Davetli kendi açtığı sıradan hesapla üye olur.
4. **Erişim paketi tek bir gruptur.** Katalog yok, onay tek aşamalı.
5. **Onaylanan erişimin bitişi yok.** Entra'da paketin bitişi var; bizde yıllık gözden geçirme kapsar (ADR-0085).
6. **Süre 14 gün** (GitHub'da 7): sınav haftalarını kapsasın diye.
7. **Lisanslı ürün değil, core'da yazılır.**

## Considered Options

- **Entra B2B gibi davette hesap açmak.** Kişinin eylemi olmadan ad ve e-posta ile hesap açılırdı. Self-registration dışında ikinci, adresi doğrulanmamış bir hesap açma yolu ve gizlilik metninde ayrı bir madde gerekirdi. Hesap varlığı da sızardı.
- **Davette var olan hesabı doğrudan eklemek.** Hesap varlığını davet edene söylerdi. Doğrudan ekleme zaten aday aramasıyla yapılabiliyor.
- **Hesap açılınca daveti kendiliğinden kabul etmek.** Kişinin kendi eylemi olmadan üyelik yazılırdı; açık bir "Katıl" seçildi.
- **Talebi panelde istemek.** Paneli yetkisi olmayan herkese açmak gerekirdi.
- **Onaylanan üyeliğe dönem sonu bitişi koymak.** Sıradan üyeliğe süre konmaz (ADR-0078); yıllık gözden geçirme yeterli.
- **Daveti hemen, talebi `TEAM_DELEGATION` ile açmak** (spec önerisi). Yusuf ikisinin birlikte, devirle aynı anda açılmasını seçti.
- **7 ya da 30 günlük davet.** 7 gün sınav haftasına yetmez; 30 gün adresi gereğinden uzun tutar.

## Kaynaklar

- Microsoft Entra, B2B işbirliği ve davet: https://learn.microsoft.com/en-us/entra/external-id/what-is-b2b
- Microsoft Entra, B2B kullanıcı ekleme (davette hesap oluşur, en çok 20 gruba atanabilir): https://learn.microsoft.com/en-us/entra/external-id/add-users-administrator
- Microsoft Entra, dış işbirliği ayarları ("By default, all users … can invite external users"): https://learn.microsoft.com/en-us/entra/external-id/external-collaboration-settings-configure
- Microsoft Entra, erişim paketleri: https://learn.microsoft.com/en-us/entra/id-governance/entitlement-management-overview
- Microsoft Entra, My Access ile erişim isteği: https://learn.microsoft.com/en-us/entra/id-governance/entitlement-management-request-access
- GitHub, organizasyona davet ("Invitations expire after 7 days"): https://docs.github.com/en/organizations/managing-membership-in-your-organization/inviting-users-to-join-your-organization
- Google Groups, grup bulma ve katılma ("Ask to join group"): https://support.google.com/groups/answer/1067205
- Hub: davet, talep ve gözden geçirme spec'i §2–§3, §10, §14.
