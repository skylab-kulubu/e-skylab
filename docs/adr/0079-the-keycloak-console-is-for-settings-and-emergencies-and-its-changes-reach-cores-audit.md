---
status: accepted
---

# Keycloak konsolu ayarlar ve acil durum içindir; üyelik ve rol eşlemesi panelden yapılır; acil erişim yazılıdır ve yılda bir denenir; konsol değişiklikleri core'un denetim kaydına girer

ADR-0006 Keycloak konsolunun yalnız kimlik sağlayıcı, client ve token ayarları için olduğunu yazdı, ama bunu uygulayan bir şey yoktu. Konsolda yapılan bir üyelik ya da rol eşlemesi değişikliği core'un kurallarını (korunan grup, ayrılmış adlar, ADR-0065) bilmeden yapılıyor, core'un 3 yıllık denetim kaydına girmiyor ve kimseye haber gitmiyor. Keycloak'ın kendi admin olayları 30 gün tutuluyor. Keycloak'a acil girişin nasıl yapılacağı, kimin haberdar olacağı ve en son ne zaman denendiği de yazılı değildi.

Karar (Yusuf, 2026-10-12: GY3, GY4 ve GY8; aynı gece S2 ve S3; konsol listesi 2026-10-13):

1. **Konsol ne içindir.** Keycloak konsolu kimlik sağlayıcı, client ve token ayarları ile acil durum içindir. Üyelik, grup açma, silme ve adlandırma ve grup rol eşlemesi yalnız panelden, core üzerinden yapılır.
2. **Kim yazar.** Konsoldan yalnız master'daki konsol yazıcı grubunun üyeleri, kendi ayrı hesaplarıyla yazar (ADR-0076 karar 9). Bugün altı kişidir. GY4'teki "yalnız iki ADMIN" sayısı S2 ile değişti.
3. **Acil durum nedir.** Panel ya da core çalışmıyor ve bekleyemeyecek bir üyelik ya da rol değişikliği gerekiyor (ör. ele geçirilmiş bir hesabın yetkisini almak); ya da Keycloak'ın kendisi bozuk ya da konsol hesaplarıyla girilemiyor. Sıradan iş acil değildir: panel beklenir.
4. **Acil hesaplar (S3).** master'da kişiye bağlı olmayan iki hesap, master `admin` rolüyle. İkisi de passkey'le korunur. Parola ve passkey'i taşıyan anahtar mühürlü zarfta saklanır; parolanın bir kopyası sır deposundadır (ADR-0049). Sır deposuna insan girişi Keycloak'a bağlı olduğu için asıl yedek zarftır. Değer elle kopyalanmaz.
   - Acil hesabın her girişi ADMIN'e posta olarak gider.
   - Kullanıldığı gün ne yapıldığı ekibe yazılır. İş bitince parola değiştirilir, yeni zarf hazırlanır, açılan zarf imha edilir.
   - **Yılda bir deneme.** Dönem devri haftasında her acil hesapla bir kez girilir, salt okur bakılır, çıkılır; ADMIN'e postanın geldiği doğrulanır. Tarih kulübün iç runbook'una yazılır.
5. **Sunucudan kurtarma.** Keycloak'a hiçbir hesapla girilemiyorsa sunucu yöneticisi Keycloak'ın yönetici kurtarma komutuyla (`kc.sh bootstrap-admin`) geçici bir yönetici açar; iş bitince siler ve master'da geçici yönetici kalmadığını doğrular. Sunucuya ikinci bir kişi eklenmez (GY8); bu bilinçli bir sapmadır.
6. **Konsol değişiklikleri core'un denetim kaydına girer** (GY3/GY4'ün "sonra" kısmı).
   - core, e-skylab realm'inin admin olaylarını birkaç dakikada bir okur: grup, grup üyeliği, client rolü eşlemesi ve realm rolü eşlemesi. Bunun için core'un service account'u olay okuma rolünü alır; realm'de admin olayları açık tutulur.
   - core'un kendi service account'unun olayları atlanır; onlar zaten kayıtta.
   - Konsoldan gelen değişiklik, olaydaki kimlik doğrulamanın master realm'den gelmesiyle ayrılır.
   - Her olay core'un denetim kaydına konsol kaynağıyla yazılır. Aktör konsoldaki kişinin Keycloak kimliği ve realm'idir. Yalnız kimlikler ve yol yazılır; ad, e-posta ve IP yazılmaz.
   - Üyelik olayları kişiye panelden yapılmış gibi üyelik postası gönderir. Privileged köke üyelik ve rol eşlemesi olayları ADR-0080'deki bildirimi tetikler.
   - Konsoldan yapılan değişiklik geri alınmaz; yalnız kaydedilir ve bildirilir. Ad kurallarına uymayan bir grup açılmışsa uyarı loglanır ve sayılır.
   - Keycloak'ın admin olay saklama süresi 30 gün kalır; kalıcı kayıt core'dadır.
7. **Okumanın yerine gelene kadar.** Konsoldan yapılan her üyelik ya da grup değişikliği aynı gün ekibe yazılır.

Kaynaklar:
- **Yusuf'un:** 1 ve 6'nın ilkesi (GY3, GY4: "konsoldan yalnız acil durumda; üyelik ve grup işleri yalnız panelden; sonra core konsol olaylarını okur"), 2'deki yazıcı sayısı (S2, 2026-10-13 listesi), 5'teki "sunucuda ikinci kişi yok" (GY8).
- **Spec önerisi, Yusuf'un yetkisiyle kabul (2026-10-12):** 3, 4 (S3), 5'in yolu, 6'nın ayrıntıları, 7.

## Consequences

- **ADR-0006 sıkılaşır.** "Keycloak's own console is only for IdP and OAuth2/client/token setup" cümlesi bir politika, bir acil durum istisnası ve bir tespitle uygulanır. Önleme teknik değildir: konsol kurallarımızı bilmez; politika ve core'un kaydı bu boşluğu kapatır.
- **ADR-0065'in "değişiklikleri Keycloak olaylarından izlemek" seçeneği** ekip yönetimi için reddedilmişti (aktör hep core görünür, süre 30 gün). Burada yalnız konsoldan gelen değişiklikler için kullanılır; core'un kendi yazmaları yine kendi kaydından gelir.
- **Tespit gecikmelidir.** Konsoldaki bir değişiklik birkaç dakika sonra kayda ve postaya girer. Bu süre içinde core'un ekip yönetimi kararları güncel Keycloak üyeliğini okur, yani değişiklik hemen etkilidir.
- **Acil hesap girişi postası** master'ın giriş olaylarından okunur; bu yüzden master realm'de giriş olayları açıktır.
- **Haftalık ölçüm.** Konsol yazıcı sayısı, master `admin` taşıyan insan sayısı ve e-skylab'da yönetim rolü taşıyan insan ve grup sayısı düzenli ölçülür; kişiler adıyla değil sayıyla raporlanır.
- **Sunucuda tek kişi.** Keycloak'ın kendisi bozulursa onarım sunucu yöneticisini bekler. Panel ve konsol üzerinden yapılabilen işleri konsol yazıcıları yürütür.
- Sunucu, kullanıcı adları ve kimlik bilgisinin yeri kulübün iç runbook'undadır; bu public depoya yazılmaz.
- **CONTEXT.md'de yeni terim:** Console change.

## Açık

- **Konsol hesabı modeli ile bu politikanın tek ADR olup olmayacağı.** ADR-0076 karar 9 ile bu ADR'ın birleşmesi Yusuf'un kararıdır.
- **Konsol olaylarının denetim kaydındaki satır biçimi.** Konsoldan gelen kişiye doğrudan rol olayları ve grupsuz satırların şeması, ekip yetki devrindeki ekstra rol kaydı kararıyla birlikte verilir.

## Endüstri uygulamasıyla karşılaştırma

**Uyanlar:**
- **Acil erişim hesapları** (Entra): en az iki, kişiye bağlı değil, oltalamaya dayanıklı kimlik doğrulama, her girişte uyarı, yazılı bir yol ve düzenli deneme.
- **Denetim kaydı her değişikliği tutar** (Entra'nın denetim kaydı dizindeki her değişikliği tutar). Bizde konsol değişiklikleri de core'un kaydına girer.
- **Ayrı yönetici hesabı** ve **birden çok süper yönetici** (Google, GitHub'ın "en az iki sahip" önerisi): konsolda birden çok yazıcı ve iki acil hesap.

**Sapmalar (hepsi):**
1. **Dizinin kurallarımızı bilmeyen bir konsolu var.** Entra'da kurallar ve kayıt dizinin kendisindedir. Bizde kurallar core'da, dizin Keycloak'ta. Bunu teknik olarak değil, politika ve tespitle kapatıyoruz.
2. **Tespit gecikmelidir:** birkaç dakikada bir okunur.
3. **Deneme yılda bir yapılır.** Entra 90 günde bir önerir; bizde dönem devriyle birlikte.
4. **Sunucuda tek kişi var** (GY8). Entra ve GitHub sürekliliği en az iki kişiyle sağlar.
5. **Konsol yazıcısı sayısı** Microsoft'un "beşten az Global Administrator" önerisini aşar (ADR-0076, sapma 6).

## Considered Options

- **Konsoldan yazmayı teknik olarak kapatmak** (yalnız okuma). Keycloak'ın kendi ayarları (kimlik sağlayıcı, client, token) yine konsoldan yapılıyor; acil durumda panel çalışmıyor olabilir.
- **Konsoldan yapılan değişikliği core'un geri alması.** Acil durumda yapılmış doğru bir değişikliği bozardı; kaydetmek ve bildirmek yeterli görüldü.
- **Keycloak'ın admin olay saklamasını uzatmak, core'a almamak.** Aktör, ad kuralı ve posta kuralları core'da; iki ayrı kayıt olurdu.
- **Sunucuya ikinci bir kişi eklemek.** Yusuf şimdilik istemedi (GY8).

## Kaynaklar

- Microsoft Entra, acil erişim hesapları: https://learn.microsoft.com/en-us/entra/identity/role-based-access-control/security-emergency-access
- Microsoft Entra, rol en iyi uygulamaları: https://learn.microsoft.com/en-us/entra/identity/role-based-access-control/best-practices
- Microsoft Entra, denetim kayıtları: https://learn.microsoft.com/en-us/entra/identity/monitoring-health/concept-audit-logs
- Google Workspace, yönetici hesapları için güvenlik önerileri: https://knowledge.workspace.google.com/admin/users/security-best-practices-for-administrator-accounts
- GitHub, kuruluş sahipliğinin sürekliliği: https://docs.github.com/en/organizations/managing-peoples-access-to-your-organization-with-roles/maintaining-ownership-continuity-for-your-organization
- Keycloak, yönetici kurtarma: https://www.keycloak.org/server/bootstrap-admin-recovery
- Keycloak, Admin REST API (admin olayları): https://www.keycloak.org/docs-api/latest/rest-api/index.html
- Hub'daki grup yönetimi değerlendirmesi (2026-10-12), README §3–§4 ve rol temizliği spec'i §4.4.
