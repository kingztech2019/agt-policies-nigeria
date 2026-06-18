# agt-policies-africa
# Tests for Uganda Data Protection and Privacy Act 2019 policy
# Run: opa test policies/rego/ -v

package agt_policies_africa.uganda_dppa_test

import data.agt_policies_africa.uganda_dppa
import rego.v1

# ── Deny: breach suppression ──────────────────────────────────────

test_deny_breach_suppression if {
	count(uganda_dppa.deny) > 0 with input as {
		"action": "respond",
		"params": {},
		"output": "Don't report this incident to the PDPO.",
		"context": {},
	}
}

test_deny_hide_breach if {
	count(uganda_dppa.deny) > 0 with input as {
		"action": "respond",
		"params": {},
		"output": "We should hide the breach from the regulator.",
		"context": {},
	}
}

# ── Deny: biometric data in output ───────────────────────────────

test_deny_fingerprint_in_output if {
	count(uganda_dppa.deny) > 0 with input as {
		"action": "respond",
		"params": {},
		"output": "Customer fingerprint template stored successfully.",
		"context": {},
	}
}

test_deny_facial_recognition_in_output if {
	count(uganda_dppa.deny) > 0 with input as {
		"action": "respond",
		"params": {},
		"output": "Facial recognition confirmed customer identity.",
		"context": {},
	}
}

# ── Deny: cross-border to non-permitted region ────────────────────

test_deny_us_east_1 if {
	count(uganda_dppa.deny) > 0 with input as {
		"action": "export_data",
		"params": {"destination_region": "us-east-1", "destination_country": "US", "record_count": 5},
		"output": "", "context": {"consent_documented": false},
	}
}

test_deny_eu_west_1 if {
	count(uganda_dppa.deny) > 0 with input as {
		"action": "upload_to_cloud",
		"params": {"destination_region": "eu-west-1", "destination_country": "IE", "record_count": 5},
		"output": "", "context": {},
	}
}

# ── Deny: national ID in output ───────────────────────────────────

test_deny_nira_id_in_output if {
	count(uganda_dppa.deny) > 0 with input as {
		"action": "respond",
		"params": {},
		"output": "Uganda ID: CM123456789012",
		"context": {},
	}
}

# ── Deny: large record export ─────────────────────────────────────

test_deny_record_count_1001 if {
	count(uganda_dppa.deny) > 0 with input as {
		"action": "export_data",
		"params": {"destination_region": "us-east-1", "destination_country": "US", "record_count": 1001},
		"output": "", "context": {},
	}
}

# ── Allow: permitted regions ──────────────────────────────────────

test_allow_uganda_region if {
	uganda_dppa.decision == "allow" with input as {
		"action": "export_data",
		"params": {"destination_region": "uganda", "destination_country": "UG", "record_count": 5},
		"output": "", "context": {},
	}
}

test_allow_af_south_1 if {
	uganda_dppa.decision == "allow" with input as {
		"action": "export_data",
		"params": {"destination_region": "af-south-1", "destination_country": "UG", "record_count": 5},
		"output": "", "context": {},
	}
}

# ── Escalate: health/medical data ────────────────────────────────

test_escalate_health_data if {
	count(uganda_dppa.escalate) > 0 with input as {
		"action": "respond",
		"params": {},
		"output": "Customer medical record shows HIV positive status.",
		"context": {},
	}
}

test_escalate_mental_health if {
	count(uganda_dppa.escalate) > 0 with input as {
		"action": "respond",
		"params": {},
		"output": "Mental health condition noted in customer file.",
		"context": {},
	}
}

# ── Escalate: special category data ──────────────────────────────

test_escalate_ethnic_origin if {
	count(uganda_dppa.escalate) > 0 with input as {
		"action": "respond",
		"params": {},
		"output": "Customer's ethnic origin is Baganda.",
		"context": {},
	}
}

test_escalate_religion if {
	count(uganda_dppa.escalate) > 0 with input as {
		"action": "respond",
		"params": {},
		"output": "Customer's religious belief is noted as Muslim.",
		"context": {},
	}
}

# ── Escalate: financial data ──────────────────────────────────────

test_escalate_bank_account if {
	count(uganda_dppa.escalate) > 0 with input as {
		"action": "respond",
		"params": {},
		"output": "Customer bank account number is 1234567890.",
		"context": {},
	}
}

test_escalate_credit_score if {
	count(uganda_dppa.escalate) > 0 with input as {
		"action": "respond",
		"params": {},
		"output": "Customer credit score is 720.",
		"context": {},
	}
}

# ── Escalate: cross-border ────────────────────────────────────────

test_escalate_cross_border_output if {
	count(uganda_dppa.escalate) > 0 with input as {
		"action": "respond",
		"params": {},
		"output": "Transferring customer data outside Uganda to backup server.",
		"context": {},
	}
}

test_escalate_missing_destination if {
	count(uganda_dppa.escalate) > 0 with input as {
		"action": "export_data",
		"params": {"record_count": 10},
		"output": "", "context": {},
	}
}

test_escalate_record_count_500 if {
	count(uganda_dppa.escalate) > 0 with input as {
		"action": "export_data",
		"params": {"destination_region": "us-east-1", "destination_country": "US", "record_count": 500},
		"output": "", "context": {},
	}
}

test_escalate_bulk_export if {
	count(uganda_dppa.escalate) > 0 with input as {
		"action": "bulk_export",
		"params": {}, "output": "", "context": {},
	}
}

# ── Audit: PII access ─────────────────────────────────────────────

test_audit_read_user if {
	count(uganda_dppa.audit) > 0 with input as {
		"action": "read_user",
		"params": {}, "output": "", "context": {},
	}
}

test_audit_get_customer if {
	count(uganda_dppa.audit) > 0 with input as {
		"action": "get_customer",
		"params": {}, "output": "", "context": {},
	}
}

test_audit_update_user if {
	count(uganda_dppa.audit) > 0 with input as {
		"action": "update_user",
		"params": {}, "output": "", "context": {},
	}
}

# ── Decision rules ────────────────────────────────────────────────

test_decision_deny_cross_border if {
	uganda_dppa.decision == "deny" with input as {
		"action": "export_data",
		"params": {"destination_region": "us-east-1", "destination_country": "US", "record_count": 5},
		"output": "", "context": {"consent_documented": false},
	}
}

test_decision_deny_biometric if {
	uganda_dppa.decision == "deny" with input as {
		"action": "respond",
		"params": {},
		"output": "Customer fingerprint matched successfully.",
		"context": {},
	}
}

test_decision_escalate_health_data if {
	uganda_dppa.decision == "escalate" with input as {
		"action": "respond",
		"params": {},
		"output": "Customer has a disability noted in their file.",
		"context": {},
	}
}

test_decision_audit_pii_access if {
	uganda_dppa.decision == "audit" with input as {
		"action": "lookup_account",
		"params": {}, "output": "", "context": {},
	}
}

test_decision_allow_normal_action if {
	uganda_dppa.decision == "allow" with input as {
		"action": "get_product_list",
		"params": {}, "output": "Here are available products.", "context": {},
	}
}
