package skylab.announcements

import future.keywords.if
import future.keywords.in
import data.skylab.common

default allow = false

# Herkes duyuruları okuyabilir
allow if {
    input.resource.type == "ANNOUNCEMENT"
    input.action == "READ"
}

# Privileged kullanıcılar tüm işlemleri yapabilir
allow if {
    input.resource.type == "ANNOUNCEMENT"
    input.action in {"CREATE", "UPDATE", "DELETE"}
    common.is_privileged
}

# Liderler kendi event type'larına ait duyuruları yönetebilir
allow if {
    input.resource.type == "ANNOUNCEMENT"
    input.action in {"CREATE", "UPDATE", "DELETE"}

    event_type := input.resource.eventType
    authorized := data.skylab.event_type_roles[event_type]

    some role in input.user.roles
    role in authorized
}
