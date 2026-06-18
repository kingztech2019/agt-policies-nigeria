# agt-policies-africa
# Tests for Tanzania Personal Data Protection Act 2022 policy
# Run: opa test policies/rego/ -v

package agt_policies_africa.tanzania_pdpa_test

import data.agt_policies_africa.tanzania_pdpa
import rego.v1

# ── Deny: breach suppression ──────────────────────────────────────

test_deny_breach_suppression if {
	count(tanzania_pdpa.deny) > 0 with input as {
		"action": "respond",
		"params": {},
		"output": "Don't report this incident to the PDPC.",
		"context": {},
	}
}

test_deny_suppress_alert if {
	count(tanzania_pdpa.deny) > 0 with input as {
		"action": "respond",
		"params": {},
		"output": "We must suppress notification to the PDPC about this breach.",
		"context": {},
	}
}

# ── Deny: biometric data ──────────────────────────────────────────

test_deny_fingerprint_in_output if {
	count(tanzania_pdpa.deny) > 0 with input as {
		"action": "respond",
		"params": {},
		"output": "Customer fingerprint template extracted and stored.",
		"context": {},
	}
}

test_deny_iris_scan_in_output if {
	count(tanzania_pdpa.deny) > 0 with input as {
		"action": "respond",
		"params": {},
		"output": "Iris scan data matched to customer account.",
		"context": {},
	}
}

# ── Deny: cross-border ────────────────────────────────────────────

test_deny_us_cross_border if {
	count(tanzania_pdpa.deny) > 0 with input as {
		"action": "export_data",
		"params": {"destination_region": "us-east-1", "destination_country": "US", "record_count": 5},
		"output": "", "context": {"consent_documented": false},
	}
}

test_deny_eu_cross_border if {
	count(tanzania_pdpa.deny) > 0 with input as {
		"action": "sync_to_remote",
		"params": {"destination_region": "eu-central-1", "destination_country": "DE", "record_count": 10},
		"output": "", "context": {},
	}
}

# ── Deny: processing without consent ─────────────────────────────

test_deny_processing_without_consent if {
	count(tanzania_pdpa.deny) > 0 with input as {
		"action": "respond",
		"params": {},
		"output": "We are sharing this data without consent from the customer.",
		"context": {},
	}
}

# ── Deny: NIDA national ID in output ─────────────────────────────

test_deny_nida_in_output if {
	count(tanzania_pdpa.deny) > 0 with input as {
		"action": "respond",
		"params": {},
		"output": "NIDA number: 19990101123456789012",
		"context": {},
	}
}

# ── Deny: large record count ──────────────────────────────────────

test_deny_record_count_1001 if {
	count(tanzania_pdpa.deny) > 0 with input as {
		"action": "export_data",
		"params": {"destination_region": "us-east-1", "destination_country": "US", "record_count": 1001},
		"output": "", "context": {},
	}
}

# ── Allow: permitted regions ──────────────────────────────────────

test_allow_tanzania_region if {
	tanzania_pdpa.decision == "allow" with input as {
		"action": "export_data",
		"params": {"destination_region": "tanzania", "destination_country": "TZ", "record_count": 5},
		"output": "", "context": {},
	}
}

test_allow_af_south_1 if {
	tanzania_pdpa.decision == "allow" with input as {
		"action": "export_data",
		"params": {"destination_region": "af-south-1", "destination_country": "TZ", "record_count": 5},
		"output": "", "context": {},
	}
}

# ── Escalate: special category data ──────────────────────────────

test_escalate_health_data if {
	count(tanzania_pdpa.escalate) > 0 with input as {
		"action": "respond",
		"params": {},
		"output": "Customer medical record shows disability.",
		"context": {},
	}
}

test_escalate_ethnic_origin if {
	count(tanzania_pdpa.escalate) > 0 with input as {
		"action": "respond",
		"params": {},
		"output": "Customer's ethnic origin is noted.",
		"context": {},
	}
}

test_escalate_religious_belief if {
	count(tanzania_pdpa.escalate) > 0 with input as {
		"action": "respond",
		"params": {},
		"output": "Customer's religious belief is Christian.",
		"context": {},
	}
}

# ── Escalate: cross-border ────────────────────────────────────────

test_escalate_cross_border_output if {
	count(tanzania_pdpa.escalate) > 0 with input as {
		"action": "respond",
		"params": {},
		"output": "Transferring customer data outside Tanzania to our backup.",
		"context": {},
	}
}

test_escalate_missing_destination if {
	count(tanzania_pdpa.escalate) > 0 with input as {
		"action": "export_data",
		"params": {"record_count": 10},
		"output": "", "context": {},
	}
}

test_escalate_record_count_500 if {
	count(tanzania_pdpa.escalate) > 0 with input as {
		"action": "relay_data",
		"params": {"destination_region": "us-east-1", "destination_country": "US", "record_count": 500},
		"output": "", "context": {},
	}
}

test_escalate_bulk_export if {
	count(tanzania_pdpa.escalate) > 0 with input as {
		"action": "bulk_export",
		"params": {}, "output": "", "context": {},
	}
}

# ── Audit: PII access ─────────────────────────────────────────────

test_audit_read_user if {
	count(tanzania_pdpa.audit) > 0 with input as {
		"action": "read_user",
		"params": {}, "output": "", "context": {},
	}
}

test_audit_modify_profile if {
	count(tanzania_pdpa.audit) > 0 with input as {
		"action": "modify_profile",
		"params": {}, "output": "", "context": {},
	}
}

# ── Decision rules ────────────────────────────────────────────────

test_decision_deny_biometric if {
	tanzania_pdpa.decision == "deny" with input as {
		"action": "respond",
		"params": {},
		"output": "Voice print biometric data confirmed.",
		"context": {},
	}
}

test_decision_escalate_health if {
	tanzania_pdpa.decision == "escalate" with input as {
		"action": "respond",
		"params": {},
		"output": "Customer HIV test result is positive.",
		"context": {},
	}
}

test_decision_audit_pii_access if {
	tanzania_pdpa.decision == "audit" with input as {
		"action": "fetch_profile",
		"params": {}, "output": "", "context": {},
	}
}

test_decision_allow_normal_action if {
	tanzania_pdpa.decision == "allow" with input as {
		"action": "check_service_status",
		"params": {}, "output": "All systems operational.", "context": {},
	}
}
