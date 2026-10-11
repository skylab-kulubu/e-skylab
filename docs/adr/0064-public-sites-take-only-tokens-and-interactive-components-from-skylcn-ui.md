---
status: accepted
---

# Public siteler skylcn-ui'den yalnız token'ları ve etkileşimli bileşenleri alır; Space yazı tipleri ürünlerindir

ADR-0055 skylcn-ui'yi SKY LAB web ürünlerinin ortak tasarım dili yaptı. Rollout'u beş ürünü sayar: admin paneli, forms-frontend, skymail-frontend, account-center ve Keycloak login teması. Public siteler (yildizskylab.com yani `skylab-site`, `arge`, `artlab-site`) orada yok. Geçişe başlarken dört soru açık kaldı:

- Public siteler skylcn-ui'den ne alır?
- Yazı tipi her yerde Space Grotesk / Space Mono mu? `skylab-site` Manrope, `arge` ve `forms-frontend` JetBrains Mono kullanıyor. skylcn-ui'nin `theme.css`'i `--font-sans`'ı Space Grotesk'e bağlıyor; tema bir siteye girdiği anda o sitenin yazı tipi de değişir.
- skylcn-ui `motion` 13 kullanıyor. `skylab-site`, `arge` ve `forms-frontend` ise `framer-motion` 12'de. Geçilsin mi?
- ADR-0055 "Renovate veya Dependabot" diyor. Hangisi?

Bu ADR, ADR-0055'e ektir. ADR-0055'in burada sayılmayan maddeleri geçerlidir.

Karar (Kaan, 2026-10-11):

1. **Public siteler skylcn-ui'den yalnız token'ları ve etkileşimli bileşenleri alır.** `skylab-site`, `arge` ve `artlab-site` kendi görsel katmanlarını yazı tipi dahil korur. Örnek (`arge` #8): token'lar, NavigationMenu, Drawer ve `buttonVariants` alınır; yazı tipi Space'e geçmez.
2. **Space Grotesk / Space Mono ürünlerin yazı tipidir:** admin paneli (`core-frontend`), Forms (`forms-frontend`), SkyMail (`skymail-frontend`), Account Center (`account-center`) ve Keycloak login teması. Public siteler kendi yazı tiplerinde kalır.
3. **`framer-motion` 12'den `motion` 13'e geçilir,** skylcn-ui kullanan her depoda. Aynı uygulamada iki animasyon kütüphanesi birden yüklenmez.
4. **Güncelleme botu Dependabot'tur.** skylcn-ui kullanan her depoda haftada bir çalışır. `@skylab-kulubu/*` paketlerinin güncellemeleri tek, gruplu bir PR'da gelir.
5. **`skylab-site`'ın `/kapi` ve `/sertifika` sayfaları hep koyudur.** Site tamamen koyu ve tema seçicisi yok; bu iki sayfa sistem temasını izlemez.
6. **Dokümantasyon GitHub Pages'te yayımlanmaz.** Belgeler ve önizlemeler admin panelinin `/playground` yolundadır. Playground `core-frontend` imajına derlenir; production imajı onu içermez. ADR-0055'teki "wiki hazır olunca oraya taşınır" niyeti değişmedi.

## Consequences

- Public site skylcn-ui temasını içe aktarırsa kendi yazı tipi değişkenini korur. Temanın Space Grotesk bağlaması yalnız ürünlerde geçerlidir.
- skylcn-ui'ye geçen her depo aynı geçişte `framer-motion`'ı bırakır.
- skylcn-ui kullanan her depoya npm için haftalık bir Dependabot ayarı girer. Gruplu PR yalnız `@skylab-kulubu/*` paketlerini kapsar; diğer bağımlılıklar için PR açılmaz. Depo skylcn-ui'yi main'e aldığında ayar da gelir.
- ADR-0055'in ürün depolarındaki issue'ları (core-frontend#1, account-center#59, skymail-frontend#68, forms-frontend#19) bu kararlarla güncellenir.

## Considered Options

- **Public siteler skylcn-ui'yi tamamen alır (görsel katman ve yazı tipi dahil):** seçilmedi; karar 1.
- **Space Grotesk / Space Mono her yerde, public siteler dahil:** seçilmedi; karar 2.
- **`framer-motion` 12'de kalmak:** seçilmedi; karar 3.
- **Renovate:** ADR-0055 ikisini de açık bırakmıştı; Dependabot seçildi.
- **`/kapi` ve `/sertifika` sistem temasını izler:** seçilmedi; karar 5.
- **Dokümantasyon deponun GitHub Pages yüzeyinde (ADR-0055'in ilk metni):** kullanılmıyor; karar 6.
