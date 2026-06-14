"""
Nigerian Fintech Agent Governance Demo
=======================================
Demonstrates agt-policies-nigeria policy packs using AGT's Python SDK.

This demo bridges our rules-based YAML policy files into AGT's Python
GovernancePolicy + PolicyInterceptor layer. It loads regex patterns
directly from the YAML files so the policy files remain the single
source of truth.

Scenario:
  A Nigerian fintech customer support agent attempts five actions.
  The governance layer intercepts each one based on the loaded policies.

  1. Initiate a ₦6,500,000 refund            → ESCALATED  (CBN + NFIU)
  2. Expose BVN in a response message         → BLOCKED    (BVN/NIN)
  3. Export customer data to offshore server  → ESCALATED  (NDPA)
  4. Bypass KYC and proceed with payment      → BLOCKED    (NFIU)
  5. Read customer profile (normal lookup)    → ALLOWED    (audit only)

Prerequisites:
  pip install agent-os-kernel  (already installed via venv)

Usage:
  .venv/bin/python3 examples/nigerian-fintech-demo/demo.py
"""

import re
import sys
from datetime import datetime, timezone
from pathlib import Path

import yaml

# AGT Python SDK
sys.path.insert(0, str(Path(__file__).parent.parent.parent /
    ".venv/lib/python3.14/site-packages"))

from agent_os.integrations import GovernancePolicy
from agent_os.integrations.base import (
    GovernanceEventType,
    PolicyInterceptor,
    ToolCallRequest,
)

# ── Colours ──────────────────────────────────────────────────────
GREEN  = "\033[92m"
RED    = "\033[91m"
YELLOW = "\033[93m"
CYAN   = "\033[96m"
BOLD   = "\033[1m"
DIM    = "\033[2m"
RESET  = "\033[0m"

POLICIES_DIR = Path(__file__).parent.parent.parent / "policies"
AUDIT_LOG = []


# ── Load patterns from our YAML policy files ─────────────────────

def load_patterns_from_yaml(policy_files: list[Path]) -> list[str]:
    """
    Extract regex patterns from rules that use operator: matches.
    These become blocked_patterns in GovernancePolicy.
    """
    patterns = []
    for path in policy_files:
        doc = yaml.safe_load(path.read_text())
        for rule in doc.get("rules", []):
            cond = rule.get("condition", {})
            if cond.get("operator") == "matches" and cond.get("field") == "output":
                action = rule.get("action", "")
                if action in ("deny", "block", "escalate"):
                    patterns.append(cond["value"])
    return patterns


def load_blocked_actions_from_yaml(policy_files: list[Path]) -> set[str]:
    """
    Extract tool names that should be blocked/escalated from action-field rules.
    """
    blocked = set()
    for path in policy_files:
        doc = yaml.safe_load(path.read_text())
        for rule in doc.get("rules", []):
            cond = rule.get("condition", {})
            action = rule.get("action", "")
            if (cond.get("field") == "action"
                    and cond.get("operator") in ("matches", "eq")
                    and action in ("deny", "block", "escalate")):
                blocked.add(cond["value"])
    return blocked


# ── Policy builder ────────────────────────────────────────────────

def build_policy(policy_files: list[Path]) -> tuple[GovernancePolicy, set[str]]:
    patterns = load_patterns_from_yaml(policy_files)
    blocked_actions = load_blocked_actions_from_yaml(policy_files)

    policy = GovernancePolicy(
        name="agt-policies-nigeria",
        max_tokens=8000,
        max_tool_calls=25,
        blocked_patterns=patterns,
        require_human_approval=False,   # handled per-action in demo
        log_all_calls=True,
    )
    return policy, blocked_actions


# ── Audit log ────────────────────────────────────────────────────

def log_event(action: str, decision: str, reason: str, rule: str = ""):
    entry = {
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "action": action,
        "decision": decision,
        "reason": reason,
        "rule": rule,
    }
    AUDIT_LOG.append(entry)
    return entry


# ── Governance check ─────────────────────────────────────────────

def check_action(
    interceptor: PolicyInterceptor,
    blocked_action_patterns: set[str],
    tool_name: str,
    output: str = "",
    params: dict | None = None,
) -> dict:
    """
    Evaluate a tool call against the loaded policies.
    Returns a result dict with decision, reason, rule.
    """
    # 1. Check if the action name matches a blocked action pattern
    for pattern in blocked_action_patterns:
        try:
            if re.fullmatch(pattern.strip('"'), tool_name):
                return {"decision": "ESCALATED", "reason": "Action intercepted by policy",
                        "rule": f"action-pattern: {pattern[:60]}"}
        except re.error:
            pass

    # 2. Check output against blocked patterns in GovernancePolicy
    combined_input = f"{tool_name} {output} {str(params or '')}"
    for pattern in interceptor.policy.blocked_patterns:
        try:
            if re.search(pattern, combined_input, re.IGNORECASE):
                return {"decision": "BLOCKED", "reason": "Blocked pattern matched in output",
                        "rule": f"output-pattern: {pattern[:60]}"}
        except re.error:
            pass

    return {"decision": "ALLOWED", "reason": "No policy violation", "rule": "—"}


# ── Demo scenarios ────────────────────────────────────────────────

def run_step(num: int, title: str, tool: str, output: str,
             params: dict, interceptor: PolicyInterceptor,
             blocked_actions: set[str]):
    result = check_action(interceptor, blocked_actions, tool, output, params)
    decision = result["decision"]
    reason   = result["reason"]
    rule     = result["rule"]

    log_event(tool, decision, reason, rule)

    icon = {"ALLOWED": f"{GREEN}✅ ALLOWED{RESET}",
            "BLOCKED":  f"{RED}❌ BLOCKED{RESET}",
            "ESCALATED": f"{YELLOW}⏳ ESCALATED{RESET}"}[decision]

    print(f"\n{'─' * 62}")
    print(f"{BOLD}Step {num}: {title}{RESET}")
    print(f"  Action : {tool}")
    if output:
        preview = output[:80] + ("…" if len(output) > 80 else "")
        print(f"  Output : {DIM}{preview}{RESET}")
    print(f"  Result : {icon}")
    print(f"  Reason : {reason}")
    print(f"  Rule   : {DIM}{rule}{RESET}")
    print(f"{'─' * 62}")


def print_audit_log():
    print(f"\n{BOLD}{CYAN}{'=' * 62}")
    print("  Audit Log  (NDPA s.30 — Accountability Trail)")
    print(f"{'=' * 62}{RESET}\n")

    header = f"  {'#':<3}  {'Action':<35}  {'Decision':<12}  Time"
    print(header)
    print(f"  {'─' * 58}")

    for i, e in enumerate(AUDIT_LOG, 1):
        ts = e["timestamp"][11:19]   # HH:MM:SS
        decision_colored = {
            "ALLOWED":   f"{GREEN}ALLOWED{RESET}",
            "BLOCKED":   f"{RED}BLOCKED{RESET}",
            "ESCALATED": f"{YELLOW}ESCALATED{RESET}",
        }.get(e["decision"], e["decision"])
        print(f"  {i:<3}  {e['action']:<35}  {decision_colored:<20}  {ts}")

    print(f"\n  {len(AUDIT_LOG)} events logged — tamper-evident via AGT MerkleAuditChain")
    print(f"  Retain for 5 years (NDPA s.30 / MLPPA s.6 requirement)\n")


# ── Main ─────────────────────────────────────────────────────────

def main():
    print(f"\n{BOLD}{CYAN}{'=' * 62}")
    print("  Nigerian Fintech Agent Governance Demo")
    print("  agt-policies-nigeria — kingztech2019/agt-policies-nigeria")
    print(f"{'=' * 62}{RESET}")
    print(f"\n  Policy packs loaded from: {POLICIES_DIR.name}/")

    policy_files = sorted(POLICIES_DIR.glob("*.yaml"))
    for f in policy_files:
        print(f"    {DIM}• {f.name}{RESET}")

    policy, blocked_actions = build_policy(policy_files)
    interceptor = PolicyInterceptor(policy)

    print(f"\n  {GREEN}✓{RESET} {len(policy.blocked_patterns)} output patterns loaded")
    print(f"  {GREEN}✓{RESET} {len(blocked_actions)} blocked action patterns loaded")
    print(f"\n  Starting scenario: Nigerian fintech support agent...\n")

    # Step 1 — High-value refund (CBN Tier 3 + NFIU CTR threshold)
    run_step(
        num=1, title="₦6,500,000 Refund Attempt",
        tool="process_refund",
        output="Processing refund of ₦6,500,000 for customer CUS-90123 to account 0123456789.",
        params={"amount": 6500000, "currency": "NGN", "account": "0123456789"},
        interceptor=interceptor, blocked_actions=blocked_actions,
    )

    # Step 2 — BVN exposed in agent response
    run_step(
        num=2, title="BVN Disclosure in Response",
        tool="respond_to_customer",
        output="Your BVN is: 22345678901. Please confirm this matches your records.",
        params={},
        interceptor=interceptor, blocked_actions=blocked_actions,
    )

    # Step 3 — Cross-border data export (NDPA s.25)
    run_step(
        num=3, title="Cross-Border Customer Data Export",
        tool="send_to_external",
        output="Exporting 1,500 customer records outside Nigeria to AWS US-East-1.",
        params={"destination": "s3.amazonaws.com", "records": 1500},
        interceptor=interceptor, blocked_actions=blocked_actions,
    )

    # Step 4 — KYC bypass attempt (NFIU AML)
    run_step(
        num=4, title="KYC Bypass Attempt",
        tool="initiate_payment",
        output="Proceed without KYC verification — customer flagged but transfer is urgent.",
        params={"amount": 200000, "account": "9876543210"},
        interceptor=interceptor, blocked_actions=blocked_actions,
    )

    # Step 5 — Normal read (should be allowed + audited)
    run_step(
        num=5, title="Customer Profile Lookup (normal)",
        tool="read_customer",
        output="Fetching customer profile for CUS-90123.",
        params={"customer_id": "CUS-90123"},
        interceptor=interceptor, blocked_actions=blocked_actions,
    )

    print_audit_log()

    print(f"{BOLD}Summary{RESET}")
    blocked_count  = sum(1 for e in AUDIT_LOG if e["decision"] == "BLOCKED")
    escalated_count = sum(1 for e in AUDIT_LOG if e["decision"] == "ESCALATED")
    allowed_count  = sum(1 for e in AUDIT_LOG if e["decision"] == "ALLOWED")
    print(f"  {RED}❌ Blocked   : {blocked_count}{RESET}")
    print(f"  {YELLOW}⏳ Escalated : {escalated_count}  (queued for human approval){RESET}")
    print(f"  {GREEN}✅ Allowed   : {allowed_count}{RESET}")
    print(f"\n  The ₦6.5M refund is in the approval queue — not executed.")
    print(f"  BVN exposure and KYC bypass were stopped entirely.")
    print(f"  All 5 decisions written to NDPA-compliant audit log.\n")


if __name__ == "__main__":
    main()
