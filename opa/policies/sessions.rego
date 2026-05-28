package skylab.sessions

import future.keywords.if
import future.keywords.in
import data.skylab.common

default allow = false

# Herkes session'ları okuyabilir
allow if {
    input.resource.type == "SESSION"
    input.action == "READ"
}

# Privileged kullanıcılar tüm işlemleri yapabilir (MANAGE_SESSIONS dahil)
allow if {
    input.resource.type == "SESSION"
    input.action in {"CREATE", "UPDATE", "DELETE", "MANAGE_SESSIONS"}
    common.is_privileged
}

# Sahip takim uyeleri/liderleri kendi session'larini yonetebilir (TUM takimlar)
allow if {
    input.resource.type == "SESSION"
    input.action in {"CREATE", "UPDATE", "DELETE", "MANAGE_SESSIONS"}
    common.owner_member(object.get(input.resource, "ownerGroup", input.resource.eventType))
}
