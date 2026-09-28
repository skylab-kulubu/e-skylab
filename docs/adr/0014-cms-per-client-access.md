# CMS access is per site client; scope inside a site comes from Groups

Accepted. Person management is Keycloak groups only. Product access to a site's editor is a client role `cms:access` on that site's Keycloak client, assigned by group → client-role mapping. inscribed and cms-backend honour `cms:access` on the token's `azp` (the site you logged into), not a global skycms role aggregated across all clients. Page blocks stay stored per `clientId`. Within one multi-team site (arge), which team item you may edit comes from group path, not `*_LEADER` realm roles. Club-wide News and the main skylab-site are Privileged groups only.

## Ek (2026-09-28)

inscribed geçişinden sonra iki cümle değişti (ayrıntı ADR-0056 ekinde):

- **Yetkiyi kim veriyor.** inscribed yetkiyi `cms:access`'e bakarak değil, aynı Site client'ındaki `content:read` / `content:write` rollerine bakarak verir. `cms:access` bu ikisini içeren editör rolü olarak kalır; siteler editörü yalnız ona sahip olana gösterir. Site başına yetki ilkesi (token'ın `azp`'si) aynen geçerli.
- **Ana siteyi kim düzenliyor.** Ana siteyi artık yalnız Privileged gruplar değil, takım liderleri de düzenleyebilir; kendi takım kayıtlarını ana siteden de düzenleyebilsinler diye. inscribed'da yazma yetkisi site geneli olduğu için liderler ana sitenin sayfalarına da yazabilir; CMS'e yalnız koleksiyona yazma yetkisi gelene kadar bu kabul edildi. News'i yalnız Privileged gruplar yazar: bu, koleksiyonun kendi kuralıyla korunuyor.
