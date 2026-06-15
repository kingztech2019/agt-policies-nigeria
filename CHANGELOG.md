# Changelog

All notable changes to agt-policies-nigeria are documented here.

Format: [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
Versioning: [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
