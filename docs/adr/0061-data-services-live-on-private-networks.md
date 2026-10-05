---
status: accepted
---

# Veri servisleri yalnız onları kullanan uygulamalarla paylaştıkları özel ağlardadır; `dokploy-network`'te yalnız Traefik'in ulaşması gerekenler kalır

Bugün sunucudaki her Dokploy servisi tek bir overlay ağında, `dokploy-network`'te duruyor (2026-10-03 sayımında 36 konteyner). Platform Postgres'i ve Redis'i (production ve sandbox), kapı Redis'i (account-access), OpenBao, Dokploy'un kendi Postgres'i, etkinlik uygulamalarının veritabanları ve Traefik aynı ağda. Etkinlik uygulamaları da orada. Bir veritabanını bugün yalnız parolası koruyor. ADR-0057 bunu bilerek kabul etmişti ("Ağ yalıtımı yok"). Bu ADR o maddeyi değiştirir.

Karar (Yusuf, 2026-10-03):

- **Veri servisi `dokploy-network`'te durmaz.** Postgres, Redis, OpenBao ve Dokploy'un kendi veritabanları, yalnız onları kullanan uygulamalarla paylaştıkları özel bir overlay ağındadır. Etkinlik uygulamaları platformun veri servislerine adla da adresle de ulaşamaz.
- **`dokploy-network`'te yalnız Traefik'in ulaşması gereken servisler kalır:** alan adı olan uygulamalar, Traefik'in kendisi ve Dokploy'un paneli. Veri servisini kullanan bir uygulama iki ağda durur: `dokploy-network` (Traefik için) ve veri ağı.
- **Bir veri ağı bir ortama aittir.** Production ile sandbox ayrı veri ağlarındadır; bir etkinlik projesinin veritabanı kendi projesinin ağındadır. Ortamlar arası tek istisna OpenBao'dur: tek kurulum iki ortama hizmet eder (ADR-0049). İkinci istisna tarama ağı `sky-lab-scan`'dir (2026-10-05 eki).
- **Ağ üyeliğinin tek kaynağı Dokploy'dur.** Dokploy'un yönettiği servislerde üyelik Dokploy'un Networks özelliğine (`networkIds`, `detachDokployNetwork`) yazılır; böylece her deploy aynı ağları kurar. Dokploy'un yönetmediği servislerde (Dokploy'un kendisi ve veritabanları) Docker'a yazılır ve olgu betiğiyle denetlenir.
- **İlk somut adım media-frame'dir:** core'un video kare servisi token istemez; yalnız core'la paylaştığı özel ağla korunur, kod değişmez (core-internal-auth ticket 07).
- **Önce sandbox.** Her adım bir wizard'la, ölü adam anahtarlı geri dönüşle yapılır.

## Ağ düzeni

| Ağ | Üyeler | `internal` | `attachable` | Not |
|---|---|---|---|---|
| `dokploy-network` (Dokploy'un) | Traefik; alan adı olan her uygulama (core, forms, SkyMail, Keycloak, Account Center, admin paneli, inscribed, ön yüzler, kulüp siteleri, etkinlik uygulamaları); Dokploy paneli | hayır | evet | Dokploy her uygulamayı varsayılan olarak buraya bağlar. Veri servisi yok. |
| `sky-lab-production-frame` | media-frame (production), core (production) | hayır | hayır | media-frame R2'ye çıkar, bu yüzden internal değil. media-frame `dokploy-network`'ten ayrılır. |
| `sky-lab-sandbox-frame` | media-frame (sandbox), core (sandbox) | hayır | hayır | Aynısı, sandbox. |
| `sky-lab-production-data` | production Postgres, production Redis, kapı Redis'i (`account-access-redis` takma adıyla); onları kullanan production uygulamaları (core, forms, SkyMail, Keycloak, inscribed, Account Center, admin paneli; kesin liste olgu betiğinden) | evet | evet | Postgres ve Redis'in dışarı çıkışı yok. `attachable`, çünkü rotatorun kapı adımı yan konteynerini bu ağa bağlar. |
| `sky-lab-sandbox-data` | sandbox Postgres, sandbox Redis; onları kullanan sandbox uygulamaları | evet | hayır | İlk uygulanan veri ağı. |
| `sky-lab-secrets` | OpenBao; Dokploy (`${{vault…}}` referanslarını çözer); OpenBao'yu çağıran servisler (core Transit; kesin liste olgu betiğinden) | hayır | evet | OpenBao'nun insan girişi Keycloak'un public adresine gider; çıkış gerekir. `attachable`, çünkü OpenBao arayüz tüneli (`openbao-ui.sh`) bir yan konteynerdir. |
| `dokploy-internal` | `dokploy-postgres`, `dokploy-redis`, Dokploy | evet | hayır | Dokploy'un yönetmediği servisler; `docker service update` ile. |
| `sky-lab-etkinlik-data` | "SKY LAB Etkinlik" projesinin veritabanları ve onları kullanan uygulamalar | evet | hayır | Etkinlik başına ayrı ağ gerekmez: projenin veritabanları zaten projenindir (ADR-0057). |
| `ekstrem-sporlar-data` | "Ekstrem Sporlar" projesinin veritabanı ve uygulaması | evet | hayır | Aynı kural. |

Ad kuralı: `<Dokploy projesi>-<ortam>-<amaç>` (ortamı olmayanlarda `<proje>-<amaç>`). `attachable` yalnız bir yan konteynerin (`docker run --network`) bağlanması gereken ağda açıktır; wizard'ların yoklamaları üyenin ağ ad alanını paylaşır (`--network container:…`), `attachable` istemez. Servislerin DNS adları (`sky-lab-production-postgres-ik33fe` gibi) değişmez: Swarm servis adı, servisin bağlı olduğu her ağda çözülür. Uygulamaların bağlantı değerleri ve OpenBao'daki sırlar değişmez. Kapı Redis'inin `account-access-redis` takma adı yeni ağda da tanımlanır (`networkSwarm` ile).

## Dokploy (v0.30.7) ne yapabiliyor

Kaynak okundu (`Dokploy/dokploy` `v0.30.7`):

- **Networks özelliği var.** `network` tablosu ve paneldeki Networks sayfası; API `network.create` (overlay, `internal`, `attachable`, IPAM, MTU), `network.import` (Docker'da var olan ağı kaydeder). Servis başına `networkIds` ve `detachDokployNetwork` alanları uygulamada (`application`), Postgres'te, Redis'te ve öteki veritabanı türlerinde var; panelde servis → Advanced → Networks.
- **Deploy üyeliği kendisi kurar.** Uygulama, Postgres ve Redis kurucuları servis tanımını her deploy'da `resolveServiceNetworks` ile yazar: `detachDokployNetwork` yoksa `dokploy-network`, ardından `networkIds`'deki overlay ağları. Bu yüzden bir servise `docker service update --network-add` ile elle eklenen ağ bir sonraki deploy'da silinir; Dokploy alanına yazılan kalır.
- **`networkSwarm` her şeyi ezer.** Advanced → Cluster → Swarm'daki ağ JSON'u doluysa `networkIds` ve `detachDokployNetwork` yok sayılır. Takma ad gereken servis (kapı Redis'i) bu JSON'la yönetilir.
- **Postgres ve Redis `dnsrr` kipindedir** (sanal IP yok); servis adı her ağda doğrudan konteynerin adresine çözülür.
- **Traefik bağımsız bir konteynerdir ve yalnız `dokploy-network`'tedir.** Dokploy onu yalnız "Isolated Deployment" seçili compose projelerinin ağlarına bağlar (`reconnectServicesToTraefik`). Application'lar için Traefik'i özel ağlara bağlamaz; alan adı olan bir Application `dokploy-network`'ten ayrılırsa yönlendirme kırılır (panel de uyarır).
- **Şifreli overlay kuramaz.** `network.create` yalnız MTU seçeneğini geçirir; `--opt encrypted` yok. Panelden "recreate" da Docker'a yalnız kayıttaki alanları gönderir.
- **Dokploy'un kendi Postgres'i ve Redis'i** kurulumda (`setup.ts` ve kurulum betiği) `dokploy-network`'e konur; Dokploy açılışında yeniden yaratılmaz (`server.ts` yalnız ağın varlığını denetler). Bu yüzden onların ağı Docker'da değiştirilir ve Dokploy güncellemesinden sonra olgu betiğiyle denetlenir. Eski kurulumlarda bu Postgres'in parolası Dokploy kaynağında yazan sabit değerdir; v0.26.6 güvenlik betiği onu Docker secret'a taşır. Production'da hangisinin geçerli olduğu olgu betiğinin ilk sorusudur.

## Geçiş sırası

Her adım ayrı bir wizard koşusudur; bir sonrakine, öncekinin ertesi günkü gece yedeği ve 03:30 sır döndürmesi başarılıysa geçilir.

0. **Olgular** (`ops/wizards/network-facts.sh`, salt okunur): ağ başına üyeler, hangi uygulamanın hangi veri servisine bağlandığı (ortam değişkeni ADLARI ve canlı bağlantılar; değer ve IP basılmaz), Dokploy'daki ağ alanları, Dokploy Postgres'inin parola durumu.
1. **media-frame** (kare servisi açılırken ya da açıksa): `sky-lab-<ortam>-frame`; media-frame `dokploy-network`'ten ayrılır, core ikinci ağ olarak alır. Önce sandbox.
2. **Sandbox veri** (`ops/wizards/network-separation-sandbox-wizard.sh`): ağ yaratılır; istemci uygulamalar ağa eklenir (her biri ayrı doğrulanır); Postgres ve Redis ağa eklenir; doğrulama; Postgres ve Redis `dokploy-network`'ten ayrılır; doğrulama; üye olmayan bir konteynerden (Traefik, `dokploy-network`'teki bir yoklama, etkinlik uygulaması) adın çözülmediği ve bağlantı kurulamadığı kanıtlanır.
3. **Etkinlik veritabanları** (production; etki alanı küçük).
4. **Production Postgres ve Redis** (bakım penceresinde): önce istemci uygulamalar ağa (her biri bir kez yeniden başlar), sonra her veri servisi tek güncellemede ağa eklenir ve `dokploy-network`'ten ayrılır (bir kez yeniden başlar, birkaç saniye).
5. **Kapı Redis'i** (`networkSwarm` düzenlenir; takma ad ve `attachable` korunur, çünkü OpenBao rotatorunun kapı adımı ağı bu takma addan bulur ve yan konteynerini o ağa bağlar).
6. **OpenBao → `sky-lab-secrets`;** Dokploy servisi ağa eklenir (referans çözümü). Ardından bir sandbox deploy'unda referansların çözüldüğü denetlenir.
7. **Dokploy'un Postgres'i ve Redis'i → `dokploy-internal`;** önce parola Docker secret'ta olmalı.

## Geri dönüş

- Her değişiklikten ÖNCE geri dönüşü bir günlüğe yazılır (servis, eklenen/çıkarılan ağ, Dokploy alanlarının eski değeri). Geri alma günlüğü tersten koşar.
- Ölü adam anahtarı: ilk değişiklikten önce `systemd-run` ile bir zamanlayıcı kurulur; süre içinde "evet" gelmezse günlük kendiliğinden geri koşar. Zamanlayıcı Dokploy API anahtarını taşımaz (anahtar yalnız wizard'ın belleğinde); bu yüzden Dokploy alanlarını Dokploy'un veritabanına doğrudan SQL'le eski değerine döndürür, sonra Docker servislerini. Elle geri alma: wizard `--rollback`.
- Ağın kendisi geri almada silinmez (boş ağ zararsız); silinecekse Dokploy'un Networks sayfasından, hiçbir servis ona başvurmuyorken.

## Dokploy deploy'ları

- Üyelik Dokploy'a yazıldığı için bir deploy (CI kancası dahil) aynı ağları kurar. Wizard canlı değişikliği `docker service update --no-resolve-image` ile uygular ki ağ değişikliği yeni bir imaj sürümü getirmesin; ardından Dokploy alanlarından hesaplanan ağlarla canlı servisin ağlarının aynı olduğunu denetler.
- **Dokploy'da bir ağ kaydı, ona başvuran servis varken silinmez:** Dokploy silinmiş kaydı sessizce atlar; bir sonraki deploy veri servisini hiçbir ağa bağlamadan ya da uygulamayı veri ağından düşürerek kurar.
- Veritabanı isteyen yeni bir platform uygulaması açılırken Advanced → Networks'te kendi ortamının veri ağı seçilir. Unutulursa uygulama veritabanı adını çözemez ve açılışta düşer: sessiz değil, yüksek sesli bir hata.
- Dokploy güncellemesinden sonra olgu betiği koşulur (Dokploy'un kendi servisleri ve Traefik).

## Consequences

- Etkinlik uygulamaları ve `dokploy-network`'teki öteki her şey platformun Postgres'ine, Redis'ine, OpenBao'ya ve Dokploy'un veritabanına ulaşamaz. Bir uygulama ele geçse bile bu servislere parola denemesi yapamaz.
- Etkinlik uygulamaları platform uygulamalarına (core, Keycloak'un iç portu, SkyMail) iç ağdan ulaşmayı sürdürür: Traefik'in her yönlendirdiği uygulamaya ulaşması gerekir. Orayı token korur (core-internal-auth spec'i §4.1); ayrı ağ kararı core-internal-auth ticket 10'dadır.
- Veri servisinin her ağ değişikliği servisi yeniden başlatır (Swarm). Production adımları bakım penceresi ister.
- Gece yedeği (`pg_dump` konteynerin içinde, `docker exec`) ve sır döndürmesi (`docker exec` ile Postgres; kapı için ağa bağlanan yan konteyner) etkilenmez; kapı ağı `attachable` kalmalıdır.
- `TRUSTED_PROXY_RANGES` ve Keycloak'un `KC_PROXY_TRUSTED_ADDRESSES` değeri değişmez: Traefik'ten gelen istek yine `dokploy-network`'ten gelir.
- ADR-0057'nin "Ağ yalıtımı yok" maddesinin yerini bu ADR alır.

## Endüstri uygulamasıyla karşılaştırma

**Uyanlar:**
- NIST SP 800-190 §4.3.3: orkestratör ağ trafiğini hassasiyet düzeyine göre ayrı sanal ağlara ayırmalı. Veri katmanı ayrı ağda, ortamlar ayrı ağlarda.
- Microsoft cloud security benchmark NS-1 (ağ bölümleme sınırları) ve NS-2 (PaaS veri servislerini genel ağdan çıkarıp yalnız uygulama katmanına açmak, Private Endpoint deseni): veri servisi yalnız uygulama katmanından erişilir.
- Docker'ın önerisi: varsayılan ağ yerine kullanıcı tanımlı ağlar; dışarı çıkışı olmayan servis için `internal` ağ.
- Değişiklik geri dönüşlü ve önce sandbox'ta.

**Sapmalar (hepsi):**
1. **Overlay şifresiz** (CIS Docker Benchmark v1.8.0 §7.3 "bütün Swarm overlay ağları şifreli olmalı"). Docker'ın `--opt encrypted`'i düğümler arasında IPsec tüneli kurar; tek düğümde tünel yoktur, trafik hiç VXLAN'a çıkmaz, kazanç sıfır, Docker belgesi ise "kayda değer performans bedeli" diyor. Dokploy da şifreli ağ kuramaz. VXLAN portları internete kapalı (post-cutover 12). Sunucuya ikinci bir düğüm eklenirse bu sapma kapanmalıdır.
2. **Etkinlik uygulamaları ve platform aynı sunucuda** (NIST SP 800-190 §4.3.4, farklı hassasiyetteki iş yüklerini ayrı makinelerde tutmak). ADR-0057'den devralınan kabul; kaynak sınırlarıyla hafifletiliyor.
3. **Ayrım ağ üyeliği düzeyinde, akış düzeyinde değil.** Kubernetes NetworkPolicy'nin "varsayılan red + port başına izin" karşılığı yok. Aynı veri ağındaki iki uygulama birbirine o ağdan da ulaşabilir; core, Redis'i kullanmasa da Postgres'le aynı ağdaki Redis'e ulaşabilir.
4. **Etkinlik uygulamaları platform uygulamalarıyla `dokploy-network`'te kalıyor** (Traefik'in tek ağda olması). Uygulamadan uygulamaya iç erişimi kimlik doğrulaması korur, ağ korumaz.
5. **`sky-lab-production-data` ve `sky-lab-secrets` `attachable`.** Docker soketine erişen biri (root) bu ağlara bir konteyner bağlayabilir. Rotatorun kapı adımı ve OpenBao arayüz tüneli bunu gerektirir; root'a karşı ağ zaten koruma değildir. Öteki ağlarda kapalı.
6. **Veritabanı bağlantıları TLS'siz** (Microsoft cloud security benchmark DP-3, aktarılan veriyi şifrelemek). Trafik tek makinenin içinde, özel ağda kalır; kapı Redis'i zaten mTLS.
7. **Ölü adam geri dönüşü Dokploy'un veritabanına doğrudan SQL yazar** (API'yi ve denetim kaydını atlar). API anahtarı diske konmasın diye seçildi; yalnız geri dönüşte ve yalnız ağ alanlarına.

## Considered Options

- **Bugünkü kabulü sürdürmek (ADR-0057):** Etkinlik uygulaması ya da başka bir konteyner ele geçerse platform veritabanlarına ve Dokploy'un veritabanına parola denemesi yapabilir. Dokploy veritabanı eski sabit parolayla duruyorsa doğrudan okunabilir.
- **Docker'da elle `docker network connect` / `--network-add`:** Dokploy'un ilk deploy'u siler. Yalnız Dokploy'un yönetmediği servislerde kullanılır.
- **Tek bir `skylab-platform-internal` ağı (production ve sandbox birlikte):** Sandbox uygulamaları production veritabanına ulaşırdı; ortam ayrımı bozulur.
- **Her veri servisine ayrı ağ:** Daha ince ayrım ama Dokploy'da her uygulamaya üç dört ağ, panelde kalabalık. Ortam başına bir veri ağı bu ölçekte yeterli; sapma 3 olarak kayıtlı.
- **Etkinlik uygulamalarını da `dokploy-network`'ten çıkarmak (compose + Isolated Deployment ya da Traefik'i elle bağlayan systemd birimi):** Uygulamadan uygulamaya erişimi de keser ama Traefik yeniden yaratıldığında bir sonraki deploy'a kadar yönlendirme kopar. Ayrı karar (ticket 10).
- **Şifreli overlay:** Tek düğümde etkisiz, Dokploy kuramıyor; sapma 1.

## Ek: tek ClamAV, ortamlar arası ikinci ağ `sky-lab-scan` (2026-10-05)

Karar (Yusuf, 2026-10-04; uygulama planı 2026-10-05). core'un kötü amaçlı yazılım taraması (ADR-0052) için sunucuda **tek** bir ClamAV (clamd) koşar. "SKY LAB Production" projesinde durur. production core'u ve sandbox core'u ona yalnız onlarla paylaştığı bir overlay ağdan ulaşır.

Neden tek kurulum: bellek. clamd imza veritabanını yükleyince ~1 GiB tutar ve sunucuda swap yok. Ortam başına bir kopya bu belleği ikiye katlardı (yeniden deploy'da birkaç dakika dört kopya). Sandbox'ın tarama yükü ise denemelerden ibaret.

| Ağ | Üyeler | `internal` | `attachable` | Not |
|---|---|---|---|---|
| `sky-lab-scan` | clamav (production projesinde), core (production), core (sandbox) | hayır | hayır | freshclam imza veritabanını internetten indirir, bu yüzden internal değil. clamav `dokploy-network`'ten ayrılır; alan adı ve yayınlanmış portu yok. İki core `dokploy-network`'te kalır ve bu ağı ek olarak alır. |

- **Bu, "bir ağ bir ortama aittir" kuralının OpenBao'dan sonra ikinci istisnasıdır.** Ad, ortamı olmayanların kuralıyla verildi (`<proje>-<amaç>`), çünkü ağ iki ortama hizmet ediyor; `sky-lab-secrets` gibi.
- **Koruma yalnız ağ üyeliğidir.** clamd'nin kimlik denetimi yoktur; tarama dışında `SHUTDOWN` gibi komutları da vardır. Bu yüzden `dokploy-network`'te durmaz. Üyelik Dokploy'un alanlarına yazılır, her deploy aynı ağları kurar:
  - clamav: `networkIds` = [`sky-lab-scan`] ve `detachDokployNetwork`;
  - core'lar: var olan `networkIds`'e eklenir.
- **Yalıtımı kurulum wizard'ı her koşuda denetler:**
  - Üye olmayanların ağ ad alanından (Traefik, `dokploy-network`'teki yeni bir konteyner, bir etkinlik uygulaması, iki Forms) clamd'ye PING gönderilir; yanıt gelmemelidir.
  - Aynı yoklama clamav'ın kendi ad alanından PONG almalıdır. Bu, yoklama aracının çalıştığını kanıtlar.
  - İki core'dan EICAR öz-denemesi FOUND dönmelidir.
  - Sonuçlardan biri tutmazsa wizard FAIL verir.
- **Ortamlar arası etki.** İki core aynı ağda olduğu için sandbox core'u production core'una bu ağdan da ulaşabilir. Ama ikisi zaten `dokploy-network`'te birbirine ulaşıyordu; yeni bir yol açılmaz (sapma 4).
  - Sandbox core'unu ele geçiren biri clamd'yi meşgul edebilir ya da kapatabilir. Tarama durur, Swarm clamd'yi yeniden başlatır.
  - core taranamayan dosyayı hiçbir zaman temiz saymaz (fail-closed). Production'daki dosyalar `scanning` durumunda bekler ve açılmaz.
  - Gizlilik etkisi yoktur: clamd dosyayı yalnız tarar, saklamaz ve kimseye geri vermez.
- **Geçiş sırası 4 (production Postgres ve Redis)** core'un `networkIds`'ine yalnız ekleme yapar; `sky-lab-scan`'i korur. İki ortamın core'unun bu ağda buluşması o adımda engel sayılmaz.
- **Geri dönüş.** Tarama adresi core'ların ortamından silinir (tarama kapanır, taranması gereken purpose'lar reddedilir) ve clamav durdurulur. Ağ kaydı yalnız ona başvuran servis kalmayınca silinir (yukarıdaki kural).

Sapmalar (bu ekle gelenler):

8. **Ortamlar arası ikinci ağ.** Ortam ayrımı (NIST SP 800-190 §4.3.3) bir yardımcı servis için kaldırıldı. Bedeli yukarıda: yalnız erişilebilirlik, fail-closed.
9. **clamd protokolü kimliksiz ve şifresiz.** Gerekçe sapma 6 ile aynı: trafik tek makinede ve özel ağda kalır.

Değerlendirilen ve seçilmeyenler:

- **Ortam başına bir ClamAV** (2026-10-04'e kadarki plan; sandbox kopyası kuruldu, sonra durduruldu): ~1 GiB daha bellek ister.
- **clamav'ı `dokploy-network`'te bırakmak:** ağdaki her konteyner clamd'ye komut gönderebilirdi.
- **Ağı `internal` yapıp clamav'a ayrı bir çıkış ağı vermek:** üyelik aynı kalır, kazanç yok, bir ağ fazla.
- **Dışarıdan bir tarama hizmeti:** kişisel veri içeren Answer file'lar üçüncü bir tarafa giderdi. Medya kararlarında kendi konteyner seçilmişti.
