# agt-policies-africa
# Tests for Ethiopia Personal Data Protection policy
# Run: opa test policies/rego/ -v

package agt_policies_africa.ethiopia_pdp_test

import data.agt_policies_africa.ethiopia_pdp
import rego.v1

# ── Deny: breach suppression ──────────────────────────────────────

test_deny_breach_suppression if {
	count(ethiopia_pdp.deny) > 0 with input as {
		"action": "respond",
		"params": {},
		"output": "Don't report this incident to the ECA.",
		"context": {},
	}
}

test_deny_delay_breach_report if {
	count(ethiopia_pdp.deny) > 0 with input as {
		"action": "respond",
		"params": {},
		"output": "We should delay breach report submission to the ECA.",
		"context": {},
	}
}

# ── Deny: biometric data ──────────────────────────────────────────

test_deny_fingerprint_in_output if {
	count(ethiopia_pdp.deny) > 0 with input as {
		"action": "respond",
		"params": {},
		"output": "Customer fingerprint biometric template extracted.",
		"context": {},
	}
}

test_deny_voice_print_in_output if {
	count(ethiopia_pdp.deny) > 0 with input as {
		"action": "respond",
		"params": {},
		"output": "Voice print confirmed for customer authentication.",
		"context": {},
	}
}

# ── Deny: unauthorised access signal ─────────────────────────────

test_deny_unauthorised_access if {
	count(ethiopia_pdp.deny) > 0 with input as {
		"action": "respond",
		"params": {},
		"output": "Bypassing authentication to access the admin panel.",
		"context": {},
	}
}

test_deny_circumvent_access_control if {
	count(ethiopia_pdp.deny) > 0 with input as {
		"action": "respond",
		"params": {},
		"output": "Circumventing access control to retrieve the user records.",
		"context": {},
	}
}

# ── Deny: cross-border ────────────────────────────────────────────

test_deny_us_cross_border if {
	count(ethiopia_pdp.deny) > 0 with input as {
		"action": "export_data",
		"params": {"destination_region": "us-west-2", "destination_country": "US", "record_count": 5},
		"output": "", "context": {"consent_documented": false},
	}
}

# ── Deny: Fayda ID in output ──────────────────────────────────────

test_deny_fayda_id_in_output if {
	count(ethiopia_pdp.deny) > 0 with input as {
		"action": "respond",
		"params": {},
		"output": "Fayda ID: 1234567890",
		"context": {},
	}
}

# ── Deny: large record count ──────────────────────────────────────

test_deny_record_count_1001 if {
	count(ethiopia_pdp.deny) > 0 with input as {
		"action": "export_data",
		"params": {"destination_region": "us-east-1", "destination_country": "US", "record_count": 1500},
		"output": "", "context": {},
	}
}

# ── Allow: permitted regions ──────────────────────────────────────

test_allow_ethiopia_region if {
	ethiopia_pdp.decision == "allow" with input as {
		"action": "export_data",
		"params": {"destination_region": "ethiopia", "destination_country": "ET", "record_count": 5},
		"output": "", "context": {},
	}
}

test_allow_af_east_region if {
	ethiopia_pdp.decision == "allow" with input as {
		"action": "export_data",
		"params": {"destination_region": "af-east-1", "destination_country": "ET", "record_count": 5},
		"output": "", "context": {},
	}
}

# ── Escalate: health/medical data ────────────────────────────────

test_escalate_health_data if {
	count(ethiopia_pdp.escalate) > 0 with input as {
		"action": "respond",
		"params": {},
		"output": "Customer HIV test result is positive.",
		"context": {},
	}
}

test_escalate_mental_health if {
	count(ethiopia_pdp.escalate) > 0 with input as {
		"action": "respond",
		"params": {},
		"output": "Mental health condition noted in the file.",
		"context": {},
	}
}

# ── Escalate: special category data ──────────────────────────────

test_escalate_ethnic_origin if {
	count(ethiopia_pdp.escalate) > 0 with input as {
		"action": "respond",
		"params": {},
		"output": "Customer's ethnic origin is Oromo.",
		"context": {},
	}
}

test_escalate_religious_belief if {
	count(ethiopia_pdp.escalate) > 0 with input as {
		"action": "respond",
		"params": {},
		"output": "Customer's religious belief is noted as Orthodox.",
		"context": {},
	}
}

# ── Escalate: cross-border ────────────────────────────────────────

test_escalate_cross_border_language if {
	count(ethiopia_pdp.escalate) > 0 with input as {
		"action": "respond",
		"params": {},
		"output": "Transferring customer data outside Ethiopia to a third-party server.",
		"context": {},
	}
}

test_escalate_missing_destination if {
	count(ethiopia_pdp.escalate) > 0 with input as {
		"action": "forward_to",
		"params": {"record_count": 20},
		"output": "", "context": {},
	}
}

test_escalate_moderate_record_count if {
	count(ethiopia_pdp.escalate) > 0 with input as {
		"action": "relay_data",
		"params": {"destination_region": "us-east-1", "destination_country": "US", "record_count": 200},
		"output": "", "context": {},
	}
}

test_escalate_bulk_export if {
	count(ethiopia_pdp.escalate) > 0 with input as {
		"action": "dump_database",
		"params": {}, "output": "", "context": {},
	}
}

# ── Audit: PII access ─────────────────────────────────────────────

test_audit_read_user if {
	count(ethiopia_pdp.audit) > 0 with input as {
		"action": "read_user",
		"params": {}, "output": "", "context": {},
	}
}

test_audit_patch_account if {
	count(ethiopia_pdp.audit) > 0 with input as {
		"action": "patch_account",
		"params": {}, "output": "", "context": {},
	}
}

# ── Decision rules ────────────────────────────────────────────────

test_decision_deny_biometric if {
	ethiopia_pdp.decision == "deny" with input as {
		"action": "respond",
		"params": {},
		"output": "Facial recognition confirmed customer identity.",
		"context": {},
	}
}

test_decision_deny_unauthorised_access if {
	ethiopia_pdp.decision == "deny" with input as {
		"action": "respond",
		"params": {},
		"output": "Bypassing auth to retrieve records.",
		"context": {},
	}
}

test_decision_escalate_health if {
	ethiopia_pdp.decision == "escalate" with input as {
		"action": "respond",
		"params": {},
		"output": "Customer genetic test results attached.",
		"context": {},
	}
}

test_decision_audit_pii_access if {
	ethiopia_pdp.decision == "audit" with input as {
		"action": "access_pii",
		"params": {}, "output": "", "context": {},
	}
}

test_decision_allow_normal_action if {
	ethiopia_pdp.decision == "allow" with input as {
		"action": "get_exchange_rate",
		"params": {}, "output": "USD/ETB rate is 57.5.", "context": {},
	}
}
