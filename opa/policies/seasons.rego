package skylab.seasons

import future.keywords.if
import future.keywords.in
import data.skylab.common

default allow = false

allow if {
    input.resource.type == "SEASON"
    input.action == "READ"
}

allow if {
    input.resource.type == "SEASON"
    input.action in {"CREATE", "UPDATE", "DELETE"}
    common.is_privileged
}
