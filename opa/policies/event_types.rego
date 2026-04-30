package skylab.event_types

import future.keywords.if
import future.keywords.in
import data.skylab.common

default allow = false

allow if {
    input.resource.type == "EVENT_TYPE"
    input.action == "READ"
}

allow if {
    input.resource.type == "EVENT_TYPE"
    input.action in {"CREATE", "UPDATE", "DELETE"}
    common.is_privileged
}

is_valid if {
    input.name in object.keys(data.skylab.event_type_roles)
}