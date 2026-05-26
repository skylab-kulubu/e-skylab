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

# Liderler kendi event type'larına ait session'ları yönetebilir
allow if {
    input.resource.type == "SESSION"
    input.action in {"CREATE", "UPDATE", "DELETE"}

    event_type := input.resource.eventType
    authorized := data.skylab.event_type_roles[event_type]

    some role in input.user.roles
    role in authorized
}

# Liderler kendi event type'larının session'larını yönetebilir (MANAGE_SESSIONS)
allow if {
    input.resource.type == "SESSION"
    input.action == "MANAGE_SESSIONS"

    event_type := input.resource.eventType
    authorized := data.skylab.event_type_roles[event_type]

    some role in input.user.roles
    role in authorized
}
