# Superadmin visual language is a snapshot of forms-frontend admin chrome

Accepted. The greenfield superadmin must look and feel like the forms admin panel (Space Grotesk, `skylab-*` tokens, Sidebar / ListItem / ActionButton / Drawer / Pagination and the rest of that chrome). We port those primitives into superadmin TypeScript and write screens forms does not have. We do not keep the current superadmin UI kit, do not publish a shared `skylab-ui` package in this cutover, and do not import forms-frontend at runtime. Two copies will drift; that is fine. Group → `skyforms:*` mappings are data entered in superadmin, not a hardcoded matrix in the rewrite.

Superseded in part by ADR 0055 (2026-09-26): the copy-instead-of-package decision no longer holds; skylcn-ui is the shared package. The forms-look visual language still stands.
