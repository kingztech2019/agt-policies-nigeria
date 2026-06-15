# agt-policies
# Jurisdiction Router — maps customer/transaction country to applicable policy packs
#
# Purpose:
#   A single source of truth for "which policies apply to this agent action?"
#   Integrations query this file first, then evaluate only the returned packs.
#   Eliminates unnecessary policy evaluations and makes multi-country agents safe.
#
# Input schema expected:
#   {
#     "context": {
#       "customer_country":       "NG",          # ISO 3166-1 alpha-2 (primary)
#       "transaction_countries":  ["NG", "ZA"]   # optional — for cross-border transactions
#     }
#   }
#
# Callers query:
#   data.agt_policies.router.applicable_policies  → set of pack IDs
#   data.agt_policies.router.resolved_queries     → set of OPA query paths to evaluate
#   data.agt_policies.router.is_supported_jurisdiction
#   data.agt_policies.router.unsupported_jurisdiction_warning

package agt_policies.router

import rego.v1

# ── Jurisdiction → policy pack mapping ───────────────────────────
# Add new countries here. Each entry is: "ISO_CODE": {set of pack IDs}
# Pack IDs must match keys in policy_queries below.
jurisdiction_policies := {
    "NG": {"cbn", "bvn_nin", "ndpa", "nfiu"},
    "KE": {"kdpa"},
    "ZA": {"popia"},
}

# ── Policy pack → OPA query path ─────────────────────────────────
# Authoritative mapping of pack ID → query path used by integrations.
policy_queries := {
    "cbn":     "data.agt_policies_nigeria.cbn.decision",
    "bvn_nin": "data.agt_policies_nigeria.bvn_nin.decision",
    "ndpa":    "data.agt_policies_nigeria.ndpa.decision",
    "nfiu":    "data.agt_policies_nigeria.nfiu.decision",
    "kdpa":    "data.agt_policies_africa.kdpa.decision",
    "popia":   "data.agt_policies_africa.popia.decision",
}

# ── applicable_policies ───────────────────────────────────────────

# Single-jurisdiction: customer's primary country
applicable_policies contains policy if {
    some policy in jurisdiction_policies[input.context.customer_country]
}

# Multi-jurisdiction: transaction spans multiple countries
# Example: NG customer, data routed to ZA → NDPA + POPIA both apply
applicable_policies contains policy if {
    some country in input.context.transaction_countries
    some policy in jurisdiction_policies[country]
}

# ── resolved_queries ──────────────────────────────────────────────
# The OPA query paths the caller should run — ready to use directly.
# Example: opa eval -d policies/rego/ -i input.json "data.agt_policies.router.resolved_queries"
resolved_queries contains query if {
    some pack in applicable_policies
    query := policy_queries[pack]
}

# ── Jurisdiction support checks ───────────────────────────────────

is_supported_jurisdiction if {
    input.context.customer_country in object.keys(jurisdiction_policies)
}

unsupported_jurisdiction_warning := msg if {
    not is_supported_jurisdiction
    input.context.customer_country
    msg := sprintf(
        "No policy pack available for jurisdiction '%v' — action will not be evaluated against African regulatory rules. Consider contributing a policy pack.",
        [input.context.customer_country]
    )
}
