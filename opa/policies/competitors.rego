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

allow if {
    input.resource.type == "COMPETITOR"
    input.action == "CREATE"

    event_type := input.resource.eventType
    authorized := data.skylab.event_type_roles[event_type]

    some role in input.user.roles
    role in authorized
}

allow if {
    input.resource.type == "COMPETITOR"
    input.action == "UPDATE"

    event_type := input.resource.eventType
    authorized := data.skylab.event_type_roles[event_type]

    some role in input.user.roles
    role in authorized
}

# Kullanıcı kendi competitor kaydını silebilir
allow if {
    input.resource.type == "COMPETITOR"
    input.action == "DELETE"
    common.is_authenticated
    input.resource.ownerId == input.user.id
}

# Liderler kendi event type'larındaki competitor'ları silebilir
allow if {
    input.resource.type == "COMPETITOR"
    input.action == "DELETE"

    event_type := input.resource.eventType
    authorized := data.skylab.event_type_roles[event_type]

    some role in input.user.roles
    role in authorized
}
