---
status: accepted
---

# Etkinliğin durumu saklanır (taslak, yayında, iptal) ve `active` ondan türer; kopya yapıyı alır, insanları almaz, taslak başlar

Bugün etkinliğin tek durum alanı `active`. Elle açılıp kapanan bir bayrak ve iki işi karıştırıyor: "herkese göster" ve "etkinlik sürüyor". Kim okuyor:

- Girişsiz `GET /v1/events` ve `/v1/events/active` yalnız `active=true` etkinlikleri döndürüyor.
- Sertifika "Katılımı kapat" (Attendance finalization) etkinlik aktifken 409 veriyor. Organizatör sertifika için etkinliği elle Pasif yapıyor.
- Yarışmacı yalnız aktif etkinliğe ekleniyor.
- `PUT`/`PATCH` gövdesi `active` göndermezse etkinlik `false` oluyor.
- sky-app etkinlik oluşturuyor ve düzenliyor, `active`'i "Başvurular açık" diye gösteriyor ve her yazmada gönderiyor.

Taslak, iptal ve kopya yok. Yarım kurulmuş bir etkinlik kaydedildiği anda görünür. Etkinlik silinince (arşiv) biletli olsa da kaybolur. Her yıl tekrarlanan bir etkinlik (Gecekodu, ARTLAB) sıfırdan kuruluyor.

Kopyanın en riskli yeri kayıt formu. Bir Form'un aynı anda tek etkin kısa linki var ve formu anan etkinlik o linki yönetiyor (Form link). Aynı formu anan ikinci bir etkinlik kaydedilince link ona geçiyor. Kabul edilen bir Forms cevabı da formu listeleyen her etkinliğe bilet yazıyor. Kopya aynı formu ansaydı kaynağın linkini çalardı ve her cevap iki etkinliğe birden bilet yazardı.

Production'da 5 etkinlik var, hepsi geçmişte; geçişin veri riski küçük, asıl risk eski istemcilerde (sky-app'in yayındaki sürümü).

Karar (Yusuf, 2026-10-12):

1. **Durum da kopyalama da şimdi gelir.** Hub'daki admin paneli araştırmasının "kopyalama sonra, durum için `active` yeter" önerisi geçersiz.
2. **Bitmiş etkinlik girişsiz listelerden kendiliğinden düşer.** `active` = yayında ve henüz bitmemiş.
3. **Yayındaki ya da iptal edilmiş etkinliği yalnız YK ve ADMIN kaldırır,** panelde "Arşivle" adıyla ve ayrı onayla. Taslağı organizatör siler.

Nasıl (spec'ten):

- **Saklanan tek durum alanı `status`'tur:** `draft`, `published` ya da `cancelled`. "Bitti" saklanmaz, tarihten türer: etkinliğin bitişi `end_date`, yoksa `start_date` + 1 gün; ikisi de yoksa etkinlik tarihsizdir ve bitmez. Arşiv (Deletion lifecycle) ayrı bir eksendir, durumla birleşmez.
- **`active` kalkmaz, türer:** `active = status = published` ve etkinlik bitmemiş. JSON'da aynı ad ve tiple döner; `?active=true` ve `/v1/events/active` aynı ifadeyle süzer. `PUT`/`PATCH` gövdesindeki `active` ve `status` yok sayılır; durum yalnız geçiş uçlarıyla değişir. Böylece eski bir istemcinin gövdesi etkinliği gizleyemez ya da yayınlayamaz.
- **Geçişler:**
  - taslak → yayında: düzenleyebilen yapar; ad, konum ve başlangıç tarihi dolu olmalı.
  - yayında → taslak: yalnız hiç bilet ve giriş yokken.
  - yayında → iptal: bitmemiş etkinlikte. İptal son durumdur.
  - Taslak iptal edilmez, silinir.
  - Geçişler idempotenttir; yarışta 409 döner.
- **Taslağı yalnız düzenleyebilenler görür.** Düzenleyebilen kural etkinliğin yetki kuralından (`allowEvent`) okunur; ADR-0065'le üst ekip Leader'ları da bu kümeye kendiliğinden girer. Herkese açık uçlar, sky-app, site ve kapı için taslak yoktur (404; var olduğu bile söylenmez). Parametresiz listelerde düzenleyene de gelmez, panel ayrıca ister. Kendi kendine kayıt ve giriş yazılmaz. İki istisna: düzenleyen panelden kişi ekleyebilir, ve taslağa bağlı bir formun kabul edilen cevabı bilet yazar (yazılmasaydı Forms bir kez gönderdiği için cevap kaybolurdu).
- **İptal edilen etkinlik görünür kalır** (`status=cancelled`, `active=false`), ama girişsiz `active` listelerinde yoktur. Yeni kayıt, giriş, sertifika verme ve finalize kapanır; kuyrukta bekleyen sertifika işleri durur. Var olan biletler ve verilmiş sertifikalar geçerli kalır. Forms cevabı iptal edilen etkinliğe bilet yazmaz, ama core yine 2xx döner ki Forms yeniden denemesin. Giriş uçları bugünkü "oturum kapalı" kodunu, nedenini ekleyerek döner; site ve kapı ekranları değişmeden çalışır.
- **Silme (arşiv) yalnız taslaktadır**, karar 3'teki YK ve ADMIN istisnasıyla.
- **Yeni etkinlik:** `POST /v1/events` isteğe bağlı `status` alır; göndermeyen eski istemci için etkinlik yayında açılır (bugünkü davranış).
- **Attendance finalization yine elle bir eylemdir.** Kapısı `active=false` yerine "yayında ve bitti" olur: etkinlik bitince "Katılımı kapat" açılır, Pasif'e çevirme adımı kalkar. Taslak ve iptalde kapalıdır.
- **Kopya tek işlemli bir core ucudur** (`POST /v1/events/{id}/copy`, istemcinin ürettiği kimlikle idempotent). Kopya her zaman taslak başlar.
  - **Gelir (yapı):** açıklama, konum, sahip ekip, kapasite, sıralama ve ödül metni, kapak, sertifika kuralı, yetki varsa etkinliğe özel sertifika şablonu bağlaması, arşivsiz günler ve oturumlar. Oturumların iptal bayrağı sıfırlanır. Sezon, yeni başlangıcı kapsayan sezondur.
  - **Gelmez (insanlar ve geçmiş):** bilet, giriş, sertifika, yarışmacı, mail listesi, galeri ve dosyalar, LinkedIn bağlantısı. Kapı görevlileri varsayılan olarak gelmez; atama hakkı olan isterse gelir.
  - **Kayıt formları ve kısa linkleri gelmez;** kopyanın Form slot'ları boş başlar. Kısa link Form'a aittir (Form link).
  - **Tarihler birlikte kayar:** seçilen yeni başlangıçla kaynağın başlangıcı arasındaki fark etkinliğe, günlere ve oturumlara eklenir; süreler ve aralar korunur. Hesap Europe/Istanbul saatiyle yapılır.
  - Yetkisi olmayan parça atlanır, kopya yine olur ve yanıt atlananları söyler.
  - Taslak, yayında, iptal ve bitmiş etkinlik kopyalanabilir; arşivli etkinlik kopyalanamaz.

## Consequences

- **Eski istemciler değişmeden çalışır.** `active` aynı ad ve anlamla döner; yeni alanlar (`status`, yayın ve iptal zamanları, iptal açıklaması, `copiedFromEventId`) yalnız eklenir. Taslaklar eski istemciye gelmez; iptal edilenler `active=false` gelir.
- **sky-app'in "Başvurular açık" anahtarı etkisizleşir.** Gönderdiği `active` yok sayılır; Mobile Lab anahtarı kaldırana kadar böyle kalır. sky-app'in oluşturduğu etkinlik yayında açılır. Yayındaki etkinliği silmeye çalışırsa 409 alır. Sözleşme notu yayından önce Mobile Lab'e verilir.
- **Yayın sırası.** core'un durum alanı ile panelin durum eylemleri aynı hafta çıkar; aksi halde panelin "Aktif" anahtarı arada etkisiz kalır. Silmenin taslakla sınırlanması panelin yeni "Sil" kuralıyla birlikte çıkar.
- **Davranış farkı.** Bitmiş etkinlikler girişsiz listelerden düşer (karar 2). Yarışmacı ekleme `active` yerine `status=published`'a bakar; bitmiş etkinliğe sonuç girilebilir. Yarışma modülü (ADR-0068) bu kuralı yeniden yazabilir.
- **`events.active` sütunu ilk sürümde silinmez,** kod okumaz. Geri dönüşte eski kod eski bayrakla çalışır; arada açılan taslaklar eski koda göre gizli kalır. Sütun bir yayın döngüsü sonra düşer.
- **Kopyadan sonra kayıt formu.** Kopyanın sayfası kaynağın formundan **yeni** bir form açmayı önerir (Skyforms'un mevcut "bu formdan başla" akışı). Yeni form, yeni link: çift bilet ve link çalma olmaz. Forms'ta değişiklik gerekmez.
- **Saklama.** ADR-0062'nin "etkinliğin sonu" çapası değişmez.
- **CONTEXT.md'de değişenler:**
  - Yeni terimler: Event status, Event copy.
  - Event: `active` saklanmaz, türer.
  - Attendance finalization: kapı "etkinliğin bitmesi"dir, "etkinliği pasif yapmak" değil; finalize yine elle.

## Açık

Yusuf'a soruldu ya da sorulacak; cevap gelene kadar spec'in önerisi uygulanır.

- **İptal bildirimi:** öneri, v1'de elle: iptal diyaloğu mevcut "Katılımcılara mail" akışını açar. Otomatik toplu bildirim core'dan SkyMail'e kuyruk ister.
- **İptal geri alınabilir mi:** öneri, v1'de hayır. Gerçek ihtiyaçta iptal edilen etkinlik kopyalanır.
- **İptalde kayıt formu:** öneri, panel "Skyforms'ta kapat" bağlantısı verir, karar operatörün. Forms'a yeni uç gerekmez.
- **Başka ekibe kopya:** öneri, v1'de yok; kopya kaynağın ekibinde açılır, ekip sonra Ayarlar'dan değişir.
- **Kayıt formu nasıl taşınır:** öneri, kopya formsuz açılır ve Skyforms'un "bu formdan başla" akışı tek tıkla açılır. Seçenek: Forms'ta sunucu tarafında form çoğaltma ucu (Fatih'in reposunda yeni uç).
- **Yeni etkinlik taslak mı başlar:** öneri, panel her zaman taslak açar.

## Endüstri uygulamasıyla karşılaştırma

**Uyanlar:**
- Kopyada yapı gelir, insanlar ve geçmiş gelmez (Luma, Eventbrite, Tito, Bevy, Swapcard, CampusGroups); gün ve oturumlar gelir (Tito).
- Kopya taslak başlar (Tito, Bevy).
- Tarihler göreli kayar (Tito); yeni tarih sorulur (Swapcard).
- Durumlar: Bevy'de live, draft, completed, canceled; Eventbrite'ta draft, live, started, ended, canceled. "Bitti" Eventbrite API'sinde de saatten türer.
- Yayından taslağa geri alma (Eventbrite'ın "unpublish").
- İptal edilen etkinlik silinmez, raporlar için kalır; yalnız taslak silinir (Bevy).

**Sapmalar (hepsi):**
1. **Kayıt formu kopyayla gelmez.** Tito soruları kopyayla getirir. Bizde sorular Skyforms'ta ve bir formun tek linki var; kopyadan sonra tek tıkla yeni form açılır (Eventbrite'ın ayrı "içe al" adımına yakın).
2. **Luma kopyayı doğrudan yayınlar;** bizde taslak.
3. **Tito sabit +1 yıl kaydırır;** bizde tarih sorulur, +1 yıl yalnız varsayılan.
4. **Taslağa geri alma yalnız kayıt ve giriş yokken.** Eventbrite'ta bilet satılmış etkinlik de geri alınabiliyor; bizde biletli bir etkinliğin gözden kaybolması kapıyı ve sky-app'i bozar.
5. **İptalde otomatik e-posta yok** (Luma gönderir; Bevy ve Eventbrite organizatöre bırakır). Açık soru.
6. **Silme zaten arşivdir** ve geri yüklenebilir (Deletion lifecycle); Bevy'de taslak silme geri alınamaz.
7. **Toplu kopya ve görünürlük düzeyleri yok** (Luma'nın 30'lu kopyası, Tito'nun public/unlisted/secret).

## Considered Options

- **`active`'i olduğu gibi bırakmak, kopyayı sonraya almak** (araştırmanın önerisi): Yusuf ikisini birden istedi (karar 1).
- **"Bitti"yi saklanan bir durum yapmak:** her gece çalışan bir iş ya da elle "bitir" düğmesi ister; ikisi de elle çevrilen bayrak sorununu geri getirir.
- **`active` = yalnız yayında (bitmiş de görünür):** sky-app listesinde geçmiş etkinlikler birikir ve sertifika kapısı ayrı bir tarih denetimi ister. Yusuf bitmişin düşmesini seçti (karar 2).
- **`active`'i kaldırıp yalnız `status` döndürmek:** sky-app `active`'i bool olarak okuyor; alan kalkarsa ya da tipi değişirse uygulama bozulur.
- **Kopyada formu aynen bağlamak:** kaynağın kısa linki kopyaya geçer ve her cevap iki etkinliğe birden bilet yazar.
- **Yayındaki etkinliği kimsenin silememesi:** production'daki etkinliklerin çoğu deneme; temizlik için bir yol kalmalı. Yusuf YK ve ADMIN'e "Arşivle" bıraktı (karar 3).
- **Yayındaki etkinliği organizatörün silebilmesi:** liderin biletli etkinliği yanlışlıkla yok etmesine açık (karar 3).
