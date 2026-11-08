---
status: accepted
---

# Haber ve duyuru inscribed'dadır ve görünürlüğü gerçek bir erişim sınırıdır; e-postayla SkyMail gönderir, kitleye ve tercihe core karar verir

ADR-0011'de kulüp duyuruları CMS'in News koleksiyonu oldu ve sitelerde gösterimi "sonra" bırakıldı. ADR-0056'da News stock inscribed'a taşındı; SkyApp de News'i kendi token'ıyla yazmaya başladı. Bugünkü durumun sorunları:

- **Yazma yüzeyleri uyuşmuyor.** Yönetim paneli News'i düz metinle yazıyor. inscribed'ın gövdesi ise zengin metin: editörün ürettiği bir HTML metni. SkyApp gövdeyi düz metne çevirerek gösteriyor ve düzenleyip kaydettiğinde HTML'i düz metne çeviriyor.
- **Okuma ve yayın araçları eksik.** Ana site haberleri göstermiyor. Haber ile duyuru ayrılmıyor; bitiş tarihi ve hedef kitle yok.
- **E-postayla ulaşma yolu yok.** Yayımlanan bir şeyi üyelere e-postayla duyurmanın yolu yok. SkyMail bir gruba toplu gönderebiliyor, ama postalarında çıkış bağlantısı yok. ADR-0062 üye duyurusunu "her postada çıkış bağlantısı" şartıyla meşru menfaate bağlamıştı.
- **Tercih yok.** Kişinin "duyuru almak istemiyorum" diyebileceği bir kayıt hiçbir yerde yok.

Yusuf'un isteği (2026-10-12): duyurular ana siteden inscribed ile yönetilebilmeli. Bir duyuru ya da haber girilince SkyMail'le "duyuru gönder" yapılabilmeli, Medium'daki gibi. Admin panelinden de yönetilebilmeli. Her özellik hem haberde hem duyuruda olmalı.

Karar (Yusuf, 2026-10-12; açılış sırası Fatih'le, 2026-10-12):

1. **Haber ve duyuru iki türdür ve her özellik ikisinde de vardır.** Yazma yerleri: ana sitenin inscribed çekmecesi, yönetim paneli ve SkyApp. Tek kaynak inscribed'dır; yetkiye inscribed karar verir (ADR-0056).
2. **Görünürlük kayıt bazındadır ve gerçek bir erişim sınırıdır:** herkes, yalnız Member'lar ya da belirli ekipler (alt ekipleriyle). Kural inscribed'da, sunucuda uygulanır. Herkese açık uçlar özel kaydı hiçbir yoldan döndürmez (liste, slug, arama, sayılar); sızıntı testleri bunu kanıtlar. Site ve SkyApp giriş yapmış kişinin token'ıyla okur, kendi süzgecini yazmaz.
3. **İki adımda açılır.** Fatih (2026-10-12): altyapı önce herkese açık kayıtla kurulur; inscribed'a kayıt bazında görünürlük gelince özel kayıt tek değişiklikle açılır.
   - **Birinci adım: yalnız herkese açık kayıt.** Görünürlük alanı koleksiyon tanımına şimdi girer, ama tek değeri "herkes"tir. Panel, site ve SkyApp alanı bugünden okur ve yazar; seçenekleri sabit kodlamaz, koleksiyon tanımından alır. Gönderim, Duyuru tercihi, ekip ekip kitle ve tek tık çıkış bu adımda tam çalışır. Bir ekibe gönderilen postanın kaydı da web'de herkese açıktır.
   - **İkinci adım: üyeye ve ekibe özel kayıt.** "Yalnız Member'lar" ve "belirli ekipler" değerleri koleksiyon tanımına ancak üç koşul sağlanınca girer: inscribed'ın kayıt bazında görünürlüğü production'dadır; sızıntı testleri yeşildir; görünürlük eski bir istemcinin güncellemesiyle silinemez. O zamana kadar özel kayıt yazılmaz. Bizim taraftaki değişiklik bir koleksiyon tanımı içe aktarmasıdır. Yazıcılar görünürlük ve ekip seçimini bugünden taşır, SkyApp token'ı zaten gönderir; sitenin üye girişi (karar 8) ayrı bir iştir.
   - **Güncellemenin görünürlüğü silmesi.** inscribed güncellemede bütün veriyi değiştiriyor. Birinci adımda bu bir risk değildir: alanın yokluğu "herkes" demektir ve zaten her kayıt herkese açıktır. İkinci adımda risk olur. O adımdan önce şu üç yoldan biri gerekir: görünürlük kaydın üst verisinde durur, güncelleme birleştirerek yapılır ya da güncellemede gelmeyen görünürlük alanı eski değerini korur.
4. **"E-postayla gönder" ekranı SkyMail'dedir.** Panel ve site oraya bağlantı verir (ADR-0031'deki etkinlik postası gibi).
5. **Gönderen.** Şimdilik YK, DK ve ADMIN tüm üyelere ve ekiplere doğrudan gönderir; başkaları Mail onayıyla gönderir.
6. **Abonelik ekip ekiptir** ("bir kişi her şeyi özelleştirebilmeli"):
   - Kulüp geneli için bir, her ekip için ayrı anahtar vardır.
   - Her kaynakta haber ve duyuru ayrı anahtardır; bir de hepsini kapatan "tümünden çık" vardır.
   - Üst ekibe abonelik alt ekipleri kapsar; kişi bir alt ekibi ayrıca kapatabilir, en özel ayar kazanır.
   - Postadaki tek tık çıkış yalnız o postanın kategorisinden çıkarır.
   - Tercih core'da tutulur, ekranı Hesap Merkezi'ndedir.
   - Zorunlu postalar (giriş kodu, bilet ve öteki işlem postaları) tercihten etkilenmez.
7. **Ekip takibi.** Member, üyesi olmadığı görünür bir ekibi takip edebilir. Varsayılan kapalıdır. Takipçi yalnız herkese ya da tüm Member'lara açık kayıtların postasını alır; ekiplere özel kayıt (ikinci adım) takipçiye gitmez.
8. **Sitede üye girişi açılır.** yildizskylab.com'da Member giriş yapabilir ve kendisine açık kayıtları görür (ikinci adım); tasarımı ve yapımı Kaan'ındır.
9. **Ekip adlandırma ve taşıma.** Ekip adı değişince ya da ekip taşınınca (ADR-0065) özel kayıtların ekip değerini core günceller (ikinci adım).

Nasıl (spec'ten):

- **Kayıt alanları.** Tür (`kind`), yayın ve bitiş tarihi, sabitleme bitişi, kapak alt metni, bağlantı düğmesi, görünürlük ve ekipler. Yeni alanların hepsi isteğe bağlıdır ve yokluğun anlamı tanımlıdır; eski kayıtlar ve eski istemciler bozulmaz. Koleksiyonun yolu ve yanıt biçimi değişmez.
- **Gövde** inscribed editörünün ürettiği HTML alt kümesidir; okuyan her yer onu temizler. inscribed güncellemede bütün veriyi değiştirdiği için her yazıcı bütün veriyi okur, yalnız kendi alanlarını değiştirir ve hepsini geri gönderir. İkinci adımda görünürlük eski bir istemcinin güncellemesiyle silinemez (karar 3); token'lı yanıt paylaşılan önbelleğe girmez; belirsizlikte çağıran anonim sayılır.
- **Gönderim** yalnız yayımlanmış bir News'ten başlar ve kaydın o anki halini saklar; sonraki düzenleme giden postayı değiştirmez. Gönderimden önce deneme postası, canlı alıcı sayısı ve zorunlu bir gözden geçirme ekranı vardır.
- **Kitleye core karar verir.** Member'ın ve ekibin tanımı, Duyuru tercihi ve Contact consent core'dadır. SkyMail kitleyi core'un servis hesabına açık bir ucundan alır ve kendi grup çözümünü bu iş için kullanmaz.
  - Bir ekibe giden postanın kitlesi: o ekibin ve alt ekiplerinin üyeleri, artı o ekibi ya da üst ekiplerinden birini takip edenler.
  - Ekiplere özel bir kayıt yalnız görünürlüğü içindekilere gider.
  - Posta yalnız kişinin seçtiği Primary e-mail'e gider. Devre dışı, doğrulanmamış ve adressiz hesaplar atlanır.
- **Duyuru tercihi rıza değildir.** Member'a kulüp geneli ve kendi ekipleri meşru menfaatle gider (ADR-0062) ve varsayılan açıktır. Ekip, grup kimliğiyle tutulur; adlandırma ve taşıma tercihi bozmaz. Çıkış bağlantısı imzalıdır ve RFC 8058 tek tık çıkışını destekler. Tercih Contact consent kaydına konmaz, çünkü o bir onay kaydıdır ve varsayılanı kapalıdır. Hesap silinince tercih de silinir; bastırma listesi tutulmaz (ADR-0051).
- **Toplu gönderim sistem postalarını bekletmez.** SkyMail'de öncelik şeridi vardır: giriş kodu, sertifika ve form postaları önce gider. Replikalar arası paylaşılan bir hız sınırı ve günlük bütçe vardır; sağlayıcı kısma yanıtı verirse toplu şerit geri çekilir. Teslim "en az bir kez"dir; SMTP'de "tam olarak bir kez" mümkün değil.
- **Doğrudan gönderim izni** SkyMail'in bir client rolüdür ve YK, DK ve ADMIN gruplarına eşlenir (ADR-0059).
- **Leader'ın kendi ekibine yazıp göndermesi** ekip yetki devrinin (ADR-0065) güvenlik önkoşulu production'a çıkmadan açılmaz: bugün Privileged grup adından okunuyor ve `YK` adlı bir alt ekip bütün üyelere gönderme yetkisi verirdi.

## Consequences

- **inscribed.** News koleksiyon tanımı genişler. inscribed bilinmeyen alanı reddettiği için önce tanım içe aktarılır, sonra yeni alan yazan istemciler yayına çıkar. Mevcut kayıtların düz metin gövdesi paragraflara çevrilir.
- **inscribed (ikinci adım, Fatih).** Kayıt bazında okuma kuralı: isteğe bağlı token, alt ağaç eşleşmesi, her yan uçta uygulama, önbellek başlıkları. Ayrıca görünürlüğü eski istemcilerin silemeyeceği bir yazma biçimi. Ekip değeri güncellemesi (karar 9) için core'a bir CMS servis hesabı gerekir.
- **core.** Yeni yüzeyler: Duyuru tercihi kaydı ve kişinin kendi uçları, imzalı çıkış sayfası ve ucu, SkyMail'in servis hesabına açık kitle ucu, hesap silme saga'sında yeni bir adım.
- **SkyMail.** Haberden gönderim, öncelik şeridi, hız sınırı, `List-Unsubscribe` ve `List-Unsubscribe-Post` başlıkları, deneme postası, sunucu önizlemesi. Bir System template: haber postası, altlığında çıkış bağlantısıyla.
- **Hesap Merkezi.** "İletişim tercihleri" ekranı: kulüp geneli ve ekipler, duyuru ve haber, ekip takibi, ana anahtar. Kategori bazında çıkış ekranı olmadan gönderim açılmaz.
- **Site ve panel.** Ana sitede haber ve duyuru sayfaları; ikinci adımda üye girişi ve kişiye özel sayfalar, bunlar paylaşılan önbelleğe girmez. Panelde yönetim ekranı ve zengin metin editörü.
- **SkyApp.** Gövdeyi HTML olarak göstermeli ve yazarken bütün veriyi korumalıdır (sözleşme). Güncellenene kadar uygulamadan yapılan düzenleme yeni alanları siler; uygulamadan düzenleme bugün yalnız Privileged'da var ve seyrek.
- **Sızıntı testleri** birinci adımda yazılır ve anonim okumaya karşı koşar; tam matris ikinci adımın önkoşuludur.
- **Ekip adlandırma ve taşıma.** Core güncelleyene kadar özel kaydın ekip yolu eskirse kayıt üyelere kapanır; bu güvenli yöndür.
- **Metinler.** KVKK Aydınlatma Metni'ne duyuru postaları eklenir. Emsal: Kurul 2023/938, üniversite duyurularının aydınlatmaya eklenmesi.
- **ADR-0062 ile iki gerilim** avukata ve YTÜ'ye gider; ADR-0062'nin kendisi değişmez:
  - Mezunlara duyuru. Üyelik YTÜ yönergesine göre mezuniyetle bitiyor; ADR-0062'nin "mezun duyurusu meşru menfaat" satırı bununla gerilimde.
  - ADR-0062'nin konuk daveti için dayandığı Kurul 2018/119'un kapsamı.
- **CONTEXT.md'de değişenler:**
  - News: tür (haber/duyuru), görünürlük kayıt bazında gerçek erişim sınırı, bitiş ve sabitleme.
  - Yeni terimler: Announcement preference (Duyuru tercihi), Team follow (Ekip takibi), News send (Haber gönderimi).

## Açık

Yusuf'a soruldu; cevap gelene kadar spec'in önerisi uygulanır.

- **Tek koleksiyon mu, ayrı duyuru koleksiyonu mu:** öneri, tek News koleksiyonu ve tür alanı. SkyApp ve üç yazma yüzeyi hiçbir şey yapmadan ikisini de görür; her özellik bir kez kurulur.
- **Taslak ve zamanlanmış yayın:** öneri, Fatih'ten inscribed'a kalıcı taslak ve yayın zamanı istenir; gelene kadar "kaydet = yayınla". SkyMail gönderimi ayrıca zamanlanabilir.
- **Üye olmayan aboneler:** öneri, şimdilik yok; yalnız var olan Contact consent listesi, yalnız etkinlik daveti niteliğindeki duyurular için. Talep olursa açık rızalı, çift onaylı ayrı bir bülten aboneliği.
- **Postanın biçimi:** öneri, duyuru tam metin, haber "özet, kapak ve devamını oku"; gönderirken değiştirilebilir.
- **Gönderen hesap:** öneri, bugünkü kulüp posta hesabı. Ayrı gönderici alan adı ve toplu posta sağlayıcısı hacim büyürse.
- **Açılma ve tıklama izleme:** öneri, yok. Postadaki bağlantı Short link'se kişisiz kanal sayımı zaten var.
- **Sponsorlu içerik postada:** öneri, yok. Gönderimde onay kutusu, sponsor yalnız web'de. Kulüp tüzel kişi değil ve ticari ileti için gereken kaydı (İYS) yapamaz. ADR-0062 davet postası için aynı kuralı koymuştu.
- **Aynı haberin ikinci gönderimi:** öneri, kişi başına bir kez; "eksik kalanlara gönder" yeni üyelere gider.
- **Mezunlara duyuru:** öneri, avukat cevap verene kadar yok; gönderim yalnız Member'lara.

Fatih'e soruldu (2026-10-12); cevap gelene kadar birinci adım bunlarsız yürür:

- **News'i yazma yetkisi:** bugün Privileged yazar. Kuralın bir client rolüne taşınması (ADR-0059) Fatih'in onayını bekliyor.
- **Görünürlüğü silmeyen güncelleme:** birleştirerek güncelleme ya da gelmeyen alanı koruma. İkinci adımdan önce gerekir (karar 3).
- **Koleksiyon tanımının onayı:** yeni alanlar ve birinci adımın tek değerli görünürlük alanı.
- **Ekip değerini güncelleyen CMS servis hesabı** (karar 9). İkinci adımdan önce gerekir.
- **Kayıt bazında görünürlüğün zamanı:** Fatih "sonra" dedi, sürüm belli değil.

## Endüstri uygulamasıyla karşılaştırma

**Uyanlar:**
- Yazı ile e-posta aynı akışta, e-posta isteğe bağlı (Ghost, Substack, Beehiiv, Anthology Engage).
- Yayından sonraki düzenleme yalnız web'e yansır (Substack, Ghost).
- Deneme postası, canlı alıcı sayısı ve gözden geçirme ekranı (Beehiiv).
- Her postada tek tık çıkış (Ghost; Gmail ve Yahoo'nun toplu gönderici kuralları).
- Bitiş tarihi (CampusGroups) ve öne çıkarmanın bitişi (SharePoint).
- Gerçek erişim kademeleri (Engage; Ghost'ta herkes, üyeler, kademeler). Bizde ikinci adımda.
- Bülten başına abonelik (Ghost; CampusGroups'ta grup başına bildirim).

**Sapmalar (hepsi):**
1. **Abonelikte alt ekip kalıtımı.** İncelenen ürünlerde görmedik; ekip ağacıyla tutarlılık için.
2. **Üye için çift onay yok,** çünkü kimlik zaten doğrulanmış.
3. **Kalıcı taslak inscribed'ı bekliyor** (Ghost ve WordPress'te hazır).
4. **Kişi başına tek gönderim ama ikinci kitleye izin** (Ghost yazı başına tek gönderim yapıyor). Açık soruya bağlı.
5. **Açılma izleme yok.** Açık soruya bağlı.
6. **Erişim kademeleri ikinci adımda gelir.** Ghost ve Engage'de kayıt başına erişim kademesi baştan hazır; bizde birinci adımda her kayıt web'de herkese açıktır ve kitle yalnız postayı süzer. Bu ara durum SharePoint haberlerindeki kitle hedeflemesine benzer: Microsoft'ta da kitle hedefleme erişim sınırı değildir, gizlilik site ve sayfa izinleriyle sağlanır. Gerçek sınır ikinci adımda inscribed'dadır.

## Considered Options

- **Görünürlüğü yalnız hedefleme ipucu yapmak** (SharePoint'in kitle hedeflemesi gibi) ya da okuyucuda süzmek: anonim API kaydı yine döndürür. Spec önce ipucu önermişti; Yusuf gerçek erişim sınırını seçti (karar 2).
- **Girişle okunan ikinci bir koleksiyon:** üyelere CMS'in genel okuma rolünü vermek gerekirdi; okuyucular iki koleksiyonu birleştirmek zorunda kalırdı.
- **Ayrı bir duyuru koleksiyonu:** her özellik iki kez kurulurdu; SkyApp güncellenene kadar duyuruları görmezdi. Açık soru.
- **Yayında kendiliğinden e-posta (inscribed webhook'u):** göndermek bilinçli bir seçim olmalı (Ghost'ta "Publish and email" ile "Publish only" ayrı). inscribed'da webhook da yok.
- **Gönderim ekranı panelde:** Mail onayı, şablon ve rapor ikinci bir yerde kurulurdu. SkyMail başka bir servisin kullanıcı adına onaya sunmayı desteklemiyor. Yusuf SkyMail'i seçti (karar 4).
- **SkyMail'in kendi Keycloak grup çözümü:** bu yolda tercih ve hesap durumu süzgeci yok; ekibin tanımı core'dakinden ayrışırdı.
- **Tek bir "kulüp duyuruları" anahtarı** (spec'in ilk önerisi): Yusuf ekip ekip ve tam özelleştirme istedi (karar 6).
- **Tercihi Contact consent kaydında, Keycloak özniteliğinde ya da SkyMail'de tutmak:**
  - Contact consent: bir onay kaydıdır ve varsayılanı kapalıdır.
  - Keycloak özniteliği: zaman ve kaynak tutmak zor; imzalı bağlantının yazması için Keycloak yazma yetkisi gerekir.
  - SkyMail: tercih kimlikten kopar, Hesap Merkezi ikinci bir servisi çağırır.
- **Taslağı ikinci, gizli bir koleksiyonda tutmak ve yayını kendi zamanlayıcımızla yapmak:** iki koleksiyon, iki çekmece ve eşzamanlı olmayan iki yazma demek.

## Ek (2026-10-21): toplu postada çıkış SkyMail'in bütün toplu gönderimlerine genişler (ADR-0072)

Bu kararın tercih ve çıkış kuralları değişmez. ADR-0072 onları yalnız haber gönderiminden SkyMail'in bütün toplu gönderimlerine genişletir: liste, Keycloak grubu, Forms yanıtlayanları ve onaylı gönderim.

- **Tercih yine core'dadır.** "Tercihi SkyMail'de tutmak" reddi aynen geçerlidir.
- **SkyMail'in çıkış kaydı tercih değildir.** ADR-0072 SkyMail'e duyuru akışında adres başına bir çıkış kaydı (Suppression, `unsubscribed` nedeni) verir. Bu kayıt kategori, ekip ya da kanal taşımaz. Yalnız core'un tanımadığı adresin "bu adrese duyuru gönderme" kaydıdır. Kimliği olan kişinin core'daki çıkışı oraya kopyalanmaz.
- **"Bastırma listesi tutulmaz (ADR-0051)" cümlesi silmeden sonrası içindir.** SkyMail hesap açıkken adres başına kayıt tutar: kalıcı ret ve kimliği olmayan adresin çıkışı. Hesap silinince bu kayıtlar da silinir. ADR-0051 karar 4 buna göre daraltıldı (ADR-0051 eki).
- **"SkyMail'in kendi Keycloak grup çözümü" reddi haber gönderimi içindir.** Panelin grup gönderimi üyeleri Keycloak'tan çözmeye devam eder. Ama duyuru akışındaki her alıcı gönderim anında core'a sorulur (ADR-0072 karar 3).

## Ek (2026-10-24): sponsor teşekkürü postada olabilir, tanıtım yalnız izin verene gider (ADR-0062 eki)

"Sponsorlu içerik postada" açık sorusunun önerisi ("yok; sponsor yalnız web'de") şu kuralla değişir (avukat cevabı 13, Yusuf 2026-10-23; KVKK Aydınlatma Metni s6 §5.10):

- **Asıl amacı bilgilendirme olan haber ya da duyuru,** kısa bir sponsor teşekkürü ya da sponsor logosu taşıyabilir. Bu tanıtım sayılmaz. Posta, tercih ve ekip aboneliğine göre bütün alıcılara gider.
- **Asıl amacı tanıtım olan içerik** (indirim kodu, şirket iş ilanı, satış, çekiliş) yalnız tanıtım izni veren kişiye gider. Kitle, bu kararın kitlesi ile core'daki tanıtım izni listesinin kesişimidir.
- **Tanıtım izni kişi başına tek bir izindir** ve işaretsiz kutuyla alınır (ADR-0062 eki). Ekip ya da kategori başına tanıtım izni yoktur.
- **Gönderimdeki onay kutusu kalır.** Gönderen, postanın asıl amacının tanıtım olmadığını beyan eder; kısa teşekkür ve logo bu beyana engel değildir. Tanıtım postası bu beyanla gönderilemez.

## Ek (2026-10-25): açılma ve tıklama kişi bazında kaydedilir (ADR-0074)

"Sapmalar 5" ("Açılma izleme yok, açık soruya bağlı") kapanır. SkyMail haber ve duyuru postalarının açılmasını ve tıklanmasını kişi bazında kaydeder; dayanak meşru menfaattir, üye Hesap Merkezi'nden itiraz eder, gizli bağlantılar sayılmaz. Kural, kapsam ve süreler ADR-0074'tedir. Bayraklar kapalı başlar; production açılışı ayrı bir karardır.

## Ek (2026-11-08): Leader kendi ekip ağacına Mail onayıyla posta gönderir; devir açılmadan, kendi anahtarıyla

"Nasıl" bölümünün son maddesi Leader'ın kendi ekibine yazıp göndermesini ADR-0065'in güvenlik önkoşuluna bağlamıştı: Privileged grup adından okunuyordu ve `YK` adlı bir alt ekip bütün üyelere gönderme yetkisi verirdi. O önkoşul ADR-0065 karar 6'dır ve production'dadır: Privileged sabit köklerden okunur, başka yerdeki `YK` adlı grup Privileged değildir. Bu ek o maddeyi açar ve sınırlarını yazar.

İstek (Fatih, 2026-11-08): iletişim konsolunda asıl ihtiyaç, ekip liderinin kendi ekibine posta atabilmesi.

Bağımlılık: core'un kişinin ekipleri ucunu Forms'un sahip ekibiyle paylaşan ADR-0075 eki (2026-11-08) önce birleşir; bu ek ona dayanır.

**Yusuf'un kararları (2026-11-08):**

1. **Ekip postası devirden ayrı açılır.** `TEAM_DELEGATION` (ADR-0065) kapalıyken de çalışır; kendi anahtarıyla açılır.
   - Gerekçe: posta Keycloak'a yazmaz, kimsenin yetkisini değiştirmez; liderliği yalnız okur.
   - Devrin açılış önkoşulları (ekip kodu seed'i, rol temizliği, korumalı grup) Keycloak'a yazma riskleri içindir; postayı beklemez.
   - Devrin yazma yetkileri, yönetilen ağaç ve yetenek listesindeki yönetilen ekipler `TEAM_DELEGATION`'a bağlı kalır.
   - Liderliği core söyler. Bu ayrıca sorulmadı; "her şeyi core bilsin" ilkesinden (Fatih ve Yusuf, 2026-11-08) ve ADR-0065 karar 3'ten gelir. Kural ADR-0065'inkidir: Keycloak'taki güncel üyelik (karar 3), `LIDERLER` ve `KOORDINATORLER` tam yol parçası olarak, Privileged sabit köklerden (karar 6). SkyMail liderliği Keycloak'tan ya da token'dan kendisi okumaz. core aynı cevabı Forms'un sahip ekip kararına da verir (ADR-0075 eki); iki ayrı liderlik kuralı yazılmaz.
2. **Kitle yalnız ekip üyeleridir.** Seçilen ekibin ve alt ekiplerinin üyeleri, Leader grupları dahil. Ekip takipçileri (karar 7) bu postayı almaz. Gizli bir alt ekibin postası da yalnız üyelerine gider.
3. **Alt ekip Leader'ı da gönderir.** Her Leader (ya da koordinatör) kendi ekibine ve onun altındaki her alt ekibe gönderebilir; alt ekibin Leader'ı yalnız kendi alt ağacına.
4. **"Ekibim" mevcut gönderim formunda üçüncü kitle seçeneğidir; ekip ağacından çoklu seçim yapılır.**

**Mevcut kararlardan gelenler:**

5. **Her gönderim Mail onayından geçer; onaycı YK'dır.** Leader'ın doğrudan gönderme izni yoktur (karar 5; Yusuf'un 2026-10-23 "lider onayla gönderir" kararı). Bekleyen istek 7 günde düşer.

**Orkestratörün kararları ve öneriler (2026-11-08):**

6. **Anahtar SkyMail'dedir ve varsayılanı kapalıdır** (öneri). Açılışı ayrı bir karardır.
7. **Amaç duyurudur, kategori ekibindir** (orkestratör). Posta `duyuru` akışındadır ve kategorisi ekibinkidir: `team:<grupKimliği>:duyuru`. Gönderen kategoriyi değiştiremez.
   - Tercih karar 6'daki gibidir: "Üst ekibe abonelik alt ekipleri kapsar; kişi bir alt ekibi ayrıca kapatabilir, en özel ayar kazanır." Kişinin o ekip için geçerli ayarı (ekibin kendi ayarı, yoksa en yakın üst ekibinki) kapalıysa posta ona gitmez (ADR-0072 karar 3).
   - Postadaki tek tık çıkış yalnız o ekibin kategorisini kapatır.
   - `islem` amacı ekip postasında yoktur. Zorunlu ekip bilgisi (toplantı değişikliği gibi) kişiye tek tek gider.
   - Ticari içerik yoktur; sponsor tanıtımı ekip postasıyla gönderilmez (ADR-0062 eki).
8. **Çoklu seçimde gönderim kuralı** (orkestratör). Bir onay isteği birden çok ekibi taşıyabilir; YK onu tek istek olarak onaylar ya da reddeder.
   - Bir üst ekip ile onun alt ekibi birlikte seçilirse alt ekip düşer: üst ekip onu zaten kapsar.
   - Kalan her ekip kendi kategorisiyle ayrı bir gönderimdir; kategori her zaman o ekibinkidir.
   - Alıcı başına tek posta: seçilen iki ayrı ekipte olan kişi postayı bir kez, yol sırasında ilk gelen ve kategorisini kapatmadığı ekibin gönderiminden alır. İkisini de kapattıysa almaz.
   - Tekilleştirme kuyruğa alma anında yapılır. Kişi kuyruğa alındıktan sonra o ekibin kategorisini kapatırsa gönderim turundaki denetim (ADR-0072 karar 3) postayı durdurur ve öteki ekibin postası ona artık gitmez; bu bilinen ve kabul edilen bir boşluktur.
9. **Leader'a SkyMail'in liste okuma rolü verilmez** (orkestratör). O rol bütün grupları ve üyelerinin adreslerini açar. Leader ekip listesini alıcı sayısıyla görür.

**Gönderen alıcı listesini görmez, yalnız toplu sayıları görür** (Yusuf, 2026-11-08). Genel kuraldır: ekip postası dahil, bütün panel gönderimlerinde geçerlidir.

- SkyMail bugün onaylı bir gönderimi isteyen kişinin gönderimi sayar (`SentBy` isteyendir) ve göndereni kendi gönderiminin alıcılarını adı, adresi ve açma-tıklama bilgisiyle okutur (`GET /mail_tasks/{id}/tracking/recipients`; ADR-0074 karar 9'daki "panel gönderiminin kendi göndereni"). Bu karar o istisnayı varsayılan olarak kapatır.
- Gönderen kendi gönderiminin toplu sayılarını görür (gitti, atlandı, hata; takip açıksa açılma ve tıklama toplamları, ADR-0074 karar 9'un 10 kişi eşiğiyle).
- Kişi kişi alıcı listesi yalnız kişi bazında takip okuma rolü olanlara açıktır (`skymail:mails:tracking:read`: ADMIN, YK ve DK; ADR-0074 karar 9 aynen geçerlidir, yalnız gönderen istisnası kapanır).
- SkyMail'de bir ayar anahtarı bu kuralı değiştirebilir; varsayılanı "yalnız sayı"dır.
- Bunun için ADR-0074 karar 9'a bir ek ve SkyMail'de bir bilet gerekir (gönderen istisnası anahtara bağlanır, rapor ekranı buna uyar).
- Gönderim formu da alıcıları göstermez, yalnız sayıyı gösterir.

Nasıl:

- **core.** Kişinin ekipleri için bir iç uç: Leader olduğu ekipler ve altlarındaki her alt ekip, üyesi olduğu öteki ekipler. Kimlik, yol, kod, görünen ad ve rol döner; kişi, adres ve sayı dönmez. Keycloak'tan taze okunur, kısa önbellek. Yalnız servis hesapları çağırır: SkyMail ve Forms, bugün ellerinde olan rollerle, her rol kendi ürününe bağlı. Kenardan 404.
- **SkyMail.**
  - Kişinin ekip listesini core'dan alır, her ekip için alıcı sayısını kendisi hesaplar.
  - Onay isteği bir Keycloak grubunu hedefliyorsa ve grup isteyenin Leader olduğu ağaçtaysa liste okuma rolü aranmaz. `LIDERLER` grubunun kendisi, ağaç dışındaki bir grup ve Privileged kökler seçilemez.
  - Liderliğe istek gönderilirken, yeniden gönderilirken ve **onay anında** yeniden bakılır. Onay anında isteyen artık o ekibin Leader'ı değilse o ekip gönderilmez. Çok ekipli istekte yalnız liderliği kaybedilen ekip düşer, ötekiler gider; hiçbiri kalmazsa istek gerekçeyle reddedilir.
  - core'a ulaşılamıyorsa ekip postası gönderilmez; SkyMail kendi okumasına düşmez. Onay anında ulaşılamazsa istek beklemede kalır, onay sonra yeniden denenir.
  - **Serbest duyuruda şablon okuma rolü aranmaz (dar istisna).** Mail onayı isteyenin gönderdiği şeyi okuyabilmesini ister (Yusuf, 2026-09-24); bugün bu, şablon için `skymail:templates:read` demektir. Ekip postasında serbest duyuru çerçevesi (`free.basic`) seçildiğinde bu rol aranmaz: içeriği gönderen kendisi yazar, okuyacağı başka bir şey yoktur. Yayımlanmış bir şablonla gönderim yine rol ister; istisna başka çerçeveye ve ekip postası dışındaki isteklere uygulanmaz.
  - **Koltuk rolden değil core'un liderlik cevabından gelir.** Ekip postası rotaları skymail-backend'de `/v1`'in `skymail:access` kapısından önce kendi zincirine alınır: kişinin ekip listesi (`/v1/me/team_audiences`), ekip hedefli onay isteğini gönderme ve yeniden gönderme, onaycının geri gönderdiği isteği kabul ve ret (`accept`, `decline`), kişinin kendi istek listesi ve detayı, serbest duyuru önizlemesi. Zincir `skymail:access` taşıyanı ya da core'un cevabında en az bir `leader` satırı olanı geçirir (60 sn önbellek). Hesap erişim kapısı (`AccountAccessGate`) bu zincirde de çalışır: devre dışı ya da erişimi kapatılmış hesap rolsüz yoldan da giremez. core'a ulaşılamazsa yalnız ekip postası 503 olur, SkyMail'in geri kalanı etkilenmez. Emsal: `/v1/me/inbox` ve `/v1/me/email-delivery` da `skymail:access` kapısından önce kendi zincirindedir. Keycloak'ta rol değişmez, Keycloak yayını gerekmez.
  - **Alıcılar SkyMail'in Keycloak grup çözümüyle bulunur.** Bu, "Nasıl" bölümündeki "Kitleye core karar verir" maddesinden ("kendi grup çözümünü bu iş için kullanmaz") bir sapmadır. Bu kararın 2026-10-21 eki buna izin verir: o ret haber gönderimi içindir, panelin grup gönderimi üyeleri Keycloak'tan çözmeye devam eder, ama duyuru akışındaki her alıcı gönderim anında core'a sorulur (ADR-0072 karar 3). Ekip postası bu yolu kullanır; tercih, hesap durumu ve kategori kararı yine core'dadır.
- **Arayüz.** "Ekibim" seçeneği, ekip ağacı seçici, alıcı sayısı. Birincil düğme "Onaya sun"dur. `skymail:access` taşımayan ama ekip listesi boş olmayan kişi "Erişimin yok" yerine sade bir "Ekibime gönder" görünümü görür. Rolsüz Leader şablon okumaz, serbest duyuru yazar.

Sınırlar:

- Leader yalnız kendi ağacına gönderir.
- Leader'ın kendi onaylı gönderiminin sonuç ekranı (gitti, atlandı, hata sayıları) sonraki iştir; kişi bazında görünüm Leader'a açılmaz (yukarıdaki genel kural).

Endüstri karşılaştırması:

- **Uyanlar:** sahiplik dizindeki güncel üyelikten okunur (Entra, Exchange). Grup alt grupları kapsar. Bekleyen istek 7 günde düşer (Google Groups). Üye ekip ekip çıkabilir (Google Groups'taki kişisel teslim ayarı). Gönderme izni yoksa istek onaya düşer, onaylama ayrı izindir (HubSpot).
- **Sapmalar:**
  1. Grup sahibi kendi grubuna onaysız yazamaz. Exchange'de sahipler moderasyondan muaftır, Google Groups'ta yönetici yazar. Bizde her gönderim YK onayından geçer.
  2. Onay kapısı kişiye bağlıdır, kitleye değil (HubSpot gibi; Exchange'in kitle başına moderasyonu gibi değil).
  3. Dağıtım grubu üyesi Exchange'de çıkamaz; bizde çıkabilir, çünkü duyuru meşru menfaate dayanır (ADR-0062).
  4. **Koltuk rolden değil liderlikten gelir.** Entra'da bir uygulamaya giriş kullanıcıya ya da gruba atamayla (app role assignment) gelir. Bizde rolsüz Leader'ın SkyMail'in ekip postası kısmına girişi core'un liderlik cevabından türetilir; Keycloak'ta rol eşlenmez. Neden: rolü bütün seviyelerdeki Leader gruplarına eşlemek ADR-0076 karar 4'ü delerdi ve tek seferlik seed sonradan açılan alt ekipleri kaçırırdı.
  5. **Alıcıları posta aracının grup çözümü bulur** (yukarıda, "Nasıl"). Haber gönderiminde kitleyi core çözer; ekip postasında SkyMail Keycloak grubundan çözer, core her alıcıyı gönderimde denetler (2026-10-21 eki).
  6. **Gönderen kendi gönderiminin alıcılarını görmez, yalnız toplu sayıları görür.** ADR-0074 karar 9 panel göndereninin kişi bazında görünümünü açıyordu; Yusuf'un 2026-11-08 kararı bunu varsayılan olarak kapatır, kişi bazında liste yalnız takip okuma rolüyle açılır. Varsayılanı SkyMail'deki bir anahtar değiştirebilir.

Kaynaklar:

- https://learn.microsoft.com/en-us/exchange/recipients-in-exchange-online/moderated-recipients-exo/configure-moderated-recipients-exo
- https://support.google.com/groups/answer/2464975?hl=en
- https://knowledge.hubspot.com/marketing-email/request-approval-to-send-a-marketing-email
- Ayrıntılı inceleme: sky_lab_genel `notes/iletisim-ekip-lideri-gonderim-20261108.md`.
