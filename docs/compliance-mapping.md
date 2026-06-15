# Compliance Mapping — African Regulatory Requirements → Rego Rules

This document maps each regulatory obligation to the exact Rego rule that enforces it,
the input that triggers it, and the expected decision. Intended for compliance officers,
auditors, and developers integrating these policies.

---

## Nigeria Data Protection Act 2023 (NDPA)

Enforcing authority: **Nigeria Data Protection Commission (NDPC)**
Rego file: `policies/rego/ndpa-data-residency.rego`

| Section | Obligation | Rego Rule | Trigger | Decision |
|---|---|---|---|---|
| s.25(1) | Restrict cross-border transfer to non-adequate jurisdictions | `deny[msg]` — non-permitted region | `action` in transfer set + `destination_region` not in `{af-south-1, nigeria, NG, ng}` | `deny` |
| s.25(1) | Block transfer to non-Nigerian country without consent | `deny[msg]` — non-NG country | `destination_country != "NG"` + `consent_documented != true` | `deny` |
| s.24 | Data minimisation — block bulk exports | `deny[msg]` — bulk export actions | `action` in `{bulk_export, dump_database, export_all, ...}` | `deny` |
| s.24 | Data minimisation — block disproportionate record exports | `deny[msg]` — record count > 1000 | `record_count > 1000` | `deny` |
| Schedule 1 | Biometric data must not be transmitted without lawful basis | `deny[msg]` — biometric output | output contains fingerprint / facial recognition / iris / retina | `deny` |
| s.22(5) | 72-hour breach notification obligation | `deny[msg]` — breach suppression | output contains "don't report" / "hide the breach" / "suppress alert" | `deny` |
| s.25(1) | Cannot verify adequacy without destination metadata | `escalate[msg]` — missing destination | transfer action with no `destination_region` or `destination_country` | `escalate` |
| s.24 | Moderate record exports require DPO approval | `escalate[msg]` — record count 100–1000 | `100 < record_count <= 1000` | `escalate` |
| s.25(1) | Cross-border language in output triggers review | `escalate[msg]` — output pattern | output contains "outside Nigeria" / "cross-border" / "offshore" | `escalate` |
| Schedule 1 | Health/medical data requires explicit lawful basis | `escalate[msg]` — health output | output contains medical record / HIV / mental health / disability | `escalate` |
| s.30 | Accountability — log all personal data access | `audit[msg]` — PII access | `action` in `{read_user, get_customer, lookup_account, fetch_profile, ...}` | `audit` |
| s.30 | Accountability — log all personal data modifications | `audit[msg]` — PII modification | `action` in `{update_user, modify_profile, patch_account, ...}` | `audit` |

**Try it:**
```bash
# NDPA s.25 — cross-border deny
opa eval -d policies/rego/ndpa-data-residency.rego \
  -i examples/inputs/ndpa-deny-cross-border.json \
  "data.agt_policies_nigeria.ndpa.decision"
# → "deny"

# NDPA — permitted region
opa eval -d policies/rego/ndpa-data-residency.rego \
  -i examples/inputs/ndpa-allow-permitted.json \
  "data.agt_policies_nigeria.ndpa.decision"
# → "allow"
```

---

## Central Bank of Nigeria — Transaction Controls

Regulatory references:
- **CBN Circular FPR/DIR/GEN/CIR/07/003** — Tiered KYC limits
- **CBN NIP Framework** — ₦10M single-transaction cap
- **CBN USSD Banking Guidelines** — ₦100,000 daily limit

Rego file: `policies/rego/cbn-transaction-limits.rego`

| Regulation | Obligation | Rego Rule | Trigger | Decision |
|---|---|---|---|---|
| CBN Maker-Checker | AI agent cannot self-approve financial transactions | `deny[msg]` — self-approval | `action` in `{approve_transfer, confirm_payment, auto_approve, ...}` | `deny` |
| CBN NIP Framework | Single transaction cap ₦10,000,000 | `deny[msg]` — NIP cap | transfer action + `amount > 10,000,000` | `deny` |
| CBN NIP Framework | Defence-in-depth: detect large amounts in output | `deny[msg]` — text pattern | output contains ₦/NGN/naira + amount > 10M | `deny` |
| CBN Tiered KYC — Tier 3 | Transfers ₦5M–₦10M require human approval | `escalate[msg]` — tier 3 | transfer action + `5,000,000 <= amount <= 10,000,000` | `escalate` |
| CBN Tiered KYC — Tier 2 | Tier 2 customers capped at ₦200,000 | `escalate[msg]` — tier 2 | transfer action + `amount > 200,000` + `kyc_tier == 2` | `escalate` |
| CBN Tiered KYC — Tier 1 | Tier 1 customers capped at ₦50,000 | `escalate[msg]` — tier 1 | transfer action + `amount > 50,000` + `kyc_tier == 1` | `escalate` |
| CBN Fraud Controls | Refunds require human approval | `escalate[msg]` — refund | `action` in `{process_refund, issue_refund, manual_refund, ...}` | `escalate` |
| CBN Agent Banking | Bulk/batch payments require approval | `escalate[msg]` — bulk | `action` in `{bulk_transfer, payroll_run, batch_payment, ...}` | `escalate` |
| CBN USSD Guidelines | USSD transactions require human review | `escalate[msg]` — USSD | `action` starts with `ussd_` | `escalate` |
| CBN Record-Keeping | All financial actions must be logged | `audit[msg]` — financial prefix | `action` starts with `transfer_`, `payment_`, `refund_`, `reversal_`, etc. | `audit` |

**Try it:**
```bash
# CBN NIP cap — deny
opa eval -d policies/rego/cbn-transaction-limits.rego \
  -i examples/inputs/cbn-deny-nip-cap.json \
  "data.agt_policies_nigeria.cbn.decision"
# → "deny"

# CBN Tier 3 — escalate
opa eval -d policies/rego/cbn-transaction-limits.rego \
  -i examples/inputs/cbn-escalate-tier3.json \
  "data.agt_policies_nigeria.cbn.decision"
# → "escalate"

# Normal transfer — allow
opa eval -d policies/rego/cbn-transaction-limits.rego \
  -i examples/inputs/cbn-allow.json \
  "data.agt_policies_nigeria.cbn.decision"
# → "allow"
```

---

## BVN / NIN Data Protection

Regulatory references:
- **CBN BVN Policy Framework (2014, updated 2023)** — NIBSS BVN governance
- **NIMC Act** — NIN management
- **NDPA 2023 Schedule 1** — biometric data as sensitive personal data

Rego file: `policies/rego/bvn-nin-protection.rego`

| Regulation | Obligation | Rego Rule | Trigger | Decision |
|---|---|---|---|---|
| CBN BVN Framework | BVN must not appear in agent output | `deny[msg]` — BVN output | output matches `bvn is/bvn:/bvn= + 10–11 digits` | `deny` |
| CBN BVN Framework | Contextual BVN pattern in output blocked | `deny[msg]` — BVN contextual | output matches `bank verification ... 11 digits` | `deny` |
| NIMC Act | NIN must not appear in agent output | `deny[msg]` — NIN output | output matches `nin is/nin:/nin= + 10–11 digits` | `deny` |
| NIMC Act | Virtual NIN (vNIN) must not appear in output | `deny[msg]` — vNIN output | output matches `vnin/virtual nin + 16 chars` | `deny` |
| CBN BVN Framework | No direct BVN/NIN transmission to external systems | `deny[msg]` — transmission | `action` in `{send_bvn, transmit_nin, relay_kyc, ...}` | `deny` |
| NDPA Schedule 1 | Social engineering via BVN/NIN over chat blocked | `deny[msg]` — social engineering | output contains "confirm BVN over WhatsApp/call/SMS" | `deny` |
| CBN BVN Framework | BVN verification requires audit trail | `escalate[msg]` — BVN verify | `action` in `{verify_bvn, bvn_lookup, nibss_bvn_verify, ...}` | `escalate` |
| NIMC Act | NIN lookup requires documented purpose | `escalate[msg]` — NIN verify | `action` in `{verify_nin, nin_lookup, nimc_nin_verify, ...}` | `escalate` |
| CBN / NDPA | BVN/NIN identifier type in params requires approval | `escalate[msg]` — identifier type | `params.identifier_type` in `{BVN, NIN, bvn, nin}` | `escalate` |
| NDPA s.30 / CBN BVN | All identity-related actions must be logged | `audit[msg]` — identity action | `action` contains `bvn`, `nin`, `kyc`, or `identity_verify` | `audit` |

**Try it:**
```bash
# BVN in output — deny
opa eval -d policies/rego/bvn-nin-protection.rego \
  -i examples/inputs/bvn-deny-output.json \
  "data.agt_policies_nigeria.bvn_nin.decision"
# → "deny"

# BVN verification — escalate
opa eval -d policies/rego/bvn-nin-protection.rego \
  -i examples/inputs/bvn-escalate-verify.json \
  "data.agt_policies_nigeria.bvn_nin.decision"
# → "escalate"
```

---

## Input Schema Reference

All three policies share the same input structure:

```json
{
  "action":  "<tool or action name>",
  "params":  { "<key>": "<value>" },
  "output":  "<agent text output>",
  "context": { "<key>": "<value>" }
}
```

Key fields per policy:

| Policy | Key Input Fields |
|---|---|
| CBN | `params.amount`, `params.currency`, `context.kyc_tier` |
| BVN/NIN | `params.identifier_type`, `params.bvn_present`, `output` |
| NDPA | `params.destination_region`, `params.destination_country`, `params.record_count`, `context.consent_documented` |

Example input files are in [`examples/inputs/`](../examples/inputs/).

---

## Decision Values

All three policies return one of four decisions:

| Decision | Meaning | Action Required |
|---|---|---|
| `deny` | Hard block — regulation prohibits this | Stop execution immediately |
| `escalate` | Route to human approval queue | Pause and await human sign-off |
| `audit` | Allowed but must be logged | Execute and write to audit trail |
| `allow` | No violation detected | Proceed normally |
