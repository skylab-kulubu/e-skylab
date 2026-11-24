# Certificate links stay short while the club site owns verification UI

The canonical Certificate address remains `https://skyl.app/c/{opaque-serial}` so printed QRs stay compact and their destination can move without reissuing credentials. The active core-backend owns that route and responds with a temporary redirect to `https://yildizskylab.com/sertifika/{opaque-serial}`. The active `skylab-site` project owns the human verification UI and reads only the minimal public Certificate endpoint. `skyl.app` is a link service, not a separate presentation frontend; no Certificate UI belongs in the inactive skyl-app frontend or backend repositories.

## Ek: doğrulama sayfasında katılım satırı; görünürlük notu (2026-11-24)

Karar (Yusuf, 2026-11-23, K4, K5, S2, S5).

- **Doğrulama sayfası katılımı gösterir.** `yildizskylab.com/sertifika/{seri}` ve herkese açık uç (`/v1/public/certificates/:serial`, `/v1/certificates/verify/:serial`) verme anındaki katılım kopyasını gösterir: "8 oturumdan 6'sı · 9 saat". Kopya üç sayıdır: katılınan sayılan oturum, sayılan oturum toplamı (N) ve katılınan sayılan oturumların program süresi. Sertifika satırına verme anında yazılır ve değişmez; sonradan düzeltilen Check-in onu değiştirmez.
- **PDF'te yok.** Ne varsayılan şablonda ne özel tasarımda (K4).
- Bu özellikten önce verilmiş sertifikalarda satır yoktur (S2); geriye dönük doldurulmaz. İptal edilmiş sertifikada da görünür. Eşik altına elle verilmiş sertifikada gerçek sayı görünür, örneğin "8 oturumdan 4'ü" (S5).
- **Görünürlük.** Seri numarasını bilen herkes kişinin adını, etkinliği ve artık katılım sayısını ve program süresini görür. Satır her zaman görünür, kişi başına gizleme yoktur (K5). Sınırlar:
  - Seri numarası 128 bit rastgeledir; sayfa `noindex` ve `no-referrer` ile sunulur.
  - Oturum adları, Check-in saatleri, e-posta, User id ve Ticket id gösterilmez (CONTEXT _Avoid_ aynen kalır).
  - "Elle verildi" bilgisi ve gerekçe herkese açık değildir.
  - Kopya sertifika satırıyla yaşar ve onunla silinir (ADR-0062).
  - Açık (S7): gizlilik metnine "doğrulama sayfasında katılım sayısı görünür" cümlesinin eklenmesi.
- Uygulama: core-backend (katılım kopyası ve herkese açık alan) ve skylab-site (doğrulama satırı) biletleri: core-backend #404 ve skylab-site #100. Otomatik kapanış production'a kopyadan önce çıkmaz, yoksa ilk otomatik sertifikalar kopyasız kalır.

### Endüstri uygulamasıyla karşılaştırma

**Uyanlar:**
- **Credly.** Kazanma ölçütü rozetin üstünde yazılı gösterilir; bizim "8 oturumdan 6'sı" satırımız buna karşılık gelir.
- **CME (AMA PRA Cat. 1).** Katılınan oturumlar ve saat toplamı standarttır.

**Sapmalar:**
1. **PDF'e yazılmaz,** yalnız doğrulama sayfasında görünür.
2. **Süre ölçülmez.** CME katılım süresine kredi verir; bizdeki saat, katılınan oturumların program süresidir.
3. **Kişi başına gizleme yok;** satır her sertifikada görünür.
