<!-- agt-policies-nigeria — Nigeria Data Protection Act 2023 Compliance Mapping -->

# Nigeria Data Protection Act 2023 — AGT Control Mapping

> **Disclaimer**: This document is a community-maintained self-assessment mapping, NOT a validated certification or legal compliance opinion. It documents how the Agent Governance Toolkit's capabilities align with NDPA 2023 obligations relevant to AI agent systems. Organisations must perform their own compliance assessments with qualified advisors and registered Data Protection Officers.

**Document scope:** Mapping of NDPA 2023 obligations to AGT controls, specifically for AI agent deployments in Nigerian financial services, insurtech, and enterprise contexts.

**Policy pack:** [`policies/ndpa-data-residency.yaml`](../policies/ndpa-data-residency.yaml)

**Regulatory reference:** [Nigeria Data Protection Act 2023](https://ndpb.gov.ng) (signed into law 14 June 2023)

**Enforcing authority:** Nigeria Data Protection Commission (NDPC), formerly NDPB

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [NDPA 2023 Overview — Agent-Relevant Obligations](#ndpa-2023-overview)
3. [Control Mapping by Obligation](#control-mapping)
4. [Coverage Summary Matrix](#coverage-summary-matrix)
5. [Gap Analysis](#gap-analysis)
6. [Recommended Implementation Steps](#recommended-implementation-steps)

---

## Executive Summary

The Nigeria Data Protection Act 2023 (NDPA) is Nigeria's first comprehensive data protection law, aligning broadly with GDPR principles while reflecting the Nigerian regulatory context. For AI agent deployments, the most critical obligations are:

- **s.25 — Cross-border transfer restrictions**: Agents must not autonomously route personal data outside Nigeria
- **Schedule 1 — Sensitive personal data**: Health, biometric, genetic, and ethnic-origin data require heightened controls
- **s.24 — Data minimisation**: Agents must not collect or process beyond the stated purpose
- **s.30 — Accountability**: Every agent action touching personal data must produce an audit trail

This mapping covers these obligations and assesses how AGT's policy engine, audit logging, and approval queue infrastructure support NDPA compliance for AI agent systems.

**Coverage summary: 4 of 8 mapped obligations partially covered by AGT + policy pack. 4 require additional organisational controls.**

---

## NDPA 2023 Overview — Agent-Relevant Obligations {#ndpa-2023-overview}

| Section | Obligation | Agent Relevance |
|---|---|---|
| s.2(1) | Definition of personal data (broad — name, address, email, phone, location, biometric, online identifiers) | Agents regularly handle all of these |
| s.11 | Lawful basis for processing (consent, contract, legal obligation, vital interests, public task, legitimate interests) | Agent actions must have a documented lawful basis |
| s.24 | Data minimisation — collect only what is necessary | Agents must not over-collect or bulk-export |
| s.25 | Cross-border transfer — only to jurisdictions with adequate protection | Agents must not autonomously route data offshore |
| s.30 | Accountability — data controllers must demonstrate compliance | Every agent decision must be logged |
| s.22(5) | Breach notification — 72 hours to NDPC, without undue delay to data subjects | Agents must not suppress breach signals |
| Schedule 1 | Sensitive personal data (health, biometric, genetic, ethnic origin, political opinions, religious beliefs, sexual life) | Heightened controls required |
| s.40–47 | Data subject rights (access, rectification, erasure, restriction, portability, objection) | Agent-assisted fulfilment must be logged |

---

## Control Mapping by Obligation {#control-mapping}

### s.25 — Cross-Border Transfer Restrictions

> *Personal data may only be transferred to a foreign country or international organisation where that country or organisation ensures an adequate level of data protection, or where the data subject has given explicit consent.*

| Obligation | AGT Control | Policy Rule | Coverage |
|---|---|---|---|
| Block autonomous cross-border transfers | `PolicyEvaluator` — `require_approval` action | `ndpa-crossborder-explicit-transfer-block` | ✅ Covered |
| Detect offshore routing in agent output | `blocked_patterns` via output matching | `ndpa-crossborder-region-block` | ✅ Covered |
| Detect non-Nigerian cloud region routing | Output pattern matching | `ndpa-crossborder-us-eu-routing` | ⚠️ Partial — depends on agent outputting region names |
| Document destination adequacy assessment | Audit log + human approval decision | `GovernanceAuditLogger` | ⚠️ Partial — approval captures decision; adequacy rationale must be added manually |
| Maintain transfer records for NDPC | Append-only audit log | `GovernanceAuditLogger` with JSONL backend | ✅ Covered |

**Gap:** AGT does not currently enforce data residency at the infrastructure layer (i.e., it cannot verify that your audit logs themselves are stored in Nigeria). This is an organisational control outside the scope of the policy engine.

---

### Schedule 1 — Sensitive Personal Data

> *Processing of health data, biometric data, genetic data, data concerning ethnic/racial origin, political opinions, religious or philosophical beliefs, trade union membership, and data concerning a natural person's sex life shall be subject to heightened controls.*

| Sensitive Category | AGT Control | Policy Rule | Coverage |
|---|---|---|---|
| Health / medical data | Output pattern detection → `require_approval` | `ndpa-sensitive-health-data-block` | ✅ Covered |
| Biometric data | Output pattern detection → `deny` | `ndpa-sensitive-biometric-block` | ✅ Covered |
| Ethnic / racial origin | Output pattern detection → `audit` | `ndpa-sensitive-ethnic-political-block` | ⚠️ Partial — audits but does not block; organisations should escalate to `deny` where appropriate |
| Political opinions | Output pattern detection → `audit` | `ndpa-sensitive-ethnic-political-block` | ⚠️ Partial — same as above |
| BVN / NIN (biometrically linked) | Output pattern detection → `deny` | `bvn-nin-protection.yaml` (separate pack) | ✅ Covered (separate policy file) |
| Genetic data | Not yet covered | — | ❌ Gap |
| Sex life / sexual orientation | Not yet covered | — | ❌ Gap |

---

### s.24 — Data Minimisation

> *Personal data must be adequate, relevant, and limited to what is necessary in relation to the purposes for which it is processed.*

| Obligation | AGT Control | Policy Rule | Coverage |
|---|---|---|---|
| Block bulk data export operations | Tool name matching → `deny` | `ndpa-bulk-data-export-block` | ✅ Covered |
| Detect mass data collection patterns | Output pattern matching → `deny` | `ndpa-mass-data-collection-flag` | ✅ Covered |
| Enforce purpose limitation | — | Not implemented in v1 | ❌ Gap — requires integration with consent management system |

---

### s.30 — Accountability

> *The data controller must be able to demonstrate compliance with NDPA 2023 obligations. Records of processing activities must be maintained.*

| Obligation | AGT Control | Policy Rule | Coverage |
|---|---|---|---|
| Log every personal data access | `GovernanceAuditLogger` → `audit` action | `ndpa-pii-audit-all-operations` | ✅ Covered |
| Log every personal data modification | `GovernanceAuditLogger` → `audit` action | `ndpa-pii-update-audit` | ✅ Covered |
| Tamper-evident audit log | `MerkleAuditChain` (SHA-256 hash chaining) | AGT built-in | ✅ Covered |
| 5-year retention of processing records | Configurable retention on audit backend | `retention_days` schema field | ⚠️ Partial — schema field exists; enforcement requires backend implementation |
| ROPA (Record of Processing Activities) | Not generated automatically | — | ❌ Gap — must be maintained manually by Data Protection Officer |

---

### s.22(5) — Breach Notification

> *The data controller must notify the NDPC within 72 hours of becoming aware of a personal data breach, and affected data subjects without undue delay.*

| Obligation | AGT Control | Policy Rule | Coverage |
|---|---|---|---|
| Block agents from suppressing breach signals | Output pattern matching → `deny` | `ndpa-breach-suppression-block` | ✅ Covered |
| Automatic breach escalation workflow | — | Not implemented — requires integration with incident response system | ❌ Gap |

---

### s.40–47 — Data Subject Rights

> *Data subjects have the right to: access their data, rectify inaccurate data, erasure in certain circumstances, restriction of processing, data portability, and to object to processing.*

| Right | AGT Control | Coverage |
|---|---|---|
| Right of access (s.40) | Audit log provides access history — `audit` actions | ⚠️ Partial — log exists; DSAR fulfillment workflow not automated |
| Right to rectification (s.41) | Not implemented | ❌ Gap |
| Right to erasure (s.42) | Not implemented | ❌ Gap |
| Right to restriction (s.43) | Agent can be blocked via policy update | ⚠️ Partial — manual policy update required |
| Right to portability (s.44) | Not implemented | ❌ Gap |
| Right to object (s.45) | Not implemented | ❌ Gap |

---

## Coverage Summary Matrix {#coverage-summary-matrix}

| NDPA Obligation | Coverage | Key Control | Primary Gap |
|---|---|---|---|
| s.25 — Cross-border transfers | ✅ Covered | `ndpa-crossborder-*` rules + approval queue | Adequacy documentation is manual |
| Schedule 1 — Sensitive data (health, biometric) | ✅ Covered | Pattern detection + deny/require_approval | Genetic data and sex life categories not yet covered |
| s.24 — Data minimisation (bulk export) | ✅ Covered | `ndpa-bulk-data-export-block` | Purpose limitation not enforced |
| s.30 — Accountability / audit trail | ✅ Covered | `GovernanceAuditLogger` + `MerkleAuditChain` | ROPA not auto-generated; 5-year retention manual |
| s.22(5) — Breach notification | ⚠️ Partial | Suppression block | No automated incident escalation workflow |
| s.11 — Lawful basis for processing | ⚠️ Partial | Audit logging provides evidence | Lawful basis not validated per-action |
| Schedule 1 — Sensitive data (genetic, sex life) | ❌ Gap | — | Not yet implemented in v1 |
| s.40–47 — Data subject rights | ❌ Gap | Partial audit trail only | No DSAR automation |

**4 of 8 obligations covered or substantially addressed. 2 partially addressed. 2 gaps.**

---

## Gap Analysis {#gap-analysis}

### Genetic Data and Sex Life Categories (Schedule 1)

The v1 policy pack does not include pattern rules for genetic data or data concerning sexual orientation/sex life. These are lower-frequency patterns in typical fintech agent interactions but are required for full Schedule 1 coverage. Planned for v1.1.

### Purpose Limitation (s.24)

AGT's policy engine enforces data minimisation at the action level (blocking bulk exports) but cannot currently validate whether a specific data access is within the purpose the data subject consented to. This requires integration with a consent management system that tracks per-purpose consent status.

### Data Subject Rights Automation (s.40–47)

NDPA s.40–47 rights fulfilment (access, erasure, portability) requires dedicated workflows. AGT's audit log provides the data access history needed to respond to access requests, but the request intake, identity verification, and response workflow must be built separately.

### Breach Escalation Workflow (s.22(5))

The policy pack blocks agents from suppressing breach notifications but does not automate the NDPC notification workflow. Organisations must implement a separate incident response process. AGT's approval queue could be extended to serve as the escalation channel — a planned enhancement.

---

## Recommended Implementation Steps {#recommended-implementation-steps}

1. **Deploy `ndpa-data-residency.yaml`** alongside `bvn-nin-protection.yaml` and `nfiu-aml-str.yaml` as the core Nigerian compliance stack.
2. **Configure audit log retention** to meet the NDPA's accountability requirement. Set `retention_days` to at least 1825 (5 years) in your AGT audit backend configuration.
3. **Register a Data Protection Officer** with the NDPC (required for data controllers above the threshold). The DPO should review policy rules quarterly and validate regulatory accuracy.
4. **Build a DSAR intake process** that uses AGT's audit log as the source of truth for data access history.
5. **Extend the approval queue** for cross-border transfers to capture the adequacy rationale (destination country, legal basis) as structured metadata attached to the approval decision.
6. **Open a Discussion on microsoft/agent-governance-toolkit** referencing this mapping to propose it be linked from AGT's `docs/compliance/` section.

---

## Cross-References

- [CBN Transaction Limits Policy](../policies/cbn-transaction-limits.yaml) — maps to NDPA s.24 (data minimisation in financial processing)
- [BVN/NIN Protection Policy](../policies/bvn-nin-protection.yaml) — maps to NDPA Schedule 1 (biometric data)
- [NFIU AML/STR Policy](../policies/nfiu-aml-str.yaml) — intersects with NDPA s.30 (audit trail / accountability)
- [POPIA Mapping](popia-mapping.md) *(planned)* — comparative mapping for South African deployments
- [AGT SOC 2 Mapping](../../agent-governance-toolkit/docs/compliance/soc2-mapping.md) — upstream reference for mapping structure
