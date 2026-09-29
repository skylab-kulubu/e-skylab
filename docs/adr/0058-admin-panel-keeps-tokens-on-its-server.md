---
status: accepted
---

# Admin paneli token'larını kendi sunucusunda tutar; token'ı yalnız çağırdığı API'lere açıktır

Admin paneli (`admin.yildizskylab.com`, `core-frontend`) Keycloak access token'ını tarayıcı cookie'lerinde tutuyor ve tarayıcı JS'ine veriyordu; tarayıcı core, Forms ve CMS'e doğrudan `Bearer` ile gidiyordu. Token `admin` client'ının tam kapsamıyla kesildiği için 11 audience ve bütün client rollerini taşıyordu. 3,3 KB'a ulaştı, core'un 4 KiB başlık sınırını aştı (2026-09-28, core-backend#152) ve tarayıcıların cookie başına 4096 baytlık sınırına yaklaşık 0,8 KB kaldı. O sınır aşılınca tarayıcı cookie'yi sessizce düşürür, adminler giriş döngüsüne girer. Karar: admin paneli `my.` gibi bir BFF olur (ADR-0041'in admin paneline genişletilmesi) ve `admin` client'ının token'ı yalnız panelin çağırdığı API'lere açılır. Bu, RFC 10017'nin (BCP 212) kişisel veri işleyen uygulamalar için önerdiği desen ve RFC 9700'ün audience kısıtlama önerisidir (araştırma: `sky_lab_genel/notes/research-access-token-size.md`, 2026-09-28).

- **Token tarayıcıya çıkmaz.** Tarayıcıda yalnız opak bir Sign-in session tutamacı durur. Access ve refresh token'lar panelin sunucusunda şifreli tutulur; oturumlar ortak Postgres'te panelin kendi veritabanındadır (ADR-0002, `my.` ile aynı desen). Panelin core, Forms ve CMS çağrıları panelin sunucusundan geçer; sunucu yalnız bu üç API'ye ve bilinen yollara iletir. Token'ı tarayıcıya veren `/api/auth/token` kalkar. `my.`'nin auth kodu `core-frontend`'e kopyalanır.
- **Cookie RFC 10017'ye uyar:** `__Host-Http-` öneki, `HttpOnly`, `Secure`, `SameSite=Strict`, `Path=/`, `Domain` yok. Panel gizli (confidential) client'tır.
- **`admin` token'ı daralır.** Keycloak'ta `admin` client'ının "Full scope allowed" ayarı kapanır. Token'a yalnız `core` ve `forms` client rolleri eşlenir, `aud` sabit olarak `core`, `forms`, `skycms` olur, `realm_access` boşalır. Panelin kendi `content:*` rolleri ve gruplar etkilenmez. Ayar `e-skylab-keycloak` uzlaştırıcısında kodla yönetilir ve önce sandbox'taki `superadmin` client'ında uygulanır.
- **Her API'ye kendi token'ı.** BFF, oturumun token'ını Keycloak Standard Token Exchange ile core, Forms ve CMS için tek audience'lı üç token'a çevirir; her API yalnız kendisine kesilmiş token'ı görür. Bu, RFC 9700'ün ilk tercihi ve Microsoft Entra'nın API başına token modelidir. `admin` token'ındaki üç audience bu değişimin zeminidir: exchange audience ekleyemez, yalnız daraltır.
- **Geçiş serttir.** Yeni sürüm eski token cookie'lerini ilk istekte siler ve her admin bir kez yeniden giriş yapar (#68'deki gibi). Eski ve yeni yöntem birlikte çalıştırılmaz.

## Consequences

- Diğer giriş client'ları (`frontend-main`, `frontend-arge`, `skymail`, `skyforms`) aynı daraltmayı admin'den sonra tek tek, ölçülerek alır. `skyforms` Fatih'e sorulmadan değişmez. Bu uygulamalar büyük cookie'yi Auth.js ile parçaladığı için sessiz düşme riski taşımaz; onlarda kazanç güvenliktir.
- Her admin API çağrısı panelin sunucusundan geçer; bu, ek gecikme ve tek bir geçiş noktası demektir. 20 MiB'lık medya yüklemeleri route handler'dan akışla geçer, çünkü Next.js rewrite'ı gövdeyi 10 MB'ta keser. R2'ye doğrudan parça yükleme adresleri token taşımaz ve etkilenmez.
- `SameSite=Strict` yüzünden başka bir siteden (e-posta istemcisi, mesajlaşma uygulaması) tıklanan admin linki ilk istekte oturumsuz açılır ve bir kez Keycloak'a gidip döner. `*.yildizskylab.com` altından gelen linkler aynı sitedir, etkilenmez.
- Yetkinin Microsoft modeline geçmesi (client rolleri, Group overage, panelin yetki kararlarını core'dan alması) ayrı bir karardır: ADR-0059.

## Considered Options

- **Yalnız sunucu başlık sınırlarını büyütmek:** core'da yapıldı (16 KiB), ama tarayıcının cookie sınırını ve token'ın tarayıcı JS'inde durmasını çözmez.
- **Token tarayıcıda kalır, yalnız kapsam daraltılır:** Token XSS'e açık kalır. RFC 10017 BFF'yi bu desenden daha güvenli sayar.
- **Oturumu şifreli cookie'de tutmak:** RFC 10017 izin verir, ama 4 KB sınırını geri getirir.
- **Tek token, üç audience:** RFC 9700 tek API mümkün değilse küçük bir kümeye izin verir ve daha az iştir. Microsoft'un API başına token modeline birebir uymak için API başına token seçildi.
- **Lightweight access token ve introspection (ya da phantom token):** Lightweight token'da `aud` yoktur; core'un audience denetimi (ADR-0019) kırılır, üç API'de introspection ve önbellek gerekir.
- **`my.`'nin auth kodunu ortak bir pakete çıkarmak:** İki tüketici için paket bakımı fazla gelir. Üçüncü bir BFF geldiğinde yeniden düşünülür.
