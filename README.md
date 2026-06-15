# agt-policies-nigeria

[![Validate Policies](https://github.com/kingztech2019/agt-policies-nigeria/actions/workflows/validate.yml/badge.svg)](https://github.com/kingztech2019/agt-policies-nigeria/actions/workflows/validate.yml)

**Nigerian & African AI Agent Governance Policies for Microsoft's [Agent Governance Toolkit (AGT)](https://github.com/microsoft/agent-governance-toolkit)**

A community policy pack that extends AGT with compliance coverage for African regulatory frameworks — NDPA 2023, CBN regulations, NFIU/AML rules, POS geo-fencing, BVN/NIN data protection, and POPIA (South Africa).

Two policy formats:
- **YAML** (`policies/*.yaml`) — drop-in rules files, validated by the AGT linter, no new infrastructure
- **OPA Rego** (`policies/rego/*.rego`) — structured-parameter enforcement (e.g. `input.params.amount > 5000000`) that YAML regex on text output cannot achieve

---

## Why this exists

AGT covers OWASP Agentic AI Top 10, NIST AI RMF, EU AI Act, SOC 2, and HIPAA. It covers zero African regulatory frameworks. As AI agents are deployed in Nigerian fintech, insurtech, and banking — making decisions that touch regulated financial data and sensitive personal identifiers — there is no governance tooling built for this context.

This repo fills that gap.

---

## Coverage

| Policy Pack | Regulation | Key Controls |
|---|---|---|
| `ndpa-data-residency.yaml` | Nigeria Data Protection Act 2023 | Cross-border transfer restrictions, sensitive data handling, data minimisation |
| `cbn-transaction-limits.yaml` | CBN Regulations (Tiered KYC, NIP, USSD) | Transaction threshold enforcement, approval queues, SOD controls |
| `pos-geofencing.yaml` | CBN Agent Banking Guidelines | Terminal geo-zone enforcement, location-mismatch blocking |
| `bvn-nin-protection.yaml` | NIBSS / NIN Regulations | BVN/NIN masking, exposure prevention, verification approval gates |
| `nfiu-aml-str.yaml` | NFIU AML/CFT Regulations | STR/CTR triggers, structuring detection, velocity controls |
| `popia-south-africa.yaml` | POPIA (South Africa) | Cross-border transfer controls, special personal information, SA ID masking |
| `kenya-dpa.yaml` | Kenya Data Protection Act 2019 | Cross-border transfer restrictions, sensitive data, breach notification (72h to ODPC) |

### OPA Rego (structured-parameter enforcement)

| Rego Policy | Regulation | Key Advantage over YAML |
|---|---|---|
| `policies/rego/cbn-transaction-limits.rego` | CBN NIP/KYC | Checks `input.params.amount` directly — exact numeric enforcement, not text regex |
| `policies/rego/bvn-nin-protection.rego` | CBN BVN / NIMC NIN | Checks `input.params.identifier_type` and `input.params.bvn_present` in structured params |
| `policies/rego/ndpa-data-residency.rego` | NDPA 2023 s.25 | Checks `input.params.destination_region` and `input.params.record_count` — unambiguous |
| `policies/rego/nfiu-aml.rego` | NFIU AML/CFT (MLPPA 2022) | Exact ₦5M CTR threshold on `input.params.amount`, structuring zone (₦4.5M–₦4.99M) |
| `policies/rego/kdpa-data-protection.rego` | Kenya DPA 2019 s.49 | Cross-border transfers, sensitive data, biometric blocking, ODPC accountability |
| `policies/rego/popia-south-africa.rego` | POPIA (Act 4 of 2013) | `destination_country` adequacy list (POPIA s.72), SA ID 13-digit format validation |

---

## Quick Start

### Prerequisites

```bash
python3 -m venv .venv
.venv/bin/pip install agent-os-kernel agent-governance-toolkit-compliance
```

### Load and apply policy packs

```python
import yaml, re
from pathlib import Path
from agent_os.integrations import GovernancePolicy
from agent_os.integrations.base import PolicyInterceptor, ToolCallRequest

# Load regex patterns from any policy file(s)
def load_patterns(policy_files):
    patterns = []
    for path in policy_files:
        doc = yaml.safe_load(Path(path).read_text())
        for rule in doc.get("rules", []):
            cond = rule.get("condition", {})
            if cond.get("operator") == "matches" and cond.get("field") == "output":
                if rule.get("action") in ("deny", "block", "escalate"):
                    patterns.append(cond["value"])
    return patterns

patterns = load_patterns(["policies/cbn-transaction-limits.yaml",
                          "policies/bvn-nin-protection.yaml"])

policy = GovernancePolicy(
    name="nigerian-fintech",
    blocked_patterns=patterns,
    log_all_calls=True,
)

interceptor = PolicyInterceptor(policy)
```

### Validate policy files with AGT linter

```bash
# Lint all YAML policy packs
.venv/bin/python3 -c "
from agent_compliance.lint_policy import lint_file
from pathlib import Path
for p in sorted(Path('policies').glob('*.yaml')):
    r = lint_file(str(p))
    errors = [m for m in r.messages if m.severity == 'error']
    print(('✅' if not errors else '❌'), p.name)
"
```

### Validate OPA Rego policies

```bash
# Requires OPA binary — https://www.openpolicyagent.org/docs/latest/#running-opa
for f in policies/rego/*.rego; do opa check "$f" && echo "PASS $f"; done
```

### Try it now — run a policy decision with `opa eval`

```bash
# CBN: block a ₦15M transfer (exceeds NIP cap)
opa eval -d policies/rego/cbn-transaction-limits.rego \
  -i examples/inputs/cbn-deny-nip-cap.json \
  "data.agt_policies_nigeria.cbn.decision"
# → "deny"

# CBN: route a ₦6.5M transfer to human approval
opa eval -d policies/rego/cbn-transaction-limits.rego \
  -i examples/inputs/cbn-escalate-tier3.json \
  "data.agt_policies_nigeria.cbn.decision"
# → "escalate"

# BVN: block BVN number exposed in agent output
opa eval -d policies/rego/bvn-nin-protection.rego \
  -i examples/inputs/bvn-deny-output.json \
  "data.agt_policies_nigeria.bvn_nin.decision"
# → "deny"

# NDPA: block data export to AWS US-East-1
opa eval -d policies/rego/ndpa-data-residency.rego \
  -i examples/inputs/ndpa-deny-cross-border.json \
  "data.agt_policies_nigeria.ndpa.decision"
# → "deny"

# NDPA: allow export to permitted af-south-1 region
opa eval -d policies/rego/ndpa-data-residency.rego \
  -i examples/inputs/ndpa-allow-permitted.json \
  "data.agt_policies_nigeria.ndpa.decision"
# → "allow"
```

# NFIU: block a ₦6M transfer (at CTR threshold — routes to human review)
opa eval -d policies/rego/nfiu-aml.rego \
  -i examples/inputs/nfiu-escalate-ctr.json \
  "data.agt_policies_nigeria.nfiu.decision"
# → "escalate"

# NFIU: block a ₦11M transfer (exceeds NIP cap)
opa eval -d policies/rego/nfiu-aml.rego \
  -i examples/inputs/nfiu-deny-nip-cap.json \
  "data.agt_policies_nigeria.nfiu.decision"
# → "deny"

# POPIA: block SA ID number in agent output
opa eval -d policies/rego/popia-south-africa.rego \
  -i examples/inputs/popia-deny-sa-id.json \
  "data.agt_policies_africa.popia.decision"
# → "deny"

# POPIA: block biometric data in agent output
opa eval -d policies/rego/popia-south-africa.rego \
  -i examples/inputs/popia-deny-biometric.json \
  "data.agt_policies_africa.popia.decision"
# → "deny"
```

All example input files are in [`examples/inputs/`](examples/inputs/). See [`docs/compliance-mapping.md`](docs/compliance-mapping.md) for the full mapping of regulatory obligations → Rego rules → expected decisions.

---

## Policy Packs

### NDPA 2023 — Data Residency & Privacy
`policies/ndpa-data-residency.yaml`

Enforces Nigeria Data Protection Act 2023 obligations for AI agents:
- Blocks agent actions that route personal data outside Nigeria without adequate safeguards
- Requires approval for bulk data export operations
- Denies processing of sensitive personal data (health, biometric, ethnic origin) without conditions
- Audits all PII-touching tool calls for NDPC accountability requirements

### CBN Transaction Limits
`policies/cbn-transaction-limits.yaml`

Enforces Central Bank of Nigeria transaction threshold rules:
- Tiered KYC limits (Tier 1: ₦50k daily → Tier 3: ₦5M daily)
- Requires human approval for transfers approaching or exceeding NIP limits (₦10M)
- Blocks autonomous agent self-approval of financial transactions (SOD)
- USSD and contactless transaction ceiling enforcement

### POS Geo-Fencing
`policies/pos-geofencing.yaml`

Enforces CBN agent banking geo-compliance for POS terminal operations:
- Denies POS tool calls where terminal location context is absent or mismatched
- Requires approval for POS registration changes and cross-state transactions
- Audits all terminal activation and transaction events

### BVN/NIN Protection
`policies/bvn-nin-protection.yaml`

Protects Nigeria's two most sensitive personal identifiers:
- Detects and blocks BVN/NIN patterns in agent output (prevents logging/exposure)
- Denies passing BVN/NIN to external endpoints without approval
- Requires human-in-the-loop for any BVN verification action
- Masks identifiers in audit trail

### NFIU AML/STR
`policies/nfiu-aml-str.yaml`

Enforces Nigerian Financial Intelligence Unit anti-money laundering controls:
- Requires approval for transactions at or above the ₦5M CTR threshold
- Detects structuring patterns (smurfing — multiple amounts just under threshold)
- Velocity controls: flags unusual transaction frequency in a session
- Blocks agent from autonomously completing transactions that should trigger STRs

### POPIA — South Africa
`policies/popia-south-africa.yaml`

Enforces Protection of Personal Information Act (South Africa) for AI agents:
- Blocks cross-border transfers to non-POPIA-adequate jurisdictions
- Denies processing of special personal information without lawful conditions
- Detects SA ID numbers in agent output and blocks exposure
- Audits all personal information processing for RESPONSIBLE PARTY accountability

---

## Framework Integrations

| Framework | Example | Description |
|---|---|---|
| AGT (Microsoft) | [`examples/nigerian-fintech-demo/`](examples/nigerian-fintech-demo/) | GovernancePolicy + PolicyInterceptor |
| LangGraph | [`examples/langgraph-agent/`](examples/langgraph-agent/) | OPA as a governance node in a LangGraph StateGraph — all 6 Rego policies active |

### LangGraph + OPA

OPA runs as a **node** in the agent graph — not middleware. Every action must pass through it before execution:

```
task → plan → opa_check → execute       (allow)
                      ├──► human_review  (escalate)
                      └──► blocked       (deny)
```

```bash
pip install langgraph langchain-core
python examples/langgraph-agent/agent.py
```

---

## Demo

See [`examples/nigerian-fintech-demo/`](examples/nigerian-fintech-demo/) for an end-to-end AGT demo. Run it with:

```bash
.venv/bin/python3 examples/nigerian-fintech-demo/demo.py
```

A Nigerian fintech support agent attempts 5 actions. The governance layer intercepts each one live from the loaded policy files:

| Step | Action | Decision | Policy Pack |
|---|---|---|---|
| 1 | ₦6.5M refund attempt | ⏳ ESCALATED | `cbn-transaction-limits.yaml` |
| 2 | BVN exposed in response | ❌ BLOCKED | `bvn-nin-protection.yaml` |
| 3 | Export records to AWS US-East-1 | ⏳ ESCALATED | `ndpa-data-residency.yaml` |
| 4 | KYC bypass + payment | ⏳ ESCALATED | `nfiu-aml-str.yaml` |
| 5 | Normal customer lookup | ✅ ALLOWED | — |

Every decision is written to a timestamped audit log satisfying NDPA s.30 accountability requirements.

---

## Roadmap

- [x] Kenya Data Protection Act 2019 policy pack (YAML + Rego)
- [x] NFIU AML/CFT Rego policy — exact CTR threshold enforcement (`nfiu-aml.rego`)
- [x] POPIA Rego policy — SA ID validation, adequacy list, biometric blocks (`popia-south-africa.rego`)
- [x] Semantic versioning — `CHANGELOG.md` + `REGULATORY-CHANGES.md`
- [ ] ECOWAS cross-border transfer rules
- [ ] SIM swap fraud detection patterns
- [ ] NAICOM insurtech AI governance rules
- [ ] SEC Nigeria capital markets AI rules
- [ ] Ghana Data Protection Act 2012 policy pack
- [ ] OPA bundle packaging (`bundle.tar.gz`) for direct `opa run` deployment
- [ ] JSON Schema for agent input (`schemas/agent-input.json`)
- [ ] `ndpa-2023-mapping.md` — full NDPA → AGT control mapping (for AGT `docs/compliance/` contribution)

---

## Contributing

Contributions welcome — especially from practitioners with direct CBN/NDPA/NFIU compliance experience. See [CONTRIBUTING.md](CONTRIBUTING.md).

To propose a new policy rule:
1. Open an issue describing the regulation, the specific obligation, and the agent action pattern it should govern
2. Reference the exact regulatory citation (e.g., "NDPA 2023 s.25(1)(b)")
3. Submit a PR with the rule and a test case in `examples/`

---

## Relation to AGT

This repo is a **community policy pack** for [microsoft/agent-governance-toolkit](https://github.com/microsoft/agent-governance-toolkit). It is not affiliated with or endorsed by Microsoft. Policy files are compatible with AGT's `agent-os-kernel` package via `GovernancePolicy` + `PolicyInterceptor`, and validated using the `agent-governance-toolkit-compliance` linter.

A `docs/compliance/ndpa-2023-mapping.md` contribution to the AGT upstream repo is planned once this pack has real-world validation.

---

## License

MIT — same as AGT. See [LICENSE](LICENSE).

---

## Author

Built by [Oluwajuwon Omotayo](https://github.com/kingztech2019) — Nigerian AI infrastructure, NDPA compliance, and GeoGuard POS geo-fencing.
