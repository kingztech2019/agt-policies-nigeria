# agt-policies-africa
# Tests for POPIA (South Africa) policy
# Run: opa test policies/rego/ -v

package agt_policies_africa.popia_test

import data.agt_policies_africa.popia
import future.keywords.in

# ── Deny: biometric data ──────────────────────────────────────────

test_deny_biometric_fingerprint {
    count(popia.deny) > 0 with input as {
        "action": "respond",
        "params": {},
        "output": "Customer fingerprint template stored and verified successfully.",
        "context": {}
    }
}

test_deny_biometric_facial_recognition {
    count(popia.deny) > 0 with input as {
        "action": "respond",
        "params": {},
        "output": "Facial recognition matched the customer profile.",
        "context": {}
    }
}

test_deny_biometric_voice_print {
    count(popia.deny) > 0 with input as {
        "action": "respond",
        "params": {},
        "output": "Voice print authenticated the customer for this transaction.",
        "context": {}
    }
}

# ── Deny: children's personal information ────────────────────────

test_deny_children_minor {
    count(popia.deny) > 0 with input as {
        "action": "respond",
        "params": {},
        "output": "Processing minor's account data for the customer.",
        "context": {}
    }
}

test_deny_children_under_18 {
    count(popia.deny) > 0 with input as {
        "action": "respond",
        "params": {},
        "output": "This account belongs to a customer under 18 years old.",
        "context": {}
    }
}

# ── Deny: SA ID number ────────────────────────────────────────────

test_deny_sa_id_13digit {
    count(popia.deny) > 0 with input as {
        "action": "respond",
        "params": {},
        "output": "Customer ID on file: 9001015009087.",
        "context": {}
    }
}

test_deny_sa_id_contextual {
    count(popia.deny) > 0 with input as {
        "action": "respond",
        "params": {},
        "output": "SA ID: 9001015009087",
        "context": {}
    }
}

test_deny_sa_id_south_african_label {
    count(popia.deny) > 0 with input as {
        "action": "respond",
        "params": {},
        "output": "South African ID: 8506042308087",
        "context": {}
    }
}

# ── Deny: breach suppression ──────────────────────────────────────

test_deny_breach_suppression_dont_report {
    count(popia.deny) > 0 with input as {
        "action": "respond",
        "params": {},
        "output": "Don't report the breach to the Information Regulator.",
        "context": {}
    }
}

test_deny_breach_suppression_hide {
    count(popia.deny) > 0 with input as {
        "action": "respond",
        "params": {},
        "output": "We should hide the breach from the regulator.",
        "context": {}
    }
}

# ── Deny: cross-border non-adequate country ───────────────────────

test_deny_cross_border_china {
    count(popia.deny) > 0 with input as {
        "action": "export_data",
        "params": {"destination_country": "CN", "destination_region": "ap-east-1", "record_count": 100},
        "output": "", "context": {"consent_documented": false}
    }
}

test_deny_cross_border_russia {
    count(popia.deny) > 0 with input as {
        "action": "upload_to_cloud",
        "params": {"destination_country": "RU", "destination_region": "ru-central-1", "record_count": 50},
        "output": "", "context": {"consent_documented": false}
    }
}

# ── Deny: purpose limitation ──────────────────────────────────────

test_deny_purpose_limitation {
    count(popia.deny) > 0 with input as {
        "action": "respond",
        "params": {},
        "output": "Processing customer data beyond the original consent purpose.",
        "context": {}
    }
}

test_deny_data_without_authorisation {
    count(popia.deny) > 0 with input as {
        "action": "respond",
        "params": {},
        "output": "Sharing this data without authorisation from the data subject.",
        "context": {}
    }
}

# ── Escalate: cross-border actions ───────────────────────────────

test_escalate_cross_border_export_action {
    count(popia.escalate) > 0 with input as {
        "action": "export_data",
        "params": {"destination_country": "GB", "destination_region": "eu-west-2", "record_count": 50},
        "output": "", "context": {"consent_documented": true}
    }
}

test_escalate_cross_border_language_outside_sa {
    count(popia.escalate) > 0 with input as {
        "action": "respond",
        "params": {},
        "output": "Transferring customer records outside South Africa to our backup server.",
        "context": {}
    }
}

# ── Escalate: special personal information ────────────────────────

test_escalate_health_data_hiv {
    count(popia.escalate) > 0 with input as {
        "action": "respond",
        "params": {},
        "output": "Customer medical record shows HIV positive status.",
        "context": {}
    }
}

test_escalate_health_data_mental {
    count(popia.escalate) > 0 with input as {
        "action": "respond",
        "params": {},
        "output": "Mental health condition noted in customer profile.",
        "context": {}
    }
}

test_escalate_race_ethnicity {
    count(popia.escalate) > 0 with input as {
        "action": "respond",
        "params": {},
        "output": "Customer's ethnic origin is noted in the file.",
        "context": {}
    }
}

test_escalate_criminal_record {
    count(popia.escalate) > 0 with input as {
        "action": "respond",
        "params": {},
        "output": "Police clearance certificate and criminal record on file.",
        "context": {}
    }
}

# ── Audit: PII access ─────────────────────────────────────────────

test_audit_read_customer {
    count(popia.audit) > 0 with input as {
        "action": "read_customer",
        "params": {}, "output": "", "context": {}
    }
}

test_audit_get_profile {
    count(popia.audit) > 0 with input as {
        "action": "get_profile",
        "params": {}, "output": "", "context": {}
    }
}

test_audit_lookup_account {
    count(popia.audit) > 0 with input as {
        "action": "lookup_account",
        "params": {}, "output": "", "context": {}
    }
}

# ── Allow: normal operations ──────────────────────────────────────

test_allow_normal_action {
    popia.decision == "allow" with input as {
        "action": "check_fraud_score",
        "params": {}, "output": "Fraud score: 0.1 — low risk.", "context": {}
    }
}

# ── Decision rules ────────────────────────────────────────────────

test_decision_deny_biometric {
    popia.decision == "deny" with input as {
        "action": "respond",
        "params": {},
        "output": "Customer fingerprint matched successfully.",
        "context": {}
    }
}

test_decision_deny_sa_id {
    popia.decision == "deny" with input as {
        "action": "respond",
        "params": {},
        "output": "ID Number: 9001015009087",
        "context": {}
    }
}

test_decision_deny_non_adequate_country {
    popia.decision == "deny" with input as {
        "action": "export_data",
        "params": {"destination_country": "CN", "destination_region": "ap-east-1"},
        "output": "", "context": {"consent_documented": false}
    }
}

test_decision_escalate_cross_border_action {
    popia.decision == "escalate" with input as {
        "action": "export_data",
        "params": {"destination_country": "GB", "destination_region": "eu-west-2"},
        "output": "", "context": {"consent_documented": true}
    }
}

test_decision_escalate_health_data {
    popia.decision == "escalate" with input as {
        "action": "respond",
        "params": {},
        "output": "Customer has a disability recorded in their profile.",
        "context": {}
    }
}

test_decision_audit_pii_access {
    popia.decision == "audit" with input as {
        "action": "read_customer",
        "params": {}, "output": "", "context": {}
    }
}

test_decision_allow_unrelated_action {
    popia.decision == "allow" with input as {
        "action": "get_exchange_rate",
        "params": {}, "output": "ZAR/USD: 18.5", "context": {}
    }
}
