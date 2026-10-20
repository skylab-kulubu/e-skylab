---
status: accepted
---

# Geri bildirim formu bilet yazmaz; etkinliğe ya da oturuma bağlanır, yoklaması alınanlara kişiye özel bağlantıyla gider, cevaplamayana bir hatırlatma gider

Bugün etkinliğin her formu bir Form slot. Başvuru formu ve ek formlar (CTF, yarışma, özel adlı yuvalar) aynı kuralla çalışıyor:

- Forms her kabul edilen cevabı core'a bildiriyor. Rapor cevap kimliğini, durumu, giriş yapmışsa kullanıcıyı, misafirse adı ve e-postayı taşıyor. Forms etkinliği bilmiyor.
- core formu anan **her** etkinliğe bilet yazıyor: giriş yapana REGISTERED, misafire GUEST. Hiçbir etkinlik formu anmıyorsa yine 2xx döner, Forms yeniden denemez.
- Kayıt kapanışı (ADR-0066 eki) ve iptal bu yolu daraltıyor, ama form türüne bakmıyor. Bitmiş etkinliğe gelen cevap bilet yazmaya devam ediyor.

Geri bildirim formu bugün ek form olarak bağlanırsa etkinlik bittikten sonra gelen her cevap bilet yazar. Katılan kişide bilet zaten var, bir şey değişmez. Katılmayan biri linki bulup doldurursa ona yeni bir bilet yazılır. Bu yüzden geri bildirim formu güvenle bağlanamıyor. Organizatörlerin bugünkü yolu elle: panelde "Giriş yaptı" süzgeciyle katılımcıları seçmek ve linki SkyMail'den postalamak.

Yusuf'un isteği (2026-10-20): etkinliklere geri bildirim formu bağlanabilsin.

Karar (Yusuf, 2026-10-20):

1. **Geri bildirim formu etkinlikte ayrı bir alandır ve bilet yazmaz.** Etkinlik başına bir form. Her oturuma da isteğe bağlı ayrı bir form bağlanabilir.
2. **Oturumların nasıl değerlendirileceğini düzenleyen seçer** (etkinlikte Feedback mode): her oturuma ayrı form, ya da tek etkinlik formunun içinde oturumların tek tek sorulması.
3. **Kitle yoklaması alınanlardır, misafirler dahil.** Etkinlik formu etkinliğin herhangi bir oturumunda Check-in'i olan bilet sahiplerine, oturum formu o oturumda Check-in'i olanlara gider.
4. **Gönderim otomatiktir:** hedef (etkinlik ya da oturum) bittikten 2 saat sonra. Panelde varsayılan işaretli bir kutu ve "Şimdi gönder" vardır.
5. **Cevaplamayanlara tek bir hatırlatma gider,** ilk postadan 3 gün sonra. Bunun için core kimin cevapladığını bilir: giriş yapmış kişiyi kullanıcısından, misafiri postadaki kişiye özel davet kodundan.
6. **Linki olan herkes doldurabilir.** Yanıtlayan kısıtı konmaz; hatırlatma eşlemesi kişiye özel bağlantıyla yapılır.
7. **Cevaplar kişiyle bağlı kalır.** Arayüzde "anonim" denmez; aydınlatma metnine üyelerin geri bildirim cevapları eklenir.
8. **`event_with_sessions` kipinde** düzenleyen formun biçimini seçer: herkes bütün oturumları görür ve "Katılmadım" diyebilir, ya da kişi katıldığı oturumları kendisi işaretler. Bağlantıdan ön işaretleme ilk sürümde yoktur.
9. **Kişi başına günde tek posta.** Kişinin o gün katıldığı oturumların formları tek postada gider, günün son katıldığı oturumunun bitişinden 2 saat sonra. Hatırlatma da tek postadır.
10. **Form kapanınca bekleyen hatırlatma iptal olur,** form sonra yeniden açılsa da gitmez.

Nasıl:

- **Feedback mode** etkinliğin bir alanıdır: `event` (varsayılan; tek etkinlik formu), `per_session` (oturum başına isteğe bağlı form; etkinlik formu da genel değerlendirme için isteğe bağlı kalır) ya da `event_with_sessions` (tek etkinlik formu, oturumlar içinde sorulur). Kip `per_session` değilken oturum formları silinmez, ama postaları gitmez. Oturumların hangi biçimde sorulacağı (karar 8) core'da saklanmaz, formun kendi yapısıdır.
- **Alanlar.** Etkinlikte `feedbackMode`, `feedbackFormUrl`, `feedbackFormAlias` ve `feedbackAutoSend` (varsayılan açık). Oturumda `feedbackFormUrl`, `feedbackFormAlias` ve `feedbackAutoSend`. Gövdede gönderilmeyen alan korunur. Oturum güncellemesi bugün bütün gövdeyle yapıldığı için oturumdaki alanlar işaretçidir: eski bir istemci oturumu kaydederken formu silemez.
- **Bilet yazmaz.** Geri bildirim formu "bu etkinlik bu formu anıyor" listesine girmez. Cevabı hiçbir etkinliğe bilet yazmaz; core her durumda 2xx döner, Forms yeniden denemez.
- **Bir form tek yerde.** Bir form aynı anda yalnız bir yerde olabilir: bir etkinliğin başvuru ya da ek formu, bir etkinliğin geri bildirim formu ya da bir oturumun geri bildirim formu. Aksi 409'dur. Başvuru formlarının kendi aralarındaki bugünkü serbestlik değişmez.
- **Kısa link.** Geri bildirim formunun Form link'ini etkinlik yönetir, başvuru formunda olduğu gibi. Arşivde link bırakılır.
- **Bitiş zamanı.** Etkinlik için ADR-0066'daki bitiş (bitiş tarihi, yoksa başlangıç + 1 gün). Oturum için oturumun bitişi, yoksa günün bitişi, yoksa etkinliğin bitişi. Hiçbiri yoksa otomatik gönderim olmaz, yalnız "Şimdi gönder" çalışır.
- **Durum.** Taslakta form bağlanabilir, posta gitmez. İptal edilen etkinliğe ya da oturuma posta ve hatırlatma gitmez, kuyruktakiler düşer. Kayıt kapanışı geri bildirim formunu etkilemez.
- **Feedback invite.** Her gönderimde alıcı (bilet) ve hedef başına bir davet satırı tutulur: bilet, etkinlik, varsa oturum, form, kişiye özel kod, gönderim, hatırlatma ve cevap zamanları. Kod 128 bit rastgeledir.
  - Postadaki bağlantı kısa link değildir, doğrudan form adresidir ve kodu taşır. Kısa link yalnız takip etiketlerini forma taşır ve her tıklamayı kaydeder (Short-link hit); kişiye özel kod oraya düşmemeli. Posta tıklamaları bu yüzden kısa link sayılarında görünmez.
  - Kod düz saklanır, çünkü hatırlatma aynı bağlantıyı yeniden gönderir. Kodun tek yetkisi "bu bilet cevapladı" işaretini koymaktır; sızan bir kod en çok bir hatırlatmayı engeller.
  - Forms raporu geri bildirim formu için gelince core önce davet koduna, kod yoksa giriş yapmış kullanıcıya bakar. Hiçbiri eşleşmezse bir şey yazılmaz. Bekleyen ve kabul edilen cevap "cevapladı" sayılır.
  - Misafir yalnız davet koduyla eşlenir. Forms kodu cevapla saklayıp rapora koyana kadar misafir "cevapladı" sayılmaz ve hatırlatma alır; hatırlatma metni bu yüzden "henüz doldurmadıysan" der.
  - Davet satırı ilk gönderimden 90 gün sonra silinir; hedefte yalnız sayılar kalır. Bilet silinince satır da gider.
- **Hatırlatma.** İlk postadan 3 gün sonra, tek sefer, cevaplamayanlara, aynı kod ve aynı bağlantıyla. Hedef iptal edildiyse, form hedeften kaldırıldıysa ya da otomatik gönderim kapatıldıysa gitmez. Form kapanınca (panelin Form açık/kapalı anahtarı ya da Forms'un haberi) hedefin bekleyen hatırlatmaları kalıcı olarak iptal olur.
- **Gönderim.** core'un mevcut kuyruk ve işçi deseni (ADR-0066 ekindeki iptal postası gibi): satır kişi verisi taşımaz, adres gönderim anında okunur. İki SkyMail System template'i: `core.feedback-request` ve `core.feedback-reminder`. Değişkenler ad, etkinlik adı ve öğe listesidir (her öğe başlık ve bağlantı; tek hedefte tek öğe). Kitlede hiç Check-in yoksa posta gitmez.
- **Kopya (ADR-0066).** Feedback mode kopyalanır. Etkinlik ve oturum geri bildirim formları kopyalanmaz; kopya sayfasında her biri için "geçen seferin formundan yeni form" eylemi olur. Form slot'lardaki kuralın aynısı: kısa link forma aittir ve formu iki etkinlik anamaz.
- **Posta türü.** Katılınan etkinlikle ilgili bir hizmet postasıdır, duyuru ya da davet değildir; misafire de gider (ADR-0062'nin Contact consent kuralına girmez). Açılma ve tıklama takibi yoktur.

## Consequences

- **Forms değişmeden çalışır.** Geri bildirim formları 2xx alır, üyeler kullanıcılarıyla eşlenir. Forms'tan istenenler (Fatih'in reposu): geri bildirim amaçlı handoff (zorunlu ad, soyad ve e-posta alanı yok, kişi başı tek cevap), davet kodunun cevapla saklanıp rapora eklenmesi, form kapanınca core'a haber, isteğe bağlı oturum sorularının panelden üretilmesi. Bunlar gelene kadar misafir hatırlatmayı her durumda alır ve yalnız panelin anahtarı hatırlatmayı iptal eder.
- **Eski istemciler.** Yeni alanlar yalnız eklenir. Oturumdaki alanlar gönderilmezse korunur; sky-app oturum kaydederken formu silmez. sky-app'in geri bildirim bağlantısını göstermesi için sözleşme notu Mobile Lab'e ayrıca verilir.
- **Organizatörün elle yolu kalır.** "Giriş yaptı" süzgeci ve SkyMail postası bugünkü gibi çalışır; yoklama alınmamış etkinlikte tek yol odur.
- **Takip.** Posta tıklamaları kısa link sayılarına girmez. Hedefte gönderilen ve cevaplayan sayıları görünür.
- **CONTEXT.md'de değişenler:** yeni terimler Feedback form, Feedback mode, Feedback invite. Form slot: geri bildirim formu bir Form slot değildir, bilet yazmaz.

## Endüstri uygulamasıyla karşılaştırma

**Uyanlar:**
- Etkinlik bitince geri bildirim postası kendiliğinden gider ve düzenleyen bunu etkinlik başına kapatabilir; gönderim zamanı ayarlanabilir (Luma "Post-Event Feedback").
- Oturum başına ayrı değerlendirme formu (Whova session feedback forms).
- Oturum yoklaması QR ile alınır ve kimin hangi oturumda olduğu bilinir (Whova session check-in).

**Sapmalar (hepsi):**
1. **Soruları ürün değil Forms tutar.** Luma tek bir emoji puanı ve yorum sorar; bizde düzenleyen formu Forms'ta kendisi kurar.
2. **Kitle Check-in'den gelir, bilet sahiplerinin hepsi değil.** Luma postayı etkinliğin konuklarına gönderir; bizde yalnız yoklaması alınanlara gider.
3. **Kişiye özel bağlantı ve tek hatırlatma** ilk sürümde var; uygulama içi değerlendirme (Whova) ilk sürümde yok, sky-app için sözleşme notu yazılır.
4. **Gecikme sabit 2 saattir** (Luma'da varsayılan bitişte hemen, zaman ayarlanabilir). Panelde "Şimdi gönder" ve otomatik gönderimi kapatan kutu var.

## Considered Options

- **Geri bildirim formunu ek form olarak bağlamak:** her cevap bilet yazar; katılmayan biri linki doldurursa bilet alır.
- **Form slot'lara rol vermek (başvuru, yarışma, geri bildirim):** bilet yazma kuralı yuva rolüne bağlanırdı; eski istemciler rolü bilmez ve yazarken rolü silebilir. Ayrı alan daha dar ve okunur.
- **Kişiye özel kodu kısa linkten geçirmek:** kod Short-link hit kayıtlarına düşer ve kısa link yalnız takip etiketlerini taşır.
- **Kodu şifreli ya da özetli saklamak:** hatırlatma aynı bağlantıyı yeniden gönderemezdi; kodun yetkisi yalnız bir hatırlatmayı engellemek.
- **Yanıtlayan kısıtı (yalnız katılanlar doldurabilir):** Forms'ta böyle bir ayar yok ve misafirin hesabı yok. Linki olan herkes doldurabilir (karar 6).
- **Oturum başına ayrı posta:** çok oturumlu bir günde kişiye beş posta gider. Yusuf günde tek postayı seçti (karar 9).
- **Hatırlatmasız ilk sürüm:** Yusuf hatırlatmayı ilk sürümde istedi (karar 5).
