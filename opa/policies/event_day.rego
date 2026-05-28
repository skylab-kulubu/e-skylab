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

# Sahip takim uyeleri/liderleri kendi event day'lerini yonetebilir (TUM takimlar)
allow if {
    input.resource.type == "EVENT_DAY"
    input.action in {"CREATE", "UPDATE", "DELETE"}
    common.owner_member(object.get(input.resource, "ownerGroup", input.resource.eventType))
}