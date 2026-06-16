# agt-policies
# Tests for jurisdiction router
# Run: opa test policies/rego/ -v

package agt_policies.router_test

import data.agt_policies.router
import rego.v1

# ── Nigeria: correct policy set ───────────────────────────────────

test_ng_has_cbn if {
	"cbn" in router.applicable_policies with input as {"context": {"customer_country": "NG"}}
}

test_ng_has_bvn_nin if {
	"bvn_nin" in router.applicable_policies with input as {"context": {"customer_country": "NG"}}
}

test_ng_has_ndpa if {
	"ndpa" in router.applicable_policies with input as {"context": {"customer_country": "NG"}}
}

test_ng_has_nfiu if {
	"nfiu" in router.applicable_policies with input as {"context": {"customer_country": "NG"}}
}

# NG: 4 jurisdiction packs + 5 universal = 9 total
test_ng_has_exactly_9_policies if {
	count(router.applicable_policies) == 9 with input as {"context": {"customer_country": "NG"}}
}

test_ng_popia_not_applicable if {
	not "popia" in router.applicable_policies with input as {"context": {"customer_country": "NG"}}
}

test_ng_kdpa_not_applicable if {
	not "kdpa" in router.applicable_policies with input as {"context": {"customer_country": "NG"}}
}

# ── Universal policies always present ────────────────────────────

test_universal_prompt_injection_always_present if {
	"prompt_injection" in router.applicable_policies with input as {"context": {"customer_country": "NG"}}
}

test_universal_pii_leakage_always_present if {
	"pii_leakage" in router.applicable_policies with input as {"context": {"customer_country": "KE"}}
}

test_universal_tool_permissions_always_present if {
	"tool_permissions" in router.applicable_policies with input as {"context": {"customer_country": "ZA"}}
}

test_universal_human_approval_always_present if {
	"human_approval" in router.applicable_policies with input as {"context": {"customer_country": "NG"}}
}

test_universal_model_routing_always_present if {
	"model_routing" in router.applicable_policies with input as {"context": {"customer_country": "ZA"}}
}

# ── Kenya: correct policy set ─────────────────────────────────────

test_ke_has_kdpa if {
	"kdpa" in router.applicable_policies with input as {"context": {"customer_country": "KE"}}
}

# KE: 1 jurisdiction pack + 5 universal = 6 total
test_ke_has_exactly_6_policies if {
	count(router.applicable_policies) == 6 with input as {"context": {"customer_country": "KE"}}
}

test_ke_cbn_not_applicable if {
	not "cbn" in router.applicable_policies with input as {"context": {"customer_country": "KE"}}
}

# ── South Africa: correct policy set ─────────────────────────────

test_za_has_popia if {
	"popia" in router.applicable_policies with input as {"context": {"customer_country": "ZA"}}
}

# ZA: 1 jurisdiction pack + 5 universal = 6 total
test_za_has_exactly_6_policies if {
	count(router.applicable_policies) == 6 with input as {"context": {"customer_country": "ZA"}}
}

# ── Multi-jurisdiction: NG customer, ZA transaction ───────────────

test_cross_border_ng_za_has_ndpa if {
	"ndpa" in router.applicable_policies with input as {"context": {
		"customer_country": "NG",
		"transaction_countries": ["NG", "ZA"],
	}}
}

test_cross_border_ng_za_has_popia if {
	"popia" in router.applicable_policies with input as {"context": {
		"customer_country": "NG",
		"transaction_countries": ["NG", "ZA"],
	}}
}

test_cross_border_ng_za_has_cbn if {
	"cbn" in router.applicable_policies with input as {"context": {
		"customer_country": "NG",
		"transaction_countries": ["NG", "ZA"],
	}}
}

# NG+ZA: 5 jurisdiction packs + 5 universal = 10 total
test_cross_border_ng_za_total_10_policies if {
	count(router.applicable_policies) == 10 with input as {"context": {
		"customer_country": "NG",
		"transaction_countries": ["NG", "ZA"],
	}}
}

test_cross_border_ng_ke_has_kdpa if {
	"kdpa" in router.applicable_policies with input as {"context": {
		"customer_country": "NG",
		"transaction_countries": ["NG", "KE"],
	}}
}

# NG+KE: 5 jurisdiction packs + 5 universal = 10 total
test_cross_border_ng_ke_total_10_policies if {
	count(router.applicable_policies) == 10 with input as {"context": {
		"customer_country": "NG",
		"transaction_countries": ["NG", "KE"],
	}}
}

# ── resolved_queries: correct OPA paths returned ──────────────────

test_ng_resolved_queries_contains_cbn_path if {
	"data.agt_policies_nigeria.cbn.decision" in router.resolved_queries with input as {"context": {"customer_country": "NG"}}
}

test_ng_resolved_queries_contains_ndpa_path if {
	"data.agt_policies_nigeria.ndpa.decision" in router.resolved_queries with input as {"context": {"customer_country": "NG"}}
}

test_ke_resolved_queries_contains_kdpa_path if {
	"data.agt_policies_africa.kdpa.decision" in router.resolved_queries with input as {"context": {"customer_country": "KE"}}
}

# ── Jurisdiction support checks ───────────────────────────────────

test_ng_is_supported if {
	router.is_supported_jurisdiction with input as {"context": {"customer_country": "NG"}}
}

test_ke_is_supported if {
	router.is_supported_jurisdiction with input as {"context": {"customer_country": "KE"}}
}

test_za_is_supported if {
	router.is_supported_jurisdiction with input as {"context": {"customer_country": "ZA"}}
}

test_us_not_supported if {
	not router.is_supported_jurisdiction with input as {"context": {"customer_country": "US"}}
}

test_gh_not_supported if {
	not router.is_supported_jurisdiction with input as {"context": {"customer_country": "GH"}}
}

test_unsupported_country_warning_fires if {
	router.unsupported_jurisdiction_warning with input as {"context": {"customer_country": "US"}}
}

test_unsupported_warning_contains_country_code if {
	contains(router.unsupported_jurisdiction_warning, "US") with input as {"context": {"customer_country": "US"}}
}
