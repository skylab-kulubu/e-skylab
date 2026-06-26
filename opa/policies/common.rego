package skylab.common

import future.keywords.if
import future.keywords.in

# Ayrıcalıklı mı? (ADMIN/YK/DK gruplarından biri — grup yolundan; rol/role mapping gerekmez)
#   .../ADMIN, .../YK, .../DK         -> direkt uye
#   .../YK/...                         -> alt grup (orn. YK pozisyonlari)
is_privileged if {
    some g in input.user.groups
    some pg in data.skylab.privileged_groups
    endswith(g, concat("", ["/", pg]))
}
is_privileged if {
    some g in input.user.groups
    some pg in data.skylab.privileged_groups
    contains(g, concat("", ["/", pg, "/"]))
}

# Herhangi bir takimda lider mi? (lider alt grubunda uyelik -> grup yolundan)
is_leader if {
    some g in input.user.groups
    some sub in data.skylab.leader_subgroups
    contains(g, concat("", ["/", sub]))
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

# --- Sahiplik (ownership) helper'lari: TUM takimlar icin calisir ---
# Kaynak = Keycloak grup ağacı. Sentetik {owner}_LEADER rolune BAKILMAZ.

# Verilen sahip takimda uye mi? (grup yolu sahip takima isaret ediyor)
#   .../OWNER      -> takimin direkt uyesi
#   .../OWNER/...  -> takimin alt grubunda (Liderler/Koordinatorler dahil)
owner_member(owner) if {
    some g in input.user.groups
    endswith(g, concat("", ["/", owner]))
}
owner_member(owner) if {
    some g in input.user.groups
    contains(g, concat("", ["/", owner, "/"]))
}

# Verilen sahip takimda lider mi? (grup yolu .../OWNER/<lider-alt-grup>)
owner_leader(owner) if {
    some g in input.user.groups
    some sub in data.skylab.leader_subgroups
    contains(g, concat("", ["/", owner, "/", sub]))
}
