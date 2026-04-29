package skylab.users

import future.keywords.if
import future.keywords.in
import data.skylab.common

default allow = false

# Kendi profili
allow if {
    input.resource.type == "USER"
    input.action in {"READ_ME", "UPDATE_ME"}
    input.user.id != ""
}


allow if {
    input.resource.type == "USER"
    input.action in {"READ", "LIST"}
    common.is_privileged
}


allow if {
    input.resource.type == "USER"
    input.action in {"UPDATE", "DELETE", "PROMOTE"}
    common.is_privileged
}


#skyforms users can access to all users
allow if {
    input.resource.type == "USER"
    input.action == "READ"
    "skyforms:access" in input.user.roles
}