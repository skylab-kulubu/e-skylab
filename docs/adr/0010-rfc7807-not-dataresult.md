# HTTP is the resource plus RFC 7807 errors

_Güncelleme (2026-11-24): RFC 7807'nin yerini RFC 9457 aldı. Hata gövdesinin kuralı aşağıdaki ekte._

Go APIs return the resource as JSON with HTTP status as the outcome (200/201/204). Errors use RFC 7807 problem+json (`title`, `status`, `detail`, `instance`). The Java `DataResult` envelope (`success`, `message`, `data`) is not preserved. This matches cms-backend today and common public API practice; superadmin will be rewritten against it.

## Ek: RFC 9457 ve tek hata gövdesi (2026-11-24)

RFC 9457 (Temmuz 2023) RFC 7807'yi geçersiz kıldı. Gövde aynıdır; kural core'un bugünkü biçimidir (`internal/handlers/problem.go`) ve bütün Go servislerinde aynıdır:

- `Content-Type: application/problem+json`.
- `type` `about:blank`'tir. `title` HTTP durumunun adıdır (`Not Found`, `Conflict`) ve isteğe göre değişmez (RFC 9457 §4.2.1).
- `status` HTTP durum kodu, `detail` insanın okuyacağı açıklamadır.
- Makinenin okuduğu hata kodu `code` uzantı üyesindedir (`ticket_qr_superseded`, `registration_closed`). İstemci `title`'a ya da `detail`'e göre değil, `code`'a göre dallanır. Başka uzantı üyesi gerekirse eklenir (§3.2).
- SkyMail bugün kendi gövdesini döner (`code`, `message`, `params`). Geriye uyumlu geçer: problem+json alanlarının yanında `code`, `message` ve `params` uzantı üyesi olarak kalır, ön yüz `code` okumaya devam eder.

### Endüstri uygulamasıyla karşılaştırma

**Uyanlar:**
- RFC 9457'nin gövdesi ve medya türü.
- Makinece okunur hata kodu: Google AIP-193 ve Microsoft Azure REST API yönergeleri de istemcinin metne değil koda bakmasını ister.

**Sapmalar:**
1. **Özel sorun türü için `type` URI'si yok.** RFC 9457 kendine özgü anlamı olan sorunlar için belgelenmiş bir `type` URI'si önerir; biz `about:blank` ve `code` kullanırız. Türleri anlatan yayımlanmış bir sayfa yok, istemcilerin hepsi `code` okuyor.

Kaynaklar: RFC 9457 https://www.rfc-editor.org/rfc/rfc9457 · Google AIP-193 https://google.aip.dev/193 · Microsoft Azure REST API yönergeleri https://github.com/microsoft/api-guidelines/blob/vNext/azure/Guidelines.md
