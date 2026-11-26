---
status: accepted
---

# Misafir biletleri ve sertifikaları, e-postası doğrulanmış adres olan hesaba bağlanır; bilet misafir kalır, hiçbir şey birleştirilmez

Form yanıtı, girişsiz başvuru, "Katılımcı ekle", CSV içe aktarma ve kapıda kayıt bilet yazarken kişiyi yalnız e-postasıyla tanır. Bugün bu bilet, e-posta bir üyeninki olsa bile misafir biletidir: `owner_id` boş kalır, kişi onu "Biletlerim"de, sertifikasını "Sertifikalarım"da görmez; sonradan hesap açan ya da adresini hesabına ekleyen kişi için de bağlayan bir yol yoktur. Biletlerim ve sertifika listesi yalnız sahibe göre okur.

Karar (Yusuf, 2026-11-26: "o e-postanın misafir biletleri ve sertifikaları hesabına bağlansın", "e-posta bir hesabın e-postasıyla eşleşiyorsa doğrudan o hesaba bağlansın", "mevcut bütün misafir biletleri için bir kerelik toplu eşleştirme"; aynı gece K1–K8 önerileri onaylandı):

1. **Bağlamak sahibi yazmaktır.** Bilet `GUEST` kalır; misafirin verdiği ad, e-posta, telefon, bilet anahtarı, kodu ve QR sürümü değişmez. Yalnız `owner_id` hesaba yazılır; core'un bağladığını `owner_linked_at` ve `owner_link_source` (`write`, `sync`, `bulk`) söyler. Kapı, postalar, bilet sayfası ve sertifika adı bileti türüne göre okuduğu için aynen çalışır: bilet misafirin e-postası, adı ve koduyla bulunur, ayrıca kişiyle de. Kişi bileti Biletlerim'de görür ve kendi bileti olarak iptal edebilir; aynı etkinliğe üye olarak başvurursa "zaten kayıtlısın" alır.
2. **Yalnız doğrulanmış adres.** Eşleme ADR-0044'ün doğrulanmış adresleriyle, News alıcı sorusunun (ADR 0072 karar 3) aynı dizini ve kuralıyla yapılır: `emailVerified` birincil e-posta, YTÜ kimlik sağlayıcısına bağlı hesabın okul e-postası, damgalı (`personalEmailVerifiedAt`) kişisel e-posta. Okul ve kişisel e-posta öznitelikleri kişiye kapalıdır (`edit=[admin]`); birincil e-posta yalnız kodla değişir. Adres tam bir hesabın olmalı; o hesap Keycloak'ta etkin, hizmet hesabı değil, core'da aktif ve silme isteği olmamalı. İki hesabın adresi kimseye bağlanmaz. Doğrulanmamış adres hiç bağlanmaz; doğrulanınca bağlanır. Böylece başkasının adresini hesabına ekleyen kişi o adresin biletlerini alamaz.
3. **Kimseye hesap açılmaz.** Adresi hiçbir hesabın olmayan bilet misafir biletidir.
4. **Ne zaman.** Bilet yazılırken (hesabın o etkinlikte bileti yoksa; her hatada bağsız yazılır, bağlama yazımı asla bozmaz); kullanıcı eşitlemesinin her turunun sonunda, Keycloak'ın kayıt ve e-posta/profil olaylarının uyandırdığı turda (ADR-0071'in olayları; yeni bir olay yok); bir kerelik toplu komutla, eskiler için.
5. **Tek anahtar.** Bağlamanın tamamı veritabanındaki tek bir anahtara bağlıdır; göç kapalı açar. Toplu komut bağlar ve anahtarı açar; yayın gerekmez. Kapatmak ya da bütün bağları geri almak aynı komutladır. İlk açılış ARTLAB'dan (27 Kasım) sonradır.
6. **Birleştirme yok.** Kişinin etkinlikte zaten bileti varsa (kendi kaydı ya da başka adresiyle bağlanmış bilet), adresinin misafir bileti bağsız kalır ve kendi QR'ı, sayfası, postası, katılımları ve alan girişleriyle çalışmaya devam eder; sayılır. Bilet sistemleri kayıtları ayrı tutar (Luma, Eventbrite: her kayıt bir giriş hakkı, hesapta e-postayla görünür); birleştirme CRM'in kişi işlemidir. Birleştirmek misafire postalanmış QR'ı kapıda reddettirir.
7. **Sertifika e-postayla da bağlanır.** Sahipsiz sertifika biletinin sahibine, bileti sahipsizse adresinin hesabına (2. kural) bağlanır; iptal edilmiş olanlar dahil. Çift bilet durumunda da kişi sertifikasını görür. Doğrulama sayfası ve sertifika postası değişmez.
8. **Bağ kalır.** Adres sonradan hesaptan çıkar ya da doğrulaması düşerse bağ kendiliğinden kalkmaz: bağlandığı an adres kanıtlıydı. Geri alma yalnız komutladır.
9. **Kişisel veri.** Bağlı biletin misafir adı ve e-postası hesabın verisidir: hesap silinince, hangi adresle bağlanmış olursa olsun temizlenir; misafir kimliği saklama kuralı ona uygulanmaz. Telefon yalnız etkinlik için istendiğinden bağlı bilette de etkinlikten 90 gün sonra silinir (ADR-0062 saklama kuralı `guest_phone` v2).
10. **Denetim.** Team audit kaydına satır yazılmaz: bağlama ekibin kararı değil, sistemin kişi başına işidir. İz biletin ve sertifikanın kendi satırındadır; toplu komut ve eşitleme yalnız sayı yazar, kişi ya da adres yazmaz.

Sektörle karşılaştırma: Eventbrite ve Luma misafir kaydını aynı e-postayla açılan hesapta gösterir, kaydı birleştirmez; biz de öyle. Sapmalar: bağlamayı kişi "sahiplen" düğmesiyle değil, doğrulanmış adresle core kendiliğinden yapar; bilet misafir türünde kalır (kapıda orijinal e-postayla bulunsun diye).

Kapsam dışı: üye "Katıl" dediğinde aynı etkinlikte doğrulanmış adresinin bağsız misafir biletini bağlayıp "zaten kayıtlısın" demek (bugünkü gibi ikinci bilet yazılır); Forms'un girişli kişiyi `userId` ile göndermesi (Forms'un işi).

Uygulama: core-backend `docs/guest-account-links.md` (#489).
