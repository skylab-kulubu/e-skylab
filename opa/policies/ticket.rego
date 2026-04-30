package skylab.ticket

import future.keywords.if
import future.keywords.in
import data.skylab.common

default allow = false

allow if {
    input.resource.type == "TICKET"
    input.action in {"READ", "VALIDATE"}
    common.is_privileged
}


allow if {
    input.resource.type == "TICKET"
    input.action == "VALIDATE"

    event_type := input.resource.eventType
    authorized := data.skylab.event_type_roles[event_type]

    some role in input.user.roles
    role in authorized
}


allow if {
    input.resource.type == "TICKET"
    input.action == "READ_ME"
    common.is_authenticated
}

allow if {
    input.resource.type == "TICKET"
    input.action == "CREATE"
    common.is_authenticated
}