package skylab.media

import future.keywords.if
import future.keywords.in
import data.skylab.common

default allow = false

allow if {
    input.resource.type == "MEDIA"
    input.action == "READ"
}

allow if {
    input.resource.type == "MEDIA"
    input.action in {"UPLOAD"}
    common.is_authenticated
}

allow if {
    input.resource.type == "MEDIA"
    input.action == "DELETE"
    common.is_privileged
}