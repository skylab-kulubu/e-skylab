package skylab.child_test

import future.keywords.if
import data.skylab.sessions
import data.skylab.event_day
import data.skylab.certificate

# WEBLAB lideri (event_type_roles'da YOK) artik kendi session'ini yonetebilir -> owner-model fix
test_weblab_leader_can_create_session if {
    sessions.allow with input as {
        "action": "CREATE",
        "resource": {"type": "SESSION", "eventType": "WEBLAB", "ownerGroup": "WEBLAB"},
        "user": {"id": "u1", "roles": ["WEBLAB_LEADER"], "groups": []},
    }
}

# WEBLAB uyesi grup yolundan event_day guncelleyebilir
test_weblab_member_via_group_can_update_eventday if {
    event_day.allow with input as {
        "action": "UPDATE",
        "resource": {"type": "EVENT_DAY", "eventType": "WEBLAB", "ownerGroup": "WEBLAB"},
        "user": {"id": "u2", "roles": ["WEBLAB"], "groups": ["/Users/Arge/WEBLAB"]},
    }
}

# Baska takimin uyesi WEBLAB certificate'ini yonetemez
test_other_team_cannot_manage_certificate if {
    not certificate.allow with input as {
        "action": "DELETE",
        "resource": {"type": "CERTIFICATE", "eventType": "WEBLAB", "ownerGroup": "WEBLAB"},
        "user": {"id": "u3", "roles": ["ALGOLAB"], "groups": ["/Users/Arge/ALGOLAB"]},
    }
}
