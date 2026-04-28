package skylab.events

import future.keywords.if
import future.keywords.in
import data.skylab.common

default allow = false



allow if {
    input.resource.type == "EVENT"
    input.action in {"READ"}
}


# admins
allow if {
    input.resource.type == "EVENT"
    input.action in {"CREATE", "UPDATE", "DELETE"}
    common.is_privileged
}

# liderlerin yetki akışı
allow if {
    input.resource.type == "EVENT"
    input.action in {"CREATE", "UPDATE", "DELETE"}

    event_type := input.resource.eventType
    authorized := data.event_type_roles[event_type]

    some role in input.user.roles
    role in authorized
}