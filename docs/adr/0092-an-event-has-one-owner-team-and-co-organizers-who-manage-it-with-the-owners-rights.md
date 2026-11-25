---
status: accepted
---

# Bir etkinliğin tek sahibi ve ortak düzenleyenleri olur; ortaklar sahibin yetkisiyle yönetir, sahipliği ve listeyi yalnız sahip değiştirir

Bir Event'in tek bir Owner team'i var (ADR-0018). Yetki bu tek Team code'dan hesaplanıyor: kişinin token'ındaki grup yolları Owner team'e göre okunuyor, ata Leader kalıtımı geçiyor (ADR-0065 karar 2), gereken seviye ekibin `EventPermissions` satırından geliyor. Kulübün büyük etkinliklerini ise çoğu zaman birkaç ekip birlikte yapıyor: sahip YK olur, ama etkinliği WEBLAB ve ARTLAB da yönetir. Bugün bunun tek yolu ya ortak ekibin insanlarını sahip ekibe almak ya da her işi YK'ya yaptırmak. İkisi de yanlış yere yetki verir. Kişi bazlı tek mekanizma kapı görevlisidir (Door staff) ve yalnız `Validate` hakkı verir.

Karar (Yusuf, 2026-11-25: "ana sahip YK ama düzenleyebilenler şu ekipler/ortak ekipler"; aynı gün S1–S4 soruları cevaplandı; maddelerin yanında hangisi olduğu yazar):

1. **Owner team tektir ve değişmez.** Event'in yanına **Co-organizer (Ortak düzenleyen)** listesi gelir: başka ekipler (Team code'la) ve sınırlı sayıda kişi (e-skylab hesabıyla). Ortak düzenleyen Owner team değildir. Owner team'in okunduğu her yerde (`ownerTeam` alanı, Team code bağları, Certificate template zinciri, CMS ve Forms eşleşmesi, "Düzenleyen" satırı) yine tek sahip okunur.
2. **Liste core'un verisidir; Keycloak'a dokunulmaz.** Ortak ekip bir Keycloak grubu ya da rolü açmaz; token'daki grup yolu okunur (ADR-0059). Ortak kişi Keycloak'ta hiçbir şey değiştirmez. Liste core'da `event_co_organizers` tablosunda durur, yetki kararını core verir.
3. **Organizatör ekipler kümesi.** Bir Event'in organizatör ekipleri Owner team ile ortak ekiplerin birleşimidir. Kişinin seviyesi her organizatör ekip için ayrı hesaplanır. Kişi, organizatör ekiplerden herhangi birinde o ekipteki seviyesi o ekip için gereken seviyeyi karşılıyorsa işi yapabilir. Ata Leader kalıtımı ortak ekiplere de geçer: WEBLAB ortaksa üst ekibinin Leader'ı da o Event'te Leader sayılır.
4. **Yönetim, ortak ekip başına seçilir (Yusuf S2).** Her ortak ekip satırı `management` taşır, ekleyen seçer:
   - `leaders` ("yalnız liderler"): o ekipten yalnız Leader sayılır, bütün organizatör işlerinde. O ekipte sıradan üyelik bu Event'te **hiçbir hak vermez**: sertifika rolü (Certificate manager), Team door scan ve `team_competition_manage` dahil.
   - `members` ("bütün üyeler"): ekip, GECEKODU kuralındaki sahip ekip gibi davranır. `Update` düzeyindeki işler (düzenleme, Draft'ı görme, durum geçişleri, günler ve oturumlar, içerik, Ticket okuma) üyeye de açılır. Sahip ekipte de Leader isteyen işler (Ticket verme, rolsüz sertifika verme, Competition organizatörlüğü) ortak ekipte de Leader ister. Kapı `Update` düzeyinde değildir; `members` üyeye kapı açmaz. Bu seçimde sahip ekiple aynı kurallar geçer: sertifika rolü, Team door scan ve `team_competition_manage` sahip ekipteki gibi işler.
   - Seçim verilmezse sahip ekibin kuralından türetilir: sahibin satırında `Update` için `MEMBER` varsa `members`, yoksa `leaders`. Saklanan değer her zaman açıktır; sahip ekibin kuralı sonradan değişse de satır değişmez.
   - Ortak ekibin kendi `EventPermissions` satırı okunmaz.
   - Ekip ayarları (`team_door_scan`, `team_competition_manage`) kişinin seviyesini aldığı ekipten okunur; `leaders` seçili ortak ekipte okunmaz.
5. **Kişi eklenebilir, sınırlı (Yusuf S1).** Ortak kişi Event üzerinde Leader seviyesinde sayılır ve iki seçimi yoktur. Event başına en çok 10 kişi. Kişinin yetkisi Event bitişinden 30 gün sonra kendiliğinden düşer; satır bitişten 90 gün sonra silinir (kapı görevlisiyle aynı kural). Her ekleme ve çıkarma kayda girer ve postayla bildirilir. Ekip satırlarının süresi yoktur. Panel önce ekip önerir: "Ekibi varsa ekibi ekleyin".
6. **Sahibe kalanlar (Yusuf S3).** Yeni `ManageOrganizers` kararı yalnız Owner team Leader'larına (atalar dahil) ve Privileged'a açıktır; Owner team'i olmayan Event'te yalnız Privileged'a. Bu karar:
   - Owner team'i değiştirmek (iki tarafta `Update` kuralı sürer, ama ortak düzenleyen seviyesi sayılmaz);
   - ortak düzenleyen listesini ve satırların seçimlerini değiştirmek;
   - silmek ve arşivlemek (`Delete`; yayımlanmış Event'te ADR-0066'daki YK ve ADMIN kuralı sürer).

   Ek olarak sahip ekibin Leader'ı **kapı görevlisi atar** (atalar dahil; Privileged zaten atar; Owner team'i olmayan Event'te yalnız Privileged). Ortak düzenleyen atayamaz.
7. **Ortağa açık olanlar sahiple aynıdır.** Event'i düzenlemek, Draft'ı görmek, yayınlamak, taslağa almak, iptal etmek ve geri almak; günler ve oturumlar; içerik ve Media; Ticket okuma ve verme; katılımcı postası; Certificate verme ve geri alma, Attendance finalization, Rescan, Attendance rule; Competition organizatörlüğü; kapı (Leader seviyesi kapı yetkisi verir; sıradan üye, `members` seçili ortak ekipte de, yalnız atanmış kapı görevlisiyse ya da seviyesini aldığı ekipte Team door scan açıksa okutur); Event kopyalama.
8. **Certificate manager** organizatör ekiplerin her birinde olabilir: `members` seçili ortak ekibin üyesi sertifika rolünü taşıyorsa o Event'te Certificate manager'dır. `leaders` seçili ortak ekibin üyesi rolü taşısa da olmaz. Rol yine Role group'tan gelir (ADR-0076).
9. **Görünüm, ortak ekip başına seçilir (Yusuf S4).** Her ortak ekip satırı `visibility` taşır:
   - `co_organizer` ("Ortak düzenleyen"): site Event sayfası, Ticket page ve PDF'i ve sertifika doğrulama sayfasında "Düzenleyen" satırının altında "Ortak düzenleyen: …" satırıyla görünür. Herkese açık Event JSON'unda `coOrganizerTeams` alanında yalnız bunlar durur.
   - `helper` (**Helper team**, "Yardımcı ekip"): yalnız panelde görünür, dışarıdaki hiçbir yüzeyde görünmez; herkese açık ekip filtresi (`?team=`) de onu eşleştirmez. Yetkisi daha az değildir: yetkiyi yönetim seçimi belirler, görünüm değil.
   - Varsayılan `co_organizer`.
   - **Kişiler dışarıda hiçbir yerde görünmez.** Listeyi ve kişilerin adını yalnız Event'i düzenleyebilen görür.
   - **Sertifika PDF'inde yalnız sahip görünür.** Yeni sertifikalar o an `co_organizer` olan ekiplerin anlık görüntüsünü alır, doğrulama sayfası onu gösterir. Verilmiş sertifika sonradan değişmez.
10. **Certificate template zinciri değişmez:** Event bağlaması, Owner team bağlaması, SKY LAB varsayılanı. Ortak ekipler zincire girmez; yalnız Event bağlamasında seçilebilecek şablonlara ortak ekiplerin şablonları eklenir.
11. **Doğrulamalar.** Ortak ekip Owner team'den farklı, var olan bir Team code olur; Privileged kökler (YK, DK, ADMIN) ortak olamaz; en çok 10 ekip. Sahip ekip değişince yeni sahip listedeyse listeden düşer. Team code yeniden adlandırma denetimi (ADR-0065 karar 7) bu tabloyu da koda bağlı kayıt sayar.
12. **Denetim ve posta.** Her ekleme, çıkarma ve seçim değişikliği Team audit record'a yazılır, reddedilen yazmalar dahil; kayıt yazılamazsa değişiklik yapılmaz (ADR-0065 karar 9). Eklenen kişiye ve eklenen ekibin Leader'larına posta gider (ADR-0080 deseni), çıkarmada kısa bir bilgi postası gider. Kişinin süresi dolunca ve yalnız seçimi değişen ekibe posta gitmez.
13. **Kopya (ADR-0066).** Ortak ekipler kopyaya taşınır. Ortak kişiler yalnız istenirse, kopyalayanın `ManageOrganizers` yetkisi varsa ve hesap etkinse taşınır (kapı görevlisi deseni). Kopyalayan yalnız ortak düzenleyense kopyanın sahibi kaynak Event'in sahibi kalır.
14. **Tek kaynak.** Event'ten türeyen her yetki kararı core'da tek bir yardımcıdan geçer; Event başına önbelleklenir, ekip başına değil. Panel bu kararı Event cevabındaki `viewer.can` alanından okur. `/v1/me/capabilities` değişmez.

## Consequences

- Ortak listesi boş Event'lerde davranış birebir aynı kalır.
- Owner team'i okuyan bütün bağlar (Team media library, CMS, Forms eşleşmesi, posta şablonlarındaki `OwnerTeam` değişkeni) tek sahibe bakmaya devam eder. Ortak düzenleyen sahip ekibin Team media library'sinden seçer ya da yeni Media yükler; kendi ekibinin başka Event'lerindeki Media'yı kullanamaz. Genişletme ayrı karardır.
- Forms kendiliğinden değişmez: Event'in bağlı formu yine formun sahibi ve collaborator'larınındır. Forms isterse ileride `coOrganizerTeams` alanını okuyabilir; karar Forms'un sahibinindir.
- sky-app'te değişiklik gerekmez; kapı ekranı core'un `Validate` kararını kullanır. Mobile Lab'e Event JSON'undaki yeni alan için sözleşme notu gider.
- ADR-0065 ve ADR-0076'ya kısa ekler girer; CONTEXT.md'ye Co-organizer ve Helper team terimleri eklenir. ADR-0062'nin süreler tablosuna ortak kişi satırı eklenir.

## Endüstri uygulamasıyla karşılaştırma

Model, Luma'nın manager ve check-in staff ayrımıyla Microsoft Teams'in "organizatör tektir, co-organizer'ın yetkisi dizinde değil toplantı nesnesinde durur" kuralının birleşimidir. Ortak düzenleyen Luma'nın manager'ına, Door staff check-in staff'ine karşılık gelir; sahip çıkarılamaz ve sahipliği yalnız sahip devreder (Teams, Google Calendar); kişi sınırı Teams'in 10 co-organizer sınırıdır; Eventbrite'taki gibi sayfada tek bir sahip görünür. Bilinçli sapmalar: birincil birim kişi değil ekiptir; listeyi ortaklar değil yalnız sahip değiştirir (Luma'da manager host ekler); silme ve arşiv sahibe kalır (Meetup'ta host siler); ortak düzenleyen Event'i düzenler ve katılımcıya posta atar (Teams'te co-organizer daveti düzenleyemez). Kaynaklar aşağıda.

## Considered Options

- **İkinci bir Owner team alanı ya da birden çok Owner team.** Seçilmedi: Team code bağları, şablon zinciri ve "Düzenleyen" satırı hangi sahibi okuyacağını bilemez.
- **Ortak düzenleyeni Keycloak grubu ya da rolü yapmak.** Seçilmedi: Event başına grup açmak ağacı şişirir; erişim tek kaynağa aittir, dizine değil (Teams co-organizer'ı da Entra grubu değildir).
- **Ortakların listeyi değiştirmesi** (Luma). Seçilmedi: yetkiyi kim verdiği sahipte kalmalı.
- **Kapı görevlisi tablosunu genelleştirip tek `event_people(role)` tablosu.** Şimdilik seçilmedi: kapı tablosunun göçü, kopyası, saklama kuralı ve sky-app sözleşmesi hazır. Panelde ikisi tek bölümde görünür; birleştirmek ileride mümkün.
- **Yalnız ekip, kişi yok.** Seçilmedi (S1): ekibi olmayan bir kişinin tek bir Event'i yönetmesi gerekebiliyor; süre, sınır ve kayıtla daraltıldı.

## Kaynaklar

- Yusuf'un kararları (2026-11-25): S1 kişi eklenir, en çok 10, bitişten 30 gün sonra düşer; S2 yönetim ortak ekip başına `leaders | members`, varsayılan sahip ekibin kuralı; S3 sahibe sahiplik, liste, silme, arşiv ve kapı görevlisi ataması; S4 görünüm ortak ekip başına `co_organizer | helper`, sertifika PDF'inde yalnız sahip, kişiler dışarıda yok.
- Spec önerisi (Yusuf'un kararı olmayanlar): yeni ortak ekibin görünüm varsayılanı `co_organizer`, en çok 10 ekip, Privileged köklerin ortak olamaması, kişi satırının 90 gün saklanması, şablon zincirinin değişmemesi, kopya kuralı.
- Luma, Adding Hosts and Managers: https://help.luma.com/p/adding-hosts-and-managers-to-your-event
- Microsoft, Add co-organizers to a meeting in Microsoft Teams: https://support.microsoft.com/en-us/office/add-co-organizers-to-a-meeting-in-microsoft-teams-0de2c31c-8207-47ff-ae2a-fc1792d466e2
- Microsoft, Roles in a Teams meeting: https://support.microsoft.com/en-us/article/roles-in-a-teams-meeting-c16fa7d0-1666-4dde-8686-0a0bfe16e019
- Meetup, How to add an event host: https://help.meetup.com/hc/en-us/articles/41293714166797-How-to-Add-an-Event-Host-or-Co-Host-on-Meetup
- Eventbrite, Permissions definitions: https://www.eventbrite.com/help/en-us/articles/362073/
- Google Apps Script, CalendarEvent `guestsCanModify`: https://developers.google.com/apps-script/reference/calendar/calendar-event-series
- ADR-0018 (sahipsiz Event), ADR-0059 (takım izinleri grup yoludur), ADR-0062 (saklama süreleri), ADR-0065 (ekip liderleri, ata kalıtımı, denetim kaydı), ADR-0066 (kopya), ADR-0068 (yarışma), ADR-0076 (yalnız gruplar), ADR-0080 (yetki değişikliği postası).
