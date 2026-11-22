# Ticket is door identity; Event QR Walk-in is apply

Capacity and the door read the Ticket. A skyforms response is extra fields, not door proof: Member apply writes the Ticket first, then the form row is kept in sync. Event QR stays an attendee-scanned join poster (CONTEXT). No Ticket yet → Walk-in Apply (Ticket assigned; no ticket mail, or “already checked in” if that moment also wrote Check-in). Check-in is still Oturum QR or staff SkyPass / Ticket QR. Staff do not scan the poster. Rejected: form-only registration as a door pass; Event QR as a staff door credential.

## Ek: iki kapı düzeni (2026-11-22)

Karar (Yusuf, 2026-11-22; ADR-0082). Etkinliğin kapı düzeni (`entryMode`) görevli okutmasının ne yazdığını belirler.

- **`per_session` (varsayılan):** yukarıdaki kural aynen geçerli; görevlinin SkyPass ya da Ticket QR okutması o oturuma Check-in yazar.
- **`venue`:** görevlinin okutması o güne Alana giriş (Venue entry) yazar, Check-in yazmaz. Check-in yalnız katılımcının okuttuğu Oturum QR'ı ve masayla gelir. Alana giriş yoklama değildir, sertifikada sayılmaz.
- **Oturum QR'ı döner ve imzalıdır, bilet yazmaz.** Biletsiz kişinin bilet alma yolu yine Walk-in'dir (Event QR).
