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

Karar (Yusuf, 2026-10-12):

1. **Haber ve duyuru iki türdür ve her özellik ikisinde de vardır.** Yazma yerleri: ana sitenin inscribed çekmecesi, yönetim paneli ve SkyApp. Tek kaynak inscribed'dır; yetkiye inscribed karar verir (ADR-0056).
2. **Üyeye ve ekibe özel web duyurusu şimdi gelir.** Görünürlük kayıt bazındadır ve gerçek bir erişim sınırıdır: herkes, yalnız Member'lar ya da belirli ekipler (alt ekipleriyle). Kural inscribed'da, sunucuda uygulanır. Herkese açık uçlar özel kaydı hiçbir yoldan döndürmez (liste, slug, arama, sayılar); sızıntı testleri bunu kanıtlar. Site ve SkyApp giriş yapmış kişinin token'ıyla okur, kendi süzgecini yazmaz.
3. **Özel kayıt önkoşulu.** inscribed'ın kayıt bazında görünürlüğü production'a çıkıp sızıntı testleri geçmeden özel kayıt yazılmaz; "yalnız Member'lar" ve "belirli ekipler" değerleri koleksiyon tanımına ondan sonra girer.
4. **"E-postayla gönder" ekranı SkyMail'dedir.** Panel ve site oraya bağlantı verir (ADR-0031'deki etkinlik postası gibi).
5. **Gönderen.** Şimdilik YK, DK ve ADMIN tüm üyelere ve ekiplere doğrudan gönderir; başkaları Mail onayıyla gönderir.
6. **Abonelik ekip ekiptir** ("bir kişi her şeyi özelleştirebilmeli"):
   - Kulüp geneli için bir, her ekip için ayrı anahtar vardır.
   - Her kaynakta haber ve duyuru ayrı anahtardır; bir de hepsini kapatan "tümünden çık" vardır.
   - Üst ekibe abonelik alt ekipleri kapsar; kişi bir alt ekibi ayrıca kapatabilir, en özel ayar kazanır.
   - Postadaki tek tık çıkış yalnız o postanın kategorisinden çıkarır.
   - Tercih core'da tutulur, ekranı Hesap Merkezi'ndedir.
   - Zorunlu postalar (giriş kodu, bilet ve öteki işlem postaları) tercihten etkilenmez.
7. **Ekip takibi.** Member, üyesi olmadığı görünür bir ekibi takip edebilir. Varsayılan kapalıdır. Takipçi yalnız herkese ya da tüm Member'lara açık kayıtların postasını alır; ekiplere özel kayıt takipçiye gitmez.
8. **Sitede üye girişi açılır.** yildizskylab.com'da Member giriş yapabilir ve kendisine açık kayıtları görür; tasarımı ve yapımı Kaan'ındır.
9. **Ekip adlandırma ve taşıma.** Ekip adı değişince ya da ekip taşınınca (ADR-0065) özel kayıtların ekip değerini core günceller.

Nasıl (spec'ten):

- **Kayıt alanları.** Tür (`kind`), yayın ve bitiş tarihi, sabitleme bitişi, kapak alt metni, bağlantı düğmesi, görünürlük ve ekipler. Yeni alanların hepsi isteğe bağlıdır ve yokluğun anlamı tanımlıdır; eski kayıtlar ve eski istemciler bozulmaz. Koleksiyonun yolu ve yanıt biçimi değişmez.
- **Gövde** inscribed editörünün ürettiği HTML alt kümesidir; okuyan her yer onu temizler. inscribed güncellemede bütün veriyi değiştirdiği için her yazıcı bütün veriyi okur, yalnız kendi alanlarını değiştirir ve hepsini geri gönderir. Görünürlük eski bir istemcinin güncellemesiyle silinemez; token'lı yanıt paylaşılan önbelleğe girmez; belirsizlikte çağıran anonim sayılır.
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
- **inscribed (öncelikli, Fatih).** Kayıt bazında okuma kuralı: isteğe bağlı token, alt ağaç eşleşmesi, her yan uçta uygulama, önbellek başlıkları. Ayrıca görünürlüğü eski istemcilerin silemeyeceği bir yazma biçimi. Ekip değeri güncellemesi (karar 9) için core'a bir CMS servis hesabı gerekir.
- **core.** Yeni yüzeyler: Duyuru tercihi kaydı ve kişinin kendi uçları, imzalı çıkış sayfası ve ucu, SkyMail'in servis hesabına açık kitle ucu, hesap silme saga'sında yeni bir adım.
- **SkyMail.** Haberden gönderim, öncelik şeridi, hız sınırı, `List-Unsubscribe` ve `List-Unsubscribe-Post` başlıkları, deneme postası, sunucu önizlemesi. Bir System template: haber postası, altlığında çıkış bağlantısıyla.
- **Hesap Merkezi.** "İletişim tercihleri" ekranı: kulüp geneli ve ekipler, duyuru ve haber, ekip takibi, ana anahtar. Kategori bazında çıkış ekranı olmadan gönderim açılmaz.
- **Site ve panel.** Ana sitede haber ve duyuru sayfaları ve üye girişi; kişiye özel sayfalar paylaşılan önbelleğe girmez. Panelde yönetim ekranı ve zengin metin editörü.
- **SkyApp.** Gövdeyi HTML olarak göstermeli ve yazarken bütün veriyi korumalıdır (sözleşme). Güncellenene kadar uygulamadan yapılan düzenleme yeni alanları siler; uygulamadan düzenleme bugün yalnız Privileged'da var ve seyrek.
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
- **News'i yazma yetkisi:** bugün Privileged yazar. Kuralın bir client rolüne taşınması (ADR-0059) Fatih'in onayını bekliyor.

## Endüstri uygulamasıyla karşılaştırma

**Uyanlar:**
- Yazı ile e-posta aynı akışta, e-posta isteğe bağlı (Ghost, Substack, Beehiiv, Anthology Engage).
- Yayından sonraki düzenleme yalnız web'e yansır (Substack, Ghost).
- Deneme postası, canlı alıcı sayısı ve gözden geçirme ekranı (Beehiiv).
- Her postada tek tık çıkış (Ghost; Gmail ve Yahoo'nun toplu gönderici kuralları).
- Bitiş tarihi (CampusGroups) ve öne çıkarmanın bitişi (SharePoint).
- Gerçek erişim kademeleri (Engage) ve bülten başına abonelik (Ghost; CampusGroups'ta grup başına bildirim).

**Sapmalar (hepsi):**
1. **Abonelikte alt ekip kalıtımı.** İncelenen ürünlerde görmedik; ekip ağacıyla tutarlılık için.
2. **Üye için çift onay yok,** çünkü kimlik zaten doğrulanmış.
3. **Kalıcı taslak inscribed'ı bekliyor** (Ghost ve WordPress'te hazır).
4. **Kişi başına tek gönderim ama ikinci kitleye izin** (Ghost yazı başına tek gönderim yapıyor). Açık soruya bağlı.
5. **Açılma izleme yok.** Açık soruya bağlı.

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
