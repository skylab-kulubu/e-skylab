# Minor product UIs live in superadmin; skyl.app is a redirect host

Authenticated URL shortening (create, my links, moderator list, QR) moves into superadmin. `skyl.app` stays only as the public short-link hostname (Traefik → core 301). We do not deploy `skyl-app-frontend`. Forms, CMS/inscribed, skymail, Place, and the later account center stay their own apps: those are major panels. Kaan’s polish is the superadmin screens in the forms chrome snapshot, not a second skyl.app skin.

This supersedes treating skyl.app as a logged-in site. ADR 0019’s public `skyl-app` OAuth client is unused; superadmin’s client plus `core` `url:*` roles are enough.
