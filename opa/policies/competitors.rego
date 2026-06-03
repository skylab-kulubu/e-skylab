package skylab.competitors

import future.keywords.if
import future.keywords.in
import data.skylab.common

default allow = false

allow if {
    input.resource.type == "COMPETITOR"
    input.action == "READ_PUBLIC"
}

allow if {
    input.resource.type == "COMPETITOR"
    input.action == "READ_ME"
    input.user.id != ""
}

allow if {
    input.resource.type == "COMPETITOR"
    input.action in {"READ", "LIST", "CREATE", "UPDATE", "DELETE"}
    common.is_privileged
}

# Kullanici kendi adina kayit olabilir (self-registration)
allow if {
    input.resource.type == "COMPETITOR"
    input.action == "CREATE"
    common.is_authenticated
    input.resource.ownerId == input.user.id
}

# Sahip takim uyesi/lideri baskasi adina kayit yapabilir (TUM takimlar)
allow if {
    input.resource.type == "COMPETITOR"
    input.action == "CREATE"
    common.owner_member(object.get(input.resource, "ownerGroup", input.resource.eventType))
}

# Sahip takim uyesi/lideri competitor guncelleyebilir
allow if {
    input.resource.type == "COMPETITOR"
    input.action == "UPDATE"
    common.owner_member(object.get(input.resource, "ownerGroup", input.resource.eventType))
}

# Kullanıcı kendi competitor kaydını silebilir (self)
allow if {
    input.resource.type == "COMPETITOR"
    input.action == "DELETE"
    common.is_authenticated
    input.resource.ownerId == input.user.id
}

# Sahip takim uyesi/lideri competitor silebilir
allow if {
    input.resource.type == "COMPETITOR"
    input.action == "DELETE"
    common.owner_member(object.get(input.resource, "ownerGroup", input.resource.eventType))
}
