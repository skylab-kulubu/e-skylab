---
status: accepted
---

# Kapı görevlisi biletsiz kişiyi kapıda kaydeder; misafir bileti yazılır, bilet postası gider, venue kipinde alana girişi aynı istekte yazılır

Kapıya bileti olmadan gelen kişi bugün içeri alınamıyor: bilet yazmak `ticket.assign` istiyor ("Katılımcı ekle"), kapı görevlisinin ise yalnız okutma ve giriş yazma hakkı var (Door staff, `Validate`). CONTEXT'teki Walk-in tanımı kişinin afiş QR'ını kendisinin okutmasıydı ve "bilet postası gitmez" diyordu; bu yol hiç yapılmadı. ARTLAB'de (27 Kasım, `venue` kipi, sınırsız kontenjan, sertifika 5/5 oturum katılımı) kapıda kayıt gerekiyor.

Karar (Yusuf, 2026-11-26: "Kapıda kayıt özelliği ekleyelim; QR okuyan arkadaşlarda o yetki de olsun"; posta ve alanlar aynı gün):

1. **Kim:** Event'in kapısına yazabilen herkes (Door staff, Team door scan üyesi, organizatör ekip Leader'ı, Co-organizer kişi, Privileged). Kapıda kayıt yeni bir rol ya da `ticket.assign` vermez; yalnız bu tek eylemi açar.
2. **Ne yazılır:** ad, soyad, e-posta zorunlu; telefon, üniversite, bölüm, sınıf isteğe bağlı (etkinlik istatistiği; KVKK: yalnız sorulan alınır). Kişinin Event'te bileti varsa (misafir e-postası ya da üyenin hesap e-postası) yenisi açılmaz, kapı bunu açıkça söyler. Yoksa **her zaman misafir bileti** yazılır, e-posta bir üyenin olsa da: kapı kimsenin hesabına bilet yazmaz.
3. **Kontenjan:** bilet kontenjan altında yazılır; dolu Event reddeder, bekleme listesine düşürmez. Taslak, iptal, arşiv ve bitmiş Event reddeder.
4. **Bilet postası gider.** Kişinin oturumlarda katılım QR'ı ve sertifika için bilete ve e-postasına ihtiyacı var; yazılan her yeni bilet gibi `event.ticket-created` gider. Eski "Walk-in'e bilet postası gitmez" kuralı kalkar.
5. **Giriş:** `venue` kipinde günün Venue entry'si aynı istekte yazılır, kaynağı `walk_in` (bulunan bilette `desk`). `per_session` kipinde yalnız bilet yazılır; oturum katılımı her zamanki gibi.
6. **Kayıt:** yazılan her bilet Team audit'te `ticket.walk_in` satırıdır (Event'in takımı, bilet ve Event; ad, e-posta, telefon yok). Leader ya da Privileged olmayan kapı görevlisinin dayanağı `door_staff`'tır. Satır açılamazsa hiçbir şey yazılmaz. Kişi başına hız sınırı vardır.

Sonuç: Walk-in artık kapıda görevlinin yaptığı kayıttır; afiş QR'ıyla kişinin kendi kaydı ayrı bir iş olarak kalır (yapılmadı). Ayrıntı core `docs/walk-in.md`.
