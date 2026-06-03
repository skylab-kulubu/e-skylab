package skylab.events

import future.keywords.if
import future.keywords.in
import future.keywords.contains
import data.skylab.common

default allow = false

# Herkes okuyabilir
allow if {
    input.resource.type == "EVENT"
    input.action == "READ"
}

# Privileged (ADMIN/YK/DK) her seyi yapar
allow if {
    input.resource.type == "EVENT"
    input.action in {"CREATE", "UPDATE", "DELETE"}
    common.is_privileged
}

# SEVIYE-BAZLI SAHIPLIK (ABAC):
# Kullanicinin etkinligin SAHIBI takimdaki seviyesi, aksiyon icin gereken seviyeler arasinda mi?
allow if {
    input.resource.type == "EVENT"
    input.action in {"CREATE", "UPDATE", "DELETE"}

    some level in user_levels
    level in required_levels
}

# --- Sahip takim ---
# ownerGroup gonderilmisse onu, yoksa eventType'i kullan (eventType != sahip takim senaryosuna hazir).
owner := object.get(input.resource, "ownerGroup", input.resource.eventType)

# --- Kullanicinin sahip takimdaki seviyeleri ---
# LEADER: {owner}_LEADER rolu (lider alt grubundan miras; alt grup adi onemli degil)
user_levels contains "LEADER" if {
    concat("", [owner, "_LEADER"]) in input.user.roles
}

# MEMBER (rol sinyali): {owner} rolu (takim grubundan miras)
user_levels contains "MEMBER" if {
    owner in input.user.roles
}

# MEMBER (grup sinyali): grup yolu sahip takima isaret ediyor mu
#   .../OWNER      -> takimin direkt uyesi
#   .../OWNER/...  -> takimin alt grubunda (Leaders/Coordinator dahil)
user_levels contains "MEMBER" if {
    some g in input.user.groups
    endswith(g, concat("", ["/", owner]))
}

user_levels contains "MEMBER" if {
    some g in input.user.groups
    contains(g, concat("", ["/", owner, "/"]))
}

# --- Aksiyon icin gereken seviyeler (izin matrisi; eventType bazli) ---
# Once etkinlige ozel tanim; yoksa _default'a dus.
required_levels := levels if {
    levels := data.skylab.event_permissions[input.resource.eventType][input.action]
}

required_levels := levels if {
    not data.skylab.event_permissions[input.resource.eventType][input.action]
    levels := data.skylab.event_permissions._default[input.action]
}
