---
status: accepted
---

# Yetki veren değişiklik bildirilir: rol eşlemesi yalnız ADMIN'e, yönetim grubuna üyelik ADMIN'e, o kökün üyelerine ve kişiye; YTÜ ile doğrulanmamış hesap yönetim grubuna eklenirken uyarı verilir, engellenmez

Tek bir YK üyesi kimseye haber vermeden YK'ya kişi ekleyebiliyordu; bir gruba rol eşlemesi de sessizce yapılıyordu. Değişiklik denetim kaydına giriyordu (ADR-0065 karar 9), ama kaydı ancak arayan görüyordu. Yönetim gruplarına eklenen kişinin kulübün bildiği kişi olup olmadığı da denetlenmiyordu: aynı adla açılmış başka bir hesap seçilebilirdi.

Karar (Yusuf, 2026-10-12: GY5 ve GY9; aynı gün 22:15 alıcı kuralı "UYELER'e mail gitmemeli; sektördeki gibi"; panel metni Kaan'ın, 2026-10-19):

1. **Bir gruba rol eşlenince ya da eşleme kaldırılınca** posta **yalnız ADMIN'e** gider. Grubun üyelerine gitmez. Postada rolün sınıfı (yönetici ya da uygulama rolü, ADR-0065'in 2026-10-12 eki) ve grubun alt ağacındaki üye sayısı yazar.
2. **Bir Privileged köke ya da altına kişi eklenince ya da çıkarılınca** posta üç yere gider:
   - ADMIN'e;
   - değişen grubun bağlı olduğu Privileged kökün bütün üyelerine;
   - eklenen ya da çıkarılan kişiye, kendi yönetim üyeliği postasıyla.

   Değişikliği yapan kişi bu bilgi postasını almaz.
3. **İçerik.** Kim, neyi, hangi gruba, ne zaman; paneldeki ilgili sayfanın bağlantısı. E-posta adresi yazılmaz. Her alıcı değişiklik başına tek posta alır.
4. **Varsayılan açık.** Bildirim core'da varsayılan olarak açıktır; şablon anahtarı boş bırakılırsa kapanır.
5. **Konsoldan yapılan aynı değişiklikler** de, core onları okuduğunda (ADR-0079 karar 6) aynı postayı tetikler.
6. **YTÜ'ye bağlı olmayan hesap** (CONTEXT "YTÜ-linked"; core'da `ytu_linked`) bir Privileged köke ya da altına eklenirken panel **uyarır, engellemez** (GY9). Mezun yöneticilerin YTÜ hesabı olmayabilir.
   - Grubun Privileged olup olmadığını ve kişinin doğrulanıp doğrulanmadığını panel core'un yanıtından öğrenir; panelde grup adına bakan kural yazılmaz.
   - Aday listesinde işaret yalnız doğrulanmamış kişide ve yalnız hedef Privileged iken çıkar (Kaan, 2026-10-19).
   - Onay sorusu kişinin e-posta adresini gösterir ve adresin o kişiye ait olduğunun kontrol edilmesini ister.
   - Ekleme hiçbir durumda engellenmez. Uyarının onaylanıp onaylanmadığı denetim kaydının o satırına yazılır.

Kaynaklar:
- **Yusuf'un:** 1 ve 2'nin alıcıları (GY5, 2026-10-12 22:15), 6'nın "uyar, engelleme" kuralı (GY9).
- **Kaan'ın:** 6'daki işaretin yeri ve onay metni (2026-10-19).
- **Spec önerisi:** 3, 4, 5 ve 6'daki denetim kaydı işareti (hub'daki grup yönetimi README §4 taslak D, biletler 05 ve 07).

Bu ADR core'da ve panelde 2026-10'da uygulanmış davranışı kayda geçirir.

## Consequences

- **Büyük gruplara posta gitmez.** `/UYELER` gibi bir gruba rol eşlemesi yüzlerce kişiye değil, yalnız ADMIN'e gider.
- **Akran görünürlüğü.** YK'ya eklenen kişiyi YK'nın öbür üyeleri de öğrenir; DK'ya ekleneni DK üyeleri (ADR-0077 karar 6).
- **Posta kuyruğu ayrıdır.** Bilgi postası üyelik postasının kuyruğunu kullanmaz; eski bir core sürümü bu satırları "gruba eklendin" postası olarak göndermesin diye.
- **Doğrulama kaynağı.** core'un kullanıcı kaydındaki YTÜ bağı okunur; core'da hesabı olmayan kişi doğrulanmamış sayılır.
- **CONTEXT.md'de değişen:** Privileged ve YTÜ-linked terimleri bu kuralları anar.

## Endüstri uygulamasıyla karşılaştırma

**Uyanlar:**
- **PIM bildirimleri.** PIM, rol atandığında yöneticilere (PIM for Groups'ta grubun kalıcı sahiplerine) ve atanan kişiye posta gönderir; grubun öbür üyelerine göndermez. Kural 1 ve kural 2'nin kişiye giden postası bunun karşılığıdır.
- **Google Alert Center'ın "User granted Admin privilege" kuralı.** Yönetici yetkisi verilmesi bir uyarı üretir.
- **Dış kişinin ayrı ele alınması.** Entra'da misafir ayrı bir hesap türüdür ve gözden geçirmede ayrıca onaylanır; Google'da dış üye eklemek varsayılan kapalıdır ve güvenlik grubuna dış hesap girmez; GitHub'da dış katkıcı takıma eklenemez.

**Sapmalar (hepsi):**
1. **Yönetim grubuna üyelik o kökün öbür üyelerine de bildirilir** (akran görünürlüğü, GY5). PIM yalnız yöneticilere, grup sahiplerine ve atanan kişiye bildirir.
2. **Varsayılan açık.** Google'ın kuralı varsayılan kapalıdır.
3. **Doğrulanmamış hesap engellenmez, uyarılır.** İncelenen ürünler dış kişiyi engelliyor ya da ayrı bir hesap türü olarak tutuyor. Bizde ayrı bir hesap türü yok; ayrımı "YTÜ-linked" taşır. Gerekçe: mezun yöneticilerin YTÜ hesabı olmayabilir.

## Considered Options

- **Rol eşlemesinde grubun bütün üyelerine posta.** Yusuf reddetti: "UYELER'e mail gitmemeli".
- **Yönetim grubuna üyelikte yalnız ADMIN'e posta** (PIM gibi). Yusuf akran görünürlüğünü seçti.
- **Bu kuralları ADR-0077'ye ya da ADR-0079'a katmak** (taslakta önerilmişti). Ayrı tutuldu, çapraz bağlıdır.
- **Doğrulanmamış hesabı yönetim grubuna almamak.** Mezun yöneticiler yüzünden reddedildi (GY9).

## Kaynaklar

- Microsoft Entra, PIM posta bildirimleri: https://learn.microsoft.com/en-us/entra/id-governance/privileged-identity-management/pim-email-notifications
- Microsoft Entra, PIM for Groups: https://learn.microsoft.com/en-us/entra/id-governance/privileged-identity-management/concept-pim-for-groups
- Microsoft Entra, erişim gözden geçirme: https://learn.microsoft.com/en-us/entra/id-governance/access-reviews-overview
- Microsoft Entra, dinamik üyelik ve kullanıcı türü: https://learn.microsoft.com/en-us/entra/identity/users/groups-dynamic-membership
- Google Workspace, sistem tanımlı uyarı kuralları ("User granted Admin privilege", varsayılan kapalı): https://knowledge.workspace.google.com/admin/reports/view-and-edit-system-defined-rules
- Google Workspace, kuruluş geneli grup politikaları: https://knowledge.workspace.google.com/admin/groups/set-organization-wide-policies-for-using-groups
- Google Workspace, güvenlik grupları: https://knowledge.workspace.google.com/admin/groups/control-access-to-sensitive-data-with-security-groups
- GitHub, dış katkıcı ekleme: https://docs.github.com/en/organizations/managing-user-access-to-your-organizations-repositories/managing-outside-collaborators/adding-outside-collaborators-to-repositories-in-your-organization
- Hub'daki grup yönetimi değerlendirmesi (2026-10-12) ve README §3–§4.
