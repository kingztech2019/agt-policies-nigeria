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
| 2026-06-19 | Mauritius DPA 2017 (Act No. 20/2017) | Initial implementation: most GDPR-aligned African DPA; DPO mandatory for ALL controllers (no size threshold — stricter than GDPR), mandatory Commissioner registration (MUR 200,000/5yr penalty), 72h breach notification, six processing principles, cross-border safeguards requirement, automated decision-making transparency, Mauritius NIC ([A-Z][0-9]{6,7}) blocking, special categories (racial/ethnic, political, religious, trade union, health/mental, sexual orientation, genetic/biometric, criminal proceedings). Unique: DPO mandatory universally, no size threshold. | `policies/rego/mauritius-dpa.rego`, `policies/mauritius-dpa.yaml` | ✅ Current |
| 2026-06-19 | Egypt PDPL No. 151/2020 | Initial implementation: Art. 1 sensitive data (financial + children's = unique in Africa), Art. 2 data subject rights, Art. 3 children's data conditions, Art. 4 sensitive processing restrictions, Art. 6 lawful basis, Art. 7 breach notification (72h PDPC + 3-day subjects), Art. 8 DPO mandatory, Arts. 14-15 cross-border restrictions, Art. 19 PDPC, Art. 26 licensing. Egypt National ID (14-digit) blocking, financial data escalation, biometric deny. | `policies/rego/egypt-pdpl.rego`, `policies/egypt-pdpl.yaml` | ✅ Current |
| 2026-06-18 | Ghana DPA 2012 (Act 843) | Initial implementation: s.17 data minimisation, s.33 data subject participation, s.37 special personal data, s.38 cross-border adequacy, s.40 security. Ghana Card (GHA-XXXXXXXXX-X, NIA Act 707) blocking, biometric deny, DPC breach suppression, special category escalation. Monitor: Ghana Data Protection Bill 2025 pending. | `policies/rego/ghana-dpa.rego`, `policies/ghana-dpa.yaml` | ✅ Current |
| 2026-06-18 | Rwanda Law 058/2021 | Initial implementation: Art. 3(2)/10 sensitive data, Art. 21 automated decisions, Art. 43 48h breach notification to NCSA (strictest in Africa), Art. 44/45 breach reporting/communication, Art. 48-50 cross-border transfer restrictions. Rwanda NIDA 16-digit ID blocking, biometric deny, automated decision escalation for AI agents. | `policies/rego/rwanda-dpa.rego`, `policies/rwanda-dpa.yaml` | ✅ Current |
| 2026-06-18 | Ethiopia Proclamation 1321/2024 | CORRECTION: Ethiopia PDPP was enacted July 24, 2024 (Federal Negarit Gazette). Pack fully rewritten from draft to enacted law with correct article citations. ECA is supervisory authority. "draft" tag removed from comply54 registry. | `policies/rego/ethiopia-pdp.rego`, `policies/ethiopia-pdp.yaml` | ✅ Current (enacted) |
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
| Ethiopia PDPP 1321/2024 | ECA | Implementing regulations, ECA enforcement guidance, adequacy list | Annual |
| Egypt PDPL No. 151/2020 | PDPC / MCIT | PDPC adequacy list (not yet published), Executive Regulations updates, sector-specific guidelines | Ongoing |
| Ghana DPA 2012 (Act 843) | DPC | Ghana Data Protection Bill 2025 — when enacted, cross-border and breach rules may change significantly | Monitor — pending |
| Rwanda Law 058/2021 | NCSA | NCSA enforcement regulations, adequacy determinations, implementing guidelines | Ongoing |
| Mauritius DPA 2017 (Act 20/2017) | Data Protection Commissioner | Commissioner adequacy determinations (transfers), guidance on compelling legitimate interests, DPO implementation guidance | Ongoing |

---

## How to file a regulatory change

1. Open an issue with the label `regulatory-change`
2. Provide the exact reference: circular number, gazette notice, or amendment act
3. Identify which rule(s) in which file(s) need updating
4. Submit a PR — the PR description should reference this file and the regulatory source

**Do not update thresholds or adequacy lists without citing the source document.**
