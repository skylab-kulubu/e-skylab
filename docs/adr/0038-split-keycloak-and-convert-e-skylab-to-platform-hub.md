# ADR 0038: Split Keycloak and convert e-skylab to the platform hub

- Status: accepted
- Date: 2026-09-20

## Context

`e-skylab` aynı ağaçta Keycloak, Eureka, Gateway, LDAP, OPA, RabbitMQ,
observability ve eski Java servislerini taşıyordu. Üretim artık Eureka veya bu
Gateway'i kullanmıyor. Keycloak ise bağımsız, test edilmiş bir imaj ve kendi
sürüm sürecine sahip.

## Decision

- Keycloak ağacı Git geçmişi korunarak `e-skylab-keycloak` deposuna taşınır.
- Keycloak CI, sürüm etiketleri, üretim Compose'u ve runbook'u yeni depoya
  aittir. İmaj adı `ghcr.io/skylab-kulubu/e-skylab-keycloak` olarak kalır.
- `e-skylab` çalışan kod veya dağıtım iş akışı içermez; platform hub'ı olarak
  mimariyi, depo kataloğunu, ortak alan dilini ve ADR'leri tutar.
- Eureka, Gateway, LDAP ve diğer eski çalışma zamanı parçaları ana daldan
  kaldırılır.
- Taşıma öncesi monorepo ağacı
  `legacy/e-skylab-monolith-2026-09-20` etiketiyle korunur.

## Consequences

- Keycloak değişikliklerinin sahibi ve yayın sınırı nettir.
- Hub belgeleri herhangi bir servisin dağıtımıyla karışmaz.
- Eski parçalar varsayılan klonda yer kaplamaz, fakat Git geçmişinden geri
  alınabilir.
- Platform çapındaki değişiklikler hub ADR'si ve ilgili ürün depolarındaki
  uygulama değişiklikleriyle birlikte yürütülür.
