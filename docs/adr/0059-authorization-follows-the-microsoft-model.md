---
status: accepted
---

# Yetki Microsoft modelindedir: uygulama geneli izinler client rolü, takım izinleri grup yolu; çok gruplu kişinin grupları sorulur

core bütün Privileged, Leader ve Owner team kararlarını token'daki tam grup yollarından veriyordu (ADR-0005, ADR-0006). inscribed'ın News kuralı 10 grup yolunu birebir listeliyordu; YK'ya alt grup eklendikçe liste elle güncelleniyordu. Admin paneli core'un kurallarını token'ı kendisi okuyarak kopyalıyordu. Keycloak'ta bir kişinin token'ındaki grup sayısını sınırlayan bir mekanizma yok. Karar: SKY LAB yetkiyi Microsoft Entra'nın modeliyle yönetir (araştırma: `sky_lab_genel/notes/research-groups-out-of-token.md`, 2026-09-29).

- **Uygulama geneli izinler client rolüdür** (Entra'nın app role'leri). Privileged'dan gelen izinler core'da kaynak başına client rollerine bölünür (örneğin `events:manage`, `users:manage`; kesin liste core'daki Privileged denetimlerinden çıkar). Roller SKY LAB admin arayüzünden gruplara eşlenir; başlangıçta `ADMIN`, `YK` ve `DK`'ya verilir, alt gruplar miras alır, bugünkü davranış değişmez. inscribed'ın News kuralı da bir role bağlanır. Privileged hâlâ bir grup üyeliğidir; değişen, uygulamanın ona nasıl baktığıdır.
- **Takım izinleri grup yoludur.** Leader ve Owner team kararları grup ağacından gelir: WEBLAB yalnız kendi kaynaklarını yönetir. Entra'nın app role'leri de uygulama genelidir, takıma bağlı izni ifade etmez; takım başına rol yoktur (ADR-0014).
- **Her uygulama yalnız okuduğu grupları alır.** `groups` kapsamı, grupları okumayan client'ların token'ından çıkar (Entra'nın "groups assigned to the application" karşılığı).
- **İstemci access token'ı okumaz.** Admin arayüzü neyi gösterip neye izin vereceğini core'un "yeteneklerim" yanıtından öğrenir; yetki kuralları yalnız core'dadır.
- **Group overage.** Bir kişi 30'dan fazla grup yolundaysa SKY LAB'ın Keycloak mapper'ı `groups` yerine Microsoft biçiminde bir işaret yazar: `"_claim_names": {"groups": "src1"}` ve `"_claim_sources": {"src1": {"endpoint": …}}`. Servis yalnız işaretin varlığına bakar ve grupları kendi yapılandırmasından bildiği yerden sorar. core bunu service account'uyla Keycloak Admin REST'ten yapar (Entra'da Graph çağrısının karşılığı). Sonuç 60 saniye önbellekte tutulur, core'un kendi üyelik yazmalarında hemen silinir; Keycloak'a ulaşılamazsa istek reddedilir. Eşik ayarlanabilir; 30, tam yol biçimindeki token'ımıza göre seçildi (Entra'nın 200'ü kısa grup kimlikleri içindir).

## Consequences

- ADR-0006'nın "Core Go authorizes from group paths in the JWT" cümlesi daralır: Privileged izinleri client rollerinden, takım izinleri grup yollarından gelir. ADR-0005'in reddettiği ek HTTP atlaması yalnız Group overage'daki kişiler için kabul edilir; yetki yine core'un içinde verilir.
- Overage işareti yalnız onu anlayan servislere giden token'larda açılır: önce `admin` client'ı (News role taşındıktan sonra) ve yalnız core'a giden client'lar. inscribed işareti anlayana kadar site client'larında (`frontend-main`, `frontend-arge`) açılmaz; bu Fatih'e sorulur. forms-backend grup okumaz, etkilenmez. sky-app yalnız sözleşmeyle ele alınır.
- Overage, `admin` client'ının kapsamı daraltıldıktan (ADR-0058) sonra açılır; böylece BFF'den önce de 30 yol admin cookie'sine sığar.
- Kişi başı grup sayısı core'daki bir rapor komutuyla ölçülür; admin girişinde access token 3,6 KB'ı geçerse uyarı loglanır.
- Group overage'daki bir kişinin yetkisi Keycloak'ın erişilebilirliğine bağlanır: Keycloak'a ulaşılamazsa istekleri 503 alır.

## Considered Options

- **Overage'ı yalnız eşik aşılınca yazmak:** Daha ucuzdur ve hiç çalışmayan bir kod yolu bırakmaz. Entra'da bu güvenlik ağı her zaman açık olduğu için şimdi yazıldı.
- **Bütün grup yolu yetkisini role çevirmek:** Takım başına rol gerekir; ADR-0014 ve sözlükle çelişir, ağacın anlamı kaybolur.
- **Grupları her istekte sunucu tarafında sormak:** Her isteğe bir atlama ekler; inscribed'da Fatih kod eklemeden uygulanamaz.
- **Grupları introspection ya da UserInfo'dan almak:** Admin REST, Entra'nın Graph çağrısının karşılığıdır ve core'da hazırdır.
- **Eşik 200:** Tam yol biçiminde yaklaşık 8 KB grup eder; cookie ve başlık sınırlarını aşar.
- **`"hasgroups": true` işareti:** Entra'nın eski implicit akışındaki biçimdir; normal akıştaki `_claim_names`/`_claim_sources` biçimi OIDC'ye daha yakındır ve Microsoft örnek kodları onu yakalar.
