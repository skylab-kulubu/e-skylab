---
status: accepted
---

# Place'in giriş yöntemi ortamdan seçilir; e-skylab girişini backend yürütür, yetkiler Keycloak rollerinden gelir

Place'e bugüne kadar yalnız okul maili ile girilebiliyordu: kişi adresini yazar, gelen bağlantıya tıklar, Place kendi oturum cookie'sini verir. Admin ve moderatör yetkileri Place'in kendi veritabanında elle tutuluyordu. Karar (2026-09-29):

- **Giriş yöntemi bir ortam değişkenidir.** Place backend'i `mail`, `eskylab` ya da `both` modunda çalışır; varsayılan `mail`. Frontend modu backend'den sorar; mod tek yerden değişir.
- **e-skylab girişini backend yürütür.** Place backend'i Keycloak'ın gizli istemcisi `place`'tir (Authorization Code + PKCE). Dönüşte Place, mail girişindeki oturum cookie'sinin aynısını verir; Keycloak token'ları saklanmaz ve tarayıcıya gitmez (ADR-0058'in yönü). Girişten sonrası iki yöntemde aynıdır. e-skylab oturumu olan biri sayfayı açınca sessizce giriş yapmış olur. Place'ten çıkış yalnız Place oturumunu kapatır.
- **Hesabı okul e-postası belirler.** Mail ile gelen de e-skylab ile gelen de aynı Place hesabına düşer. e-skylab'dan gelen okul adresi yalnız `place` istemcisine eklenen `school_email` claim'inden okunur; kişinin birincil adresi (ADR-0044, kişisel adres olabilir) eşlemede kullanılmaz. Hesap yoksa ilk girişte açılır. Kulüp üyesi olmak gerekmez.
- **Yetkiler yalnız Keycloak rollerinden gelir.** `place:admin` ve `place:moderator` uygulama geneli izinlerdir, yani client rolüdür (ADR-0059); yönetim arayüzünden kişiye ya da gruba verilir. Yetki yalnız e-skylab ile açılan oturumlarda gelir; mail ile açılan her oturum normal kullanıcıdır, yetkililer her modda e-skylab ile girer. Yetkili oturum 8 saat sürer, geri alınan bir yetki en geç o sürede düşer. Place'in veritabanındaki eski yetkiler taşındıktan sonra yetki vermez.
- **Place grup okumaz;** `place` istemcisinin token'ına grup claim'i konmaz (ADR-0059).

## Consequences

- Mod değişikliği bir ortam değişkeni ve yeniden başlatmadır; kod ya da derleme gerekmez.
- Aynı işte mail giriş bağlantısı tek kullanımlık olur ve herkese açık bir beyaz liste ucu kapanır.
- `place` istemcisi, kulübün öteki özel istemcileri gibi, kuru koşu varsayılan bir operatör betiğiyle açılır; istemci sırrı OpenBao'da durur (ADR-0049).
- Place frontend'i kulüp reposuna gelince moda göre giriş sayfasını gösterir; o zamana kadar yeni backend `mail` modunda çalışır ve yalnız yetkililer e-skylab ile girer.
- Token'ların Place veritabanında düz saklanması, cookie'de `SameSite` olmaması ve girişte ban denetimi ayrı işlerdir.

## Considered Options

- **Tarayıcıda token (herkese açık PKCE istemcisi, API her istekte token doğrular):** Place'in bütün yetki denetiminin ve oturum modelinin değişmesi gerekir; ADR-0058'in yönüne de ters.
- **Yalnız e-skylab:** Kulüp hesabı olmayan ya da o an e-skylab'a giremeyen katılımcılar için mail yolu kalsın istendi; bu yüzden üç mod var.
- **Yetkiler Place'in veritabanında kalsın:** Kulübün yetki yönetimi (yönetim arayüzü, gruplar) Place'i kapsamazdı; ADR-0059'un "uygulama geneli izin client rolüdür" kuralıyla da çelişirdi.
- **Her girişi YTÜ Microsoft'a zorlamak (en sıkı okul adresi kanıtı):** Her girişte Microsoft ekranı; bir etkinlik oyunu için `school_email` claim'i yeterli güven sayıldı.
