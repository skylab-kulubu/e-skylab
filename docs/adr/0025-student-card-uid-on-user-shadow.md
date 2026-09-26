# Student-card UID lives on the User shadow, not in Keycloak

The bound ISO 14443-A UID is a physical-access binding (campus PACS card number), not login identity. Store it as a unique nullable column on the Go User shadow (same pattern as `schoolEmail`); one card one user; rebind replaces the old UID. Door tap looks up postgres, not the Keycloak Admin API. Keycloak already holds the person (`sub`, `skyNumber` attribute). Rejected: a Keycloak user attribute for the RFID; a SkyPass-only table as the source of truth; a second campus “öğrenci no” field beside the UID `NfcService` already polls.
