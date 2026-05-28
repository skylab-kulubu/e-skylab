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

# Sahip takim uyeleri/liderleri kendi certificate'larini yonetebilir (TUM takimlar)
allow if {
    input.resource.type == "CERTIFICATE"
    input.action in {"CREATE", "UPDATE", "DELETE"}
    common.owner_member(object.get(input.resource, "ownerGroup", input.resource.eventType))
}