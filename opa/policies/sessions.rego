package skylab.sessions

import future.keywords.if
import future.keywords.in
import data.skylab.common

default allow = false

allow if {
    input.resource.type == "SESSION"
    input.action == "READ"
}

allow if {
    input.resource.type == "SESSION"
    input.action in {"CREATE", "UPDATE", "DELETE", "MANAGE_SESSIONS"}
    common.is_privileged
}


allow if {
    input.resource.type == "SESSION"
    input.action in {"CREATE", "UPDATE", "DELETE"}

    event_type := input.resource.eventType
    authorized := data.skylab.event_type_roles[event_type]

    some role in input.user.roles
    role in authorized
}