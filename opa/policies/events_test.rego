package skylab.events_test

import future.keywords.if
import data.skylab.events

# Lider GECEKODU event silebilir (default DELETE -> LEADER)
test_leader_can_delete if {
    events.allow with input as {
        "action": "DELETE",
        "resource": {"type": "EVENT", "eventType": "GECEKODU", "ownerGroup": "GECEKODU"},
        "user": {"id": "u1", "roles": ["GECEKODU_LEADER"], "groups": []},
    }
}

# Uye GECEKODU event SILEMEZ (DELETE -> sadece LEADER)
test_member_cannot_delete_gecekodu if {
    not events.allow with input as {
        "action": "DELETE",
        "resource": {"type": "EVENT", "eventType": "GECEKODU", "ownerGroup": "GECEKODU"},
        "user": {"id": "u2", "roles": ["GECEKODU"], "groups": []},
    }
}

# Uye GECEKODU event GUNCELLEYEBILIR (override: UPDATE -> LEADER+MEMBER)
test_member_can_update_gecekodu if {
    events.allow with input as {
        "action": "UPDATE",
        "resource": {"type": "EVENT", "eventType": "GECEKODU", "ownerGroup": "GECEKODU"},
        "user": {"id": "u2", "roles": ["GECEKODU"], "groups": []},
    }
}

# Uye AGC event GUNCELLEYEMEZ (override yok -> _default: UPDATE sadece LEADER)
test_member_cannot_update_agc if {
    not events.allow with input as {
        "action": "UPDATE",
        "resource": {"type": "EVENT", "eventType": "AGC", "ownerGroup": "AGC"},
        "user": {"id": "u3", "roles": ["AGC"], "groups": []},
    }
}

# Privileged (ADMIN) her seyi yapar
test_privileged_can_delete_any if {
    events.allow with input as {
        "action": "DELETE",
        "resource": {"type": "EVENT", "eventType": "AGC", "ownerGroup": "AGC"},
        "user": {"id": "admin", "roles": ["ADMIN"], "groups": []},
    }
}

# Grup yolu sinyali ile uyelik (rol olmadan, gruptan)
test_member_via_group_path if {
    events.allow with input as {
        "action": "UPDATE",
        "resource": {"type": "EVENT", "eventType": "GECEKODU", "ownerGroup": "GECEKODU"},
        "user": {"id": "u4", "roles": [], "groups": ["/Users/Organizasyon/GECEKODU"]},
    }
}
