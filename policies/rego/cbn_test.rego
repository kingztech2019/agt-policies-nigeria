# agt-policies-nigeria
# Tests for CBN Transaction Limits policy
# Run: opa test policies/rego/ -v

package agt_policies_nigeria.cbn_test

import data.agt_policies_nigeria.cbn
import future.keywords.in

# ── Deny: maker-checker self-approval ────────────────────────────

test_deny_approve_transfer {
    count(cbn.deny) > 0 with input as {
        "action": "approve_transfer",
        "params": {}, "output": "", "context": {}
    }
}

test_deny_auto_approve {
    count(cbn.deny) > 0 with input as {
        "action": "auto_approve",
        "params": {}, "output": "", "context": {}
    }
}

test_deny_confirm_payment {
    count(cbn.deny) > 0 with input as {
        "action": "confirm_payment",
        "params": {}, "output": "", "context": {}
    }
}

# ── Deny: NIP cap exceeded ────────────────────────────────────────

test_deny_nip_cap_exceeded {
    count(cbn.deny) > 0 with input as {
        "action": "nip_transfer",
        "params": {"amount": 11000000, "currency": "NGN"},
        "output": "", "context": {}
    }
}

test_deny_nip_cap_one_naira_over {
    count(cbn.deny) > 0 with input as {
        "action": "instant_transfer",
        "params": {"amount": 10000001, "currency": "NGN"},
        "output": "", "context": {}
    }
}

test_deny_nip_cap_not_triggered_at_exactly_cap {
    # exactly 10M is at cap (not above) — deny should NOT fire for amount alone
    count(cbn.deny) == 0 with input as {
        "action": "nip_transfer",
        "params": {"amount": 10000000, "currency": "NGN"},
        "output": "", "context": {}
    }
}

# ── Deny: text output pattern ─────────────────────────────────────

test_deny_large_amount_in_output_ngn {
    count(cbn.deny) > 0 with input as {
        "action": "respond",
        "params": {},
        "output": "Processing transfer of NGN 11,000,000 to account.",
        "context": {}
    }
}

test_deny_large_amount_in_output_naira {
    count(cbn.deny) > 0 with input as {
        "action": "respond",
        "params": {},
        "output": "I will send naira 12000000 to the recipient.",
        "context": {}
    }
}

# ── Escalate: Tier 3 (₦5M–₦10M range) ───────────────────────────

test_escalate_tier3_at_ceiling {
    count(cbn.escalate) > 0 with input as {
        "action": "nip_transfer",
        "params": {"amount": 5000000, "currency": "NGN"},
        "output": "", "context": {}
    }
}

test_escalate_tier3_mid_range {
    count(cbn.escalate) > 0 with input as {
        "action": "wire_transfer",
        "params": {"amount": 7500000, "currency": "NGN"},
        "output": "", "context": {}
    }
}

test_escalate_tier3_at_nip_cap {
    count(cbn.escalate) > 0 with input as {
        "action": "nip_transfer",
        "params": {"amount": 10000000, "currency": "NGN"},
        "output": "", "context": {}
    }
}

# ── Escalate: Tier 2 ──────────────────────────────────────────────

test_escalate_tier2_over_ceiling {
    count(cbn.escalate) > 0 with input as {
        "action": "nip_transfer",
        "params": {"amount": 250000, "currency": "NGN"},
        "output": "", "context": {"kyc_tier": 2}
    }
}

# ── Escalate: Tier 1 ──────────────────────────────────────────────

test_escalate_tier1_over_ceiling {
    count(cbn.escalate) > 0 with input as {
        "action": "send_money",
        "params": {"amount": 60000, "currency": "NGN"},
        "output": "", "context": {"kyc_tier": 1}
    }
}

# ── Escalate: refunds ─────────────────────────────────────────────

test_escalate_process_refund {
    count(cbn.escalate) > 0 with input as {
        "action": "process_refund",
        "params": {"amount": 5000, "currency": "NGN"},
        "output": "", "context": {}
    }
}

test_escalate_manual_refund {
    count(cbn.escalate) > 0 with input as {
        "action": "manual_refund",
        "params": {}, "output": "", "context": {}
    }
}

# ── Escalate: bulk payments ───────────────────────────────────────

test_escalate_bulk_transfer {
    count(cbn.escalate) > 0 with input as {
        "action": "bulk_transfer",
        "params": {}, "output": "", "context": {}
    }
}

test_escalate_payroll_run {
    count(cbn.escalate) > 0 with input as {
        "action": "payroll_run",
        "params": {}, "output": "", "context": {}
    }
}

# ── Escalate: USSD ────────────────────────────────────────────────

test_escalate_ussd_action {
    count(cbn.escalate) > 0 with input as {
        "action": "ussd_transfer",
        "params": {}, "output": "", "context": {}
    }
}

# ── Allow: normal transfers under all limits ──────────────────────

test_allow_small_nip_transfer_tier3 {
    cbn.decision == "allow" with input as {
        "action": "nip_transfer",
        "params": {"amount": 50000, "currency": "NGN"},
        "output": "", "context": {"kyc_tier": 3}
    }
}

test_allow_read_action {
    cbn.decision == "allow" with input as {
        "action": "read_account",
        "params": {}, "output": "", "context": {}
    }
}

# ── Decision rules ────────────────────────────────────────────────

test_decision_deny_for_self_approval {
    cbn.decision == "deny" with input as {
        "action": "approve_transfer",
        "params": {}, "output": "", "context": {}
    }
}

test_decision_deny_for_nip_cap {
    cbn.decision == "deny" with input as {
        "action": "nip_transfer",
        "params": {"amount": 15000000, "currency": "NGN"},
        "output": "", "context": {}
    }
}

test_decision_escalate_for_tier3_transfer {
    cbn.decision == "escalate" with input as {
        "action": "nip_transfer",
        "params": {"amount": 6500000, "currency": "NGN"},
        "output": "", "context": {}
    }
}

test_decision_escalate_for_refund {
    cbn.decision == "escalate" with input as {
        "action": "process_refund",
        "params": {"amount": 1000, "currency": "NGN"},
        "output": "", "context": {}
    }
}

test_decision_audit_for_transfer_prefix_action {
    # "transfer_reference" starts with "transfer_" → audit, no deny or escalate
    cbn.decision == "audit" with input as {
        "action": "transfer_reference",
        "params": {}, "output": "", "context": {}
    }
}

test_decision_allow_for_unrelated_action {
    cbn.decision == "allow" with input as {
        "action": "get_exchange_rate",
        "params": {}, "output": "", "context": {}
    }
}
