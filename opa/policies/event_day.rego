package skylab.event_day

import future.keywords.if
import future.keywords.in
import data.skylab.common

default allow = false

# read is allowed for everyone
allow if {
    input.resource.type == "EVENT_DAY"
    input.action in {"READ"}
}

# admin all access
allow if {
    input.resource.type == "EVENT_DAY"
    input.action in {"CREATE", "UPDATE", "DELETE"}
    common.is_privileged
}

# only leaders can edit their events day
allow if {
    input.resource.type == "EVENT_DAY"
    input.action in {"CREATE", "UPDATE", "DELETE"}

    event_type := input.resource.eventType
    authorized := data.skylab.event_type_roles[event_type]

    some role in input.user.roles
    role in authorized
}