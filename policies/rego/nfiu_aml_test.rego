# agt-policies-nigeria
# Tests for NFIU AML/CFT policy
# Run: opa test policies/rego/ -v

package agt_policies_nigeria.nfiu_test

import data.agt_policies_nigeria.nfiu
import future.keywords.in

# ── Deny: NIP cap exceeded ────────────────────────────────────────

test_deny_nip_cap_11M {
    count(nfiu.deny) > 0 with input as {
        "action": "nip_transfer",
        "params": {"amount": 11000000, "currency": "NGN"},
        "output": "Initiating transfer of ₦11,000,000.", "context": {}
    }
}

test_deny_nip_cap_15M {
    count(nfiu.deny) > 0 with input as {
        "action": "transfer_funds",
        "params": {"amount": 15000000, "currency": "NGN"},
        "output": "Transfer of ₦15,000,000 initiated.", "context": {}
    }
}

test_deny_nip_cap_just_over {
    count(nfiu.deny) > 0 with input as {
        "action": "nip_transfer",
        "params": {"amount": 10000001, "currency": "NGN"},
        "output": "", "context": {}
    }
}

# ── Deny: structuring patterns ────────────────────────────────────

test_deny_structuring_split_pattern {
    count(nfiu.deny) > 0 with input as {
        "action": "respond",
        "params": {},
        "output": "Let us split the transfer into 3 parts to avoid the ₦5 million threshold.",
        "context": {}
    }
}

test_deny_structuring_break_down {
    count(nfiu.deny) > 0 with input as {
        "action": "respond",
        "params": {},
        "output": "I will break down the transfer to avoid reporting requirements.",
        "context": {}
    }
}

# ── Deny: KYC controls ────────────────────────────────────────────

test_deny_kyc_bypass {
    count(nfiu.deny) > 0 with input as {
        "action": "respond",
        "params": {},
        "output": "We will skip kyc for this customer and proceed with the transaction.",
        "context": {}
    }
}

test_deny_unverified_customer_proceed {
    count(nfiu.deny) > 0 with input as {
        "action": "respond",
        "params": {},
        "output": "Customer not verified. Proceed with transfer anyway.",
        "context": {}
    }
}

# ── Escalate: CTR threshold (exact numeric) ───────────────────────

test_escalate_ctr_threshold_exact_5M {
    count(nfiu.escalate) > 0 with input as {
        "action": "nip_transfer",
        "params": {"amount": 5000000, "currency": "NGN"},
        "output": "", "context": {}
    }
}

test_escalate_ctr_threshold_7M {
    count(nfiu.escalate) > 0 with input as {
        "action": "nip_transfer",
        "params": {"amount": 7000000, "currency": "NGN"},
        "output": "", "context": {}
    }
}

test_escalate_exactly_nip_cap_10M {
    count(nfiu.escalate) > 0 with input as {
        "action": "transfer_funds",
        "params": {"amount": 10000000, "currency": "NGN"},
        "output": "", "context": {}
    }
}

# ── Escalate: STR indicators ──────────────────────────────────────

test_escalate_round_trip_pattern {
    count(nfiu.escalate) > 0 with input as {
        "action": "respond",
        "params": {},
        "output": "Send ₦500,000 and we will transfer it back as a round trip payment.",
        "context": {}
    }
}

test_escalate_unknown_counterparty {
    count(nfiu.escalate) > 0 with input as {
        "action": "respond",
        "params": {},
        "output": "Sending funds to unknown beneficiary with no kyc on record.",
        "context": {}
    }
}

test_escalate_crypto_usdt {
    count(nfiu.escalate) > 0 with input as {
        "action": "respond",
        "params": {},
        "output": "Convert ₦500,000 to USDT and send to the wallet address.",
        "context": {}
    }
}

test_escalate_pep_governor {
    count(nfiu.escalate) > 0 with input as {
        "action": "respond",
        "params": {},
        "output": "Processing payment for the state governor's account transfer.",
        "context": {}
    }
}

test_escalate_pep_minister {
    count(nfiu.escalate) > 0 with input as {
        "action": "respond",
        "params": {},
        "output": "Politically exposed minister has requested a transaction.",
        "context": {}
    }
}

# ── Audit: financial prefix actions ──────────────────────────────

test_audit_transfer_prefix {
    count(nfiu.audit) > 0 with input as {
        "action": "transfer_batch_001",
        "params": {"amount": 100}, "output": "", "context": {}
    }
}

test_audit_payment_prefix {
    count(nfiu.audit) > 0 with input as {
        "action": "payment_confirmation",
        "params": {}, "output": "", "context": {}
    }
}

test_audit_reversal_prefix {
    count(nfiu.audit) > 0 with input as {
        "action": "reversal_request",
        "params": {}, "output": "", "context": {}
    }
}

# ── Audit: structuring zone (₦4.5M–₦4.99M) ──────────────────────

test_audit_structuring_zone_4_8M {
    count(nfiu.audit) > 0 with input as {
        "action": "nip_transfer",
        "params": {"amount": 4800000, "currency": "NGN"},
        "output": "", "context": {}
    }
}

test_audit_structuring_zone_4_5M {
    count(nfiu.audit) > 0 with input as {
        "action": "nip_transfer",
        "params": {"amount": 4500000, "currency": "NGN"},
        "output": "", "context": {}
    }
}

# ── Allow: normal operations ──────────────────────────────────────

test_allow_small_transfer_50k {
    nfiu.decision == "allow" with input as {
        "action": "nip_transfer",
        "params": {"amount": 50000, "currency": "NGN"},
        "output": "", "context": {}
    }
}

test_allow_non_financial_action {
    nfiu.decision == "allow" with input as {
        "action": "check_balance",
        "params": {}, "output": "Account balance retrieved.", "context": {}
    }
}

# ── Decision rules ────────────────────────────────────────────────

test_decision_deny_nip_cap {
    nfiu.decision == "deny" with input as {
        "action": "nip_transfer",
        "params": {"amount": 12000000, "currency": "NGN"},
        "output": "", "context": {}
    }
}

test_decision_deny_structuring {
    nfiu.decision == "deny" with input as {
        "action": "respond",
        "params": {},
        "output": "Splitting the payment to avoid the ₦5 million threshold.",
        "context": {}
    }
}

test_decision_deny_kyc_bypass {
    nfiu.decision == "deny" with input as {
        "action": "respond",
        "params": {},
        "output": "Bypass kyc and proceed with the transaction.",
        "context": {}
    }
}

test_decision_escalate_ctr_6M {
    nfiu.decision == "escalate" with input as {
        "action": "nip_transfer",
        "params": {"amount": 6000000, "currency": "NGN"},
        "output": "", "context": {}
    }
}

test_decision_escalate_pep {
    nfiu.decision == "escalate" with input as {
        "action": "respond",
        "params": {},
        "output": "Government official senator account transfer processing.",
        "context": {}
    }
}

test_decision_audit_structuring_zone {
    nfiu.decision == "audit" with input as {
        "action": "nip_transfer",
        "params": {"amount": 4800000, "currency": "NGN"},
        "output": "", "context": {}
    }
}

test_decision_allow_small_transfer {
    nfiu.decision == "allow" with input as {
        "action": "nip_transfer",
        "params": {"amount": 30000, "currency": "NGN"},
        "output": "", "context": {}
    }
}
