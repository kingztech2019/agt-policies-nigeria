# Changelog

All notable changes to agt-policies-nigeria are documented here.

Format: [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
Versioning: [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
