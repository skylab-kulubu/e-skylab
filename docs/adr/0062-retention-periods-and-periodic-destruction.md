---
status: accepted
---

# Saklama süreleri ve periyodik imha

Gizlilik denetimi (2026-10-03) süresiz kalan kişisel veri buldu: konuk biletleri (telefon dahil), SkyMail alıcı satırları ve gövdeleri, sistem postalarındaki sıfırlama bağlantıları, form yanıtları, Place ve Guessr'daki IP'ler. Core `PERIODIC_DESTRUCTION_INTERVAL` (90 gün) değerini açılışta okuyor, ama onu kullanan bir iş yok. KVKK md. 4/2-(d) saklamayı işlendiği amaç için gereken süreyle sınırlıyor. Silme Yönetmeliği md. 11 de süresi dolan verinin periyodik imhada yok edilmesini istiyor.

Karar (Yusuf, 2026-10-03): her veri kategorisi **hukuken savunulabilecek en uzun süre** tutulur. "Süresiz" ancak iki durumda yazılır: amaç sürüyorsa (hesap açık, rıza geri alınmamış, sertifika doğrulanıyor, sonuç yayında) ya da veri anonimse. Bu kapsama yeni amaçlar eklenir: gelecek etkinliklere davet, topluluk ve mezun ilişkileri, etkinlik geçmişi ve arşivi, sertifika doğrulama. Tasarım, kod kanıtları ve hukuki gerekçe: `sky_lab_genel/.scratch/data-lifecycle/saklama-sureleri-onerisi.md`.

- **Süre amaçtan gelir.** Her kişisel veri kategorisinin bir amacı, KVKK md. 5'ten bir dayanağı ve bir Retention period'u vardır. Amaç bitince veri silinir ya da anonimleşir. Deletion lifecycle (ADR-0042) değişmedi: kayıt kalır, kişi gider; arşivlemek saati durdurmaz.
- **Süreler.** "Etkinlik + N", etkinliğin bitiminden itibaren sayılır. Core'da bu `events.end_date`, yoksa son `event_days.end_date`, yoksa `events.start_date`'tir. Çapası olmayan satıra dokunulmaz, tutanakta sayılır. Place, Guessr ve Ekstremspor'da `EVENT_ENDED_AT` kullanılır.

  | Veri | Süre | Dayanak |
  |---|---|---|
  | Üye hesabı ve profili | kişi silene kadar. 2 yıl giriş yapmayana bir hatırlatma gider, hesap kendiliğinden silinmez | sözleşme; mezunda meşru menfaat |
  | Üye ve mezun duyuruları | hesap ve tercih sürdükçe; her postada çıkış bağlantısı | meşru menfaat |
  | Konuğun adı ve e-postası, Davet onayı varsa | rıza geri alınana kadar. 3 yıl hiçbir etkinliğe gelmeyene bir yenileme sorusu gider; 60 gün yanıt gelmezse rıza biter | açık rıza |
  | Konuğun adı ve e-postası, rıza yoksa (sertifikadaki e-posta dahil) | kişinin en son etkinliği + 2 yıl; bekleyen sertifika işi olan bilete dokunulmaz | sözleşme, meşru menfaat |
  | Konuğun telefonu | etkinlik + 90 gün, rıza olsa da | sözleşme |
  | Yoklama ve yarışma geçmişi | üyede hesapla birlikte; konukta konuk kimliği boşalınca anonimleşir, sonra süresiz | sözleşme, meşru menfaat |
  | Club archive: yayımlanmış kazananlar, konuşmacılar, etkinlik fotoğrafları; sertifikalar (ad, etkinlik, seri) | süresiz; istek üzerine kaldırılır | meşru menfaat (doğrulama dahil) |
  | Kısa bağlantı tıklaması | IP, user-agent ve `user_id` 1 yılda boşalır, referer alan adına iner. Kişisiz satır süresiz kalır | meşru menfaat |
  | Özel dosya erişim kaydı | açılış IP'si 1 yıl; kaydın geri kalanı (kim, hangi dosya, ne zaman) 3 yıl | meşru menfaat |
  | Keycloak kullanıcı ve admin olayları | 30 gün | meşru menfaat, md. 12 |
  | SkyMail: alıcısı olmayan duyuru (şablon sürümü, değişkenler, gönderen, sayılar) | süresiz | meşru menfaat |
  | SkyMail: alıcı başına gövdesiz durum kaydı | üyede hesapla birlikte; konukta konuk süresince | sözleşme, meşru menfaat |
  | SkyMail: kişiselleştirilmiş gövde ve HTML | 1 yıl | meşru menfaat |
  | SkyMail: sistem postası değişkenleri (sıfırlama ve doğrulama bağlantıları) | 30 gün | — |
  | SkyMail: arşivlenmiş elle listenin alıcıları | arşivden 1 yıl sonra | — |
  | Place ve Guessr: hesap, okul e-postası | Davet onayı varsa rıza sürdükçe; yoksa etkinlik + 1 yıl | sözleşme; açık rıza |
  | Place ve Guessr: yasaklı hesap (IP değil) | etkinlik + 2 yıl | meşru menfaat |
  | Place ve Guessr: IP'ler, giriş ve Turnstile belirteçleri | etkinlik + 90 gün | meşru menfaat |
  | Son tuval, isimsiz skorlar, adını göstermeyi seçenin lider tablosu adı | süresiz | anonim; açık rıza (`show_name`) |
  | Davet onayı kaydı | rıza sürdükçe; geri alındıktan ya da bittikten sonra 3 yıl | ispat |
  | Hesap silme kanıtı, imha tutanağı (kişisiz) | en az 3 yıl, hiçbir kod yolu silmez | Yönetmelik md. 7(3) |
  | Ham konteyner günlükleri | en çok 90 gün | — |
  | Yedekler | R2 31 gün, yerel 90 gün (değişmedi; "yıllık arşiv yedeği" yok) | ADR-0053 |

- **Davet onayı (Contact consent).** Üye olmayan birine (konuk, oyuncu, reddedilen başvuran) gelecek etkinlik daveti yalnız açık rızayla gider. Konuk böyle bir postayı beklemez, meşru menfaat bunu taşımaz (Kurul 2018/119). Core'da tek bir rıza kaydı tutulur: `contact_consents` (normalize e-posta, amaç, kanal, metin sürümü, kaynak, veriliş, geri alma, bitiş nedeni, son etkinlik). Core guest apply, Forms, Place ve Guessr bu kayda yazar. SkyMail davet listesini yalnız buradan okur.
  - Kutu işaretsiz gelir, aydınlatmadan ayrı durur, hizmet şartı yapılmaz. Kutuyu işaretlemeyen de kaydolur, oynar, başvurur.
  - Görevli başkası adına kutuyu işaretleyemez; kişiye bir onay bağlantısı gönderir.
  - Her davet postasında imzalı bir "davet almak istemiyorum" bağlantısı ve `List-Unsubscribe` başlığı olur. Geri alma tekrar edilebilir: ikinci tıklama da aynı sonucu verir. Adres yolda değil gövdede taşınır.
  - Geri alınınca konuğun verisi rızasız süreye döner. Süre en son etkinlikten işler.
  - Rıza geriye dönük işlemez. Bugünkü konuklara rıza sormak için posta atılmaz; davet listesi sıfırdan başlar.
  - Account erasure (ADR-0051) kişinin rıza kayıtlarını da siler. Bastırma listesi yine yok (ADR-0051 karar 4).
  - Davet postasına sponsor ya da ticari içerik konmaz; sponsorlar yalnız etkinlik sayfasında görünür. Konursa ileti ticari sayılabilir; o zaman 6563 onayı ve İYS kaydı gerekir.
- **Periodic destruction run.** Her servis kendi verisini kendi işiyle siler (ADR-0051'deki ilke): core, SkyMail, Place, Guessr ve Forms. Core başka bir servisin veritabanına yazmaz. İş her gün koşar ve süresi dolanı o gün işler. Politikadaki "en geç" süre, kural süresine bir gün eklenerek bulunur. 90 günlük `PERIODIC_DESTRUCTION_INTERVAL`, kayıt ve alarm birimidir: her dönemin sonunda bir imha tutanağı çıkar, dönem içinde başarılı koşu yoksa alarm gelir. Zamanlama süreç ömrüne değil, veritabanındaki son başarılı koşuya bakar. Kip `off | dry-run | apply`'dır ve her servis önce dry-run ile açılır. Dry-run ile apply aynı kural tanımından üretilir. İş partilerle çalışır, aynı anda tek kopya koşar (advisory lock) ve büyük değişimde durur. Her koşu kişisiz bir makbuz yazar: kural, zaman, satır sayısı. Bir yedek geri yüklenirse iş hemen bir kez apply kipinde koşar.
- **Forms Fatih'indir.** Önerimiz amaca göre süre. Kabul edilen ekip başvurusu üyelik ve mezuniyet boyunca kalır. Reddedilen başvuru, işaretsiz bir "gelecek alımlarda değerlendirilsin" kutusu işaretlenmişse rıza geri alınana kadar, işaretlenmemişse kapanış + 1 yıl kalır. Etkinlik başvurusu konuk kuralına uyar. Anket analizden sonra anonimleşir. Bunun için Forms'a `ClosedAt` ve amaç alanları gerekir. Form sahibi daha kısa bir süre seçebilir. Davet kutusu core'un rıza kaydına yazar. Uygulama Fatih'in kararıdır.
- **Ekstremspor'un veri sorumlusu Ekstrem Sporlar Kulübü'dür.** Onların metni ne diyorsa o uygulanır; biz yalnız altyapıyı işletiriz.

## Consequences

- ADR-0037'deki "default retention 90 days" değişir. Tıklama satırı silinmez; 1 yılda kişisel alanları boşalır. Bugünkü saatlik 90 günlük silme kalkar. Liste ve form istatistiği pencereleri ayrı bir sabite ayrılır.
- Özel dosya erişim kaydının süresi 1 yıldan 3 yıla uzar; IP yine 1 yılda boşalır.
- Yeni yüzeyler gelir:
  - core: `contact_consents`, `POST /v1/consents`, imzalı geri alma sayfası ve ucu, SkyMail için davet listesi okuma ucu, guest apply gövdesinde `consents`, `retention_runs`;
  - Hesap Merkezi'nde "iletişim tercihleri";
  - SkyMail'de çıkış bağlantısı ve kendi imha işi;
  - Place ve Guessr'da `EVENT_ENDED_AT` ve kendi işleri;
  - Forms'ta `ClosedAt` ve amaç alanı (Fatih).
- Metinler değişir: KVKK Aydınlatma Metni yenilenir (yeni amaçlar, amaç başına dayanak, süre özeti). Gizlilik Politikası'nın saklama tablosu yenilenir. Davet için ayrı bir Açık Rıza Metni yazılır. Guessr'ın "oynarsan KVKK'yı kabul etmiş olursun" ifadesi ile Place'in zorunlu "okudum, onaylıyorum" kutusu kalkar. Yarışma kaydına ve etkinlik mekânına arşiv aydınlatması gelir. Taslaklar `sky_lab_genel/notes/hukuki/` altında; yayından önce avukat ya da YTÜ hukuk birimi okur.
- "Süresiz" satırların hepsi bir amaca bağlı. Amaç biterse (hesap silinir, rıza geri alınır, kişi kaldırılmayı ister) süre de biter. "Her ihtimale karşı saklama" yoktur.
- Açık sorular avukata ve YTÜ'ye gider: 5651 yer sağlayıcılığı, 6563'ün ticari ileti tanımı, arşiv için md. 28/1-c, rızasız 2 yıl, mezun duyurusu, 10 kişi anonimlik eşiği, veri sorumlusunun kim olduğu. Yanıtlar süreleri kısaltabilir. Uzatmaları ise ancak yeni bir karar yapabilir.
- Standartlarla karşılaştırma:
  - IP'yi 1 yıl tutmak CNIL'in güvenlik günlüğü tavsiyesinin (6 ay–1 yıl) üst ucu. Erişim kaydının 3 yılı da CNIL'in iç denetim üst sınırı.
  - Keycloak olaylarının 30 günü Microsoft Entra oturum açma günlükleriyle eşleşir.
  - **Sapma:** GA4 IP saklamaz; biz kötüye kullanım incelemesi için 1 yıl saklıyoruz.
  - **Sapma:** Postmark gövdeyi varsayılan 45 gün tutar; biz şikâyet incelemesi için 1 yıl tutuyoruz.
  - Microsoft ve Google Forms yanıtları sahibi silene kadar tutar. Forms önerimiz amaca göre süreyle bunlardan sıkıdır; "üyelik boyunca" kısmında onlara yaklaşır.

## Considered Options

- **En kısa makul süreler** (aynı günkü ilk öneri: konuk 1 yıl, telefon 30 gün, alıcı satırı 90 gün, yanıt kapanış + 1 yıl): Yusuf azami savunulabilir süreyi seçti. İlk öneri belgede kayıt için duruyor.
- **Konuğa daveti meşru menfaatle göndermek:** konuk bu postayı beklemez. Kurul tanıtım iletisi için açık rıza ya da md. 5/2'deki başka bir şartı arıyor.
- **Her uygulama kendi rızasını tutar, SkyMail'e elle liste aktarılır:** daha az iş, ama geri alma bir yerde unutulur ve ispat dağınık kalır.
- **Konuk verisini TBK md. 146'daki 10 yıllık zamanaşımı boyunca tutmak:** ücretsiz etkinlikte bu "her ihtimale karşı saklama" olur. 2 yılın arkasında somut amaçlar var: sertifikayı yeniden gönderme, katılım belgesi, tekrar başvuruyu tanıma.
- **Hareketsiz hesabı 2 yıl sonra silmek:** üyelik ve mezun ilişkisi bunu gerektirmiyor. Hatırlatma ve kişinin kendi silmesi yetiyor.
- **Keycloak olaylarını uzatmak:** Keycloak tek bir kişinin olaylarını silemez. 30 günden uzun tutulursa silinen kişinin adresi, silme için tanınan 30 günü aşar.
- **İmhayı 90 günde bir toplu koşturmak:** her süreye 90 güne kadar gecikme ekler. Ayrıca core her yayında yeniden başladığı için süreç içindeki 90 günlük bir sayaç hiç dolmaz.
- **Core'un merkezden süpürmesi ya da başka veritabanlarına doğrudan yazması:** her servise uç, yetki ve core bağımlılığı ekler. ADR-0051 eki bu yolu inscribed için zaten reddetti.
- **Yıllık arşiv yedeği:** silinen kişiyi ve süresi dolan veriyi geri getirir (ADR-0053).
