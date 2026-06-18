# Regulatory Changes Log

This file tracks when regulations change and which policy files need updating.
When a regulation updates, open a PR that:
1. Updates the affected `.rego` and/or `.yaml` files
2. Adds or updates test cases in the corresponding `_test.rego`
3. Adds an entry to this table

---

## Change history

| Date | Regulation | Change | Affected files | Status |
|------|-----------|--------|---------------|--------|
| 2026-06-18 | Uganda DPPA 2019 | Initial implementation: s.4 lawful basis, s.13 cross-border, s.19 sensitive data, s.22 security, s.25 breach notification. NIRA ID blocking, biometric deny, PDPO breach suppression, financial data escalation. | `policies/rego/uganda-dppa.rego`, `policies/uganda-dppa.yaml` | ✅ Current |
| 2026-06-18 | Tanzania PDPA 2022 | Initial implementation: s.8 lawful basis, s.13 sensitive data, s.17 security, s.25 cross-border, s.28 breach notification. NIDA 20-digit ID blocking, biometric deny, PDPC breach suppression, consent enforcement. | `policies/rego/tanzania-pdpa.rego`, `policies/tanzania-pdpa.yaml` | ✅ Current |
| 2026-06-18 | Ethiopia Proclamation 958/2016 + draft PDPP | Initial implementation: Computer Crime Proclamation 958/2016 (unauthorised access), Electronic Transactions Proclamation 1205/2020, draft PDPP. Fayda/MOSIP ID blocking, unauthorised access detection, ECA breach suppression, cross-border controls. Pack tagged draft — update on enactment. | `policies/rego/ethiopia-pdp.rego`, `policies/ethiopia-pdp.yaml` | ⚠️ Draft — monitor for PDPP enactment |
| 2026-06-15 | NFIU AML/CFT (MLPPA 2022) | Initial Rego implementation: CTR ₦5M, NIP cap ₦10M, structuring zone, PEP, KYC bypass | `policies/rego/nfiu-aml.rego`, `policies/nfiu-aml-str.yaml` | ✅ Current |
| 2026-06-15 | POPIA (Act 4 of 2013) | Initial Rego implementation: s.72 adequacy list, SA ID, biometric, children's data | `policies/rego/popia-south-africa.rego`, `policies/popia-south-africa.yaml` | ✅ Current |
| 2026-06-14 | CBN NIP Framework | Initial implementation: ₦10M single-transaction cap, tiered KYC thresholds, SOD | `policies/rego/cbn-transaction-limits.rego`, `policies/cbn-transaction-limits.yaml` | ✅ Current |
| 2026-06-14 | NDPA 2023 | Initial implementation: s.25 data residency, s.27 consent, s.30 minimisation | `policies/rego/ndpa-data-residency.rego`, `policies/ndpa-data-residency.yaml` | ✅ Current |
| 2026-06-14 | Kenya DPA 2019 | Initial implementation: s.25 sensitive data, s.26 consent, s.41 breach, s.49 cross-border | `policies/rego/kdpa-data-protection.rego`, `policies/kenya-dpa.yaml` | ✅ Current |
| 2026-06-14 | NIBSS BVN / NIMC NIN | Initial implementation: BVN/NIN masking, transmission blocks, verification gate | `policies/rego/bvn-nin-protection.rego`, `policies/bvn-nin-protection.yaml` | ✅ Current |

---

## Key regulations to watch

| Regulation | Authority | Watch for | Review cadence |
|-----------|-----------|-----------|----------------|
| CBN NIP Framework | CBN | Circulars updating NIP single-transaction or daily caps | Ad hoc (CBN circular) |
| CBN Tiered KYC | CBN | Tier 1/2/3 daily limit revisions | Annual (typically Q1) |
| NDPA 2023 | NDPC | Implementation regulations, NDPC guidelines | Ongoing |
| MLPPA 2022 / NFIU | NFIU | Updated STR typologies, threshold changes | Annual |
| FATF | NFIU / CBN | Nigeria mutual evaluation follow-ups | Biennial |
| Kenya DPA 2019 | ODPC | ODPC data protection regulations and guidelines | Ongoing |
| POPIA | Information Regulator SA | Information Regulator guidance notes | Ongoing |
| Uganda DPPA 2019 | PDPO / NITA-U | Commencement regulations, PDPO enforcement guidelines, adequacy list updates | Ongoing |
| Tanzania PDPA 2022 | PDPC | PDPC subsidiary regulations, enforcement guidance, adequacy determinations | Ongoing |
| Ethiopia PDPP (draft) | ECA / MInT | Enactment and gazetting of dedicated Personal Data Protection Proclamation | Critical — review quarterly |

---

## How to file a regulatory change

1. Open an issue with the label `regulatory-change`
2. Provide the exact reference: circular number, gazette notice, or amendment act
3. Identify which rule(s) in which file(s) need updating
4. Submit a PR — the PR description should reference this file and the regulatory source

**Do not update thresholds or adequacy lists without citing the source document.**
