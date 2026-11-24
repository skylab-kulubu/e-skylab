# Admin writes club profile; User phone is admin-only PII

_Güncelleme (2026-11-24): Kişi kendi telefonunu `GET /v1/users/me`'de görür (Hesap Merkezi'nde salt okur). "omit it from `GET /v1/users/me`" kuralı yalnız bu kadar değişir: başkasının telefonu yönetim dışı hiçbir yanıtta yoktur. Kod (`internal/handlers/me.go`) ve CONTEXT "User phone" zaten böyle._

Privileged people (or whoever already may manage that User in admin) may PATCH another User's club profile: name, LinkedIn, university, faculty, department, phone. skyNumber and password/passkey stay off that write — password is Account Console `e.` Empty PATCH keys follow `PUT/PATCH /v1/users/me` (omitted stay; empty string on replace clears). Phone lives on the User shadow but is admin-panel-only: omit it from `GET /v1/users/me` and every non-admin payload (sky-app, SkyPass, public roster, CMS, guest Ticket as “User phone”, forms). Rejected: treating JWT `phoneNumber` as the looked-up card; putting phone on sky-app profile.
