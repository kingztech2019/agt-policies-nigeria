# Changelog

All notable changes to agt-policies-nigeria are documented here.

Format: [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
Versioning: [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.6.0] — 2026-06-19

Indian Ocean expansion — Mauritius policy pack.

### Added

- **Mauritius DPA 2017** (`mauritius-dpa.yaml` + `rego/mauritius-dpa.rego`) — Data Protection Act 2017 (Act No. 20 of 2017), effective January 15, 2018, enforced by the Data Protection Commissioner (dataprotection.govmu.org). The most GDPR-aligned data protection law in Africa — directly modeled on EU GDPR 2016/679. Key provisions: DPO mandatory for ALL controllers/processors (no size threshold — stricter than GDPR), mandatory Commissioner registration with 3-year renewal (penalty: MUR 200,000 or 5 years imprisonment), six GDPR-aligned processing principles, 72-hour breach notification to Commissioner plus data subject notification without undue delay for high risk, cross-border transfers require proof of appropriate safeguards filed with Commissioner (derogations: consent, contract, public interest, legal claims, vital interests), automated decision-making transparency obligation (data subjects must be informed of logic/significance/consequences), special categories (racial/ethnic, political, religious, trade union, health/mental, sexual orientation, genetic/biometric, criminal proceedings). Mauritius National ID Card (NIC format: [A-Z][0-9]{6,7}, e.g. A123456) blocking. Electronic marketing: data subjects may object at any time. 39 tests.
- **Jurisdiction router updated** — `MU` added to `jurisdiction_policies` and `policy_queries`; `test_mu_is_supported` added to router tests.
- **README updated** — African Regulatory Compliance table, OPA Rego table, Jurisdiction Router table, Quick Start examples, and Roadmap updated for Mauritius.

### Changed

- Total OPA tests: 486 → 526 (39 new Mauritius tests + 1 new router test)
- Jurisdiction count: 9 → 10 (added MU)

---

## [1.5.0] — 2026-06-19

North Africa expansion — Egypt policy pack.

### Added

- **Egypt PDPL No. 151/2020** (`egypt-pdpl.yaml` + `rego/egypt-pdpl.rego`) — Egypt Personal Data Protection Law No. 151 of 2020 (Official Gazette No. 29 bis, 15 July 2020). Covers: financial data as sensitive category (Art. 1 — **unique in Africa**: credit scores, account balances, loan history are classified alongside health/biometric data), children's data as sensitive category (Art. 1/3 — also unique in Africa), biometric deny, Egypt National ID (14-digit format: [2|3][YYMMDD][Gov][Seq][Check]) blocking, DPO mandatory escalation (Art. 8), unlicensed-processing deny (Art. 26 — up to EGP 2M), 72-hour breach notification to PDPC (Art. 7 — plus 3-day data subject notification), cross-border transfer restrictions (Arts. 14-15, PDPC adequacy list pending), bulk export controls. Permitted regions: af-south-1, me-south-1, me-central-1, egypt, EG. 39 tests.
- **Jurisdiction router updated** — `EG` added to `jurisdiction_policies` and `policy_queries`.
- **README updated** — African Regulatory Compliance table, OPA Rego table, Jurisdiction Router table, Quick Start examples, and Roadmap updated for Egypt.

### Changed

- Total OPA tests: 447 → 486 (39 new Egypt tests)
- Jurisdiction count: 8 → 9 (added EG)

---

## [1.4.0] — 2026-06-18

West Africa expansion — Ghana and Rwanda policy packs.

### Added

- **Ghana DPA 2012** (`ghana-dpa.yaml` + `rego/ghana-dpa.rego`) — Ghana Data Protection Act 2012 (Act 843). Covers: Ghana Card national ID (GHA-XXXXXXXXX-X format, NIA Act 707) blocking, biometric deny, DPC breach-suppression detection, special personal data escalation (s.37 — health, ethnic origin, religion, political opinion, trade union, sexual life, criminal), cross-border transfer adequacy controls (s.38), data minimisation (s.17), data subject participation (s.33). Permitted regions: `af-south-1`, `af-west-1`, `ghana`, `GH`. 30 tests.
- **Rwanda Law 058/2021** (`rwanda-dpa.yaml` + `rego/rwanda-dpa.rego`) — Rwanda Law No. 058/2021 Relating to the Protection of Personal Data and Privacy. Covers: 48-hour breach notification to NCSA (Art. 43 — strictest in Africa), automated individual decision-making escalation with right to human review (Art. 21 — critical for AI agents), Rwanda National ID (NIDA 16-digit format) blocking, biometric deny, special category data (Art. 3(2)/10 — race, health, criminal, genetic, sexual life, family details), cross-border transfer restrictions (Art. 48-50). Criminal penalties up to 10 years + 25M RWF. Permitted regions: `af-south-1`, `af-east-1`, `rwanda`, `RW`. 32 tests.
- **Jurisdiction router updated** — `GH` and `RW` added to `jurisdiction_policies`. Router tests updated: `test_gh_not_supported` removed; `test_gh_is_supported` and `test_rw_is_supported` added.
- **README updated** — African Regulatory Compliance table, OPA Rego table, Jurisdiction Router table, Quick Start examples, and Roadmap all updated for Ghana and Rwanda packs.

### Fixed

- Ethiopia CHANGELOG entry corrected: "draft PDPP" → "Ethiopia PDPP 1321/2024 (enacted July 24, 2024)". The dedicated Personal Data Protection Proclamation was enacted and published in the Federal Negarit Gazette; the pack and comply54 registry have been updated accordingly.

### Changed

- Total OPA tests: 384 → 447 (63 new tests — 30 Ghana + 32 Rwanda + 1 new router test)
- Jurisdiction count: 6 → 8 (added GH, RW)

---

## [1.3.0] — 2026-06-18

East Africa policy expansion — Uganda, Tanzania, and Ethiopia regulatory packs.

### Added

- **Uganda DPPA 2019** (`uganda-dppa.yaml` + `rego/uganda-dppa.rego`) — Uganda Data Protection and Privacy Act 2019. Covers: NIRA national ID (CM + 12-char) blocking, biometric deny, PDPO breach-suppression detection, financial data escalation, special category (health, ethnic origin, religion) escalation, cross-border transfer controls (s.13, s.19, s.22). Permitted regions: `af-south-1`, `af-east-1`, `uganda`, `UG`. 28 tests.
- **Tanzania PDPA 2022** (`tanzania-pdpa.yaml` + `rego/tanzania-pdpa.rego`) — Tanzania Personal Data Protection Act 2022. Covers: NIDA national ID (20-digit format) blocking, biometric deny, PDPC breach-suppression detection, consent-enforcement deny, special category escalation, cross-border transfer controls (s.8, s.13, s.17, s.25). Permitted regions: `af-south-1`, `af-east-1`, `tanzania`, `TZ`. 28 tests.
- **Ethiopia PDP** (`ethiopia-pdp.yaml` + `rego/ethiopia-pdp.rego`) — Ethiopia Computer Crime Proclamation No. 958/2016 + draft Personal Data Protection Proclamation. Covers: Fayda/MOSIP ID blocking, biometric deny, unauthorised-access detection (Proclamation 958/2016), ECA breach-suppression detection, special category escalation, cross-border transfer controls. Permitted regions: `af-south-1`, `af-east-1`, `ethiopia`, `ET`. Pack tagged `draft` — update when dedicated PDPP is enacted. 28 tests.
- **Jurisdiction router updated** — `UG`, `TZ`, `ET` added to `jurisdiction_policies`. NG routes 9 packs; KE, ZA, UG, TZ, ET each route 6 (5 universal + 1 regulatory).
- **README updated** — Coverage table, OPA Rego table, Jurisdiction Router table, Quick Start examples, and Roadmap all updated for the three new packs.

### Changed

- Total OPA tests: 306 → 384 (78 new tests across the three packs)
- Jurisdiction count: 3 → 6 (NG, KE, ZA → NG, KE, ZA, UG, TZ, ET)

---

## [1.2.0] — 2026-06-16

Universal agent safety controls — 5 new policy packs applicable to any AI agent.

### Added

- **Prompt Injection** (`agent-prompt-injection.yaml` + `.rego`) — blocks 19 known injection phrases; escalates structural markers (`[INST]`, `<|system|>`, `###System`). Configurable pattern sets via `data.config.prompt_injection.*`. 22 tests.
- **PII Leakage** (`agent-pii-leakage.yaml` + `.rego`) — scans agent output for credit card numbers, BVN/NIN (11-digit), SA ID (13-digit), email, and phone before delivery. Deployer allow-list for verified disclosure flows. 21 tests.
- **Tool Permissions** (`agent-tool-permissions.yaml` + `.rego`) — allow/deny/restricted-list tool governance. Default restricted set includes `delete_record`, `execute_code`, `shell_exec`, `deploy`, `grant_admin` and 10 others. 20 tests.
- **Human Approval** (`agent-human-approval.yaml` + `.rego`) — four escalation triggers: explicit action names, context `risk_level`, amount threshold (default 1M, override to 5M for CBN), bulk record count (default 500). 21 tests.
- **Model Routing Controls** (`agent-model-routing.yaml` + `.rego`) — prevents sensitive tasks (`pii_processing`, `financial_decision`, `fraud_detection`, `kyc_review`, `aml_screening`, 9 total) from using unapproved models. Audits approved model usage. 22 tests.
- **Jurisdiction router updated** — `universal_policies` set always included in `applicable_policies`. NG now routes 9 packs (4 regulatory + 5 universal); KE/ZA route 6. Router tests updated to reflect new counts.
- **Regal config updated** — `line-length`, `default-over-else`, `unresolved-reference` (data.config paths) suppressed with explanatory comments.

### Changed

- README: description updated from "African regulatory compliance" to "two-layer governance" (universal safety + regulatory)
- README: Coverage section split into Universal Agent Safety Controls and African Regulatory Compliance tables
- `.regal/config.yaml`: 3 additional suppression entries with documented rationale

---

## [1.1.0] — 2026-06-15

Framework integrations: CrewAI and Microsoft AutoGen.

### Added

- **CrewAI integration** (`examples/crewai-agent/agent.py`) — `OPAGovernanceTool` as a CrewAI `BaseTool`. Two-agent crew: `compliance_agent` calls OPA before `executor_agent` proceeds. `step_callback` safety net. 6 demo scenarios including NG+ZA cross-border.
- **Microsoft AutoGen integration** (`examples/autogen-agent/agent.py`) — `check_compliance()` registered as a callable tool for `GovernanceAgent` inside a three-agent GroupChat (`UserProxy → GovernanceAgent → ExecutorAgent`). 8 demo scenarios covering NG, KE, ZA jurisdictions.
- Both examples include: jurisdiction router integration, `build_crew()`/`build_group_chat()` stubs with full real-LLM instructions, colored terminal output

### Changed

- README: Framework Integrations table expanded to 4 entries (AGT, LangGraph, CrewAI, AutoGen)
- README: Added architecture diagrams for CrewAI and AutoGen governance flows

---

## [1.0.0] — 2026-06-15

First stable release. Full YAML + Rego parity across all six African policy packs.

### Added

- **NFIU AML Rego** (`policies/rego/nfiu-aml.rego`) — MLPPA 2022 AML/CFT controls in Rego. Exact numeric CTR threshold enforcement on `input.params.amount` (₦5M, ₦10M). Structuring zone detection (₦4.5M–₦4.99M). PEP, round-trip, and cash-equivalent pattern matching. 28 tests.
- **POPIA Rego** (`policies/rego/popia-south-africa.rego`) — POPIA Act 4 of 2013 controls in Rego. Structured `destination_country` adequacy checks (POPIA s.72). SA ID number format-aware regex (YYMMDD + 7 digits). Biometric, children's data, and breach suppression hard blocks. 30 tests.
- **CHANGELOG.md** — version history (this file)
- **REGULATORY-CHANGES.md** — tracker for regulation updates requiring policy revision
- Example inputs for NFIU and POPIA scenarios (`examples/inputs/`)
- LangGraph agent updated: NFIU and POPIA policies now active as governance nodes (6 → 8 policies in evaluation chain)

### Changed

- README: Rego coverage table updated to show all 6 policies (previously 4)
- README: test count updated (118 → 176 total OPA tests)

---

## [0.1.0] — 2026-06-14 *(initial release)*

- NDPA 2023 Rego policy (`policies/rego/ndpa-data-residency.rego`) — 34 tests
- CBN Transaction Limits Rego policy (`policies/rego/cbn-transaction-limits.rego`) — 26 tests
- BVN/NIN Protection Rego policy (`policies/rego/bvn-nin-protection.rego`) — 28 tests
- Kenya DPA 2019 Rego policy (`policies/rego/kdpa-data-protection.rego`) — 30 tests
- 118 total OPA tests passing
- NFIU AML/STR YAML policy (`policies/nfiu-aml-str.yaml`)
- POPIA South Africa YAML policy (`policies/popia-south-africa.yaml`)
- POS Geo-fencing YAML policy (`policies/pos-geofencing.yaml`)
- CBN Transaction Limits YAML policy (`policies/cbn-transaction-limits.yaml`)
- BVN/NIN Protection YAML policy (`policies/bvn-nin-protection.yaml`)
- NDPA 2023 YAML policy (`policies/ndpa-data-residency.yaml`)
- Kenya DPA YAML policy (`policies/kenya-dpa.yaml`)
- GitHub Actions CI (3 jobs: OPA syntax+tests, AGT YAML lint, end-to-end demo)
- LangGraph agent integration example (`examples/langgraph-agent/`)
- Compliance mapping doc (`docs/compliance-mapping.md`)
- 8 example input JSON files
- Listed in [awesome-opa](https://github.com/open-policy-agent/awesome-opa) (PR #82, merged by anderseknert)
