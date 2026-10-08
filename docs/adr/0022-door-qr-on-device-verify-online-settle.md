# Door QR authenticity is on-device; check-in settles online

Staff scanner proves SkyPass QR (and Ticket QR if signed) authentic by verifying the signature on-device; it does not call mint or core to know the code is real. Check-in still settles online (`POST /v1/tickets/:ticketId/event-days/:eventDayId/check-in` or the SkyPass equivalent) so double-entry and live counts exist when core is up. If core is unreachable, a valid unexpired signature is accepted at the door as a Queued check-in and duplicates are reconciled after sync — club/campus fail-open, not concert fail-closed. Student-card UID tap stays an online lookup (UID → bound User); a last-known cache is not locked. Rejected: mint-round-trip as the authenticity path; concert-style fail-closed when the network is down; treating a bound Student-card UID as an on-device-signed credential. Who may scan is ADR 0021.

## Ek: Google Wallet kodu yalnız çevrimiçi (2026-10-09)

Karar (Yusuf, 2026-10-09). Google Wallet'taki SkyPass kodu imza değil, Google'ın `rotatingBarcode` TOTP'sidir: SHA1, 60 saniye, biçim `SPW1:<pas kimliği>:<8 hane>`; pas başına sır, sunucudaki bir anahtardan HKDF ile türetilir. TOTP imza olmadığı için tarayıcı onu cihazda doğrulayamaz; her pasın sırrını görevli telefonlarına dağıtmak da kabul edilmedi.

- **Google Wallet kodu yalnız çevrimiçi doğrulanır.** Kodu core denetler; core'a ulaşılamazken Queued check-in olarak kuyruğa alınmaz. Kapı Google Wallet kodları için o sırada fail-closed'dur; öğrenci kartı ve masa kalır.
- **Kod kapıda tek kullanımlıktır.** Taranan kod, check-in sonra başarısız olsa da harcanmış sayılır; pasın bir sonraki kodu en geç bir dakika içinde gelir.
- **Uygulama içi SkyPass QR değişmez:** imzalıdır (~60 sn), cihazda doğrulanır, core'a ulaşılamazken Queued check-in olarak kuyruğa alınabilir.

Kaynak: core-backend#209, `docs/skypass-google-wallet.md`.
