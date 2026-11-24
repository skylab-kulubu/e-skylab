---
status: accepted
---

# Yayın modeli: main kendiliğinden sandbox'a gider; production'a aynı ağacın imajı, squash'lı production dalıyla terfi eder; yayını insan Mac'ten tek komutla başlatır

ADR-0028 sunucuda derleme yapılmayacağını ve Dokploy'un GHCR'dan çekeceğini yazdı, ama yayının nasıl yapıldığını yazmadı. "Production pins `:latest`" cümlesi de bayatladı. Bugünkü model kodda ve sihirbazlarda duruyor, hiçbir ADR'de yok (sektör denetimi 05, 2026-11-24). Bu ADR onu yazıya geçirir.

Karar (Yusuf: main → production tek squash, Eylül 2026; tek komut, 2026-11-22; sektör denetiminden sonra yazıya geçti, 2026-11-24):

1. **main kendiliğinden sandbox'a gider.** İş kısa ömürlü dallardan PR'la main'e girer. main'e her push'ta CI koşar, imaj GHCR'a `:latest`, `:sandbox` ve commit etiketleriyle basılır (core-backend ayrıca `tree-<git ağacı>`), sandbox'ın Dokploy kancası çağrılır. e-skylab-keycloak'a bu karar uygulanmaz: main GHCR'a imaj basmaz, sandbox kancası yoktur (karar 3).
2. **production dalı squash'lıdır.** Yayın, main'in ağacını production'ın üstüne tek bir commit yapar (`git commit-tree "$(git rev-parse 'origin/main^{tree}')" -p origin/production`), bunu `release/production-<tarih>-<konu>` dalına iter, production'a PR açar ve `gate` yeşil olunca squash'la birleştirir. production'ın ağacı main'in bir ağacına bayt bayt eşittir; satır düzeyinde birleştirme kararı yoktur.
   - production'ın soy ağacı main'e bağlı değildir. Ne yayında, ne değil, `git log` ile değil `git diff origin/production origin/main` ile okunur.
   - Ağaç eşitliği main'deki her işi taşır. main'de başkasının birleştirip henüz yayınlanmamış işi varsa yayından önce sahibine sorulur.
3. **İmaj yeniden derlenmez, terfi eder.** production push'unda main'de test edilmiş imaj yeniden etiketlenir ve production'ın Dokploy kancası çağrılır; sandbox'ta koşan bayt production'da koşar. Depoya göre yol:
   - **core-backend:** GHCR iş akışı aynı ağacın tam test koşusunun yeşil geçtiğini arar (`scripts/ci/tested-tree.sh`) ve main'in `tree-<ağaç>` imajını `:production` ve commit etiketiyle yeniden etiketler.
   - **skymail-backend, skymail-frontend:** main'deki `gate` koşusunu GitHub API'siyle bulur, o koşunun `sha-` etiketli imajını terfi ettirir.
   - **account-center:** imaj `production-<sha7>` etiketiyle terfi eder.
   - **core-frontend:** `production-candidate` imajı terfi eder (bu imaj ayrı derlenir, sapma 5).
   - **e-skylab-keycloak:** production push'unda CI'ın test ettiği aday paket yayımlanır; CI'daki adayın SHA-256'sı yayında yeniden doğrulanır.
   - Yeni depolar bu kalıpla açılır.
4. **Hotfix yolu.** main yayınlanmamış iş taşıyorsa ve yalnız bir düzeltme çıkacaksa: production'dan `hotfix/<ad>` dalı açılır, düzeltmenin main'deki commit'leri cherry-pick edilir, PR production'a açılır. Bu ağaç main'de hiç olmadığı için CI onu kendi koşusunda test eder ve imajı yeniden derler (core-backend'de iş akışı bunu kendisi ayırır). Sonraki tam yayın (ağaç = main) onu çakışmasız içine alır.
5. **Geri dönüş aynı imajladır.** core-backend'de ağaç etiketleri kalıcıdır: geri dönmek, önceki ağacın imajını yeniden `:production` yapmak ve kancayı çağırmaktır; yeni derleme gerekmez. Öbür depolarda geri dönüş, önceki yayının imajına ya da adayına aynı yolla dönmektir; ağaç etiketiyle geri dönüş yalnız core-backend'de vardır.
6. **Yayını insan Mac'ten tek komutla başlatır.** `ops/wizards/tek-komut.sh` bir planın adımlarını sırayla koşar: kuru koşu ve beklenen satırlar, PR, `gate`, `--match-head-commit` ile squash birleştirme, GHCR terfisini bekleme, kanca, çalışan konteynerin özetini GHCR özetiyle karşılaştırma. Sunucu adımları (göç öncesi DB dökümü, Dokploy ve OpenBao ayarları, doğrulamalar) sunucuda `systemd-run` birimlerinde koşar ve SSH koparsa sürer. Plan dışı bir şeyde durur ve geri alma satırını basar. Planlı adımlar onay sormaz; insana yalnız parola ve tarayıcı girişi sorulur. Sırlar argv'ye, ekrana ve günlüğe girmez.
7. **GitHub Environments onay kapısı kullanılmaz.**
   - Onay zaten vardır: yayın bir PR'ın birleşmesidir ve onu yayını başlatan insan yapar. "Required reviewers" aynı kişiye ikinci bir tıklama ekler; ayrı bir onaylayan yoktur.
   - Kapı yalnız Actions'taki işi durdurur. Yayının yarısı sunucudadır (göç öncesi döküm, ayarlar, doğrulama) ve sudo ister; sunucu anahtarı parolalıdır ve Actions'a verilmez.
   - Ortam yalnız dal politikası ve yayın değişkeni için kullanılır: e-skylab-keycloak'ın `keycloak-production` ortamı (Touch ID kanıtı) gibi.

## Consequences

- ADR-0028'in "Production pins `:latest`" cümlesi düzeldi (o ADR'nin 2026-11-24 güncellemesi).
- CONTEXT.md'ye "Release" ve "Hotfix" eklendi.
- Açık işler (bu ADR karara bağlamaz): yayın sihirbazlarının ortak gövdesini (PR → squash → terfi → kanca → özet) parametreli tek betikte toplamak; deploy kancalarını repo secret'ından `production` ortamının secret'ına taşımak; core-frontend'in `NEXT_PUBLIC_*` adreslerini çalışma anına taşıyıp tek imaja inmek (Kaan); production push'unda yeniden derleyen depoları terfiye geçirmek (sahipleri).

## Endüstri uygulamasıyla karşılaştırma

**Uyanlar:**
- **Bir kez derle, terfi ettir** (karar 3). 12-factor'ün derleme, yayın ve çalıştırma ayrımı ve Google Cloud Deploy'un aynı yapıtı ortamdan ortama terfi ettirmesi.
- **Trunk-based geliştirme ve GitHub Flow** (karar 1). Kısa ömürlü dallar, main her zaman sandbox'ta.
- **Tekrarlanabilir, denetlenebilir yayın** (karar 6). Google SRE release engineering: kuru koşu, beklenen satır, çalışan özetin doğrulanması.
- **Test edilmiş ağaç kapısı** (karar 3). NIST SSDF PW.7/PW.8: gözden geçir, test et, sonra yayınla.

**Sapmalar (hepsi):**
1. **Ortam dalı.** Sektörde yayını genelde değişmez bir sürüm etiketi ya da GitHub Deployments kaydı belirler. Bizde squash'lı production dalı belirler ve `git log` yanıltır. Dal, kancanın tetikleyicisi ve PR'daki `gate`'in yeridir; ağaç eşitliği sürümün kanıtıdır.
2. **Kademeli yayın (canary) yok.** Google SRE canary'yi, Microsoft halka halka yayını önerir. Tek sunucu ve küçük trafikte bunun yerine sandbox ön ortamı, özet doğrulaması ve aynı imajla geri dönüş var.
3. **Onay kapısı yok, yayın tek kişinin Mac'inden** (karar 7). GitHub Environments'ın "required reviewers" kuralı ve yalnız production dalından deploy kullanılmıyor. Tek kişi bağımlılığı bilinçli kabul.
4. **GitOps yok.** OpenGitOps, Argo CD ve Flux istenen durumu Git'te tutar ve sürekli uzlaştırır. Dokploy'un istenen durumu (env, ağ, alan adı) kendi veritabanındadır ve GitOps desteği yoktur; sapmayı olgu betikleri yakalar. Yayın başına kopyalanan sihirbaz SRE'nin "toil" dediği iştir (Consequences'taki açık iş).
5. **core-frontend her commit için iki imaj basar.** `NEXT_PUBLIC_*` adresleri derlemede gömülür, production baytları sandbox'ta koşmamış olur (12-factor III). Aynı ağaçtan, aynı koşuda derlenir.
6. **Bazı depolarda yayın, ağacın main'de test edilmiş olmasına bağlı değildir** (skylab-site, arge, artlab-site, cms-backend, yildizplace-backend, ekstremspor, Forms): production push'unda imaj yeniden derlenir. arge'nin testi PR'da ve main'de koşar, ama production yayını o koşuya bakmaz; yildizplace-backend production'da `mvn verify` koşup derler. Karar 3'e ve SSDF'ye aykırıdır; sahiplerinin işidir.
7. **Değişiklik kaydı GitHub Deployments'ta değil,** hub'daki yayın günlüklerindedir. DORA'nın dört ölçütünden yalnız yayın sıklığı ölçülebiliyor.

## Considered Options

- **main'i production'a birleştirmek.** Squash geçmişinde iki tarafın da dokunduğu her dosya çakışır ve satır düzeyinde karar ister; ağaç eşitliği bunu kaldırır.
- **Production'da yeniden derlemek.** Sandbox'ta koşmamış bayt yayınlanır; terfi seçildi.
- **GitHub Environments onayıyla Actions'tan yayın.** Sunucu adımları Actions'a sunucu anahtarı vermeden yapılamaz (karar 7).
- **GitOps uzlaştırıcısı.** Kubernetes yok; Dokploy'un durumu Git'te değil.
- **Değişmez sürüm etiketiyle (`v*`) yayın.** core'da etiket iş akışı var ama Dokploy kancası daldan tetiklenir; dal ve ağaç eşitliği yetiyor.

## Kaynaklar

- 12-factor, derleme/yayın/çalıştırma: https://12factor.net/build-release-run · yapılandırma: https://12factor.net/config
- Google Cloud Deploy, terfi: https://cloud.google.com/deploy/docs/promote-release
- Trunk-based development: https://trunkbaseddevelopment.com/ · GitHub Flow: https://docs.github.com/en/get-started/using-github/github-flow
- Google SRE, release engineering: https://sre.google/sre-book/release-engineering/ · toil: https://sre.google/sre-book/eliminating-toil/ · canary: https://sre.google/workbook/canarying-releases/
- Microsoft, safe deployment practices: https://learn.microsoft.com/en-us/azure/well-architected/operational-excellence/safe-deployments
- GitHub, deployments and environments: https://docs.github.com/en/actions/reference/workflows-and-actions/deployments-and-environments
- OpenGitOps: https://opengitops.dev/ · Argo CD: https://argo-cd.readthedocs.io/en/stable/ · Flux: https://fluxcd.io/flux/concepts/
- NIST SP 800-218 (SSDF): https://csrc.nist.gov/pubs/sp/800/218/final
- DORA dört ölçüt: https://dora.dev/guides/dora-metrics-four-keys/
- Next.js ortam değişkenleri: https://nextjs.org/docs/app/guides/environment-variables
- Kod: core-backend `.github/workflows/ghcr.yml`, `scripts/ci/tested-tree.sh`; e-skylab-keycloak `.github/workflows/release.yml`; hub `ops/wizards/tek-komut.sh`.
