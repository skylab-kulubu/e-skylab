package skylab.ticket

import future.keywords.if
import future.keywords.in
import data.skylab.common

default allow = false

# Privileged kullanıcılar okuma ve doğrulama yapabilir
allow if {
    input.resource.type == "TICKET"
    input.action in {"READ", "VALIDATE"}
    common.is_privileged
}

# Liderler kendi event type'larına ait biletleri okuyabilir ve doğrulayabilir
allow if {
    input.resource.type == "TICKET"
    input.action in {"READ", "VALIDATE"}

    event_type := input.resource.eventType
    authorized := data.skylab.event_type_roles[event_type]

    some role in input.user.roles
    role in authorized
}

# Giriş yapmış kullanıcılar kendi biletlerini görebilir
allow if {
    input.resource.type == "TICKET"
    input.action == "READ_ME"
    common.is_authenticated
}

# Giriş yapmış kullanıcılar bilet oluşturabilir (başvuru üzerinden)
allow if {
    input.resource.type == "TICKET"
    input.action == "CREATE"
    common.is_authenticated
}

# Kullanıcı yalnızca kendi biletini iptal edebilir
allow if {
    input.resource.type == "TICKET"
    input.action == "CANCEL"
    common.is_authenticated
    input.resource.ownerId == input.user.id
}

# Privileged kullanıcılar herhangi bir bileti iptal edebilir
allow if {
    input.resource.type == "TICKET"
    input.action == "CANCEL"
    common.is_privileged
}
