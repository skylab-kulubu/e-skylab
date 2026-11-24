# Certificate issuance follows attendance finalization and runs as durable jobs

An Oturum Check-in recomputes eligibility but does not issue a Certificate. An authorized organizer explicitly finalizes attendance after the Event is closed, which snapshots the eligible recipients and queues one durable, idempotent issuance job per recipient; manual issue remains available. Workers resolve and pin the template version, render through Gotenberg with bounded concurrency, store the result, and hand the notification to skymail. Rendering and storage retry in the durable job; delivery lifecycle belongs to skymail after the handoff. This avoids attendees collecting a Certificate before the Event ends and prevents a large Event from rendering every PDF inside one HTTP request.

## Ek: otomatik kapanış, erken elle kapatma, yeniden tarama ve gerekçeli elle verme (2026-11-24)

Karar (Yusuf, 2026-11-23, K3, K6–K8 ve S3, S4, S6, S8): "Etkinlik bitince bir şeye basmak zorunda kalmamalıyım."

- **Otomatik Attendance finalization.** Son canlı oturumun bitişinden 1 saat sonra katılım kendiliğinden kapanır, sertifikalar üretilir ve gönderilir. Oturumun bitiş saati yoksa günün, o da yoksa etkinliğin bitişi alınır; sayılmayanlar dahil bütün canlı oturumlara bakılır. Kapanış elle kapatmayla aynı yoldur: uygunlar o anda alınır, kişi başına kalıcı iş kuyruğa girer. Kapatan kişi boştur, kaynak `auto` yazılır. Şartlar: etkinlik yayında ve arşivsiz, kural `none` değil, otomatik kapanış açık, katılım henüz kapanmamış, en az bir canlı oturum var. Vadesi 7 günden eski olan etkinlik kendiliğinden kapanmaz.
- **Bu, CONTEXT'teki "_Avoid_: silently finalizing from the clock alone" satırını bilerek kaldırır.** Kapanış saate bağlıdır ama sessiz değildir: panel kapanış saatini önceden gösterir, kapanınca "kendiliğinden" yazar ve etkinliği yayınlayana kısa bir posta gider (S6; SkyMail `core.certificate-auto-finalized`: kaç sertifika kuyruğa girdi, paneldeki Sertifikalar sekmesi). Yeni _Avoid_: son oturum bitmeden kapatmak.
- **Etkinlik başına anahtar** (S8). Panelde otomatik kapanış kapatılabilir; varsayılan açıktır. Göç anında bitmiş ama katılımı kapanmamış eski etkinliklerde kapalı başlar (S3): eski etkinliklere toplu posta gitmez, düzenleyen elle kapatır.
- **Erken elle kapatma** (K7, S4). Elle kapatma artık etkinlik bitince **ya da son canlı oturum bitince** açılır; 1 saati beklemez. Yukarıdaki "Event kapandıktan sonra" şartı bu kadar genişler. Taslak ya da iptal edilmiş etkinlik yine kapatılamaz.
- **Çift kapanış olmaz.** Elle kapatma ile otomatik kapanış ya da iki sunucu kopyası yarışırsa tek kapanış ve tek iş grubu yazılır.
- **"Uygunları yeniden tara"** (`rescan`, K8). Yalnız kapanmış etkinlikte çalışır. O an uygun olan, **hiç sertifikası olmayan** (etkin ya da iptal edilmiş) ve bekleyen işi olmayan biletleri `rescan` nedeniyle kuyruğa alır. İptal edilmiş sertifikası olana yeniden verilmez: iptal bir karardır, tarama onu geri almaz; gerekirse elle verilir. Kimse çıkmazsa iş grubu açılmaz.
- **Eşik altına elle verme gerekçe ister, ek onay yoktur** (K3). Gerekçe 1–500 karakterdir ve iş grubu satırında kalır: kim, ne zaman, neden. Uygun kişiye elle vermede gerekçe isteğe bağlıdır. Gerekçe herkese açık değildir; panelde sertifika çalışma alanını okuyabilen görür.
- Uygulama: core-backend #401 (gerekçe), #402 (otomatik kapanış, anahtar, erken kapatma, yeniden tarama, posta); panel core-frontend #163 ve kişi listesi bileti; SkyMail şablonu skymail-frontend.

### Endüstri uygulamasıyla karşılaştırma

**Uyanlar:**
- **Moodle.** Tamamlama ölçütü ile sertifika ayrıdır; sertifika ölçüt tamamlanınca açılır. Bizde Check-in uygunluğu günceller, verme kapanıştan sonra başlar.
- **Accredible.** Kurala bağlı verme ile elle verme yan yanadır.

**Sapmalar:**
1. **Cvent elle, biz otomatik.** Cvent'te oturum sayısına bağlı otomatik sertifika yoktur; rapor dökülüp elle postalanır.
2. **Gerekçeli istisna.** Accelevents'te elle istisna akışı yoktur; bizde eşik altına gerekçeyle verilir.
3. **Kapanış zamanı** (son oturum + 1 saat) bizim seçimimizdir; araştırılan ürünlerin belgelerinde bir karşılığı bulunmadı.
