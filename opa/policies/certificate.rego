package skylab.certificate

import future.keywords.if
import future.keywords.in
import data.skylab.common

default allow = false

# authenticated users can see their certiicate
allow if {
    input.resource.type == "CERTIFICATE"
    input.action in {"READ", "READ_ME"}
    common.is_authenticated
}

# admin all access
allow if {
    input.resource.type == "CERTIFICATE"
    input.action in {"CREATE", "UPDATE", "DELETE"}
    common.is_privileged
}

# only leaders can edit their certiicate
allow if {
    input.resource.type == "CERTIFICATE"
    input.action in {"CREATE", "UPDATE", "DELETE"}

    event_type := input.resource.eventType
    authorized := data.event_type_roles[event_type]

    some role in input.user.roles
    role in authorized
}