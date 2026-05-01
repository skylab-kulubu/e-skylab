package skylab.common

import future.keywords.if
import future.keywords.in

is_privileged if {
    some role in input.user.roles
    role in data.skylab.privileged_roles
}

is_leader if {
    some role in input.user.roles
    role in data.skylab.leader_roles
}

has_role(role) if {
    role in input.user.roles
}

is_authenticated if {
    input.user.id != ""
    count(input.user.roles) > 0
}