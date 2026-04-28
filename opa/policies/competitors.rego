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
     authorized := data.event_type_roles[event_type]

     some role in input.user.roles
     role in authorized

}