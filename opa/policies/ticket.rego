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

# Sahip takim uyeleri/liderleri kendi biletlerini okuyabilir/dogrulayabilir (TUM takimlar)
allow if {
    input.resource.type == "TICKET"
    input.action in {"READ", "VALIDATE"}
    common.owner_member(object.get(input.resource, "ownerGroup", input.resource.eventType))
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
