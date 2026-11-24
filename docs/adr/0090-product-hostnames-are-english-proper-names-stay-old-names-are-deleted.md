---
status: accepted
---

# Ürün alt alan adları İngilizcedir; etkinlik ve kulüp adları özel isim olarak kalır; eski Türkçe adlar yönlendirme olarak tutulmaz: SkyMail arayüzü `notify.`, durum sayfası `status.`, SkyEvents `events.`

Alt alan adlarının çoğu İngilizce (`admin.`, `my.`, `forms.`, `api.`, `cdn.`), ama üç ürün Türkçe adla açıldı: SkyMail arayüzü `iletisim.` (ADR-0070 karar 8 "Açık: Alan adı", 25 Ekim), durum sayfası `durum.` ve sinyal deposu `nabiz.`. Arayüzün eski adı `mail.` de 301 ile yaşıyordu; servis ADR-0070 ile posta, push ve SMS taşıyacağı için "mail" adı da artık ürünü anlatmıyor.

Karar (Yusuf, 2026-11-24):

1. **Ürün adresleri İngilizce, kısa ve ürünün işine uygundur.** Sandbox karşılığı `sandbox-<ad>.` olur.
2. **Etkinlik ve kulüp adları özel isimdir, olduğu gibi kalır:** `gecekodu.`, `artlab.`, `skydays.`, `yildizjam.`, `ekstrem.`, `arge.`, `agc.` (ve sandbox'ları). Bunlar çevrilmez.
3. **Eski Türkçe adlar yönlendirme olarak tutulmaz; geçişle birlikte silinir.** Geçiş tek penceredir: yeni ad açılır, onu kullanan her yer (uygulama ayarları, derlemede gömülen adresler, Keycloak istemcisi, şablonlar, Forms'un yayını) aynı pencerede yeni ada geçer. Eski ad, aynı pencerenin sonunda ön koşul kapısı tutunca silinir: hiçbir uygulamanın ayarında ve yayındaki paketinde eski ad kalmamıştır, yayımlanmış şablonlarda eski ad yoktur, yeni adda giriş çalışır. Kapı tutmazsa silme durur ve eksik olan söylenir; eski ad yönlendirmeye çevrilmez, eksik tamamlanınca silinir.
4. **SkyMail arayüzü: `notify.yildizskylab.com`, sandbox `sandbox-notify.yildizskylab.com`.** `iletisim.`, `mail.`, `sandbox-iletisim.` ve `sandbox-mail.` silinir. Yalnız adres değişir: depo adları (`skymail-*`), Keycloak istemci kimliği `skymail`, `skymail:*` rolleri, imajlar, `/v1` yolları ve koddaki "skymail" adları aynı kalır. Arayüzde görünen ürün adı ayrı iştir. Bu karar ADR-0070 karar 8'in alan adı cümlesini ve "Açık: Alan adı" maddesini kapatır.
5. **`skymail` istemcisinin adresleri kodda durur.** Redirect URI, web origin, çıkış dönüşü, `rootUrl` ve `baseUrl` e-skylab-keycloak uzlaştırıcısının işidir (`reconcile_login_clients`): production'da yalnız `notify.` kalır, başka satır silinir. Tek istisna sandbox realm'idir: `sandbox-notify.`'ın yanında yerel geliştirme için `http://localhost:3000` da kalır (production'da localhost yok). Bu adresler o güne kadar Admin Console'da elle tutuluyordu.
6. **Durum sayfası: `status.yildizskylab.com`.** `durum.` silinir. Sinyal deposu `nabiz.` kalkar; sunucu işlerinin sinyali `status.yildizskylab.com/heartbeat` yolundan alınır (`POST /heartbeat/<iş>/<olay>`, özet `GET /heartbeat`). Sıra: önce yeni yol çalışır, sonra sunucu ve GitHub tarafı yeni adrese geçer, en sonda `nabiz.` ve `durum.` silinir.
7. **SkyEvents: `events.yildizskylab.com`, sandbox `sandbox-events.yildizskylab.com`** (`event.` değil; CONTEXT.md'deki Event site ve ADR-0034 ile aynı).

Kapsam dışı: `bildirim.` ve `duyuru.` web adı değil, Microsoft 365'in gönderen alt alanlarıdır (ADR-0072) ve kalır. `e.`, `e-admin.`, `devops1.`, `app.`, `cdn.`, `api.` ve öbür İngilizce adlar değişmez.

## Consequences

- Silmeden sonra daha önce gönderilmiş postalardaki konsol bağlantıları açılmaz (Mail onayı istek ve sonuç postalarındaki düğmeler, gönderim hatası postasındaki görev bağlantısı) ve SkyMail şablonlu eski postaların başlık logosu boş görünür. Açılma ve tıklama takibi, abonelikten çıkma ve giriş kodu gibi bağlantılar konsol adını kullanmadığı için etkilenmez. Yusuf bunu kabul etti.
- Eski GitHub alarm issue'larındaki ve RSS öğelerindeki `durum.…/#olay-N` bağlantıları kırılır.
- Konsola bağlanan her uygulama (skymail-backend `SKYMAIL_UI_URL`, skymail-frontend şablonları ve `AUTH_URL`, core-frontend ve forms-frontend'in derlemede gömülen `mail_url`'si, Keycloak karşılama sayfası) silmeden önce `notify.`'la yayında olmalıdır. Forms Fatih'in deposudur; ona not gider, silme Forms'un yeni adla yayınını bekler.
- e-skylab-keycloak'ın uzlaştırıcısı production'da ilk koşuda `iletisim.` ve `mail.` satırlarını siler; o sürüm geçiş penceresinde yayınlanır.
- README ve `docs/repositories.md` arayüz adresini `notify.` olarak gösterir.

## Endüstri uygulamasıyla karşılaştırma

**Uyanlar:**
- İngilizce, işi anlatan kısa alt alan adları (`status.`, `notify.`, `events.`) yaygın kullanımdır; durum sayfaları için `status.<alan>` neredeyse standart addır.
- Bir ürünün tek kanonik adresi olması: aynı içeriğin iki adda yayınlanmaması.

**Sapma:**
1. **Eski ad yönlendirmesiz silinir.** Sektör alan adı taşımada eski adreslerin kalıcı yönlendirmesini uzun süre tutmayı önerir (Google Search Central site taşıma rehberi en az bir yıl; W3C "Cool URIs don't change"). Bizde eski adlar geçişle birlikte silinir. Gerekçe: konsol herkese açık bir site değil, kulüp içi bir araçtır; eski bağlantıların çoğu tek kullanımlık ya da kısa ömürlü postalardadır; yönlendirme dosyası, ek DNS kaydı, sertifika ve Keycloak satırı bakım ister. Bedeli yukarıda yazılı; Yusuf kabul etti.

## Considered Options

- **Eski adları bir süre 301 ile tutmak.** Seçilmedi (karar 3).
- **İki adın birlikte çalıştığı geçiş dönemi** (`AUTH_TRUST_HOST` ile). Gereksiz bir ara durum ve iki adın Keycloak'ta birlikte kayıtlı kalması; seçilmedi.
- **`notifications.` ya da `comms.`** Uzun ya da belirsiz; `notify.` kısa ve işi anlatıyor.
- **Türkçe adları sürdürmek** (`iletisim.`, `durum.`). Öbür ürün adlarıyla tutarsız; seçilmedi.

## Kaynaklar

- Google Search Central, site taşıma: https://developers.google.com/search/docs/crawling-indexing/site-move-with-url-changes
- W3C, Cool URIs don't change: https://www.w3.org/Provider/Style/URI
- ADR-0034 (etkinlik siteleri), ADR-0070 (iletişim servisi), ADR-0072 (posta akışları ve gönderen alt alanları).
