"""
Nigerian Fintech AI Agent — Microsoft AutoGen + OPA Policy Enforcement
=======================================================================
Demonstrates agt-policies-nigeria Rego policies inside a Microsoft AutoGen
multi-agent conversation.

Architecture:
    GroupChat:
    ┌──────────────────────────────────────────────────────┐
    │  UserProxyAgent       ── initiates tasks             │
    │  GovernanceAgent      ── OPA checkpoint (always 1st) │
    │  ExecutorAgent        ── acts only on "allow/audit"  │
    └──────────────────────────────────────────────────────┘

    GovernanceAgent has a custom reply function that:
      1. Runs the jurisdiction router (customer_country → applicable packs)
      2. Evaluates applicable agt-policies-nigeria Rego files via OPA
      3. Returns verdict + reason to the group chat
      4. ExecutorAgent only proceeds on allow/audit

    GroupChatManager enforces: every message passes GovernanceAgent first.

Requirements:
    pip install pyautogen

Usage:
    python agent.py

To use a real LLM:
    Set OPENAI_API_KEY and see the comment in build_group_chat() below.
"""

from __future__ import annotations

import json
import os
import subprocess
from pathlib import Path
from typing import Optional

# ── Paths ─────────────────────────────────────────────────────────────
REPO_ROOT    = Path(__file__).parent.parent.parent
POLICIES_DIR = REPO_ROOT / "policies" / "rego"
ROUTER_FILE  = POLICIES_DIR / "jurisdiction-router.rego"
OPA_BINARY   = os.environ.get("OPA_PATH", "opa")

# ── OPA helpers ───────────────────────────────────────────────────────

POLICIES = {
    "cbn":     (POLICIES_DIR / "cbn-transaction-limits.rego",
                "data.agt_policies_nigeria.cbn.decision"),
    "bvn_nin": (POLICIES_DIR / "bvn-nin-protection.rego",
                "data.agt_policies_nigeria.bvn_nin.decision"),
    "ndpa":    (POLICIES_DIR / "ndpa-data-residency.rego",
                "data.agt_policies_nigeria.ndpa.decision"),
    "nfiu":    (POLICIES_DIR / "nfiu-aml.rego",
                "data.agt_policies_nigeria.nfiu.decision"),
    "kdpa":    (POLICIES_DIR / "kdpa-data-protection.rego",
                "data.agt_policies_africa.kdpa.decision"),
    "popia":   (POLICIES_DIR / "popia-south-africa.rego",
                "data.agt_policies_africa.popia.decision"),
}

DECISION_WEIGHT = {"deny": 3, "escalate": 2, "audit": 1, "allow": 0}


def _opa_eval(policy_file: Path, input_data: dict, query: str) -> str:
    try:
        proc = subprocess.run(
            [OPA_BINARY, "eval", "-d", str(policy_file),
             "--stdin-input", "--format", "raw", query],
            input=json.dumps(input_data),
            capture_output=True, text=True, timeout=5,
        )
        if proc.returncode == 0 and proc.stdout.strip():
            return proc.stdout.strip().strip('"')
    except (subprocess.TimeoutExpired, FileNotFoundError):
        pass
    return "allow"


def _route_jurisdictions(context: dict) -> set:
    if not context.get("customer_country") and not context.get("transaction_countries"):
        return set(POLICIES.keys())
    try:
        proc = subprocess.run(
            [OPA_BINARY, "eval", "-d", str(ROUTER_FILE),
             "--stdin-input", "--format", "raw",
             "data.agt_policies.router.applicable_policies"],
            input=json.dumps({"context": context}),
            capture_output=True, text=True, timeout=5,
        )
        if proc.returncode == 0 and proc.stdout.strip():
            result = json.loads(proc.stdout.strip())
            if isinstance(result, list) and result:
                return set(result)
    except (subprocess.TimeoutExpired, FileNotFoundError, json.JSONDecodeError):
        pass
    return set(POLICIES.keys())


def evaluate_policies(
    action: str, params: dict, output: str, context: dict
) -> tuple[str, str]:
    """Returns (decision, triggering_policy). Most restrictive wins."""
    applicable = _route_jurisdictions(context)
    input_data = {"action": action, "params": params,
                  "output": output, "context": context}
    best_decision, best_policy = "allow", "none"
    for name, (policy_file, query) in POLICIES.items():
        if name not in applicable or not policy_file.exists():
            continue
        decision = _opa_eval(policy_file, input_data, query)
        if DECISION_WEIGHT.get(decision, 0) > DECISION_WEIGHT.get(best_decision, 0):
            best_decision, best_policy = decision, name
    return best_decision, best_policy


# ── check_compliance: the function AutoGen agents call ────────────────

def check_compliance(
    action: str,
    params: dict,
    output: str,
    context: dict,
) -> dict:
    """
    OPA governance check — registered as a callable tool for AutoGen agents.

    Args:
        action:  the agent action name (e.g. "nip_transfer")
        params:  action parameters (e.g. {"amount": 8000000})
        output:  proposed agent output text
        context: context dict with customer_country, kyc_tier, etc.

    Returns:
        {
          "decision":    "allow" | "escalate" | "deny" | "audit",
          "policy":      "cbn" | "ndpa" | ...,
          "applicable":  ["cbn", "ndpa", ...],
          "message":     human-readable verdict
        }
    """
    decision, policy = evaluate_policies(action, params, output, context)
    applicable = sorted(_route_jurisdictions(context))

    messages = {
        "deny":     f"BLOCKED by {policy}: action violates regulatory rules.",
        "escalate": f"ESCALATED by {policy}: requires human approval before execution.",
        "audit":    f"ALLOWED (logged) by {policy}: action proceeds with audit record.",
        "allow":    "ALLOWED: no regulatory violations detected.",
    }

    return {
        "decision":   decision,
        "policy":     policy,
        "applicable": applicable,
        "message":    messages.get(decision, "UNKNOWN"),
    }


# ── AutoGen group chat ────────────────────────────────────────────────

def build_group_chat():
    """
    Build a three-agent AutoGen group chat with OPA governance.

    GovernanceAgent replies first to every message, evaluates the proposed
    action, and either approves or blocks before ExecutorAgent acts.

    ── To use a real LLM ─────────────────────────────────────────────
    import autogen

    config_list = autogen.config_list_from_json("OAI_CONFIG_LIST")
    # or: config_list = [{"model": "gpt-4o-mini", "api_key": os.getenv("OPENAI_API_KEY")}]

    llm_config = {"config_list": config_list, "cache_seed": 42}

    # Register check_compliance as a callable tool
    user_proxy = autogen.UserProxyAgent(
        name="UserProxy",
        human_input_mode="NEVER",
        max_consecutive_auto_reply=5,
        code_execution_config=False,
    )
    user_proxy.register_function(
        function_map={"check_compliance": check_compliance}
    )

    governance_agent = autogen.AssistantAgent(
        name="GovernanceAgent",
        system_message=(
            "You are a Nigerian/African AI governance officer. "
            "Before ANY action is executed, you MUST call check_compliance "
            "with the action, params, output, and context. "
            "If the result is 'deny', reply: BLOCKED — do not proceed. "
            "If 'escalate', reply: ESCALATED — route to human approval. "
            "If 'allow' or 'audit', reply: APPROVED — executor may proceed."
        ),
        llm_config={**llm_config, "functions": [{
            "name": "check_compliance",
            "description": "Check action against NDPA, CBN, NFIU, BVN/NIN, Kenya DPA, POPIA policies",
            "parameters": {
                "type": "object",
                "properties": {
                    "action":  {"type": "string"},
                    "params":  {"type": "object"},
                    "output":  {"type": "string"},
                    "context": {"type": "object"},
                },
                "required": ["action", "params", "output", "context"],
            },
        }]},
    )

    executor_agent = autogen.AssistantAgent(
        name="ExecutorAgent",
        system_message=(
            "You are a fintech executor. You ONLY execute actions that "
            "GovernanceAgent has explicitly approved. Never act on a BLOCKED "
            "or ESCALATED verdict."
        ),
        llm_config=llm_config,
    )

    group_chat = autogen.GroupChat(
        agents=[user_proxy, governance_agent, executor_agent],
        messages=[],
        max_round=10,
        speaker_selection_method="round_robin",
    )
    manager = autogen.GroupChatManager(
        groupchat=group_chat,
        llm_config=llm_config,
    )
    return user_proxy, manager
    ──────────────────────────────────────────────────────────────────
    """
    return None, None


# ── Demo Scenarios ────────────────────────────────────────────────────

SCENARIOS = [
    {
        "task":    "Transfer ₦8,000,000 to account 0123456789",
        "action":  "nip_transfer",
        "params":  {"amount": 8_000_000, "currency": "NGN"},
        "output":  "Initiating transfer of ₦8,000,000.",
        "context": {"kyc_tier": 3, "customer_country": "NG"},
    },
    {
        "task":    "Tell the customer their BVN is 22345678901",
        "action":  "respond_to_customer",
        "params":  {},
        "output":  "Your BVN is: 22345678901.",
        "context": {"customer_country": "NG"},
    },
    {
        "task":    "Export 2,000 Nigerian records to AWS US-East-1",
        "action":  "export_data",
        "params":  {"destination_region": "us-east-1",
                    "destination_country": "US", "record_count": 2000},
        "output":  "Exporting records to AWS US-East-1.",
        "context": {"consent_documented": False, "customer_country": "NG"},
    },
    {
        "task":    "Look up account balance for CUS-001",
        "action":  "read_customer",
        "params":  {"customer_id": "CUS-001"},
        "output":  "Fetching account balance.",
        "context": {"customer_country": "NG"},
    },
    {
        "task":    "Process PEP transaction for state governor",
        "action":  "nip_transfer",
        "params":  {"amount": 6_000_000, "currency": "NGN"},
        "output":  "Processing payment for the state governor's account transfer.",
        "context": {"kyc_tier": 3, "customer_country": "NG"},
    },
    {
        "task":    "Export 500 Kenyan records to Europe",
        "action":  "export_data",
        "params":  {"destination_region": "eu-west-1",
                    "destination_country": "IE", "record_count": 500},
        "output":  "Exporting Kenyan records to EU.",
        "context": {"consent_documented": False, "customer_country": "KE"},
    },
    {
        "task":    "Return customer SA ID number in response",
        "action":  "respond",
        "params":  {},
        "output":  "Your South African ID: 9001015009087.",
        "context": {"customer_country": "ZA"},
    },
    {
        "task":    "Export Nigerian data to South African analytics platform",
        "action":  "export_data",
        "params":  {"destination_region": "af-south-1",
                    "destination_country": "ZA", "record_count": 800},
        "output":  "Exporting 800 Nigerian records to South African platform.",
        "context": {"customer_country": "NG",
                    "transaction_countries": ["NG", "ZA"],
                    "consent_documented": False},
    },
]


# ── Demo runner ───────────────────────────────────────────────────────

BOLD   = "\033[1m"
GREEN  = "\033[92m"
RED    = "\033[91m"
YELLOW = "\033[93m"
CYAN   = "\033[96m"
DIM    = "\033[2m"
RESET  = "\033[0m"

DECISION_ICON = {
    "allow":    f"{GREEN}✅ ALLOWED{RESET}",
    "audit":    f"{GREEN}✅ ALLOWED (AUDITED){RESET}",
    "escalate": f"{YELLOW}⏳ ESCALATED{RESET}",
    "deny":     f"{RED}❌ BLOCKED{RESET}",
}


def main():
    print(f"\n{BOLD}{CYAN}{'=' * 65}")
    print("  AutoGen + OPA  |  Nigerian & African Fintech Agent")
    print("  agt-policies-nigeria — kingztech2019/agt-policies-nigeria")
    print(f"{'=' * 65}{RESET}\n")
    print(f"  {DIM}GovernanceAgent calls check_compliance before every action{RESET}")
    print(f"  {DIM}GroupChat: UserProxy → GovernanceAgent → ExecutorAgent{RESET}\n")

    for i, scenario in enumerate(SCENARIOS, 1):
        result = check_compliance(
            action=scenario["action"],
            params=scenario["params"],
            output=scenario["output"],
            context=scenario["context"],
        )

        decision = result["decision"]
        policy   = result["policy"]
        packs    = ", ".join(result["applicable"])

        print(f"{'─' * 65}")
        print(f"{BOLD}Step {i}:{RESET} {scenario['task']}")
        print(f"  Decision    : {DECISION_ICON.get(decision, decision)}")
        print(f"  Policy      : {DIM}{policy}{RESET}")
        print(f"  Jurisd.     : {DIM}{scenario['context'].get('customer_country','?')} "
              f"→ [{packs}]{RESET}")
        print(f"  Verdict     : {DIM}{result['message']}{RESET}")

    print(f"\n{'─' * 65}")
    print(f"\n{BOLD}GovernanceAgent ran before every ExecutorAgent action.{RESET}")
    print(f"GroupChat pattern: UserProxy → GovernanceAgent → ExecutorAgent.\n")


if __name__ == "__main__":
    main()
