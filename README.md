<div align="center">
  <a href="https://yildizskylab.com">
    <img src="https://raw.githubusercontent.com/skylab-kulubu/skylab-assets/main/logos/skylab/skylab-colored.svg" alt="SKY LAB Logo" width="120" />
  </a>

  <h1>SKY LAB Platform Hub</h1>

  <p>
    Yıldız Teknik Üniversitesi SKY LAB kulüp platformunun<br />
    mimari haritası, depo kataloğu ve ortak karar merkezi.
  </p>

  <p>
    <img src="https://img.shields.io/badge/Platform-Architecture-003694?style=for-the-badge" alt="Platform Architecture" />
    <img src="https://img.shields.io/badge/Source_of_Truth-Documentation-ffffff?style=for-the-badge&labelColor=003694" alt="Documentation Source of Truth" />
  </p>
</div>

---

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
