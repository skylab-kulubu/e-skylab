package skylab.competitors_test

import future.keywords.if
import data.skylab.competitors

# Kullanici kendi adina kayit olabilir (self-registration -> ownerId == user.id)
# Not: authenticated kullanici her zaman en az "USER" rolune sahiptir (is_authenticated geregi)
test_self_registration_allowed if {
    competitors.allow with input as {
        "action": "CREATE",
        "resource": {"type": "COMPETITOR", "eventType": "AGC", "ownerId": "u1"},
        "user": {"id": "u1", "roles": ["USER"], "groups": []},
    }
}

# Baskasi adina kayit -> yetkili rol yoksa RED
test_other_registration_denied_without_role if {
    not competitors.allow with input as {
        "action": "CREATE",
        "resource": {"type": "COMPETITOR", "eventType": "AGC", "ownerId": "u1"},
        "user": {"id": "u2", "roles": [], "groups": []},
    }
}

# Baskasi adina kayit -> yetkili rol (AGC) varsa IZIN
test_other_registration_allowed_with_role if {
    competitors.allow with input as {
        "action": "CREATE",
        "resource": {"type": "COMPETITOR", "eventType": "AGC", "ownerId": "u1"},
        "user": {"id": "u2", "roles": ["AGC"], "groups": []},
    }
}

# Kullanici kendi competitor kaydini silebilir (self-delete)
test_self_delete_allowed if {
    competitors.allow with input as {
        "action": "DELETE",
        "resource": {"type": "COMPETITOR", "eventType": "AGC", "ownerId": "u1"},
        "user": {"id": "u1", "roles": ["USER"], "groups": []},
    }
}
