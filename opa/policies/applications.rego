package skylab.applications

import future.keywords.if
import future.keywords.in
import data.skylab.common

default allow = false

# Herkes misafir başvurusu yapabilir
allow if {
    input.resource.type == "APPLICATION"
    input.action == "CREATE_GUEST"
}

# Giriş yapmış kullanıcılar başvuru yapabilir
allow if {
    input.resource.type == "APPLICATION"
    input.action == "CREATE"
    common.is_authenticated
}

# Kullanıcı kendi başvurusunu görebilir
allow if {
    input.resource.type == "APPLICATION"
    input.action == "READ"
    common.is_authenticated
    common.is_owner
}

# Kullanıcı kendi başvurusunu iptal edebilir
allow if {
    input.resource.type == "APPLICATION"
    input.action == "CANCEL"
    common.is_authenticated
    common.is_owner
}

# Privileged kullanıcılar tüm başvuruları görebilir ve yönetebilir
allow if {
    input.resource.type == "APPLICATION"
    input.action in {"READ", "LIST", "APPROVE", "REJECT", "DELETE"}
    common.is_privileged
}

# Liderler kendi event type'larına ait başvuruları yönetebilir
allow if {
    input.resource.type == "APPLICATION"
    input.action in {"READ", "LIST", "APPROVE", "REJECT"}

    event_type := input.resource.eventType
    authorized := data.skylab.event_type_roles[event_type]

    some role in input.user.roles
    role in authorized
}
