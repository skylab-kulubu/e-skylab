---
status: accepted
---

# Her uygulamanın kişiye özel ayarları core'da, uygulamanın kendi isim alanında durur; core değeri saklar, sınırlar ve siler, içini yorumlamaz

Forms'ta "Formlarım" listesinin filtreleri sayfa yenilenince kayboluyor. Kişi her girişte aynı ayarları yeniden yapıyor (Fatih, 2026-11-08). Forms ve panel bazı ayarları tarayıcının `localStorage`'ında tutuyor; bunlar başka cihaza geçmiyor ve tarayıcı silinince gidiyor. Uygulamaların kendi veritabanında tutması da "her şeyi core bilsin, diğerleri aptal olsun" ilkesine ters düşer (Fatih ve Yusuf, 2026-11-08; ADR-0075).

Karar (Yusuf ve Fatih, 2026-11-08: "Hesap servisinde her uygulamaya özel kullanıcı ayarları", "core bilsin"; Yusuf aynı gün 3 ve 9'u onayladı; ayrıntılar tasarım önerisi):

1. **Tek depo core'da.** Core'da `app_preferences` tablosu durur: kişi (Keycloak `sub`) × uygulama × anahtar → JSON değer. Kişiye özel uygulama ayarı başka yerde (uygulamanın veritabanı, Keycloak özniteliği) tutulmaz. Tarayıcı deposu yalnız önbellektir.
2. **Uygulama yalnız kendi isim alanına erişir.** Uçlar `/v1/users/me/app-preferences/{app}` altındadır ve yalnız kişi token'ı kabul eder; servis hesabı reddedilir. Token'ın `aud`'u `core` içermelidir (değişmedi). İsim alanını token'ın `azp`'si seçer: core ayarındaki istemci → uygulama eşlemesi (`APP_PREFERENCE_CLIENTS`). Başka uygulamanın isim alanına giden istek 403 alır. `azp` audience yerine geçmez.
3. **Hesap Merkezi istisnası.** Hesap Merkezi (`account-center`) kişinin bütün uygulamalarının özetini (anahtar sayısı, son değişiklik) okur ve bir uygulamanın ayarlarını sıfırlayabilir. Değerleri okumaz, yazmaz. Ekranı ana listede ayrı bir "Uygulama ayarları" satırıdır.
4. **Core değerin içini yorumlamaz.** Değer opaktır, varsayılanı uygulama verir; sunucuda yalnız kişinin açık seçimi durur. Uygulama değerle birlikte bir `schemaVersion` gönderir; biçim değişirse dönüşümü uygulama yapar.
5. **Sınırlar.** Anahtar başına değer en çok 4 KB, uygulama başına en çok 32 anahtar ve toplam 32 KB, istek gövdesi en çok 8 KB. Uygulama ve anahtar adları dar bir karakter kümesine uyar.
6. **Çakışma.** Varsayılan kural anahtar başına son yazanın kazanmasıdır. Her yanıt bir sürüm (`ETag`) taşır; istemci `If-Match` gönderirse tutmayan yazma 412 alır.
7. **Yalnız görünüm durumu yazılır.** Değere kişi adı, e-posta, form içeriği ya da arama metni yazılmaz. Geçici iş durumu (taslak, açık sekme) tarayıcıda kalır.
8. **Silme.** Hesap silmede core içi `erase_app_preferences` adımı kişinin bütün satırlarını siler (`erase_communication_preferences`'in ardından). Silinmekte olan kişiye yeni satır yazılmaz. Kendiliğinden süre dolması yoktur; listeden çıkan bir uygulamanın satırları tek seferlik bir migration ile silinir.
9. **Dayanak ve aydınlatma.** Kişisel veridir, dayanak m.5/2-c'dir (hizmetin sunulması), rıza istenmez. Aydınlatma metninin 1. satırının veri sütununa "uygulama görünüm ayarları" eklenir; ayrı satır açılmaz, avukata sorulmaz. Production'da bir uygulama ancak bu metin yayımlandıktan sonra açılır; core'da eşleme boşken özellik kapalıdır.
10. **Kapsam dışı.** Uygulamalar arası ortak ayarlar (dil, tema, saat dilimi) bu depoya girmez; onları core şemalı alan olarak tutar (ayrı karar). İletişim tercihi ve rızalar kendi kayıtlarında kalır.

Kaynaklar:
- **Fatih'in ve Yusuf'un:** ihtiyaç ve "core bilsin" ilkesi (2026-11-08).
- **Yusuf'un:** 3'teki ekran yeri ve 9'daki aydınlatma kararı (2026-11-08); ilk dilimde yalnız Forms açılır.
- **Tasarım önerisi:** 2–10 (hub'daki `notes/uygulama-tercihleri-tasarim-20261108.md`).

## Consequences

- **Forms'un işi küçük.** Forms tablo açmaz. Açılışta bir kez okur, değişince 1 saniye bekleyip yazar. Yeni bir ayar için core'da değişiklik gerekmez.
- **Yeni uygulama açmak bir ayar değişikliği.** `APP_PREFERENCE_CLIENTS`'e bir satır eklenir; migration ve kod gerekmez. Token'ında `aud core` olmayan istemci (bugün SkyMail konsolu) önce Keycloak'ta core audience'ını alır.
- **Cihazlar arası.** Ayar başka cihazda bir sonraki açılışta görünür. Anında itme yok.
- **Core değerden habersiz.** Bir uygulama bozuk ya da eski biçimde değer yazarsa core bunu yakalamaz; uygulama okuyamadığı değeri yok sayar ve varsayılana döner.
- **Hesap silme bir adım uzar.** Core içi, dış servis çağrısı yok.
- **CONTEXT.md'de yeni terim:** App preference (Uygulama tercihi).

## Endüstri uygulamasıyla karşılaştırma

**Uyanlar:**
- **Uygulama başına isim alanı, yalnız sahibi yazar.** Outlook eklentilerinin `RoamingSettings`'i ve Google Drive'ın `appDataFolder`'ı yalnız onları yazan uygulamaya açıktır.
- **Anahtar → JSON, platform yorumlamaz.** Outlook `RoamingSettings`, Microsoft Graph open extension, Jira user properties.
- **Sert boyut sınırı.** Graph open extension 2 KB, Jira property 32 768 bayt.
- **Sunucu deposu tek kopya, tarayıcı deposu önbellek.** Microsoft'un Office eklenti rehberi kişi düzeyindeki tercihler için kişinin kimliğine bağlı çevrimiçi bir depo öneriyor.
- **Varsayılanı uygulama verir.** `RoamingSettings` olmayan ayar için `null` döner.
- **Son yazan kazanır.** Jira properties ve `RoamingSettings`.
- **Ortak ayarlar ayrı ve şemalı.** Graph'ta `mailboxSettings` (dil, saat dilimi).

**Sapmalar (hepsi):**
1. **Anahtar başına satır.** `RoamingSettings` bütün torbayı tek seferde yazar. Biz anahtar başına yazıyoruz, iki ekran birbirini ezmesin diye.
2. **Sürüm isteğe bağlı.** Confluence user properties güncellemede sürüm numarası istiyor; bizde `If-Match` isteğe bağlı.
3. **Hesap Merkezi bütün isim alanlarını sıfırlayabilir.** Outlook ve Drive'da bunu sahip uygulama yapar; Drive'da kişi gizli uygulama verisini topluca silebiliyor, bizim sıfırlama buna yakın.
4. **Uygulama kaldırılınca veri kendiliğinden silinmez.** Drive'da kaldırılan uygulamanın klasörü silinir; bizde tek seferlik migration ile silinir.
5. **Ayrı şema sürümü alanı.** İncelenen ürünler sürümü değerin içinde bırakıyor. Biz core'un ve Hesap Merkezi'nin görebilmesi için ayrı alan tutuyoruz; core yine yorumlamaz.

## Considered Options

- **Keycloak kullanıcı özniteliği.** Token şişer, her anahtar user profile şemasına girer, yazma servis hesabıyla Admin REST'ten olur. İletişim tercihinde de reddedilmişti.
- **Her uygulama kendi veritabanında.** "Core bilsin" ilkesine ters; silme ve sıfırlama her serviste ayrı yazılırdı.
- **Core'da uygulama başına JSON şeması (kayıtlı anahtarlar).** Her yeni ayar core PR'ı ve yayını ister. Sonra isteğe bağlı olarak eklenebilir; sözleşmeyi bozmaz.
- **Tek JSON torba.** Ekranlar birbirini ezer.
- **Yalnız `localStorage` (bugünkü durum).** Cihazlar arası değil.
