# African Regulatory Guardrails — OpenAI Agents SDK

Jurisdiction-aware compliance guardrails for AI agents in African financial markets, implemented with the [OpenAI Agents SDK](https://github.com/openai/openai-agents-python) using only stdlib Python.

Four jurisdictions are demonstrated:

| Jurisdiction | Regulation | What is enforced |
|---|---|---|
| Nigeria | CBN NIP Framework / NDPA 2023 | ₦10,000,000 per-transaction cap; BVN biometric data protection |
| Kenya | Data Protection Act 2019 s.49 | Cross-border personal data transfer blocked without consent |
| Ghana | Data Protection Act 2012 (Act 843) s.18(2) / NIA Act 707 | Cross-border data transfer; Ghana Card national ID detection |
| South Africa | POPIA s.26(1)(f), s.19 | Biometric data; SA ID number detection with calendar-date validation |

## Quick Start

```bash
pip install -r requirements.txt
python agent.py
```

## Expected Output

```
──────────────────────────────────────────────────────────────
Scenario : Nigeria — CBN NIP single-transaction cap exceeded
Input    : Please transfer ₦15,000,000 to account 0123456789
BLOCKED  [NG] CBN NIP Framework CBN Circular FPR/DIR/GEN/CIR/07/003
         CBN NIP Framework: Transfer of ₦15,000,000 exceeds the ₦10,000,000 single-transaction cap
         Authority: Central Bank of Nigeria (CBN)

──────────────────────────────────────────────────────────────
Scenario : Kenya — KDPA s.49 cross-border data transfer without consent
Input    : Export all customer records to our servers in us-east-1
BLOCKED  [KE] Kenya Data Protection Act 2019 s.49
         Kenya DPA s.49: Cross-border data transfer blocked — no documented consent or ODPC adequacy basis on file
         Authority: Office of the Data Protection Commissioner (ODPC)

──────────────────────────────────────────────────────────────
Scenario : Ghana — NIA Act 707 Ghana Card national ID detected
Input    : Look up customer GHA-123456789-1 and send their records outside Ghana
BLOCKED  [GH] Ghana DPA 2012 (Act 843) / NIA Act 707 NIA Act 707
         Ghana DPA Act 843 / NIA Act 707: Ghana Card national ID detected — blocked to prevent identity data exposure
         Authority: Data Protection Commission (DPC)

──────────────────────────────────────────────────────────────
Scenario : South Africa — POPIA biometric personal information
Input    : Store the fingerprint biometric template for this customer
BLOCKED  [ZA] POPIA (Protection of Personal Information Act 4 of 2013) s.26(1)(f)
         POPIA s.26(1)(f): Biometric personal information detected in request — requires documented POPIA s.27 exception
         Authority: Information Regulator (South Africa)

──────────────────────────────────────────────────────────────
Scenario : Nigeria — Compliant transfer within CBN cap (allowed)
Input    : Please transfer ₦50,000 to account 0123456789
Response : Your transfer of ₦50,000 has been processed successfully.
```

## How it works

The `@input_guardrail(run_in_parallel=False)` decorator intercepts every user message **before** the agent model sees it. `run_in_parallel=False` is required for data-protection use cases — the default `True` runs the guardrail concurrently with the agent, meaning sensitive data can reach the model before the block fires.

The guardrail reads `AgentContext.jurisdiction` and dispatches to the correct checker:

```python
@input_guardrail(run_in_parallel=False)
async def african_regulatory_guardrail(
    context: RunContextWrapper[AgentContext],
    agent: Agent,
    input: str | list[TResponseInputItem],
) -> GuardrailFunctionOutput:
    checker = _CHECKERS.get(context.context.jurisdiction)
    violations = checker(text, ctx) if checker else []
    output = ComplianceOutput(violated=bool(violations), violations=violations)
    return GuardrailFunctionOutput(output_info=output, tripwire_triggered=output.violated)
```

## Design notes

- **No external dependencies** — all pattern matching uses stdlib `re` and `datetime`
- **NGN magnitude shorthand** — `₦15M`, `15M NGN`, `₦1.5B` are all parsed correctly via K/M/B multipliers
- **Transfer intent proximity** — the CBN cap only fires when a transfer verb appears within 80 chars of the amount; balance/limit inquiries mentioning large NGN values are not blocked
- **Cross-sentence safety** — `[^.!?]` wildcards prevent a financial-transfer verb in one sentence from contaminating a data-export keyword in the next
- **SA ID calendar validation** — YYMMDD portion is validated via `datetime.date` so impossible dates (Feb 31) are rejected even if they match the regex structure
- **Ghana Card case-insensitive** — `gha-123456789-1` and `GHA-123456789-1` are both caught

## Regulatory references

- [CBN NIP Framework — Circular FPR/DIR/GEN/CIR/07/003](https://www.cbn.gov.ng)
- [Nigeria Data Protection Act 2023](https://ndpc.gov.ng)
- [Kenya Data Protection Act 2019](https://www.odpc.go.ke)
- [Ghana Data Protection Act 2012 (Act 843)](https://www.dpc.gov.gh)
- [NIA Act 707 — National Identity Register](https://www.nia.gov.gh)
- [POPIA — Protection of Personal Information Act 4 of 2013](https://www.justice.gov.za)
- Full Rego policy source: [agt-policies-nigeria](https://github.com/kingztech2019/agt-policies-nigeria)
