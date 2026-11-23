---
status: accepted
---

# Yıllık erişim gözden geçirmesi bir dönem olarak açılır, hatırlatır ve kapanışta sonucu kendiliğinden uygular; yanıtsız kalan üyelik kalır

ADR-0078 karar 6, yıllık gözden geçirmeyi hafif hâliyle tanımlamıştı: kampanya motoru yok, tek hatırlatma postası var, işaretler dönem kapanınca silinir. Karar 6 hiç yazılmadı; karar 1–5 (yönetim üyeliklerinin bitişi) 2026-11-08'den beri production'da açık. Sıradan ekip üyeliğinin, `/ROLLER` paketlerinin ve kişiye doğrudan uygulama atamalarının bitişi yoktur; kimin hâlâ nerede olduğu yıllarca gözden geçirilmiyor. Bu ADR, ADR-0078 karar 6'nın yerine geçer; karar 1–5 değişmez.

Karar (Yusuf, 2026-11-11, karar 22: gözden geçirmenin tam hâli; 2026-11-23 01:01: yanıtsız kalan üyelik kalır, "çıksın" kararları dönem kapanınca kendiliğinden uygulanır, kapsam ekip üyelikleri, `/ROLLER`, doğrudan atamalar ve `/ADMIN`):

1. **Dönem.** Aktif Season'ın bitişinden 30 gün önce core bir gözden geçirme dönemi açar; dönem Season bitişinde kapanır (2027: 31 Mayıs – 30 Haziran, İstanbul saatiyle gün sonu). Season başına bir yıllık dönem açılır. Privileged writer ayrıca 3 ile 60 gün arası elle bir dönem açabilir ve açık dönemi erken kapatabilir. Aynı anda tek bir dönem açık olur.
2. **Kapsam ve gözden geçirenler** (Yusuf).
   - **Ekip ya da alt ekip grubuna doğrudan sıradan üyelik.** Ekibin Leader'ları gözden geçirir; yoksa en yakın üst ekibin Leader'ları, o da yoksa YK. Üyeliği değiştirebilen herkes (Team manager, ADR-0065) karar verebilir.
   - **`/ROLLER` üyelikleri ve uygulamaların kişiye doğrudan atamaları.** YK gözden geçirir; Privileged writer karar verir.
   - **`/ADMIN` üyeliği.** ADMIN'in öbür üyeleri gözden geçirir.
   - **Yönetim üyelikleri** (ADR-0078 karar 1) bu dönemde karar kalemi değildir. Bitişleri ve kendi ekranları vardır (Dönem devri); gözden geçirme ekranı sayılarını gösterir ve oraya bağlanır.
   - **Kimse kendi kalemine karar veremez.** Kalem öbür karar verebilenlere kalır.
   - DK (Privileged reader) bütün kalemleri ve ilerlemeyi okur, karar veremez (ADR-0077).
3. **Kalemler açılışta anlık liste olarak yazılır.** Dönem içinde eklenen kişi bir sonraki dönemde gözden geçirilir. Dönem içinde çıkan kişi "artık yok" diye işaretlenir. Liste yarım okunursa dönem açılmaz, ertesi gün yeniden denenir.
4. **Karar.** Her kalem için "kalsın" ya da "çıksın"; toplu seçim vardır, gerekçe metni yoktur. Karar dönem kapanana kadar değiştirilebilir.
5. **Hatırlatma ve yükseltme.** Postalar yalnız sayı taşır, kişi listesi taşımaz.
   - Açılışta, D-14'te ve D-3'te kararsız kalemi olan gözden geçirene posta gider.
   - D-7'de kararsız kalemler yedek gözden geçirene bildirilir: üst ekibin Leader'ları, en üstte YK; `/ROLLER` ve uygulama atamalarında ADMIN. `/ADMIN` kalemlerinin yedeği yoktur.
   - Kapanışta ADMIN ve YK'ya kişisiz bir özet gider: kapsam ve ekip başına kalsın, çıktı, yanıtsız ve uygulanamadı sayıları.
6. **Yanıt gelmezse kalem değişmez; üyelik kalır** (Yusuf; GY7, ADR-0078). Yanıtsızlık ekip ekip özette görünür; iki dönem üst üste yanıtsız kalan ekip ayrıca işaretlenir.
7. **Sonuç kapanışta kendiliğinden uygulanır** (Yusuf).
   - "Çıksın" kararları, kararı verenin adına ve onun o günkü yetkisiyle core'un denetimli yazıcısından uygulanır. Yetki Keycloak'tan okunur; kalmamışsa kalem uygulanmaz ve özette sayılır. Kişi bu arada yönetim üyeliğine geçtiyse kalem uygulanmaz.
   - Gözden geçiren kendi kararlarını erken de uygulayabilir.
   - Her çıkarma bir Team audit record satırı (`member.remove` ya da `app.unassign`, `via = access_review`) ve olağan üyelik postası üretir. Ayrı bir "gözden geçirme sonucu" postası yoktur.
   - Keycloak hatası ertesi gün bir kez yeniden denenir, sonra özette görünür.
8. **Saklama.** Kararlar ("kalsın" dahil) kapanıştan 30 gün sonra silinir; yanlış bir çıkarma bu sürede görülüp düzeltilir. Dönemin kişisiz özeti kalır; çıkarmaların denetim kaydı ADR-0065'teki 3 yıllık süreye bağlıdır. Hesap silinince kişinin kalemleri hemen silinir.
9. **Açılış bayrakla yapılır:** `ACCESS_REVIEWS_MODE=off|dry-run|apply`, `MANAGEMENT_TERMS_MODE` ile aynı kalıp. `dry-run` dönemi ve kalemleri açar, posta göndermez ve bir şey çıkarmaz. Production'da `apply` en geç ilk yıllık dönemin açılışından (2027-05-31) önce açılır.

Kaynaklar:
- **Yusuf'un:** tam hâlin yapılması (2026-11-11, karar 22); 2'deki kapsam, 6'daki "yanıt yoksa kalır" ve 7'deki kapanışta kendiliğinden uygulama (2026-11-23 01:01).
- **Spec önerisi:** geri kalanı (hub'daki davet, talep ve gözden geçirme spec'i §4).

## Consequences

- **ADR-0078 karar 6 bu ADR'la değişir.** "Ayrı bir kampanya motoru yazılmaz", "dönem açılınca tek hatırlatma postası" ve "işaretler kapanınca silinir" cümleleri düşer. "YK en üst ekiplerin liderlerini, ADMIN Privileged kökleri gözden geçirir" cümlesi, yönetim üyelikleri için Dönem devri ekranına yönlenir. ADR-0078'in gövdesi yeniden yazılmaz; başına bir not düşülür.
- **CONTEXT.md'de Access review tanımı yeniden yazılır.** Dönem, birincil ve yedek gözden geçiren, kapanışta uygulama ve 30 günlük saklama eklenir. "_Avoid_: a campaign engine" çıkar.
- **Aydınlatma metnine bir ek gelir:** "kalsın / çıksın" kararları ve 30 günlük süre. Production'da `apply` açılmadan önce yayında olur.
- **ADR-0062 tablosuna bir satır eklenir:** `access_review_items_age`.
- **Uygulama adımının sunucuda yetki okuması gerekir.** Kapanış işi, kararı verenin bugünkü gruplarını Keycloak'tan okuyarak yetkiyi denetler. Davet kabulü (ADR-0084) de aynı yardımcıyı kullanır.
- **Bilinçli risk:** yanıt vermeyen liderin ekibinde kimse çıkmaz. D-7 yükseltmesi ve kapanış özeti bunu görünür tutar.

## Endüstri uygulamasıyla karşılaştırma

**Uyanlar (aynen aldıklarımız):**
- **Entra access reviews:** tekrarlayan dönem, açılışta alınan anlık liste (dönem içindeki değişiklik sonraki döneme kalır), grup sahibinin gözden geçirmesi, hatırlatma, dönem sonunda bildirim, sonucun kendiliğinden uygulanması ("Auto apply results to resource") ve yanıtsızlar için "No change" seçeneği.
- **Okta Access Certification kampanyaları:** gözden geçiren, karar ve uygulama adımlarıyla aynı yapı.

**Sapmalar (hepsi):**
1. Kararı kolaylaştıran öneri (Entra'da son 30 günde giriş yoksa "çıksın" önerisi) yok.
2. **Yedek gözden geçiren yükseltmedir.** Entra'da yedek gözden geçiren yalnız grubun sahibi yoksa devreye girer; bizde birincil gözden geçiren yanıt vermezse de D-7'de yedeğe haber gider.
3. **Üç hatırlatma** (açılış, D-14, D-3). Entra tek hatırlatmayı dönemin ortasında gönderir.
4. Çok aşamalı gözden geçirme yok (Entra'da iki ya da üç aşama seçilebilir).
5. Yönetim üyelikleri bu dönemde değil, kendi bitişleri ve Dönem devri ekranıyla gözden geçirilir (ADR-0078).
6. Kararlar 30 gün sonra silinir; yalnız sayılar ve çıkarmaların denetim kaydı kalır.
7. Dönem sezona bağlıdır; ayrı bir tekrar takvimi yok. Elle dönem açılabilir.
8. Lisans yok; Entra'da access reviews Microsoft Entra ID Governance ya da Entra Suite lisansı ister, biz kulüp ölçeğinde core'da yazıyoruz.

## Considered Options

- **ADR-0078'deki hafif hâl** (tek hatırlatma, elle toplu çıkarma). Yusuf tam hâli seçti.
- **Yanıtsız kalemi çıkarmak** (Entra'da seçilebilir). Yusuf GY7'yi korudu: sıradan üyelik kimse bakmadan alınmaz.
- **Sonucu yalnız gözden geçirenin "uygula" düğmesiyle uygulamak.** Basmayı unutan liderin kararı boşa giderdi. Yusuf kapanışta kendiliğinden uygulamayı seçti; erken uygulama da serbest.
- **Kapanışta ADMIN'in tek düğmeyle uygulaması.** İşi tek kişiye yığar; kararın sahibi gözden geçirendir.
- **Yalnız ekip üyeliklerini gözden geçirmek.** `/ROLLER`, doğrudan atamalar ve `/ADMIN` hiç gözden geçirilmezdi; Yusuf geniş kapsamı seçti.
- **Yönetim üyeliklerini de kalem yapmak.** Aynı kişiye iki ekranda iki kez sorulurdu.

## Kaynaklar

- Microsoft Entra, erişim gözden geçirme: https://learn.microsoft.com/en-us/entra/id-governance/access-reviews-overview
- Microsoft Entra, erişim gözden geçirme oluşturma (anlık liste, yedek gözden geçiren, hatırlatma, "Auto apply results to resource", "If reviewers don't respond: No change", lisans): https://learn.microsoft.com/en-us/entra/id-governance/create-access-review
- Okta, Access Certification kampanyaları: https://help.okta.com/oie/en-us/content/topics/identity-governance/access-certification/campaigns.htm
- ADR-0078; hub'daki davet, talep ve gözden geçirme spec'i §4.
