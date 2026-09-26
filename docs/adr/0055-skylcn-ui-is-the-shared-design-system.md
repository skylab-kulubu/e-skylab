# ADR 0055: skylcn-ui is the shared design system for SKY LAB web products

- Status: accepted
- Date: 2026-09-26
- Author: Kaan Necip Kalp (taslakta 0039 numarasıyla yazıldı; 0039 bu seride dolu olduğu için 0055 oldu)
- Owners: Kaan Necip Kalp ve Fatih
- Supersedes: ADR 0017 (yalnızca arayüz kabuğu ve bileşenlerinin kopyalanması)

## Context

ADR 0017, superadmin'in (bugün core-frontend) forms-frontend'in yönetim
kabuğunu ve temel bileşenlerini ortak bir paket yerine TypeScript'e kopya olarak
almasını seçti. O geçiş için ortak paket yapılmayacağını ve iki kopyanın zamanla
ayrışabileceğini kabul etti. SkyMail'in yeniden yazımı da aynı gerekçeyle kabuğunu
ve temel bileşenlerini superadmin'den kopyalıyor. Aynı kopyalama alışkanlığı
diğer web ürünlerine de yayıldı. Bugün ayrışma somut:

- Aynı marka dili için beş ayrı token seti var: forms-frontend, admin paneli,
  skymail-frontend, account-center ve Keycloak login teması. Login teması nötr
  gri yerine zinc tonları ve ayrı bir mavi/pembe vurgu kullanıyor.
- skymail-frontend, admin panelinden kopyaladığı ve admin panelinde artık
  kullanılmayan bileşenleri taşıyor. Kulüp geçişi, rol etiketi ve breadcrumb
  mantığı üç depoda ayrı ayrı yaşıyor.
- Marka yükleniyor göstergesi üç farklı biçimde uygulanmış.
- Animasyonlu geçişler (açılıp kapanan paneller, liste girişleri) yalnızca
  forms-frontend'de sistematik; diğer arayüzler aynı etkileşimde farklı
  hissettiriyor.
- Açılır menü, popover, tarih seçici ve çekmece gibi overlay'ler her depoda
  elle yazılmış; odak yönetimi ve erişilebilirlik depodan depoya değişiyor.
- Açık tema yalnızca skymail-frontend'de var ve bileşenler anlamsal token
  kullanmadığı için nötr skalayı ters çevirerek elde ediliyor.

Katalogdaki `components` deposu 2023'te başlatılmış, tek bir örnek bileşen
içeren ve hiçbir üründe kullanılmayan bir paket taslağıdır.

Yeni ürünler de aynı dili kullanacak. Kopyalamaya devam etmek her yeni üründe
aynı işi yeniden yapmak ve ayrışmayı büyütmek demektir.

## Decision

- `skylcn-ui` deposu SKY LAB web ürünlerinin tasarım dili için tek doğruluk
  kaynağıdır: token'lar, tema, bileşenler ve sayfa iskeletleri burada tanımlanır.
- Dağıtım sürümlü bir npm paketidir: `@skylab-kulubu/skylcn-ui`. Paket
  bileşenleri, sayfa iskeletlerini, Tailwind temasını (`theme.css`) ve
  framework'ten bağımsız `tokens.css`'i taşır. Ürünler bileşen kopyalamaz;
  ortak bir öğedeki değişiklik `skylcn-ui`'de yapılır ve yeni sürümle gelir.
- Sürümleme semver'dir ve otomatiktir: değişiklik kayıtları Changesets ile
  tutulur, yayın GitHub Actions üzerinden npm'e provenance ile yapılır.
  Ürün depolarında Renovate veya Dependabot güncelleme PR'larını açar; kırıcı
  değişiklikler yalnızca major sürümde gelir ve geçiş notuyla duyurulur.
- Bileşenler shadcn yaklaşımıyla yazılır ve temel katman Base UI'dır (shadcn
  `base-nova` stili). Tailwind 4 kullanan ürünler temayı içe aktarır ve paketi
  `@source` ile tarar.
- Görsel dil forms-frontend'den çıkarılır: yoğun yerleşim, mikro tipografi
  ölçeği, nötr yüzeyler, lila (`skylab`) vurgu ve mevcut hareket eğrisi.
  Renkler değiştirilmez; 2026'ya uygun bir tazeleme yapılır.
- Paylaşılan bileşenler anlamsal token kullanır. Koyu tema varsayılandır,
  açık tema desteklenir.
- Tailwind kullanmayan yüzeyler için framework'ten bağımsız bir `tokens.css`
  yayımlanır. Keycloak login teması token'ları buradan alır.
- Yazı tipleri Space Grotesk (metin) ve Space Mono (kimlik, kod, sayı).
- Hareket süreleri ve eğrileri token'dır; `prefers-reduced-motion` her
  bileşende uygulanır.
- Marka logoları `skylab-assets` deposundan alınır. Yükleniyor göstergesi tek
  bir bileşendir ve kulüp işaretinden üretilir.
- Dokümantasyon ve önizlemeler Türkçe ve İngilizcedir. Kulübün proje wiki'si
  hazır olana kadar deponun GitHub Pages yüzeyinde yayımlanır; wiki hazır
  olduğunda oraya taşınır. Paketin kendisi bu taşımadan etkilenmez.
- Depo herkese açıktır. Dokümantasyona iç adres, ortam ayrıntısı veya kimlik
  bilgisi yazılmaz.
- `components` deposu eski/kullanılmayan olarak işaretlenir; yerine
  `skylcn-ui` geçer.

## Ownership

Paketi ve ürünlere geçişi Kaan ile Fatih yürütür. İş bitince ürün sahiplerine
ayrıntılı bir rapor verirler. Bir ürüne entegrasyonu ya ürün sahibi bu raporla
yapar ya da Kaan ile Fatih kendileri yapıp prod'a alır. Her ürün deposunda bu
ADR'ye bağlanan bir issue açılır. ADR metni ürün depolarına kopyalanmaz.

## Rollout

Geçiş ürün ürün yapılır ve her ürünün kendi deposunda yürür:

1. Admin paneli (core-frontend, ilk kullanıcı).
2. forms-frontend. Paket derlenmiş JavaScript olarak yayımlandığı için
   JavaScript deposunda da doğrudan kullanılır; form oluşturucuya özgü
   parçalar üründe kalır.
3. skymail-frontend. Yeniden yazım paket çıkana kadar kopyayla devam eder; bu
   adımda ADR 0017 kapsamındaki kopyalar kaldırılır ve açık tema token'larla
   yeniden kurulur.
4. account-center. Önce token'lar, sonra bileşenler.
5. Keycloak login teması. Paketin `tokens.css`'i kullanılır; geçişte lila
   vurgu denenir, beğenilmezse login'e özel vurgu token'ı olarak geri alınır.

## Consequences

- Ürünler aynı görünür ve aynı hissettirir; yeni bir ürün ortak iskeletle
  başlar.
- Overlay ve form bileşenleri tek bir erişilebilir temelden gelir.
- `skylcn-ui` bakım isteyen bir üründür: sürüm notları, geçiş rehberleri ve
  görsel testler onun sorumluluğundadır.
- Güncellemeler ürünlere otomatik PR olarak gelir; ürünün CI'ı ve sandbox'ı
  yeni sürümü birleşmeden önce doğrular.
- Bir ürünün ortak bir öğeden farklı davranmasına ihtiyaç duyulursa bu,
  üründe yerel bir kopya ile değil pakette bir seçenek (prop, varyant, token)
  ile çözülür.
- Paket npm'de herkese açıktır; yayın yetkisi GitHub Actions'a verilir,
  kişisel token kullanılmaz.

## Rejected alternatives

- Kopyalamaya devam etmek (ADR 0017): ayrışma beş token setiyle ve kaynağında
  kaldırılmış olup kopyalarda yaşamaya devam eden bileşenlerle kanıtlandı.
- Yalnızca shadcn registry'si: kod ürüne kopyalanır ve sürüm yoktur;
  güncellemeler elle çekilir ve yerel düzeltmelerle ayrışma yeniden başlar.
  Ürünün sahiplenip değiştirmesi beklenen sayfa şablonları için ileride ek
  olarak bir registry sunulabilir.
- `components` deposunu canlandırmak: 2023'ün Storybook, Rollup ve SCSS
  yığını bugünkü Next.js, React 19 ve Tailwind 4 ürünleriyle uyumsuz.
