---
status: accepted
---

# Saklama süreleri ve periyodik imha

_Güncelleme (2026-11-24): Servis olaylarının saklama satırları ve Forms yanıtı ile Answer file arasındaki çelişki notu aşağıdaki ekte._

Gizlilik denetimi (2026-10-03) süresiz kalan kişisel veri buldu: konuk biletleri (telefon dahil), SkyMail alıcı satırları ve gövdeleri, sistem postalarındaki sıfırlama bağlantıları, form yanıtları, Place ve Guessr'daki IP'ler. Core `PERIODIC_DESTRUCTION_INTERVAL` (90 gün) değerini açılışta okuyor, ama onu kullanan bir iş yok. Saklama, verinin işlendiği amaç için gereken süreyle sınırlı olmalı; süresi dolan veri periyodik imhada yok edilir.

Karar (Yusuf, 2026-10-03): her veri kategorisi **amacıyla savunulabilecek en uzun süre** tutulur. "Süresiz" ancak iki durumda yazılır: amaç sürüyorsa (hesap açık, rıza geri alınmamış, sertifika doğrulanıyor, sonuç yayında) ya da veri anonimse. Bu kapsama yeni amaçlar eklenir: gelecek etkinliklere davet, topluluk ve mezun ilişkileri, etkinlik geçmişi ve arşivi, sertifika doğrulama.

- **Süre amaçtan gelir.** Her kişisel veri kategorisinin bir amacı ve bir Retention period'u vardır. Amaç bitince veri silinir ya da anonimleşir. Deletion lifecycle (ADR-0042) değişmedi: kayıt kalır, kişi gider; arşivlemek saati durdurmaz.
- **Süreler.** "Etkinlik + N", etkinliğin bitiminden itibaren sayılır. Core'da bu `events.end_date`, yoksa son `event_days.end_date`, yoksa `events.start_date`'tir. Çapası olmayan satıra dokunulmaz, tutanakta sayılır. Place, Guessr ve Ekstremspor'da `EVENT_ENDED_AT` kullanılır.

  | Veri | Süre |
  |---|---|
  | Üye hesabı ve profili | kişi silene kadar. 2 yıl giriş yapmayana bir hatırlatma gider, hesap kendiliğinden silinmez |
  | Üye ve mezun duyuruları | hesap ve tercih sürdükçe; her postada çıkış bağlantısı |
  | Konuğun adı ve e-postası, Davet onayı varsa | rıza geri alınana kadar. 3 yıl hiçbir etkinliğe gelmeyene bir yenileme sorusu gider; 60 gün yanıt gelmezse rıza biter |
  | Konuğun adı ve e-postası, rıza yoksa (sertifikadaki e-posta dahil) | kişinin en son etkinliği + 2 yıl; bekleyen sertifika işi olan bilete dokunulmaz |
  | Konuğun telefonu | etkinlik + 90 gün, rıza olsa da |
  | Yoklama ve yarışma geçmişi | üyede hesapla birlikte; konukta konuk kimliği boşalınca anonimleşir, sonra süresiz |
  | Club archive: yayımlanmış kazananlar, konuşmacılar, etkinlik fotoğrafları; sertifikalar (ad, etkinlik, seri) | süresiz; istek üzerine kaldırılır |
  | Kısa bağlantı tıklaması | IP, user-agent ve `user_id` 1 yılda boşalır, referer alan adına iner. Kişisiz satır süresiz kalır |
  | Özel dosya erişim kaydı | açılış IP'si 1 yıl; kaydın geri kalanı (kim, hangi dosya, ne zaman) 3 yıl |
  | Keycloak kullanıcı ve admin olayları | 30 gün |
  | SkyMail: alıcısı olmayan duyuru (şablon sürümü, değişkenler, gönderen, sayılar) | süresiz |
  | SkyMail: alıcı başına gövdesiz durum kaydı | üyede hesapla birlikte; konukta konuk süresince |
  | SkyMail: kişiselleştirilmiş gövde ve HTML | 1 yıl |
  | SkyMail: sistem postası değişkenleri (sıfırlama ve doğrulama bağlantıları) | 30 gün |
  | SkyMail: arşivlenmiş elle listenin alıcıları | arşivden 1 yıl sonra |
  | Place ve Guessr: hesap, okul e-postası | Davet onayı varsa rıza sürdükçe; yoksa etkinlik + 1 yıl |
  | Place ve Guessr: yasaklı hesap (IP değil) | etkinlik + 2 yıl |
  | Place ve Guessr: IP'ler, giriş ve Turnstile belirteçleri | etkinlik + 90 gün |
  | Son tuval, isimsiz skorlar, adını göstermeyi seçenin (`show_name`) lider tablosu adı | süresiz |
  | Davet onayı kaydı | rıza sürdükçe; geri alındıktan ya da bittikten sonra 3 yıl |
  | Hesap silme kanıtı, imha tutanağı (kişisiz) | en az 3 yıl, hiçbir kod yolu silmez |
  | Ham konteyner günlükleri | en çok 90 gün |
  | Yedekler | R2 31 gün, yerel 90 gün (değişmedi; "yıllık arşiv yedeği" yok; ADR-0053) |

- **Davet onayı (Contact consent).** Üye olmayan birine (konuk, oyuncu, reddedilen başvuran) gelecek etkinlik daveti yalnız Davet onayıyla gider. Core'da tek bir rıza kaydı tutulur: `contact_consents` (normalize e-posta, amaç, kanal, metin sürümü, kaynak, veriliş, geri alma, bitiş nedeni, son etkinlik). Core guest apply, Forms, Place ve Guessr bu kayda yazar. SkyMail davet listesini yalnız buradan okur.
  - Kutu işaretsiz gelir, gizlilik metninden ayrı durur, hizmet şartı yapılmaz. Kutuyu işaretlemeyen de kaydolur, oynar, başvurur.
  - Görevli başkası adına kutuyu işaretleyemez; kişiye bir onay bağlantısı gönderir.
  - Her davet postasında imzalı bir "davet almak istemiyorum" bağlantısı ve `List-Unsubscribe` başlığı olur. Geri alma tekrar edilebilir: ikinci tıklama da aynı sonucu verir. Adres yolda değil gövdede taşınır.
  - Geri alınınca konuğun verisi rızasız süreye döner. Süre en son etkinlikten işler.
  - Rıza geriye dönük işlemez. Bugünkü konuklara rıza sormak için posta atılmaz; davet listesi sıfırdan başlar.
  - Account erasure (ADR-0051) kişinin rıza kayıtlarını da siler. Bastırma listesi yine yok (ADR-0051 karar 4).
  - Davet postasına sponsor ya da ticari içerik konmaz; sponsorlar yalnız etkinlik sayfasında görünür.
- **Periodic destruction run.** Her servis kendi verisini kendi işiyle siler (ADR-0051'deki ilke): core, SkyMail, Place, Guessr ve Forms. Core başka bir servisin veritabanına yazmaz. İş her gün koşar ve süresi dolanı o gün işler. Politikadaki "en geç" süre, kural süresine bir gün eklenerek bulunur. 90 günlük `PERIODIC_DESTRUCTION_INTERVAL`, kayıt ve alarm birimidir: her dönemin sonunda bir imha tutanağı çıkar, dönem içinde başarılı koşu yoksa alarm gelir. Zamanlama süreç ömrüne değil, veritabanındaki son başarılı koşuya bakar. Kip `off | dry-run | apply`'dır ve her servis önce dry-run ile açılır. Dry-run ile apply aynı kural tanımından üretilir. İş partilerle çalışır, aynı anda tek kopya koşar (advisory lock) ve büyük değişimde durur. Her koşu kişisiz bir makbuz yazar: kural, zaman, satır sayısı. Bir yedek geri yüklenirse iş hemen bir kez apply kipinde koşar.
- **Forms Fatih'indir.** Önerimiz amaca göre süre. Kabul edilen ekip başvurusu üyelik ve mezuniyet boyunca kalır. Reddedilen başvuru, işaretsiz bir "gelecek alımlarda değerlendirilsin" kutusu işaretlenmişse rıza geri alınana kadar, işaretlenmemişse kapanış + 1 yıl kalır. Etkinlik başvurusu konuk kuralına uyar. Anket analizden sonra anonimleşir. Bunun için Forms'a `ClosedAt` ve amaç alanları gerekir. Form sahibi daha kısa bir süre seçebilir. Davet kutusu core'un rıza kaydına yazar. Uygulama Fatih'in kararıdır.
- **Ekstremspor'un saklama kuralları Ekstrem Sporlar Kulübü'nündür.** Onların kuralı uygulanır; biz yalnız altyapıyı işletiriz.

## Consequences

- ADR-0037'deki "default retention 90 days" değişir. Tıklama satırı silinmez; 1 yılda kişisel alanları boşalır. Bugünkü saatlik 90 günlük silme kalkar. Liste ve form istatistiği pencereleri ayrı bir sabite ayrılır.
- Özel dosya erişim kaydının süresi 1 yıldan 3 yıla uzar; IP yine 1 yılda boşalır.
- Yeni yüzeyler gelir:
  - core: `contact_consents`, `POST /v1/consents`, imzalı geri alma sayfası ve ucu, SkyMail için davet listesi okuma ucu, guest apply gövdesinde `consents`, `retention_runs`;
  - Hesap Merkezi'nde "iletişim tercihleri";
  - SkyMail'de çıkış bağlantısı ve kendi imha işi;
  - Place ve Guessr'da `EVENT_ENDED_AT` ve kendi işleri;
  - Forms'ta `ClosedAt` ve amaç alanı (Fatih).
- Metinler değişir: gizlilik metinlerindeki saklama özeti yenilenir. Davet için ayrı bir onay metni yazılır. Guessr'daki "oynarsan kabul etmiş olursun" ifadesi ile Place'in zorunlu "okudum, onaylıyorum" kutusu kalkar. Yarışma kaydına ve etkinlik mekânına arşiv bilgilendirmesi gelir.
- "Süresiz" satırların hepsi bir amaca bağlı. Amaç biterse (hesap silinir, rıza geri alınır, kişi kaldırılmayı ister) süre de biter. "Her ihtimale karşı saklama" yoktur.
- Açık sorular: rızasız 2 yıl, mezun duyurusu, 10 kişi anonimlik eşiği. Yanıtlar süreleri kısaltabilir. Uzatmaları ise ancak yeni bir karar yapabilir.
- Standartlarla karşılaştırma:
  - IP güvenlik günlüğü için 1 yıl, erişim kaydı iç denetim için 3 yıl tutulur.
  - Keycloak olaylarının 30 günü Microsoft Entra oturum açma günlükleriyle eşleşir.
  - **Sapma:** GA4 IP saklamaz; biz kötüye kullanım incelemesi için 1 yıl saklıyoruz.
  - **Sapma:** Postmark gövdeyi varsayılan 45 gün tutar; biz şikâyet incelemesi için 1 yıl tutuyoruz.
  - Microsoft ve Google Forms yanıtları sahibi silene kadar tutar. Forms önerimiz amaca göre süreyle bunlardan sıkıdır; "üyelik boyunca" kısmında onlara yaklaşır.

## Considered Options

- **En kısa makul süreler** (aynı günkü ilk öneri: konuk 1 yıl, telefon 30 gün, alıcı satırı 90 gün, yanıt kapanış + 1 yıl): Yusuf azami savunulabilir süreyi seçti. İlk öneri belgede kayıt için duruyor.
- **Konuğa daveti rızasız göndermek:** konuk bu postayı beklemez.
- **Her uygulama kendi rızasını tutar, SkyMail'e elle liste aktarılır:** daha az iş, ama geri alma bir yerde unutulur ve ispat dağınık kalır.
- **Konuk verisini 10 yıl tutmak:** ücretsiz etkinlikte bu "her ihtimale karşı saklama" olur. 2 yılın arkasında somut amaçlar var: sertifikayı yeniden gönderme, katılım belgesi, tekrar başvuruyu tanıma.
- **Hareketsiz hesabı 2 yıl sonra silmek:** üyelik ve mezun ilişkisi bunu gerektirmiyor. Hatırlatma ve kişinin kendi silmesi yetiyor.
- **Keycloak olaylarını uzatmak:** Keycloak tek bir kişinin olaylarını silemez. 30 günden uzun tutulursa silinen kişinin adresi, silme için tanınan 30 günü aşar.
- **İmhayı 90 günde bir toplu koşturmak:** her süreye 90 güne kadar gecikme ekler. Ayrıca core her yayında yeniden başladığı için süreç içindeki 90 günlük bir sayaç hiç dolmaz.
- **Core'un merkezden süpürmesi ya da başka veritabanlarına doğrudan yazması:** her servise uç, yetki ve core bağımlılığı ekler. ADR-0051 eki bu yolu inscribed için zaten reddetti.
- **Yıllık arşiv yedeği:** silinen kişiyi ve süresi dolan veriyi geri getirir (ADR-0053).

## Ek (2026-10-24): sponsor teşekkürü duyurudur, tanıtım yalnız izin verene gider; yeni saklama satırları (ADR-0070, ADR-0072)

**Sponsor ve tanıtım.** Davet onayı maddesindeki "Davet postasına sponsor ya da ticari içerik konmaz; sponsorlar yalnız etkinlik sayfasında görünür" cümlesinin yerine şu kural geçer (Yusuf, 2026-10-23):

- **Asıl amaç belirler.** Asıl amacı bilgilendirme olan duyurudaki kısa sponsor teşekkürü ya da sponsor logosu ("Etkinliğimiz X'in katkılarıyla düzenlenmektedir.") tanıtım sayılmaz. Bu posta, duyuru tercihine göre bütün alıcılara gider. Davet postası da buna dahildir.
- **Tanıtım yalnız izin verene gider.** Asıl amacı bir mal ya da hizmetin tanıtımı olan içerik (indirim kodu, şirket iş ilanı, satış, çekiliş) tanıtımdır. Yalnız tanıtım izni veren kişiye gider.
- **Tanıtım izni kişi başına tek bir izindir.** Core'da `contact_consents` içinde `promotional` amacıyla tutulur. Kutu işaretsiz gelir, varsayılan kapalıdır ve hizmet şartı yapılmaz. Kutu üç yerde görünür: Hesap Merkezi iletişim tercihleri, kayıttan sonraki ilk Hesap Merkezi ekranı ve SkyForms formları; kayıt formunda görünmez. İzin açıksa ilk Hesap Merkezi ekranında ve formlarda kutu gösterilmez; iletişim tercihlerindeki anahtar her zaman görünür, çünkü izin oradan geri alınır. Formda kutuyu boş bırakmak geri alma değildir. Girişsiz verilen izin çift onaylıdır. Hesapsız kişide izin e-posta adresine bağlıdır; aynı adresle hesap açılınca hesabın izni sayılır. İzin üç yoldan geri alınır: Hesap Merkezi iletişim tercihleri, tanıtım postasındaki çıkış bağlantısı ve info@yildizskylab.com'a yazmak. Hesap silinince izin de silinir (Account erasure rıza kayıtlarını siler). Davet onayındaki 3 yıllık yenileme sorusu bu izinde yoktur.
- **Beyan kalır.** Duyuruyu gönderen her gönderimde postanın asıl amacının tanıtım olmadığını beyan eder; kısa teşekkür ve logo bu beyana engel değildir. Asıl amacı tanıtım olan posta bu beyanla gönderilemez.
- **Kendi izni.** Tanıtım içeriği yalnız kulübün kendi tanıtım iznine dayanarak gider.

**Süreler tablosuna eklenen satırlar.** ADR-0072 Consequences "Saklama" satırı, ADR-0070'in "Saklama" maddesi ve yeni kategorilerin süreleri bu ekle tabloya girer:

| Veri | Süre |
|---|---|
| SkyMail: duyuru akışından çıkış kaydı (adres, akış, zaman, kaynak) | kişi yeniden abone olana, kişinin isteğiyle geri alınana ya da hesap silinene kadar |
| SkyMail: çıkışı geri alma kaydı (kim, zaman, gerekçe, kaydın kaynağı ve ilk tarihi; adres yok) | 3 yıl, sonra silinir; hesap silinince yetkilinin kimliği değiştirilir |
| SkyMail: kişi bazında açılma ve tıklama | 90 gün; sonra posta ve bağlantı bazında sayılar kalır: 10 ve daha çok alıcılı gönderimde anonim ve süresiz, 10'dan az alıcılı gönderimde 1 yıl sonra silinir |
| SkyMail: gönderilen posta içeriği (Forms yanıt kopyaları dahil) | 1 yıl |
| Uygulama içi bildirim (kutu öğesi) | 90 gün; hesapla birlikte silinir |
| Bildirim cihaz kaydı | son görülmeden 270 gün sonra ya da çıkışta |
| SMS teslim satırı | e-postanın kişiselleştirilmiş gövde süresiyle (1 yıl, öneri) |
| Tanıtım izni kaydı (yer, zaman; hesapsız kişide e-posta adresine bağlı) | izin sürdükçe; geri alındıktan sonra 3 yıl, sonra silinir |
| Ters vekil sunucu erişim kaydı (zaman, kaynak IP ve port, hedef, yöntem, maskelenmiş yol, sonuç) | 1 yıl, günlük dosyalarının zaman damgalı bütünlük özetiyle; sonra IP ve port kaldırılır, gün, sayfa ve sonuç sayıları anonim ve süresiz |
| Ham konteyner ve sunucu günlükleri (erişim kaydı dışında) | en çok 90 gün (değişmedi; kapsam netleşti) |
| Kart çip numarası | kart kaydı kaldırılınca ya da hesap silinince |
| YK üyelerinin adı, soyadı ve görevi (site) | görev süresince |
| Etkinlik fotoğraf ve videoları (arşiv ve paylaşım) | itiraz edilene kadar; itirazda 7 gün içinde kulübün kendi yerlerinden kaldırılır |
| Tek kişinin odakta olduğu görüntünün kişiyle özdeşleşen kullanımı (afiş, kapak, tanıtım videosu) | rıza geri alınana kadar; geri alınınca 7 gün içinde kaldırılır |
| Yarışma sonuçları ve konuşmacılar (arşiv) | itiraz edilene kadar |
| Formda özel nitelikli veri | etkinliğin bitiminden 30 gün |
| Kişisel veri başvuruları ve yazışmaları | başvurunun sonuçlanmasından 3 yıl; kimlik belgesi kopyası doğrulamadan sonra silinir |
| İş ortağı, sponsor, tedarikçi: sözleşme ve ödeme belgesi | ilişkinin bitiminden 10 yıl |
| İş ortağı, sponsor, tedarikçi: yalnız yazışma | son yazışmadan 3 yıl |
| SkyForms form yanıtları | kural yok, kendiliğinden silme yok; Fatih'in kuralı gelince değişir |

- "Club archive" satırındaki etkinlik fotoğrafları ile "Ham konteyner günlükleri" satırı yukarıdaki satırlarla daralır. Üye olmayan kişinin duyuru rızası Davet onayı satırlarına tabidir; süreleri değişmedi (kapsam aşağıda genişler).
- SkyMail'in çıkış kaydı tercih değildir ve kendiliğinden düşmez. Kişi yeniden abone olunca, panel kişinin isteğiyle ya da bir hatadan sonra gerekçeyle geri alınca, ya da hesap silinince (ADR-0051 eki) silinir. Periyodik imha bu kayda dokunmaz; SkyMail'in silme adımı dokunur. Geri alma kaydı adres tutmaz.
- Anonim, geri döndürülemez demektir. IP'nin ya da e-posta adresinin özeti anonim sayılmaz; süre sonunda yalnız toplam sayılar kalır.

**Davet onayının kapsamı genişler.** Davet onayı artık yalnız gelecek etkinliklere davet değil, kulübün diğer etkinlik ve duyurularına ilişkin postaları da kapsar. Kutu metni "Diğer etkinlik ve duyurulardan haberdar olmak istiyorum." olur (metin sürümü `davet-v2`). Core'daki amaç aynı kalır (`event_invitations`); sürüm vermeyen kayıt `davet-v2`'ye düşer, `davet-v1` kabul edilmeye devam eder. SkyMail bu amacın kitlesini duyurularda da okur. Kişinin kaydolduğu etkinlikle ilgili postalar (bilet, yer ya da saat değişikliği, iptal, geri bildirim formu, sertifika) bu rızaya bağlı değildir. Kutuyu işaretlemeyen de etkinliğe katılır. Giriş yapılmadan verilen rıza, kişinin adresine giden onay postası onaylanınca geçerli olur; o zamana kadar adrese duyuru gitmez. Yenileme sorusu (3 yıl, 60 gün) ve rıza kaydının 3 yıllık ispat süresi değişmez. Davet onayı ile tanıtım izni ayrı kayıtlardır: biri duyuru ve davet, öteki tanıtım içeriği içindir.

**Açık sorulara eklenenler:**
- Hesabı olmayan adresin silme başvurusunda çıkış kaydının silinmesi ve ardından adresin yeniden duyuru alabilmesi (ADR-0072 Açık).
- YTÜ'ye bildirilen katılımcı listesinin alanları.
- SkyForms yanıtlarının süre kuralı (Fatih).

## Ek (2026-10-24, ikinci): tanıtım izni kutusu yalnız iletişim tercihlerinde

Yusuf ve Fatih (2026-10-24): kulüp şu an tanıtım içeriği göndermiyor. Bu yüzden önceki ekteki "Kutu üç yerde görünür" cümlesi daralır. Tanıtım izni kutusu yalnız Hesap Merkezi iletişim tercihlerinde çıkar. Kayıttan sonraki ilk Hesap Merkezi ekranında ve SkyForms formlarında kutu yoktur.

- Önceki ekin şu kısımları bu yüzden boşa düşer: ilk ekranda ve formlarda kutunun gizlenmesi, formda boş bırakılan kutu, girişsiz verilen iznin çift onayı ve hesapsız kişinin e-posta adresine bağlı izni. İzni yalnız hesabı olan kişi verir.
- Değişmeyenler: kişi başına tek izin, işaretsiz ve varsayılan kapalı kutu, üç geri alma yolu (iletişim tercihleri, tanıtım postasındaki çıkış bağlantısı, info@yildizskylab.com), izin kaydının geri almadan sonra 3 yıl saklanması ve hesap silinince silinmesi.
- Duyuru rızası (Davet onayı, `davet-v2`) ve onun formdaki kutusu aynen kalır.
- Kutuyu yeniden ilk ekrana ya da formlara koymak yeni bir karar ister.

## Ek (2026-10-25): açılma ve tıklama takibinin kayıtları (ADR-0074)

2026-10-24 ekindeki "SkyMail: kişi bazında açılma ve tıklama" satırı ADR-0074'ün süresidir. Tabloya iki satır eklenir:

| Veri | Süre |
|---|---|
| SkyMail: takip bağlantısı adresleri (gönderimde kaydedilen hedefler) | 1 yıl, sonra adres boşalır ve bağlantı "süresi doldu" der; maskelenen ya da sonradan hassaslaşan gönderimde saklama işinin ilk koşusunda; kişiyi adlandıran adres hesap silmede |
| core: takip tercihi değişikliklerinin kaydı (kişi, yeni ve önceki değer, kaynak, zaman; adres ve IP yok) | 3 yıl, sonra silinir; hesap silinince hemen |

- Takibe itiraz eden kişinin olayları itirazla silinir; tercih satırı hesapla yaşar.
- "Açık sorular"daki 10 kişilik anonimlik eşiği SkyMail'in takip toplamları için de geçerlidir.

## Ek (2026-10-27): geri dönen postanın kayıtları (ADR-0073)

ADR-0073'ün Consequences "Saklama" maddesindeki iki satır tabloya girer:

| Veri | Süre |
|---|---|
| SkyMail: ret kaydı (kuyruk satırına bağlı; tür, `Action`, ek kod, SMTP kodu, `AS` belirteci, zaman, rapor kimliğinin özeti; adres ve metin yok) | 1 yıl; kuyruk satırı silinince onunla |
| SkyMail: bastırma kaydı (küçük harfli adres, varsa kişinin `sub`'ı, kaynak, kod, ilk ve son görülme, sayı, son kuyruk satırı) | kaldırılana ya da hesap silinene kadar |

- Bastırma kaydı kendiliğinden düşmez (ADR-0073 karar 7). Periyodik imha ona dokunmaz; panelden kaldırma ve Account erasure siler.
- Teslim raporunun kendisi SkyMail'de saklanmaz (ADR-0073 karar 3). Gönderen kutusunun Gelen Kutusu'nda Exchange'in saklama etiketiyle 30 gün sonra silinir (karar 2); Exchange'in işlem gecikmesi (en çok 7 gün) ve kurtarılabilir öğeler süresi (varsayılan 14 gün) buna eklenir.

## Ek (2026-10-27, ikinci): bastırma listesinden kaldırma kaydı 3 yıl (ADR-0073)

Karar (Yusuf, 2026-10-27): ADR-0073'ün kaldırma denetim kaydı, çıkışı geri alma kaydı gibi 3 yıl saklanır. Kayıtta kaldıran görevlinin kimliği olduğu için süresiz tutulamaz; amaç (kimin neyi kaldırdığının ispatı) geri alma kaydınınkiyle aynıdır. Tabloya bir satır eklenir:

| Veri | Süre |
|---|---|
| SkyMail: bastırma listesinden kaldırma kaydı (kim, zaman, kaldırılan satırın kaynağı, kodu, sayısı ve ilk görülmesi; adres yok) | 3 yıl, sonra silinir; hesap silinince yetkilinin kimliği değiştirilir |

- SkyMail'in içerik süpürücüsü siler; süre sabittir, ayarı yoktur.

## Ek (2026-10-31): yönetim görevi kaydı ve ekip denetim kaydı (ADR-0065, ADR-0078)

Karar (Yusuf, 2026-10-31): biten yönetim görevinin kaydı, ekip denetim kaydı gibi 3 yıl saklanır. Bu, ADR-0078'deki "Bitmiş terimlerin saklama süresi" açık sorusunu kapatır. ADR-0065'in Consequences'ındaki denetim kaydı satırı da bu ekle tabloya girer. Tabloya iki satır eklenir:

| Veri | Süre |
|---|---|
| core: yönetim görevi kaydı (YK, DK ve ekip liderliği; kişi ve grup kimliği, başlangıç, planlanan ve gerçek bitiş, uyarılar; ad ve adres yok) | görev sürdükçe; bitiminden (`ended_at`) 3 yıl sonra silinir; hesap silinince hemen |
| core: ekip denetim kaydı (kim, hangi grubu, ne zaman, nasıl değiştirdi; kişi ve grup kimlikleri, grup yolu, kod ve rol adları; ad ve adres yok) | 3 yıl, sonra silinir; hesap silinince silinmez, kimlik kimseye çözülmez |

- Süre görevin gerçekten bittiği günden işler: core'dan çıkarma, devir ya da Keycloak'ta artık bulunmama. Planlanan bitiş ya da süre doldu işareti saati başlatmaz; süresi dolmuş ama kişisi hâlâ grupta olan görev açıktır ve kalır.
- Görevin denetim satırları (uzatma, devir, süre dolması) kendi 3 yılına bağlıdır; görev kaydı silinince onlar kalır.
- İkisini de core'un periyodik imha işi siler; süre sabittir, ayarı yoktur.

## Ek (2026-11-24): servis olaylarının kayıtları (ADR-0071); Forms yanıtı ile Answer file

**Süreler tablosuna eklenen satırlar.** ADR-0071 karar 6'nın saklama maddesi tabloya girer. Olaylarda ad, e-posta, telefon ve IP yoktur, yalnız kimlikler vardır (ADR-0071 karar 5).

| Veri | Süre |
|---|---|
| Tüketicinin işlenmiş olay kaydı (`consumed_events`: olay kimliği; tekrar eleme için) | 30 gün |
| RabbitMQ: DLQ'daki olay | 14 gün |
| RabbitMQ: `unrouted` kuyruğundaki olay | 1 gün |
| Yayıncının giden kutusu satırı (yayımlanmamış olay) | onayda silinir; onay gelmezse 7 gün sonra bırakılır |

- DLQ'daki kimlikler hesap silme için tanınan 30 gün içinde düşer.

**Forms yanıtı ile Answer file çelişkisi.** ADR-0052, Answer file'ı formun kapanışından 6 ay sonra siler. Bu ADR'nin 2026-10-24 eki ise SkyForms yanıtları için "kural yok, kendiliğinden silme yok" der. Yanıt dururken eki silinebilir. Yanıt süresi Fatih'in kararıdır; soru ve önerimiz (amaca göre süre) Fatih'e iletildi. Karar gelene kadar iki metin de olduğu gibi kalır.

## Ek (2026-11-25): Event'in ortak kişileri (ADR-0092)

Tabloya bir satır eklenir:

| Veri | Süre |
|---|---|
| core: Event'in ortak düzenleyen kişisi (Event, kişinin kimliği, ekleyenin kimliği, eklenme zamanı) | Event'in bitişinden 90 gün sonra silinir (kapı görevlisi satırıyla aynı); yetki bitişten 30 gün sonra düşer; hesap silinince hemen |

- Ortak ekip satırlarının süresi yoktur; ekip yapısal bir birimdir ve kişisel veri taşımaz.
- Ekleme ve çıkarma kayıtları ekip denetim kaydındadır ve onun 3 yılına bağlıdır.

## Ek (2026-11-25, ikinci): etkinlik değişikliği bildirim yanıtının kaydı

Karar (Yusuf, 2026-11-25): yayındaki bir Event'in saati, yeri ya da başka ayrıntıları değişince düzenleyen "Bilet sahiplerine bildir" sorusunu yanıtlar. Core yanıtı kaydeder. Bu kayıt da ekip denetim kaydı gibi 3 yıl saklanır. Tabloya bir satır eklenir:

| Veri | Süre |
|---|---|
| core: bildirim yanıtının kaydı (Event, kaydeden kişinin kimliği, değişen alanların adları, yanıt, bildirimin sıraya girip girmediği, zaman; metin, ad ve adres yok) | 3 yıl, sonra silinir; hesap silinince silinmez, kimlik kimseye çözülmez; kişi kaydı tamamen silinirse kimlik boşaltılır |

- Core'un periyodik imha işi siler (`event_change_notices_age`); süre sabittir, ayarı yoktur.
- Event silinirse kayıtları da gider.

## Ek (2026-11-25, üçüncü): Biletsiz yanıtlayan kaydı (ADR-0069)

ADR-0069'un 2026-11-25 eki, bağlanan formun biletsiz yanıtlayanlarını core'da tutar. Tabloya bir satır eklenir:

| Veri | Süre |
|---|---|
| core: Biletsiz yanıtlayan (Event, form ve yanıt kimliği, yanıt zamanı, Forms durumu; girişli yanıtta hesap kimliği, misafirde ad, soyad, e-posta; cevap metni yok) | Event'in bitişinden 2 yıl sonra silinir (konuk verisiyle aynı süre; tarihsiz Event'te kaydın zamanından); form Event'ten çıkarılınca, bilet yazılınca ve hesap silinince hemen |

- Core'un periyodik imha işi siler (`form_respondents`); bütün yeni kurallar gibi önce kuru koşuda başlar. Arşivlemek saati durdurmaz.
