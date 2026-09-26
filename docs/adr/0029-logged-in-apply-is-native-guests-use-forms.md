# Logged-in apply is native; guests use Event forms

An Event can attach several Event forms (SkyDays / YıldızJam: apply plus CTF or contest). A signed-in User registers with their account (Member apply → Ticket) and is not dumped onto a public form. The public Form URL is for Guest apply only. `formUrl` stays the public guest link (external or skyl.app Short link); a skyforms Form id is stored besides that string when the bounce exists, not parsed from it. Rejected: one form slot forever; always-redirect-to-forms; replacing `formUrl` with an opaque Form id.
