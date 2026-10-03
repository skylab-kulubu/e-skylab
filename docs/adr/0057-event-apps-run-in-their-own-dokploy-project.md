---
status: accepted
---

# Etkinlik uygulamaları platformla aynı sunucuda, ayrı bir Dokploy projesinde çalışır

Place, Guessr ve 3aşağı5yukarı kulübün etkinlik uygulamalarıdır: bir stant haftası, jam ya da sponsor etkinliği için yazılırlar, etkinlik bitince bakımları azalır. Bu uygulamalar da Dokploy'a taşınır ama "SKY LAB Production" projesine girmez. Hepsi "SKY LAB Etkinlik" adlı ayrı bir Dokploy projesinde, `production` adlı tek bir ortamda çalışır. "SKY LAB Production" platformu ve kulübün web sitelerini taşır: Keycloak, core, Forms, SkyMail, CMS, OpenBao ve onların veri katmanı; ana site ve artlab, gecekodu gibi statik tanıtım siteleri. Ayrım uygulamanın ne tuttuğuna göredir: kendi verisini, kendi login'ini ya da kendi sırlarını tutan etkinlik uygulamaları "SKY LAB Etkinlik"e girer; veri tutmayan, yalnız sayfa sunan kulüp siteleri ana siteyle birlikte Production'da durur (2026-09-29). ADR-0028 bu uygulamaların "kendi ortamlarında" kaldığını söylüyordu; bu karar o ortamın Dokploy'daki karşılığını belirler.

Ayrı proje dört şey sağlar:
- **Erişim:** Bir etkinlik ekibine yalnız kendi projesi açılır. Platform uygulamalarını ve değişkenlerini görmez.
- **Sırlar:** Etkinlik projesinin ortamı kendi OpenBao sağlayıcısını kullanır (ADR-0049), platform sırlarını okuyamaz.
- **Temizlik:** Etkinlik bittiğinde uygulaması platform projesine dokunmadan silinir.
- **Düzen:** Bu kulüpte Dokploy "ortamı" bir aşamayı anlatır; production ile sandbox projelerle ayrılır.

## Consequences

- **Veri:** Her etkinlik uygulamasının kendi veritabanı vardır. Platform Postgres'i ve Redis'i kullanılmaz (ADR-0028). İmajlar GHCR'dan çekilir, sunucuda derleme yapılmaz.
- **Ağ yalıtımı yok:** Ayrı proje ağı ayırmaz; Dokploy servisleri aynı Docker ağını paylaşır. Ayrım erişim, sır ve düzen düzeyindedir. Platform veritabanlarını yalnız kimlik bilgileri korur. *(2026-10-03: ADR-0061 bu maddeyi değiştirir; bkz. aşağıdaki ek.)*
- **Kaynak sınırı:** Etkinlik uygulamaları platformla aynı sunucudadır. Bu yüzden her birine CPU ve RAM sınırı konur; bir etkinliğin trafiği platformu yavaşlatmamalı.
- **Başkası adına barındırılan siteler:** Kulübün başkası adına barındırdığı, etkinlik uygulaması olmayan bir site etkinlik projesini paylaşmaz, kendi projesine girer. Ekstremspor'un hangi projeye gireceği, sahibi netleşince bu kurala göre belirlenir.

## Considered Options

- **"SKY LAB Production" projesine eklemek:** En az iştir. Ama etkinlik uygulamalarını platformun erişimi, sırları ve proje değişkenleriyle aynı yere koyar.
- **"SKY LAB Production" içinde ayrı bir Dokploy ortamı:** Ortamın aşama anlamını bozar. Proje düzeyindeki paylaşılan değişkenler bu ortamdan da görünür.
- **Her uygulamaya ayrı proje:** Etkinlik başına bir proje, bu ölçekte panelde gereksiz kalabalık yapar. Ortak kural ve sınırlar tek projede daha kolay tutulur.

## Ek: ağ ayrımı (2026-10-03)

"Ağ yalıtımı yok" maddesi ADR-0061 ile değişti. Veri servisleri (platform ve etkinlik veritabanları, Redis'ler, OpenBao, Dokploy'un veritabanı) `dokploy-network`'ten çıkar ve yalnız onları kullanan uygulamalarla paylaştıkları özel ağlarda durur. Etkinlik projesinin veritabanları kendi projesinin veri ağındadır; etkinlik uygulamaları platformun veri servislerine ulaşamaz. Etkinlik uygulamaları alan adları için `dokploy-network`'te kalır; platform uygulamalarına iç erişimi token korur.
