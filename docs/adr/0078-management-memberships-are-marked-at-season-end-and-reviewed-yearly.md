---
status: accepted
---

# Yönetim üyelikleri dönem sonunda süresi dolmuş diye işaretlenir, kendiliğinden kalkmaz; yılda bir, dönem devrinde gözden geçirilir

YK, DK ve ekip liderliği bir dönem (Season) içindir, ama Keycloak'taki üyeliklerin bitişi yok. Eski yönetimin yetkisi, biri hatırlayıp elle alana kadar sürüyor. Kimin hâlâ hangi ekipte olduğu da yıllarca gözden geçirilmiyor. Bir sonraki dönem devri 2027 Mayıs'ının sonunda.

Karar (Yusuf, 2026-10-12: GY2 ve GY7; aynı gün 22:15 düzeltmesi "bitiş günü yalnız işaretlenir"; 2026-10-19: lider uyarısının alıcıları ve uzatma sınırı):

1. **Kapsam.** Bir Privileged köke (ADMIN hariç) ya da altındaki bir gruba doğrudan üyelik (YK, YK'nın görev grupları, DK) ve bir ekibin `LIDERLER` ya da `KOORDINATORLER` grubuna doğrudan üyelik bir **yönetim üyeliğidir**. ADMIN ağaçları ve sıradan ekip üyeliği bunun dışındadır.
2. **Bitiş dönemin sonudur.** Yeni bir yönetim üyeliğinin bitişi, aktif dönemin son günüdür (İstanbul saatiyle gün sonu). Süre ekleme anından değil, bu sabit tarihten sayılır. Aktif dönem yoksa ekleme yine yapılır, bitiş boş kalır ve bu bir uyarı olarak loglanır ve sayılır. Var olan ve konsoldan eklenen üyeliklere de aynı bitiş verilir.
3. **Bitiş yalnız işaretlenir.** Üyelik bitiş günü kendiliğinden kalkmaz; core Keycloak'a yazmaz.
   - Bitişten 14 gün ve 1 gün önce kişiye ve onun üstündekilere uyarı gider. Privileged kökte bunlar ADMIN ve o kökün üyeleridir. Leader grubunda üst ekibin Leader'ları ve YK'dır (Yusuf, 2026-10-19).
   - Bitişte üyelik panelde "süresi dolmuş" diye işaretlenir, denetim kaydına bir satır yazılır, o gün süresi dolanların listesi ADMIN'e gider.
   - Süresi dolmuş ama grupta duran üyelikler haftada bir ADMIN'e özet olarak gider (sayı ve gruplar).
   - Çıkarma elle, panelin devret/uzat ekranından yapılır.
4. **Uzatma ve devir.** Üyeliği uzatmak, devretmek ve süresi dolmuş üyeliği çıkarmak, o grubun üyeliğini değiştirebilen kişinin işidir: Privileged kökte yazabilen Privileged (DK'yı ADMIN ve YK değiştirir, ADR-0077), Leader grubunda ekibi yöneten (ADR-0065). Kimse kendi üyeliğini uzatamaz. Uzatmanın üst sınırı bir sonraki dönemin sonudur; bir sonraki dönem tanımlı değilse bugünden bir yıl (Yusuf, 2026-10-19). Her uzatma, devir ve çıkarma denetim kaydına yazılır.
5. **Süreyi core tutar.** Bitiş, uyarı ve işaret core'dadır, Keycloak Workflows'ta değil, çünkü denetim kaydı ve posta core'dadır.
6. **Yılda bir gözden geçirme** (sektördeki erişim gözden geçirmenin hafif hâli). Dönem devrinde yapılır: dönem bitişinden 30 gün önce açılır, dönem bitişinde kapanır. Ayrı bir kampanya motoru yazılmaz; dönem sezondan türer.
   - Leader kendi ekibinin üye listesini, YK en üst ekiplerin liderlerini, ADMIN Privileged kökleri gözden geçirir. Her kişi için "kalsın" ya da "çıksın" işaretlenir.
   - "Çıksın" işaretlenenler core'un denetimli yazıcısıyla toplu çıkarılır; her çıkarma ayrı bir kayıt satırı ve üyelik postası üretir.
   - **Yanıt gelmezse sıradan üyelik kalır** (GY7). Yönetim üyeliği zaten karar 3'teki işaretle görünür.
   - Dönem açılınca her Leader'a ve YK'ya tek bir hatırlatma postası gider.
   - Gözden geçirme işaretleri dönem kapanınca silinir; yalnız özet sayı kalır.

Kaynaklar:
- **Yusuf'un:** 1'in ana kuralı ve ADMIN istisnası (GY2), 3 (2026-10-12 22:15), 3'teki lider uyarısının alıcıları ve 4'teki uzatma sınırı (2026-10-19), 6'daki "yanıt yoksa kalır" (GY7).
- **Spec önerisi:** 1'in sınırları (doğrudan üyelik, görev grupları), 2, 4'ün geri kalanı, 5, 6'nın takvimi ve rolleri (hub'daki grup yönetimi değerlendirmesi ve biletleri 11–13).

## Consequences

- **ADR-0065'in "dinamik gruplar, PIM, süreli roller yok" sapması daralır.** Dinamik grup ve PIM yine yok. Yönetim üyeliğinin artık bir bitişi var, ama yalnız işaret ve bildirim üretir; erişimi kaldırmaz.
- **Süresi dolmuş bir yöneticinin yetkisi, biri ekrandan çıkarana kadar sürer.** Bu bilinçli bir risktir. ADMIN'e giden günlük liste, haftalık özet ve panel işareti onu görünür tutar.
- **Dönem devri sırası.** Yeni dönem açılıp aktif yapılmadan eklenen yönetim üyeliklerinin bitişi eski dönemin sonudur. Bu yüzden dönem devrinde önce yeni dönem açılır, sonra devir yapılır.
- **Uygulama durumu (2026-10-30).** Karar 1–5'in core uygulaması açık bir PR'dadır; karar 6 yazılmadı.
- **Açılış bayrakla.** Günlük iş core'da kapalı bir bayrağın arkasındadır; önce yalnız sayan kuru koşu, sonra uygulama açılır. Uyarı postası SkyMail'de şablonu tohumlanınca gider.
- **Kişisel veri.** Terim kaydı yalnız kimlik tutar (kişi, grup, dönem); ad ve e-posta okunurken çözülür. Denetim kaydına giren satırlar ADR-0065 karar 9'daki 3 yıllık süreye bağlıdır.
- **CONTEXT.md'de yeni terimler:** Management membership, Membership term, Season handover, Access review.

## Açık

- **Bitmiş terimlerin saklama süresi** (açık soru). Elle çıkarılmış ya da devredilmiş terim kaydı ne kadar tutulur? Öneri: denetim kaydı gibi 3 yıl. ADR-0062'nin saklama tablosuna satır olarak girer.
- *Not:* Gözden geçirmeden geriye kalan özet yalnız sayıdır, kişisel veri taşımaz.
- *Not:* Bugün alanların kendi Leader grubu yok; açılırsa bu ADR'a ek yazılır.

## Endüstri uygulamasıyla karşılaştırma

**Uyanlar:**
- **Süreli yönetim yetkisi.** Entra PIM for Groups süreli üyelik ve sahiplik verir; erişim paketlerinin süresi dolar. Google üyeliğe bitiş tarihi koyar. Okta süreli erişim isteği ve süreli yönetici rolü verir.
- **Önceden uyarı.** Google üyelik bitişinden önce haber verir.
- **Erişim gözden geçirme ve "değişiklik yok" seçeneği.** Entra access reviews ve Okta Access Certification kampanyalarının karşılığıdır; Entra'da yanıtsız kalanlar için "değişiklik yok" seçilebilir.

**Sapmalar (hepsi):**
1. **Süre dolunca erişim kalır** (Yusuf, 2026-10-12 22:15). İncelenen ürünlerin hepsi süre dolunca erişimi kendiliğinden kaldırıyor. Bizde yalnız işaretlenir ve bildirilir; çıkarma elledir.
2. **Süre sabit bir tarihten sayılır** (dönem sonu), atama anından değil.
3. **Uyarı iki kez gider:** 14 gün ve 1 gün önce. Google'da tek uyarı var, 72 saat önce.
4. **Sıradan üyeliğe süre konmaz.** Yalnız yönetim üyeliği süreli.
5. **İşi core yapar, Keycloak Workflows değil.** Keycloak 26.6'dan beri üyelik olaylarına bağlı iş akışları destekleniyor, ama kayıt ve posta core'da olduğu için seçilmedi.
6. **Gözden geçirmede kampanya motoru, öneri ve çok aşamalı onay yok.** Yılda bir yapılır ve dönem devrine bağlıdır.
7. **Lisans yok.** Entra'da süreli üyelik ve gözden geçirme ücretli yönetişim lisansı ister; biz kulüp ölçeğinde core'da yazıyoruz.

## Considered Options

- **Süre dolunca üyeliği kendiliğinden kaldırmak** (sektörün yaptığı, GY2'nin ilk hâli). Yusuf 2026-10-12 22:15'te "yalnız işaretle" diye düzeltti.
- **Keycloak Workflows ile süre sonu.** Kayıt ve posta core'da; iki yerde kural olurdu.
- **Süreyi atama anından saymak** (PIM gibi). Yönetim dönemi sabit bir tarihte bittiği için dönem sonu seçildi (GY2).
- **Sıradan ekip üyeliğine de süre koymak.** Yılda bir gözden geçirme yeterli görüldü; her yıl bütün üyeleri yeniden eklemek ağır.
- **Ayrı bir gözden geçirme kampanya motoru.** Kulüp ölçeğinde gereksiz; dönem sezondan türer.

## Kaynaklar

- Microsoft Entra, PIM for Groups: https://learn.microsoft.com/en-us/entra/id-governance/privileged-identity-management/concept-pim-for-groups
- Microsoft Entra, erişim paketleri (entitlement management): https://learn.microsoft.com/en-us/entra/id-governance/entitlement-management-overview
- Microsoft Entra, erişim gözden geçirme: https://learn.microsoft.com/en-us/entra/id-governance/access-reviews-overview
- Microsoft Entra, erişim gözden geçirme oluşturma ("If reviewers don't respond: No change"): https://learn.microsoft.com/en-us/entra/id-governance/create-access-review
- Google Cloud Identity, üyelik bitişi: https://docs.cloud.google.com/identity/docs/how-to/manage-expirations
- Okta, erişim isteği koşulları (süreli erişim): https://help.okta.com/en-us/content/topics/identity-governance/access-requests/rcar-conditions.htm
- Okta, Access Certification kampanyaları: https://help.okta.com/oie/en-us/content/topics/identity-governance/access-certification/campaigns.htm
- Okta, yönetici rolleri: https://help.okta.com/en-us/content/topics/security/governance-admin-roles/ar-admin-roles.htm
- Keycloak, sürüm notları (Workflows): https://www.keycloak.org/docs/latest/release_notes/index.html
- Hub'daki grup yönetimi değerlendirmesi (2026-10-12) ve README §3–§4.
