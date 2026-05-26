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

# Kaynağın sahibi mi? Resource context'inde ownerId beklenir.
is_owner if {
    input.resource.ownerId != ""
    input.resource.ownerId == input.user.id
}

# Belirli bir event type için yetkili mi?
is_authorized_for_event_type(event_type) if {
    authorized := data.skylab.event_type_roles[event_type]
    some role in input.user.roles
    role in authorized
}
