---
status: accepted
---

# Etkinlik uygulamaları platformla aynı sunucuda, ayrı bir Dokploy projesinde çalışır

Place, Guessr ve 3aşağı5yukarı kulübün etkinlik uygulamalarıdır: bir stant haftası, jam ya da sponsor etkinliği için yazılırlar, etkinlik bitince bakımları azalır. Bu uygulamalar da Dokploy'a taşınır ama "SKY LAB Production" projesine girmez. Hepsi "SKY LAB Etkinlik" adlı ayrı bir Dokploy projesinde, `production` adlı tek bir ortamda çalışır. "SKY LAB Production" yalnız platformu taşır: Keycloak, core, Forms, SkyMail, CMS, OpenBao ve onların veri katmanı. ADR-0028 bu uygulamaların "kendi ortamlarında" kaldığını söylüyordu; bu karar o ortamın Dokploy'daki karşılığını belirler.

Ayrı proje dört şey sağlar:
- **Erişim:** Bir etkinlik ekibine yalnız kendi projesi açılır. Platform uygulamalarını ve değişkenlerini görmez.
- **Sırlar:** Etkinlik projesinin ortamı kendi OpenBao sağlayıcısını kullanır (ADR-0049), platform sırlarını okuyamaz.
- **Temizlik:** Etkinlik bittiğinde uygulaması platform projesine dokunmadan silinir.
- **Düzen:** Bu kulüpte Dokploy "ortamı" bir aşamayı anlatır; production ile sandbox projelerle ayrılır.

## Consequences

- **Veri:** Her etkinlik uygulamasının kendi veritabanı vardır. Platform Postgres'i ve Redis'i kullanılmaz (ADR-0028). İmajlar GHCR'dan çekilir, sunucuda derleme yapılmaz.
- **Ağ yalıtımı yok:** Ayrı proje ağı ayırmaz; Dokploy servisleri aynı Docker ağını paylaşır. Ayrım erişim, sır ve düzen düzeyindedir. Platform veritabanlarını yalnız kimlik bilgileri korur.
- **Kaynak sınırı:** Etkinlik uygulamaları platformla aynı sunucudadır. Bu yüzden her birine CPU ve RAM sınırı konur; bir etkinliğin trafiği platformu yavaşlatmamalı.
- **Başkası adına barındırılan siteler:** Kulübün başkası adına barındırdığı, etkinlik uygulaması olmayan bir site etkinlik projesini paylaşmaz, kendi projesine girer. Ekstremspor'un hangi projeye gireceği, sahibi netleşince bu kurala göre belirlenir.

## Considered Options

- **"SKY LAB Production" projesine eklemek:** En az iştir. Ama etkinlik uygulamalarını platformun erişimi, sırları ve proje değişkenleriyle aynı yere koyar.
- **"SKY LAB Production" içinde ayrı bir Dokploy ortamı:** Ortamın aşama anlamını bozar. Proje düzeyindeki paylaşılan değişkenler bu ortamdan da görünür.
- **Her uygulamaya ayrı proje:** Etkinlik başına bir proje, bu ölçekte panelde gereksiz kalabalık yapar. Ortak kural ve sınırlar tek projede daha kolay tutulur.
