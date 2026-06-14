# Contributing to agt-policies-nigeria

Thank you for contributing. This project fills a real gap — if you work in Nigerian or African fintech, insurtech, or banking and have hit compliance challenges with AI agents, your domain knowledge is the most valuable thing you can bring.

## What we need most

- **Compliance practitioners** who can validate that policy rules accurately reflect CBN, NDPA, NFIU, or POPIA obligations
- **Fintech engineers** who can identify real agent action patterns (tool names, output patterns) that should be governed
- **New regulatory frameworks** — Kenya DPA, ECOWAS, NAICOM, SEC Nigeria

## How to contribute a new rule

1. **Open an issue first.** Describe:
   - The regulation and the specific section/clause
   - The agent behaviour pattern it should govern (what tool call or output triggers it)
   - The correct action: `deny`, `require_approval`, or `audit`

2. **Reference the exact citation.** Example: `NDPA 2023 s.25(1)(b) — cross-border transfer restriction`. Rules without regulatory citations will not be merged.

3. **Submit a PR** with:
   - The rule added to the correct policy YAML file
   - A comment block above the rule with the regulatory citation
   - An example showing the rule being triggered (in `examples/`)

## Adding a new policy pack (new regulation)

If you want to add a full new regulatory framework (e.g., Kenya DPA 2019):

1. Open an issue with the framework name and a list of the key agent-relevant obligations
2. Use `policies/ndpa-data-residency.yaml` as your structural template
3. Include a short `docs/<framework>-mapping.md` that maps framework obligations to AGT controls

## Regulatory accuracy disclaimer

Policy rules in this repo are maintained by community contributors, not by legal professionals. They are intended as a governance starting point, not as certified legal compliance. Organizations deploying these policies in regulated environments must perform their own compliance assessments with qualified advisors.

Always include the `⚠️ IMPORTANT` disclaimer in new policy files (see existing files for the pattern).

## Code style

- YAML files: 2-space indentation, rules grouped by regulation section with comment headers
- Rule names: `<framework>-<subject>-<action>` e.g. `ndpa-crossborder-transfer-block`
- Priority: 100 for deny/block, 90-95 for require_approval, 80-85 for audit
- Every rule must have a `message` field with the regulatory citation

## Questions

Open an issue or start a Discussion. If you are contributing Nigerian regulatory expertise and want to be listed as a maintainer, say so in your first PR.
