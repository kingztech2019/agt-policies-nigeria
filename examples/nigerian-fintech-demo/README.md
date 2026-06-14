# Nigerian Fintech Agent Governance Demo

End-to-end demo showing `agt-policies-nigeria` policy packs intercepting a Nigerian fintech customer support agent.

## Scenario

A customer support AI agent receives a request to process a ₦6,500,000 refund. The demo walks through five actions the agent attempts, showing how the governance layer handles each one.

| Step | Agent Action | Policy Pack | Decision |
|---|---|---|---|
| 1 | Verify customer BVN | `bvn-nin-protection.yaml` | ⏳ Requires approval |
| 2 | Process ₦6.5M refund | `cbn-transaction-limits.yaml` + `nfiu-aml-str.yaml` | ⏳ Requires approval |
| 3 | Export records to AWS US-East-1 | `ndpa-data-residency.yaml` | ⏳ Requires approval |
| 4 | Include BVN in response message | `bvn-nin-protection.yaml` | ❌ Denied |
| 5 | Look up customer profile (post-approval) | — | ✅ Allowed + audited |

Every decision — allowed, denied, or queued — is written to an append-only NDPA-compliant audit log.

## Quick Start

```bash
pip install agent-os-kernel
python demo.py
```

## Expected Output

```
============================================================
  Nigerian Fintech Agent Governance Demo
  Policy packs: NDPA 2023 + CBN + BVN/NIN + NFIU
============================================================

────────────────────────────────────────────────────────────
Step: 1 — BVN Verification
Action: verify_bvn
Decision: ⏳ REQUIRES_APPROVAL
Reason: BVN Verification: BVN verification requires human approval
Rule: bvn-verification-approval-gate
────────────────────────────────────────────────────────────

────────────────────────────────────────────────────────────
Step: 2 — ₦6.5M Refund Attempt
Action: process_refund
Decision: ⏳ REQUIRES_APPROVAL
Reason: CBN / Fraud Controls: Refund action requires human approval
Rule: cbn-refund-approval-gate
────────────────────────────────────────────────────────────

────────────────────────────────────────────────────────────
Step: 3 — Cross-Border Data Export
Action: send_to_external
Decision: ⏳ REQUIRES_APPROVAL
Reason: NDPA s.25: Cross-border personal information transfer requires approval
Rule: ndpa-crossborder-transfer-block
────────────────────────────────────────────────────────────

────────────────────────────────────────────────────────────
Step: 4 — BVN Disclosure in Response
Action: respond_to_customer
Decision: ❌ DENIED
Reason: BVN Protection: BVN value detected in agent output — blocked
Rule: bvn-pattern-in-output-block
────────────────────────────────────────────────────────────

────────────────────────────────────────────────────────────
Step: 5 — Customer Lookup (post-approval)
Action: read_customer
Decision: ✅ ALLOWED (audited)
Rule: ndpa-pii-audit-all-operations
────────────────────────────────────────────────────────────

============================================================
  Audit Log Summary (NDPA s.30 — Accountability Trail)
============================================================
  [1] ... | verify_bvn                  | REQUIRES_APPROVAL   | bvn-verification-approval-gate
  [2] ... | process_refund              | REQUIRES_APPROVAL   | cbn-refund-approval-gate
  [3] ... | send_to_external            | REQUIRES_APPROVAL   | ndpa-crossborder-transfer-block
  [4] ... | respond_to_customer         | DENIED              | bvn-pattern-in-output-block
  [5] ... | read_customer               | AUDITED             | ndpa-pii-audit-all-operations
```

## What this demonstrates

- **The agent's code does not change.** Governance is injected at the tool-calling layer by AGT.
- **Three different outcomes.** `deny` (BVN exposure), `require_approval` (high-value refund, cross-border export), and `allow+audit` (read-only lookup).
- **Full audit trail.** Every event is logged with timestamp, action, decision, and rule triggered — satisfying NDPA s.30 accountability requirements.
- **Nigerian-specific rules.** The ₦6.5M threshold, BVN pattern, and cross-border export block are not in any US/EU governance tool.
