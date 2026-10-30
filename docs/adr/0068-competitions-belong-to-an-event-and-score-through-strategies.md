---
status: accepted
---

# Yarışma Event'e bağlı kendi kaydıdır; aşama başına seçilen strateji puanı yalnız eklenen bir defterden hesaplar, sonuç ilanı sürümlüdür; kod çalıştıran judge kurulmaz

core'daki yarışma modeli Java döneminden kaldı. Bir Event'teki her kişi için tek bir puan ve bir "kazanan" bayrağı tutuyor. Takım, aşama, gönderim, jüri, dondurma ve sonuç ilanı yok. Production'da bu tabloda kayıt yok. Kulübün yarışmaları ise farklı biçimlerde puanlanıyor:

- **AGC:** ALGOLAB'ın haftalık etkinliği ve algoritma yarışması; dönem ve yıl puan tablosu var.
- **SKY DAYS CTF:** SKY-SEC'in yarışması. CTFd'de dinamik puanla koşuyor.
- **YıldızJam:** Oyun maratonu, jüri kararıyla sonuçlanıyor.

Hub'daki admin paneli araştırması dış platform kullanmayı önermişti: yarışma Devpost ya da Kaggle'da koşar, bizde yalnız sonuç tutulur.

Karar (Yusuf, 2026-10-12):

1. **Kulübün kendi tam yarışma modülü olur ve her puanlama türünü taşır.** Dış platform önerisi reddedildi.
2. **İlk kullanım AGC'dir.** AGC her hafta bir etkinlik yapar; gelenlere ekip 30, 50, 60 gibi elle puan verir. O dönem ya da yıl boyunca en yüksek puanlılar AGC'nin sitesinde görünür. Bu yüzden ilk dilim elle puan, katılıma bağlı toplu puan, sonuç ilanı ve dönem/yıl sıralamasıdır.
3. **Kod çalıştıran judge kurulmaz** (DOMjudge, CMS, Judge0). Kodu değerlendirilen yarışma dış platformda (ör. Codeforces Gym) yapılır, sonucu içe aktarılır.
4. **CTF ikiye ayrılır.** Büyük CTF'ler (SKY DAYS) SKY-SEC'in CTFd'sinde kalır; sonucu, sertifikası ve arşivi içe aktarmayla bize gelir. Küçük CTF'ler bizde, yerel `ctf` stratejisiyle koşar. Görev altyapısı her durumda SKY-SEC'tedir.
5. **Yüzeyler.** Sonuçlar ana sitede gösterilir; AGC'nin sitesi aynı public uçtan okur. Çevrimiçi gönderim gerekince kendi küçük katılımcı uygulamamız kurulur. sky-app yalnız okur.

Nasıl (spec'ten):

- **Competition, core'da kendi kaydıdır ve bir Event'e bağlıdır.** Owner team, Season, kayıt (Ticket), yetki ve sertifika Event'ten gelir; yarışma sahipliği ayrıca saklanmaz. Bir Event'te birden çok Competition olabilir. Etkinlikler arası toplam (AGC dönemi ve yılı) bir **Series** ile kurulur; Series yalnız ilan edilmiş sonuçları toplar. Yıl Season'dır, dönem seride adlandırılmış bir tarih aralığıdır.
- **Tek model, değiştirilebilir strateji.** Bir Competition'ın bir ya da daha çok **Stage**'i vardır; her Stage'in bir **Scoring strategy**'si ve ona ait bir ayarı olur. Strateji saf bir fonksiyondur: aşamanın defterinden puan, eşitlik anahtarları ve gösterim ayrıntısını hesaplar. Başlangıç stratejileri `manual`, `problems` (ICPC, AtCoder, IOI, sabit ve azalan puan ön ayarları; sonuç içe aktarılır), `rubric` (jüri), `ctf` ve `metric`'tir. Yeni puanlama türü kodda yeni strateji olarak eklenir; çalışma anında eklenti ya da formül dili yoktur. Derece ortak bir sıralayıcıdan çıkar: puan, sonra aşamada yazılı eşitlik zinciri, en sonda aynı derece (1, 1, 3).
- **Defter yalnız eklenir.** Gönderim, hüküm, jüri puanı, içe aktarılan sonuç ve düzeltme silinmez; düzeltme eski satırı gerekçeyle geri alır ve yenisini yazar (Deletion lifecycle, ADR-0042). Puan tablosu her an defterden yeniden hesaplanabilir; defter, puan değişikliklerinin denetim kaydıdır. Puanlar sabit noktalı tam sayıdır.
- **Leaderboard defterin bir görünümüdür:** gizli, canlı, dondurulmuş ya da yalnız yarışmacılara. Dondurma sunucuda uygulanır; public okuma dondurma anından sonraki kaydı hiç hesaba katmaz, organizatör canlı tabloyu görür.
- **Result publication açık bir işlemdir ve sürümlüdür.** Bitiş saatinin geçmesi ya da Event'in bitmesi ilan sayılmaz. İlan değişmez bir anlık görüntü yazar (derece, puan, ödül, ilan anındaki gösterim adı). Düzeltme gerekçeli yeni bir sürümdür; public son sürümü görür.
- **Entrant birey ya da takımdır; üyeleri o Event'in Ticket'larıdır.** Yarışmaya kayıt Event'in kayıt yolundan geçer (Member apply, Guest apply, Event form); yarışma kendi başvuru formunu açmaz. Bir kişi bir yarışmada en fazla bir Entrant'ta olur.
- **Yetki** ADR-0059 modeline uyar; istemci yetki hesaplamaz. Judge (jüri üyesi) yarışmaya atanır, yalnız kendisine atananları görür, kendi takımını puanlayamaz ve başkalarının puanını ilana kadar görmez.
- **Derece sertifikası bir Certificate türüdür.** İlan edilmiş bir sonuçtaki Award'a bağlanır; alıcılar ödül alan Entrant'ın Ticket'larıdır. Şablon çözümünde Award ve Competition bağlaması Event'ten önce gelir (ADR-0038'e ek). Sonuç düzeltilirse etkilenen derece sertifikaları iptal edilip yeniden verilir.
- **Eski model kalkar.** Veri taşınmaz. sky-app'in okuduğu `GET /v1/competitors/me` yanıtı aynı biçimde yeni modelden üretilir ve sky-app yeni uca geçene kadar kalır; öteki `competitors` uçları admin paneli geçince kaldırılır. Event'teki `ranked` ve `prizeInfo` alanları sky-app yazdığı için kalır, ama hiçbir yarışma kuralını etkilemez.

## Consequences

- **Platform sunucusunda ve core'da güvenilmeyen kod çalışmaz** (karar 3). Spec'teki araştırmaya göre her judge ayrıcalıklı bir bileşen ister (root, setuid ya da `--privileged`), adil süre ölçümü de ayrılmış çekirdek ister; Judge0'da 2024'te kritik sandbox kaçışları yayımlandı. Kod yarışmasında kimlik ve veri dış platformda kalır; bizde yalnız içe aktarılan sonuç durur.
- **Yarışmacı ekleme kuralı değişir.** Bugün yarışmacı yalnız aktif Event'e ekleniyor. Artık ekleme yarışmanın durumuna bağlıdır; içe aktarma ve elle puan yarışma kapandıktan sonra ilana kadar yapılabilir. Event durumu ADR-0066'dadır.
- **Yönetim kalıtımı.** Yarışma sahipliği Event'in Owner team'inden türediği için ekip yetki devrinin (ADR-0065) kalıtımı ve sabit kök kuralı yarışmaya kendiliğinden uygulanır; yarışma kodu grup adı eşleştirmesi yazmaz.
- **Yeni Media purpose'lar gelir** (ADR-0052): gönderim dosyası, cevap anahtarı (yalnız organizatör) ve görev dosyası (yalnız yarışmacılar); hepsi private.
- **Kişisel veri (ADR-0062).** "Yoklama ve yarışma geçmişi" ve "Club archive: yayımlanmış kazananlar" satırları geçerlidir. Public tabloda e-posta, Sky no ve okul görünmez. Account erasure ilan edilmiş sonuçtaki adı anonimleştirir, derece ve puan kalır.
- **CTF flag'leri açık metin saklanmaz.** Statik flag'in anahtarlı özeti, regex flag şifreli tutulur. Deneme sayısı sınırlıdır.
- **Strateji katmanı test ağırlıklıdır.** Her ön ayar, kaynağının (ICPC, AtCoder, IOI, Codeforces, CTFd) kural metninden ya da kodundan hesaplanmış altın tablolarla sınanır. Değişmezler ayrıca sınanır: girdi sırasından bağımsızlık, dondurma sonrası kaydın public tabloya sızmaması, geri alınan kaydın sayılmaması.
- **Public puan tablosu kısa ömürlü önbellekle verilir.** Canlılık yoklamayla sağlanır, sunucu itmesi (SSE, websocket) yoktur.
- **AGC'nin sitesi** bugün üç emekli Java ucunu çağırıyor ve üçü de 404 dönüyor; yeni public uca geçer.
- **CONTEXT.md'de değişenler:**
  - Yeni terimler: Competition, Stage, Entrant, Scoring strategy, Leaderboard, Result publication, Award, Series, Competition staff.
  - Certificate: katılım ve derece olmak üzere iki tür.
  - "Competitor" _Avoid_ listesine girer.

## Açık

Yusuf'a soruldu; yarışmanın ilk dilimini bekletmez, cevap gelene kadar spec'in önerisi uygulanır.

- **Event'e bağlılık:** öneri, her yarışma bir Event'e bağlı (yukarıdaki model). Seçenek: bağımsız yarışma, Event isteğe bağlı.
- ~~**Kim yönetir:** öneri, Event'in Owner team'inin Leader'ları (ADR-0065'le üst ekiplerinkiler de), uygulama geneli `competition:manage` rolü, yarışmaya atanmış Competition staff; Owner team'i olmayan Event'te yalnız Privileged (ADR-0018). Bugünkü "ekibin her üyesi" kuralı daralır; kullanım sıfır olduğu için kimse yetki kaybetmez.~~ *Kapandı (Yusuf, 2026-10-12 ve 2026-10-25); bkz. aşağıdaki ek. Kalan sorular ekin "Açık" alt başlığında.*
- **Misafir yarışabilir mi:** öneri, evet, GUEST Ticket'la; çevrimiçi gönderimde hesap açarak (ADR-0063).
- **Public tabloda ad:** öneri, bireyde ad soyad, takımda takım adı ve üyeler; yarışma ayarıyla takma ad; profil fotoğrafı yok. Reşit olmayan katılımcının adının yayımı hukuk sorusudur (veli onayı ya da hiç yayımlamamak).
- **Yeni saklama süreleri:** öneri, flag ve cevap denemeleri etkinlik + 90 gün, gönderim dosyaları etkinlik + 1 yıl (kazananınki arşiv), jüri yorumları etkinlik + 1 yıl. ADR-0062'ye ek olarak yazılır.
- **Rol adı:** öneri, `competitor:manage` Keycloak'ta ve core'un rol sözleşmesinde `competition:manage` olur.
- **Derece sertifikası şablonu:** öneri, yarışma başına tek şablon, ödül adı katmanla yazılır; ödül başına ayrı şablon seçime bağlı.
- **AGC liderine:** dönem tarihleri, seride eşitlik, kimlerin puan alacağı, haftalık etkinlikte Oturum kullanımı.

## Endüstri uygulamasıyla karşılaştırma

**Uyanlar:**
- Aşama ya da görev başına puanlama türü seçimi: CTFd'de görev türü, CMS'de "score type", DOMjudge'da yarışma başına ceza ayarı.
- Dondurma: ICPC, DOMjudge, CTFd.
- Kaggle'ın public/private tablo ayrımı.
- Devpost ve Devfolio'nun jüri ataması, çekilme ve asgari jüri sayısı.
- Eşit puana aynı derece.

**Sapmalar (hepsi):**
1. **Çalışma anında eklenti yok** (CTFd görev türlerini Python eklentisi olarak yükler).
2. **Sonuç ilanı sürümlü** (CTFd'de sonuç canlı tablodur).
3. **Flag'ler açık metin saklanmıyor;** CTFd açık metin saklıyor.
4. **Kod çalıştırılmıyor;** kod yarışması dış platformda.
5. **Katılım Event'in Ticket'larından geçiyor,** platformun kendi hesap sistemi yerine.
6. **Sertifika aynı platformda;** incelenen yarışma ürünlerinde yerleşik sertifika bulunamadı.
7. **Jüri normalleştirme yöntemi ayarda açıkça seçiliyor;** Devfolio yöntemini belirtmiyor.

## Considered Options

- **Dış platform + bizde yalnız sonuç (araştırmanın önerisi):** en az iş; Devpost ve Kaggle öğrenci etkinliğine ücretsiz. Yusuf reddetti (karar 1).
- **Bugünkü `competitors` tablosunu genişletmek:** kişi başına satır modeli takımı ve aşamayı taşımıyor. Kullanım sıfır olduğu için yeniden kurmanın bedeli yok.
- **Her yarışma türü için ayrı modül ve tablolar:** türler kendi içinde sadeleşir, ama ilan, sertifika, yetki, görünürlük ve seri her modülde tekrar eder.
- **Yarışmayı Event'ten bağımsız yapmak:** ikinci bir sahiplik alanı ve bilet dışı sertifika alıcısı gerektirir; kayıt yolu ikiye bölünür. Açık soru.
- **Çalışma anında eklenti ya da formül dili:** incelenmemiş kodu sunucuda çalıştırır ve test edilmesi zor bir yüzey açar. Yeni tür seyrek geliyor; kodda strateji eklemek yetiyor.
- **Puan tablosunu her yazışta güncellenen bir tabloda tutmak:** dondurma, geri alma ve geriye dönük dinamik CTF değeri her yazışta yeniden hesap ister ve iki kaynak ayrışabilir. Defterden hesap ve kısa önbellek bu ölçekte yeterli.
- **DOMjudge'u yarışma günü açılan ayrı bir VM'de kurmak:** spec'in önerisiydi (platform sunucusu dışında, ayrılmış çekirdeklerle). Yusuf judge kurmamayı seçti (karar 3).
- **DOMjudge'u etkinlik uygulamaları projesinde (ADR-0057) barındırmak:** o proje platformla aynı makinede; ayrıcalıklı judgehost veritabanlarının yanında durur, ayrılmış çekirdekler production'la çakışır.
- **Judge0:** yarışma katmanı yok; ayrıcalıklı servisler ve ana makinede cgroup v1 ister; 2024'te kritik sandbox kaçışları yayımlandı.
- **Bütün CTF'leri CTFd'de bırakmak ya da hepsini bize taşımak:** büyük CTF'in altyapısı SKY-SEC'te hazır; küçük CTF için ayrı bir CTFd kurmak gereksiz yük. Yusuf ikisini birden seçti (karar 4).
- **Sonuç ilanını sürümsüz, canlı tutmak (CTFd gibi):** sertifika ve arşiv belli bir sonuca bağlanamaz; düzeltme sessizce olur.

## Ek: yarışmaları kim yönetir; ilk ekip ayarı yarışmacıları kapsar (2026-10-12, 2026-10-25)

"Açık" bölümündeki "Kim yönetir" sorusu iki kararla kapandı.

**Yusuf, 2026-10-12:** "Microsoft tarzı olmalı, panelden yönetebilmeliyiz. Bazen AGC lideri + koordinatörler, bazen AGC'nin tüm üyeleri." Yani kimin yöneteceği ekip başına, panelden bir ayarla seçilir. Aynı gün ayarın ayrıntısındaki yedi soru (A1–A7) önerildiği gibi kabul edildi.

**Yusuf, 2026-10-25** (admin paneli incelemesi): ekip üyeleri etkinliklerin yarışmacılarını ekleyip düzenleyebilir, ama bunu ekibin lideri seçer. Bu ayar ADR-0065'in 2026-10-25 ekinde yazıldı ve core'da uygulandı.

Bugün geçerli olan:

1. **Organizatör.** Yarışmayı açmak, düzenlemek, durumunu değiştirmek, yarışmacı (Entrant) eklemek, puan yazmak, sonucu ilan etmek ve arşivlemek Event'in Owner team'inin Leader'larının (ADR-0065'le üst ekiplerinkiler de), `competition:manage` rolünün ve Privileged'ın işidir. Owner team'i olmayan Event'te yalnız Privileged yönetir (ADR-0018). Ekip üyeliği tek başına yarışmayı yönetmez. Bu, "Açık"taki önerinin ve 2026-10-12 kararındaki varsayılanın ("liderler ve koordinatörler") aynısıdır.
2. **İlk ekip ayarı: `members_manage_competitors`.** Ekibin kendi grubunun özniteliğidir.
   - Ekibin üyelerinin, ekibin etkinliklerinde eski yarışmacı kaydını (Competitor) ekleyip düzenleyip silip silemeyeceğini söyler.
   - Varsayılan açıktır, yani ayardan önceki kural: üyeler yazar. `false` olunca yazma yalnız ekibin Leader'larında, üst ekiplerin Leader'larında ve Privileged'dadır.
   - Okuma ve kişinin kendini yarışmacı olarak kaydetmesi ayardan etkilenmez.
   - Ayar yalnız daraltır. Bu yüzden ekibi yöneten (ekibin ya da üst ekibin Leader'ı) yazar; korunan grupta yalnız Privileged. Ekip yetki devri kapalıyken yalnız Privileged yazar.
   - Yalnız bir ekibin kendi grubu ayar taşır; Leader grubu, alan ve kök taşımaz. Alt ekibe miras yoktur: karar Owner team'in kendi grubundan okunur.
   - Değer okunamazsa ya da ekip kodu tek bir grubu göstermiyorsa varsayılan geçerlidir.
   - Her değişiklik ekip denetim kaydına eski ve yeni değerle yazılır (ekip grubunun öznitelik değişikliği olarak); reddedilen yazma da yazılır.
3. **ADR-0065 karar 8 ile ilişki.** `members_manage_competitors`, Privileged'da kalan öznitelikler (`public_listing`, `public_leaders`, `team_door_scan`) arasında değildir; onlar yetkiyi genişletir, bu yalnız daraltır (ADR-0065'in 2026-10-25 eki).
4. **2026-10-12'de kabul edilen, henüz uygulanmamış kurallar:**
   - **Kimse kendi yarışmacısına puan yazamaz** (A3): Leader ve Privileged dahil. Bugün yalnız Judge için yazılıydı.
   - **Yarışma görevlisi** (Competition staff) isteğe bağlıdır ve tek bir yarışma kapsamlıdır. Görevli yarışmayı organizatör gibi yönetir ve sonucu ilan eder (A5); görevli atayamaz, arşivleyemez, seri ayarını değiştiremez.
   - **Seri ayarı** (dönem tarihleri, toplama kuralı, hazır puanlar) yalnız Leader'da ve üstündedir (A2).
   - **Kulüp genelinde kilit yok** (A7): ayar ekip ekip değişir.
   - Ayar yalnız yarışmaları kapsar, etkinlik açmayı kapsamaz (A6).

### Açık

- **Üyelere yarışma yönetimini açan seçenek.** 2026-10-12 kararındaki "tüm üyeler" seçeneği, varsayılanı kapalı ve ekibi yönetenin açtığı bir ayardı: açıkken üyeler yarışmayı açar, puan yazar ve sonucu ilan eder (A1). ADR-0065'in 2026-10-25 eki ise lidere yalnız daraltan ayarı açar, genişleten ayarı Privileged'a bırakır. İki kural birbirini tutmuyor ve "tüm üyeler" uygulanmadı. Seçenekler: ayarı Privileged yazar; ADR-0065'teki kurala bu ayar için istisna yazılır; ya da üyelerin yarışma yönetimi gerekmez, görevli yeter. Yusuf karar verecek.
- **Yarışmacının yeni modele geçişi.** Eski yarışmacı kaydı yarışma modülüne (Entrant) geçince `members_manage_competitors` Entrant eklemeyi de kapsar mı? Bugün yarışma modülünde Entrant'ı yalnız organizatör ekler.
- **Defter satırının dayanağı.** Puan satırının hangi yetkiyle yazıldığını (Leader, ekip ayarı, görevli, Privileged) taşıması önerildi; yukarıdaki ilk açık soruya bağlıdır.

### Endüstri uygulamasıyla karşılaştırma

**Uyanlar:**
- **Microsoft Teams üye izinleri.** Ekip sahibi, sahip olmayan üyelerin neyi yapabileceğini ekip başına açıp kapatır; ayarı üye değiştiremez. Teams'te üyelerin kanal açması gibi izinler varsayılan açıktır; `members_manage_competitors` da varsayılan açıktır.
- **Entra'da kapsamlı rol ataması.** Yetki bütün kiracıya değil, bir birime ya da tek bir kaynağa verilir. Bizde ekip ağacı (ADR-0065) ve yarışma başına görevli.
- **Entra denetim kaydı.** Aktör, hedef, eski ve yeni değer (ADR-0065 karar 9).

**Sapmalar (hepsi):**
1. **Ayarı üst ekip de değiştirir.** Teams'te ayarı yalnız o ekibin sahipleri ve kiracı yöneticisi değiştirir. Bizde ADR-0065'in kalıtımı gereği üst ekibin Leader'ı da değiştirir.
2. **Kulüp genelinde kilit yok** (A7). Teams'te kiracı yöneticisi bazı seçimleri ekip sahiplerinden alabiliyor ("Team owners can change who can manage tags").
3. **"Üye" alt ekiplerin üyelerini de kapsar.** Microsoft 365 gruplarında iç içe üyelik yok; bizde Member tanımı alt ağacı içerir (A4; GitHub'ın iç içe takımları gibi).
4. **Tek anahtar.** Teams'te birçok üye izni anahtarı var; bizde yalnız yarışmacılar.
5. **Kendi puanını yazma yasağı herkese** (A3). Teams'te karşılığı yok.

### Kaynaklar

- Microsoft Teams, etiketleri yönetme ("Who can manage tags"): https://learn.microsoft.com/en-US/microsoftteams/manage-tags
- Microsoft Learn, Teams'te kanallara erişimi yönetme: https://learn.microsoft.com/en-us/training/modules/manage-collaboration-experiences-for-chat-channels/07-manage-access-channels
- Microsoft Entra, rolleri farklı kapsamlarda atama: https://learn.microsoft.com/en-us/entra/identity/role-based-access-control/assign-roles-different-scopes
