# SKY LAB platform hub

Bu depo SKY LAB'in çalışan bir servisi değildir. Platformun mimari haritasını,
depo kataloğunu, ortak alan dilini ve servisler arası kararları tek yerde tutar.
Kod, sürümleme ve dağıtım her ürünün kendi deposunda yapılır.

## Başlangıç noktaları

- [Depo kataloğu](docs/repositories.md): aktif ürünler, sahip oldukları veriler ve
  eski depoların durumu.
- [Platform mimarisi](docs/architecture.md): kimlik, API, veri ve dağıtım
  sınırları.
- [Ortak alan dili](CONTEXT.md): ekiplerin aynı kavramı aynı anlamda kullanması
  için kanonik sözlük.
- [Mimari kararlar](docs/adr): servisler arası kalıcı kararlar.
- [Admin panel boşluk raporu](docs/admin-panel-gap-report.md): admin operasyon
  kapsamı ve bilinen eksikler.

## Ana akış

```text
Kullanıcı
   │
   ├── yildizskylab.com ─────── skylab-site
   ├── admin.yildizskylab.com ─ superadmin
   ├── my.yildizskylab.com ──── account-center
   ├── forms.yildizskylab.com ─ forms-frontend
   ├── mail.yildizskylab.com ── skymail-frontend
   └── sky-app ───────────────── mobil istemci
             │
             ├── e.yildizskylab.com ─ e-skylab-keycloak
             └── API servisleri ───── core / CMS / Forms / Mail
```

Servis keşfi için Eureka ve ortak bir Spring Gateway kullanılmaz. İstemciler ve
servisler kendilerine ait, açıkça tanımlanmış API adreslerine gider; kimlik ve
yetki OIDC/JWT sözleşmeleriyle taşınır.

## Bu depoya ne girer?

- Birden fazla ürünü etkileyen mimari kararlar.
- Ürün/depo sahipliği ve yaşam döngüsü bilgisi.
- Ortak alan dili ve servisler arası HTTP/kimlik sözleşmeleri.
- Platform çapında geçiş planları ve inceleme raporları.

Uygulama kodu, Docker imajı, gizli bilgi, ortama özel ayar ve tek bir servise
ait çalıştırma kılavuzu bu depoya girmez.

## Eski monorepo

Keycloak kaynakları geçmişi korunarak
[`e-skylab-keycloak`](https://github.com/skylab-kulubu/e-skylab-keycloak)
deposuna taşındı. Artık kullanılmayan Eureka, Gateway, LDAP, OPA ve eski Java
servisleri ana daldan kaldırıldı. Taşıma öncesi ağaç
`legacy/e-skylab-monolith-2026-09-20` etiketinde salt okunur referans olarak
durur.
