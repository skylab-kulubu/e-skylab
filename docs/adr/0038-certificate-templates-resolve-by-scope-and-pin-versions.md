# Certificate templates resolve by scope and issued certificates pin a version

Certificate-template resolution is Event override → Owner-team default → required SKY LAB default; Gecekodu and AGC are Owner teams, not EventTypes. A template is edited as a draft and publishing creates an immutable version; issuance pins that version, so later edits affect only future Certificates and reissue means revoke plus a new Certificate and serial. External Canva or Figma artwork remains editable in its source and synchronizes into a draft background, while SKY LAB owns the dynamic fields and never accepts arbitrary executable HTML. This keeps brand artwork faithful without building a lossy clone of either editor or allowing historical credentials to drift.

## Ek: etkinliğe özel şablon (2026-11-25)

Karar (Yusuf, 2026-11-25): Event'i düzenleyebilen herkes Event template'i oluşturup yayınlar ve ekip şablonlarından seçer; Event kopyalanınca Event template bağımsız kopya olarak gelir.

- **Bir Certificate template bir Event'e ait olabilir (Event template).** Kayıtta `event_id` doludur; `owner_team` Event'in Owner team'idir ve Event'in Owner team'i değişince onunla değişir. Owner team'i olmayan Event'te `owner_team` boştur ve Event gibi yalnız ayrıcalıklılar yönetir. Etkinlik başına en çok bir etkin Event template vardır. Etkinlik sayfasından ya da Düzenle ekranından oluşturulur. Varsayılan başlangıç o an kullanılan şablonun yayınlanmış düzeninin kopyasıdır (`from: current`); seçilen bir şablondan (`from: <templateId>`) ya da boş düzenden (`from: blank`) de başlatılabilir.
- **Yalnız kendi Event'ine bağlanır.** Ekip ya da kulüp kapsamına, başka bir Event'e bağlanamaz (`template_event_scoped`). Yayınlanınca Event bağı kendiliğinden bu şablona kurulur; taslak hiçbir zaman kullanılmaz. Ekip şablonuna dönmek bağı kaldırmaktır; Event template taslak olarak kalır. Çözüm sırası değişmez: Event bağı, Owner team bağı, SKY LAB varsayılanı.
- **Yetki Event'i düzenleme yetkisini izler.** Event'i düzenleme (Update) yetkisi olan herkes (Owner team ve Co-organizer üyeleri ADR-0092 kurallarıyla dahil) o Event'in şablonunu oluşturur, düzenler, yayınlar ve Event'i ekip ya da kulüp şablonuna bağlar. Seçim için Owner team'in, ortak ekiplerin (ADR-0092) ve kulübün yayınlanmış şablonlarının yalnız kısa görünümü (ad, ekip, sürüm, küçük resim) açılır; düzenleri açılmaz. Ekip ve kulüp şablonlarını düzenleme, sertifika verme, iptal ve Attendance rule yetkileri değişmez.
- **Etkinlik kopyasında bağımsız kopya.** Kaynak Event'in Event template'i varsa kopya Event için bağımsız yeni bir Event template açılır: taslak düzeni aynen; yayınlanmış son sürümü varsa aynı düzen ve varlıklarla sürüm 1 olarak gelir ve kopyaya bağlanır. Kaynak bir ekip ya da kulüp şablonuna bağlıysa bağ bugünkü gibi aynı şablona kurulur.
- **Event template'ler ekip şablonu listesinde görünmez;** Event'le yaşar.
- Verilmiş sertifikalar değişmez; değişiklik yalnız sonraki sertifikaları etkiler (yukarıdaki sürüm sabitleme aynen).

### Endüstri uygulamasıyla karşılaştırma

**Uyanlar:**
- **Accredible.** Tasarımlar kurum düzeyindedir ve her grup (kurs) bir tasarım seçer; paylaşılan tasarımı düzenlemek onu kullanan bütün grupları değiştirir. Bizde Event grup karşılığıdır; ekip şablonu değişince onu kullanan Event'ler değişir.
- **Certifier.** Grup bir tasarım seçer; tasarım gruptan önce tasarım aracında hazırlanır.

**Sapmalar:**
1. **Kopyayı yerinde biz yaparız.** "Etkinliğe özel şablon oluştur" o an kullanılan şablonun bağımsız kopyasını Event'e bağlı açar; Accredible'da yalnız bir grubu değiştirmek için tasarım kütüphanede elle kopyalanır.
2. **Event template kütüphanede görünmez,** Event'le yaşar ve Event kopyalanınca bağımsız kopya olarak gelir.
3. **Yetki Event'i düzenleme yetkisini izler;** ekip şablonlarının yetkisi ayrı kalır.

## Ek: arka plan yerleşimi, PDF metinleri ve yazı tipleri (2026-11-25)

Karar (Yusuf, 2026-11-25): oranı farklı arka planda sayfa yüklemede arka plana uydurulur; PDF metni ve birebir PDF yerleşimi için iç servis kurulur; yerleşik kataloğa 10 yazı tipi eklenir ve ekipler kendi yazı tiplerini yükleyebilir.

- **Background placement.** Düzende isteğe bağlı `backgroundPlacement {fit, x, y, scale}` alanı. `fit` CSS `object-fit` anlamındadır: `contain` (Sığdır), `cover` (Doldur, kırp), `fill` (Uzat), `none` (Orijinal boyut); ek olarak `fitWidth` ve `fitHeight`. `x`, `y` `object-position` konumudur (0–1 kesir; 0,5 = %50, orta), `scale` kipin bulduğu ölçeğin çarpanıdır. Görsel ve PDF arka plan aynı hesapla yerleşir ve editör aynı kutuyu gösterir; üçü birbirini tutar.
- **Eski düzenler eskisi gibi basılır.** Alan yazılmamış düzenlerde render değişmez ve checksum aynı kalır; editör onları bugünkü baskıya eşit sabitlerle gösterir. Düzenleyen yerleşime dokununca alan yazılır.
- **Yüklemede sayfa arka plana uydurulur.** Yeni arka planın oranı sayfadan farklıysa sayfa ölçüsü arka planınkine çekilir, öğeler ölçeklenir; "Geri al" ile eski ölçü ve konumlar döner.
- **Background text conversion.** PDF arka plandaki seçilebilir metin, düzenleyen isterse düzenlenebilir katmana çevrilir: düzenleyen hangi metinlerin döneceğini seçer, seçilenler PDF'ten silinir ve aynı yerde, aynı biçimde, en yakın yazı tipiyle katman olur. Yazı tipi değiştiyse editör bunu söyler. Taranmış, eğriye çevrilmiş, görünmez (OCR) ve dikey metin dönüşmez.
- **İlkeden dar sapma.** Yukarıdaki "editörlerin kayıplı kopyasını kurmamak" ilkesinden bu bilinçli ve dar bir sapmadır. Sınırları: yalnız metin (şekil, görsel ve degrade dönüşmez), yalnız düzenleyen istediğinde ve seçtiği metinler, tek sayfa; orijinal PDF saklanır ve "Orijinale dön" ile dönüştürülen katmanlar silinip orijinal geri gelir. Canva ve Figma kaynağı düzenlenebilir kalmaya devam eder; dönüşüm onların yerine geçmez.
- **PDF ve yazı tipi işlemleri iç servistedir.** PDF okuma, metin silme, yerleştirme, önizleme ve yazı tipi denetimi yalnız iç ağdaki küçük bir servisle (pdf-tools) yapılır; dışarı açık yolu yoktur. core PDF ya da yazı tipi ayrıştırmaz ve servisin çıktısına da güvenmez. Sertifika üretimi bu servise gitmez: PDF'in yerleşmiş kopyası yayında sürüme yazılır. Servis yapılandırılmamışsa PDF yerleşimi, metin dönüştürme ve yazı tipi yükleme kapalıdır, eski yol çalışır.
- **Certificate font.** Yerleşik kataloğa 10 yazı tipi ailesi eklenir. Ayrıca ekipler ve kulüp kendi yazı tiplerini yükler (`certificate_fonts`): TTF, OTF ya da WOFF2 yüklenir, denetlenir ve denetlenmiş WOFF2 olarak saklanır. Değişken yazı tipi, koleksiyon (TTC) ve gömmeye izin vermeyen yazı tipi kabul edilmez; Türkçe harfi eksik yazı tipi kabul edilir ve uyarılır. Yükleme şablon yetkisine bağlıdır (ekip için Leader ya da şablon yönetme rolü olan Certificate manager, kulüp geneli için ayrıcalıklı); kullanmak şablonu düzenleyebilen herkese açıktır, yalnız şablonun ekibinin ve kulübün yazı tipleriyle. Kullanılan yazı tipi sürüme kopyalanır; sonradan arşivlenmesi yayınlanmış sürümleri ve verilmiş sertifikaları etkilemez.

### Endüstri uygulamasıyla karşılaştırma

**Uyanlar:**
- **CSS `object-fit` ve `object-position` (W3C).** Dört kip ve yüzdelik konum aynı anlamla.
- **Certifier.** Yüklenen arka plan tasarıma kendiliğinden uydurulur; bizde yüklemede sayfa arka plana uydurulur.
- **Canva.** PDF içe aktarınca metin düzenlenebilir olur; desteklenmeyen yazı tipi benzeriyle değiştirilir; taranmış ya da düzleştirilmiş PDF'in metni düzenlenmez.
- **Adobe Express.** PDF'i düzenlenebilir dosyaya çevirir; karmaşık düzen ve az bilinen yazı tipleri değişebilir.

**Sapmalar:**
1. **İki ek yerleşim kipi:** genişliğe ve yüksekliğe sığdır (CSS'te yok). `scale-down` yerine serbest ölçek var.
2. **Serbest kırpma dikdörtgeni, sürükleyerek konumlandırma ve arka planı döndürme yok.**
3. **Metin dönüşümü isteğe bağlı ve seçmeli;** Canva bütün belgeyi çevirir. Orijinal saklanır ve geri dönülür.
4. **Tek sayfa, 20 MiB;** Adobe Express 99 sayfa ve 99 MB kabul eder.
5. **Yazı tipi eşleşmezse sessizce düşülmez:** Sertifier'da listede olmayan yazı tipi Times New Roman'a düşer; bizde en yakın aileye düşülür ve editör bunu yazar.
6. **Yazı tipi yükleme şablon yetkisine bağlı;** Event'i düzenleyen üye yükleyemez, var olanı kullanır.
