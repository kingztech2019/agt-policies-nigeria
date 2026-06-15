# agt-policies
# Tests for jurisdiction router
# Run: opa test policies/rego/ -v

package agt_policies.router_test

import data.agt_policies.router
import rego.v1

# ── Nigeria: correct policy set ───────────────────────────────────

test_ng_has_cbn if {
    "cbn" in router.applicable_policies with input as {
        "context": {"customer_country": "NG"}
    }
}

test_ng_has_bvn_nin if {
    "bvn_nin" in router.applicable_policies with input as {
        "context": {"customer_country": "NG"}
    }
}

test_ng_has_ndpa if {
    "ndpa" in router.applicable_policies with input as {
        "context": {"customer_country": "NG"}
    }
}

test_ng_has_nfiu if {
    "nfiu" in router.applicable_policies with input as {
        "context": {"customer_country": "NG"}
    }
}

test_ng_has_exactly_4_policies if {
    count(router.applicable_policies) == 4 with input as {
        "context": {"customer_country": "NG"}
    }
}

test_ng_popia_not_applicable if {
    not "popia" in router.applicable_policies with input as {
        "context": {"customer_country": "NG"}
    }
}

test_ng_kdpa_not_applicable if {
    not "kdpa" in router.applicable_policies with input as {
        "context": {"customer_country": "NG"}
    }
}

# ── Kenya: correct policy set ─────────────────────────────────────

test_ke_has_kdpa if {
    "kdpa" in router.applicable_policies with input as {
        "context": {"customer_country": "KE"}
    }
}

test_ke_has_exactly_1_policy if {
    count(router.applicable_policies) == 1 with input as {
        "context": {"customer_country": "KE"}
    }
}

test_ke_cbn_not_applicable if {
    not "cbn" in router.applicable_policies with input as {
        "context": {"customer_country": "KE"}
    }
}

# ── South Africa: correct policy set ─────────────────────────────

test_za_has_popia if {
    "popia" in router.applicable_policies with input as {
        "context": {"customer_country": "ZA"}
    }
}

test_za_has_exactly_1_policy if {
    count(router.applicable_policies) == 1 with input as {
        "context": {"customer_country": "ZA"}
    }
}

# ── Multi-jurisdiction: NG customer, ZA transaction ───────────────

test_cross_border_ng_za_has_ndpa if {
    "ndpa" in router.applicable_policies with input as {
        "context": {
            "customer_country": "NG",
            "transaction_countries": ["NG", "ZA"]
        }
    }
}

test_cross_border_ng_za_has_popia if {
    "popia" in router.applicable_policies with input as {
        "context": {
            "customer_country": "NG",
            "transaction_countries": ["NG", "ZA"]
        }
    }
}

test_cross_border_ng_za_has_cbn if {
    "cbn" in router.applicable_policies with input as {
        "context": {
            "customer_country": "NG",
            "transaction_countries": ["NG", "ZA"]
        }
    }
}

test_cross_border_ng_za_total_5_policies if {
    count(router.applicable_policies) == 5 with input as {
        "context": {
            "customer_country": "NG",
            "transaction_countries": ["NG", "ZA"]
        }
    }
}

test_cross_border_ng_ke_has_kdpa if {
    "kdpa" in router.applicable_policies with input as {
        "context": {
            "customer_country": "NG",
            "transaction_countries": ["NG", "KE"]
        }
    }
}

test_cross_border_ng_ke_total_5_policies if {
    count(router.applicable_policies) == 5 with input as {
        "context": {
            "customer_country": "NG",
            "transaction_countries": ["NG", "KE"]
        }
    }
}

# ── resolved_queries: correct OPA paths returned ──────────────────

test_ng_resolved_queries_contains_cbn_path if {
    "data.agt_policies_nigeria.cbn.decision" in router.resolved_queries with input as {
        "context": {"customer_country": "NG"}
    }
}

test_ng_resolved_queries_contains_ndpa_path if {
    "data.agt_policies_nigeria.ndpa.decision" in router.resolved_queries with input as {
        "context": {"customer_country": "NG"}
    }
}

test_ke_resolved_queries_contains_kdpa_path if {
    "data.agt_policies_africa.kdpa.decision" in router.resolved_queries with input as {
        "context": {"customer_country": "KE"}
    }
}

# ── Jurisdiction support checks ───────────────────────────────────

test_ng_is_supported if {
    router.is_supported_jurisdiction with input as {
        "context": {"customer_country": "NG"}
    }
}

test_ke_is_supported if {
    router.is_supported_jurisdiction with input as {
        "context": {"customer_country": "KE"}
    }
}

test_za_is_supported if {
    router.is_supported_jurisdiction with input as {
        "context": {"customer_country": "ZA"}
    }
}

test_us_not_supported if {
    not router.is_supported_jurisdiction with input as {
        "context": {"customer_country": "US"}
    }
}

test_gh_not_supported if {
    not router.is_supported_jurisdiction with input as {
        "context": {"customer_country": "GH"}
    }
}

test_unsupported_country_warning_fires if {
    router.unsupported_jurisdiction_warning with input as {
        "context": {"customer_country": "US"}
    }
}

test_unsupported_warning_contains_country_code if {
    contains(router.unsupported_jurisdiction_warning, "US") with input as {
        "context": {"customer_country": "US"}
    }
}
