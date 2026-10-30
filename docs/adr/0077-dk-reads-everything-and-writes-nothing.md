---
status: accepted
---

# DK okur, yazmaz: Privileged kalır ama yalnız okuma kararlarında; okuma `global:read` ve `audit:read` rolleriyle gelir, DK'da hiçbir uygulamanın yazma rolü olmaz

DK kulübün denetleme kuruludur. Bugüne kadar üç Privileged kök (ADMIN, YK, DK) eşitti: DK, ADMIN ve YK'nın yapabildiği her şeyi yapabiliyordu, core'un yönetim rollerinin hepsini taşıyordu. Buna karşılık ekip ve grup değişikliklerinin denetim kaydını (ADR-0065 karar 9) okuyamıyordu, çünkü `audit:read` yalnız ADMIN ve YK'daydı.

Karar (Yusuf, 2026-10-12, GY1: "tam yetkiye sahip, YK'dan üstün denetleyici kurul, ama yazma yok"; aynı gün 22:15 ekleri; 2026-10-13 ve 2026-10-14 ayrıntıları):

1. **DK her şeyi okur, hiçbir şeyi değiştirmez.** Panelde gördüğü her şeyi ve denetim kaydını okur. Microsoft Entra'daki karşılığı Global Reader ile Reports Reader'ın toplamıdır.
2. **DK kökleri Privileged kalır, ama okuyucu köktür.** Korunan grup, yönetim üyeliği postası ve ayrılmış ad kuralları DK için değişmez. Değişen yalnız karardır: Privileged kısayolu DK üyelerine yalnız okuma eylemlerinde izin verir. Yazma eylemlerinde, token hangi rolleri taşırsa taşısın, izin vermez. Kişinin kendine ait olanlar kalır: kendi kısa linkleri, kendi profili ve lideri olduğu ekip. ADMIN kökü okuyucu kök olamaz; bütün kökler de okuyucu olamaz.
3. **İki okuma rolü.**
   - `global:read` (core client rolü, Global Reader'ın karşılığı): yalnız okuyan her Privileged denetimini karşılar, hiçbir yazmayı açmaz, denetim kaydını açmaz. Yalnız DK'ya eşlenir. ADR-0059'daki yalnız rol kipinde DK'nın okuması yalnız bu rolden gelir.
   - `audit:read` (denetim kaydını okuma, Reports Reader'ın karşılığı): ADMIN, YK ve DK'ya eşlenir.
4. **Bazı okumalar yazma sayılır.** Bir okuma yazma da yapıyorsa (ör. başvuranları bir posta listesine aktarmak) yazma kararı ister. Kişisel verisi hakkında kulübe başvuranların kaydına YK cevap verir; DK bu kaydı okumaz.
5. **DK'da hiçbir uygulamanın yazma rolü olmaz.**
   - core'un yönetim rolleri DK'dan bir kez kaldırılır. Kişinin kendi kısa linklerini yöneten `url:access` kalır, çünkü uygulama rolüdür.
   - Site client'larında DK'ya `cms:access` yerine `content:read` verilir. `client:admin` DK'da yoktur (ADR-0056).
   - SkyMail'de sistem postalarını okuma kalır. Duyuru gönderme yetkisi DK'ya verilmez.
   - **Forms:** DK Forms'taki bütün formları, cevapları ve iş akışlarını okur, hiçbirini değiştiremez (Yusuf, 2026-10-12 22:15). Bunun için `forms` client'ında salt okur bir rol (`skyforms:read-all`) DK köklerine eşlenir. Bu rolle hiçbir yazma ucu açılmaz. Rolün Forms'taki karşılığını Forms'un sahibi yazar. DK'daki form geneli yönetici rolü (`skyforms:*`), salt okur rol Forms'ta canlıya çıkınca kalkar.
   - `skyforms:read-all` yönetici rolüdür: kulüp geneli kişisel veri okur (ADR-0065'in 2026-10-12 eki).
6. **DK üyeliğini ADMIN ve YK değiştirir** (Yusuf, 2026-10-12 22:15; "yalnız ADMIN" önerisi kabul edilmedi). DK üyeleri DK'yı ya da başka bir grubu değiştiremez. Her değişiklik ADMIN'e ve DK üyelerine posta olarak gider (ADR-0080 kural 2) ve denetim kaydına yazılır.
7. **DK üyesi aynı zamanda bir ekibin lideriyse** o ekipteki Leader kararları kalır; DK olarak hiçbir ekibi yönetmez. Aynı anda YK'da da olan kişi YK üzerinden yazar.

Kaynaklar:
- **Yusuf'un:** 1 (GY1), 5'teki Forms okuması ve 6 (2026-10-12 22:15), tam kişi kartının (telefon dahil) okunması (2026-10-13), `url:access`'in DK'da kalması ve `skyforms:read-all`'un hemen eşlenmesi (2026-10-14).
- **Spec önerisi:** 2, 3 ve 7 (hub'daki grup yönetimi README §4 taslak A ve bilet 08).
- **core'un uygulaması, incelemede eklendi:** 4.

Bu ADR core'da ve Keycloak'ta 2026-10'da uygulanmış davranışı kayda geçirir. DK'dan form geneli yönetici rolünün kaldırılması Forms'un salt okur rolü canlıya çıkınca yapılır.

## Consequences

- **ADR-0059 değişir.** "Roller başlangıçta ADMIN, YK ve DK'ya verilir" cümlesi yazma rolleri için "ADMIN ve YK'ya" olur. DK'ya yalnız okuma rolleri verilir.
- **ADR-0065 karar 9 değişir.** `audit:read` ADMIN ve YK'ya ek olarak DK'ya da verilir.
- **Korunan grup değişmez.** DK kökü yönetici rolü (`global:read`, `audit:read`, `skyforms:read-all`) taşıdığı için korunan gruptur; üyeliğini yalnız yazabilen Privileged (ADMIN ve YK) değiştirir.
- **Yetenek yanıtı.** core'un "yeteneklerim" yanıtı DK üyesine her yazma yeteneğini `false`, her okuma yeteneğini `true` döner. Panel yazma düğmelerini buradan gizler (ADR-0059).
- **Geri dönüş.** Okuyucu kök listesi core'da bir ortam ayarıdır; boş bırakılırsa DK yeniden yazar. Keycloak'tan kaldırılan roller yedekten geri verilebilir.
- **Komşu kararlar.** Ekip yetki devri spec'indeki "DK denetim kaydını görmez" ve duyuru spec'indeki "duyuru gönderme YK, DK ve ADMIN'de" kararları bununla değişti.
- **CONTEXT.md'de değişenler:**
  - Yeni terim: Privileged reader.
  - Privileged: DK kökleri okuyucu köktür.
  - Team audit record: `audit:read` DK'da da var.

## Endüstri uygulamasıyla karşılaştırma

**Uyanlar:**
- **Global Reader.** "Global Administrator'ın okuyabildiği her şeyi okur, hiçbir şeyi değiştirmez": `global:read`.
- **Reports Reader.** Denetim ve giriş raporlarını okumak ayrı bir roldür: `audit:read`.
- **Okuyucu rol de yönetici rolüdür.** Entra'da Global Reader bir dizin rolüdür ve role-assignable gruba verilir; bizde taşıyan grup korunan gruptur.

**Sapmalar (hepsi):**
1. **DK üyeliğini YK de değiştirir.** Entra'da Global Reader'ı yalnız Privileged Role Administrator ya da Global Administrator atar; denetlenen bir yönetim organı denetçisini seçmez. Bizde denetlenen kurul (YK) denetçinin (DK) üyeliğini değiştirebilir. Her değişiklik ADMIN'e ve DK üyelerine posta olarak gider ve denetim kaydına yazılır.
2. **DK bir yönetim organıdır** ("YK'dan üstün"). Entra'da okuyucunun kimsenin üstünde bir konumu yoktur. core yalnız neyi okuyup neyi değiştirebileceğine karar verir.
3. **Ayrı hesap ya da kişi başına atama yok.** DK'nın salt okur konumu grup kökünden ve o köke eşlenen rolden gelir.
4. **Forms'un tamamını okur.** Global Reader'ın kapsamı gibi; ama kararı Forms verir, core vermez.

## Considered Options

- **DK'yı Privileged'dan çıkarıp yalnız rollerle okuma vermek.** DK'nın grubu korunan grup olmaktan çıkardı ve yönetim üyeliği postası gitmezdi.
- **DK üyeliğini yalnız ADMIN'in değiştirmesi** (spec önerisi, Entra'ya yakın). Yusuf reddetti; değişiklik posta ve kayıtla görünür.
- **DK'ya yalnız `audit:read` vermek, yazma rollerini bırakmak.** GY1 "yazma yok" diyor.
- **Okumayı her uygulamada ayrı rollerle vermek, ortak `global:read` olmadan.** Yalnız rol kipinde her okuma denetimi ayrı ayrı eşlenirdi; Global Reader'ın tek rol karşılığı daha yalın.

## Kaynaklar

- Microsoft Entra, yerleşik roller (Global Reader, Reports Reader): https://learn.microsoft.com/en-us/entra/identity/role-based-access-control/permissions-reference
- Microsoft Entra, rol atanabilir gruplar: https://learn.microsoft.com/en-us/entra/identity/role-based-access-control/groups-concept
- Hub'daki grup yönetimi değerlendirmesi (2026-10-12) ve README §3–§4.
