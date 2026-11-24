# Current Oturum is clock plus pick; ratio counts remaining scheduled talks

Staff Check-in targets the current Oturum: schedule-clock when talks on that EventDay do not overlap; staff pick when they overlap (two rooms) or the clock is wrong. Ratio denominator is scheduled Oturum that still exist; cancelled talks are deleted or marked cancelled and excluded so they do not inflate the %. An Event with zero Oturum rows issues no certificate until at least one talk exists — even a one-talk day is 1 EventDay + 1 Oturum; `once` is one Oturum Check-in, not an EventDay. Bind Check-in to the existing schedule Session under EventDay, not a second talk table. Rejected: clock-only; pick-only; counting cancelled talks; a fallback certificate on EventDays with no talks.

## Ek: payda sayılan oturumlardır; etkin eşik min(M, N) (2026-11-24)

Karar (Yusuf, 2026-11-23). ADR-0026'nın aynı tarihli ekindeki `count` kuralı ve sayılan/zorunlu oturum için kenar durumları:

- **Payda (N), canlı sayılan oturumlardır:** arşivlenmemiş bir günde, arşivlenmemiş, iptal edilmemiş ve "Sayılır" işaretli oturumlar. Pay, biletin bu oturumlardaki Check-in sayısıdır; sayılmayan oturumdaki Check-in kayıtta durur ama sayılmaz.
- **N = 0 ise sertifika yok.** Yukarıdaki "Oturum'u olmayan etkinlik sertifika vermez" kuralı genişler: oturumları olup hiçbiri sayılmayan etkinlik de vermez. `once` dahil.
- **Etkin eşik min(M, N).** Elle girilen M, iptal ya da sayımdan çıkarma yüzünden N'nin üstünde kalırsa eşik N olur; kural imkânsız hale gelmez. M < 1 kabul edilmez.
- **İptal edilen ya da arşivlenen zorunlu oturum şarttan düşer.** Kimse var olmayan bir oturumu kaçırmış sayılmaz.
- Var olan `ratio` etkinliklerinde bütün oturumlar sayılır ve hiçbiri zorunlu değildir (göç varsayılanı); sonuçları değişmez.
- Uygulama: core-backend #401.

### Endüstri uygulamasıyla karşılaştırma

**Uyanlar:**
- **Moodle ve Accelevents** ölçütü seçili parçalar üzerinden kurar; payda da yalnız seçilenlerdir. Bizde "Sayılır" işareti bu seçimdir.

**Sapmalar:**
1. **min(M, N) ile kendiliğinden gevşeme.** Araştırılan ürünlerin belgelerinde karşılığı bulunmadı; bizde bir oturumun iptali kuralı imkânsız kılmasın diye var.
2. **Zorunlu oturum iptal edilince şarttan düşer;** Accelevents'te ölçüt elle düzenlenir.
