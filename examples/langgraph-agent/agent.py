"""
Nigerian Fintech AI Agent — LangGraph + OPA Policy Enforcement
==============================================================
Demonstrates agt-policies-nigeria Rego policies as a governance node
inside a LangGraph agent graph.

Architecture:
    task ──► plan ──► opa_check ──► execute       (allow / audit)
                               ├──► human_review  (escalate)
                               └──► blocked       (deny)

OPA is a proper NODE in the graph — not middleware bolted on after.
Every action must pass through it before execution.

Requirements:
    pip install langgraph langchain-core
    # OPA binary must be available: https://www.openpolicyagent.org/docs/latest/#running-opa
    # Set OPA_PATH env var if opa is not in PATH

Usage:
    python agent.py

To use a real LLM instead of demo scenarios:
    See the comment in plan_node() below.
"""

from __future__ import annotations

import json
import os
import subprocess
from pathlib import Path
from typing import TypedDict

from langchain_core.messages import AIMessage, HumanMessage
from langgraph.graph import END, StateGraph

# ── Paths ─────────────────────────────────────────────────────────────
REPO_ROOT    = Path(__file__).parent.parent.parent
POLICIES_DIR = REPO_ROOT / "policies" / "rego"
OPA_BINARY   = os.environ.get("OPA_PATH", "opa")
ROUTER_FILE  = POLICIES_DIR / "jurisdiction-router.rego"

# ── State ─────────────────────────────────────────────────────────────

class AgentState(TypedDict):
    task:         str
    action:       str
    params:       dict
    output:       str
    context:      dict
    opa_decision: str        # allow | escalate | deny | audit
    opa_policy:   str        # which policy triggered
    messages:     list

# ── OPA Evaluation ────────────────────────────────────────────────────

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
    """Run opa eval against a single policy file and return the decision."""
    try:
        proc = subprocess.run(
            [OPA_BINARY, "eval",
             "-d", str(policy_file),
             "--stdin-input",
             "--format", "raw",
             query],
            input=json.dumps(input_data),
            capture_output=True, text=True, timeout=5,
        )
        if proc.returncode == 0 and proc.stdout.strip():
            return proc.stdout.strip().strip('"')
    except (subprocess.TimeoutExpired, FileNotFoundError):
        pass
    return "allow"  # fail-open when OPA is unavailable


def route_jurisdictions(context: dict) -> set:
    """
    Query the jurisdiction router to get applicable policy packs for this context.
    Falls back to all policies when no jurisdiction info is present (fail-open).
    """
    if not context.get("customer_country") and not context.get("transaction_countries"):
        return set(POLICIES.keys())

    try:
        proc = subprocess.run(
            [OPA_BINARY, "eval",
             "-d", str(ROUTER_FILE),
             "--stdin-input",
             "--format", "raw",
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

    return set(POLICIES.keys())  # fail-open


def evaluate_policies(
    action: str, params: dict, output: str, context: dict
) -> tuple[str, str]:
    """
    1. Query jurisdiction router → applicable policy packs for this context.
    2. Evaluate only applicable policies — skip irrelevant jurisdictions.
    Returns (decision, policy_name) — most restrictive decision wins.
    Priority: deny > escalate > audit > allow
    """
    applicable = route_jurisdictions(context)
    input_data = {
        "action": action,
        "params": params,
        "output": output,
        "context": context,
    }

    best_decision = "allow"
    best_policy   = "none"

    for name, (policy_file, query) in POLICIES.items():
        if name not in applicable:
            continue
        if not policy_file.exists():
            continue
        decision = _opa_eval(policy_file, input_data, query)
        if DECISION_WEIGHT.get(decision, 0) > DECISION_WEIGHT.get(best_decision, 0):
            best_decision = decision
            best_policy   = name

    return best_decision, best_policy


# ── Demo Scenarios ────────────────────────────────────────────────────
#
# Each entry maps a task string to (action, params, output, context).
# In production replace plan_node with a real LLM call (see below).

SCENARIOS: dict[str, tuple[str, dict, str, dict]] = {
    "Transfer ₦8,000,000 to account 0123456789": (
        "nip_transfer",
        {"amount": 8_000_000, "currency": "NGN", "account": "0123456789"},
        "Initiating transfer of ₦8,000,000 to account 0123456789.",
        {"kyc_tier": 3, "customer_country": "NG"},
    ),
    "Tell the customer their BVN is 22345678901": (
        "respond_to_customer",
        {},
        "Your BVN is: 22345678901. Please confirm this is correct.",
        {"customer_country": "NG"},
    ),
    "Export 2,000 customer records to AWS US-East-1": (
        "export_data",
        {"destination_region": "us-east-1", "destination_country": "US", "record_count": 2000},
        "Exporting 2,000 customer records outside Nigeria to AWS US-East-1.",
        {"consent_documented": False, "customer_country": "NG"},
    ),
    "Look up account balance for customer CUS-001": (
        "read_customer",
        {"customer_id": "CUS-001"},
        "Fetching account balance for CUS-001.",
        {"customer_country": "NG"},
    ),
    "Verify the customer's BVN before account opening": (
        "verify_bvn",
        {"identifier_type": "BVN"},
        "Initiating BVN verification for account opening.",
        {"purpose": "account_opening", "customer_country": "NG"},
    ),
    "Export 500 Kenyan customer records to Europe": (
        "export_data",
        {"destination_region": "eu-west-1", "destination_country": "IE", "record_count": 500},
        "Exporting 500 Kenyan customer records outside Kenya to EU infrastructure.",
        {"consent_documented": False, "customer_country": "KE"},
    ),
    "Transfer ₦6,000,000 to a politically exposed person": (
        "nip_transfer",
        {"amount": 6_000_000, "currency": "NGN"},
        "Processing payment for the state senator's account transfer.",
        {"kyc_tier": 3, "customer_country": "NG"},
    ),
    "Return customer's SA ID number in the response": (
        "respond",
        {},
        "Your South African ID: 9001015009087. Please verify this is correct.",
        {"customer_country": "ZA"},
    ),
    "Export Nigerian customer data to South African analytics platform": (
        "export_data",
        {"destination_region": "af-south-1", "destination_country": "ZA", "record_count": 800},
        "Exporting 800 Nigerian customer records to South African analytics platform.",
        {
            "customer_country": "NG",
            "transaction_countries": ["NG", "ZA"],
            "consent_documented": False,
        },
    ),
}


# ── Graph Nodes ───────────────────────────────────────────────────────

def plan_node(state: AgentState) -> dict:
    """
    Determine the action to take from the task description.

    Demo mode: maps task → (action, params, output, context) via SCENARIOS.

    ── To use a real LLM ────────────────────────────────────────────────
    from langchain_openai import ChatOpenAI   # or langchain_anthropic
    from langchain_core.prompts import ChatPromptTemplate
    import json

    llm = ChatOpenAI(model="gpt-4o-mini")

    prompt = ChatPromptTemplate.from_messages([
        ("system", "You are a Nigerian fintech agent. Given a task, output JSON: "
                   "{action, params, output, context}"),
        ("human", "{task}"),
    ])
    response = (prompt | llm).invoke({"task": state["task"]})
    parsed = json.loads(response.content)
    return {**parsed, "messages": state["messages"] + [HumanMessage(content=state["task"])]}
    ─────────────────────────────────────────────────────────────────────
    """
    task = state["task"]
    action, params, output, context = SCENARIOS.get(
        task,
        ("unknown_action", {}, f"Executing: {task}", {}),
    )
    return {
        "action":   action,
        "params":   params,
        "output":   output,
        "context":  context,
        "messages": state.get("messages", []) + [HumanMessage(content=task)],
    }


def opa_check_node(state: AgentState) -> dict:
    """
    OPA governance checkpoint.
    Evaluates the planned action against ALL agt-policies Rego files.
    This node runs on every action without exception.
    """
    decision, policy = evaluate_policies(
        state["action"],
        state["params"],
        state["output"],
        state["context"],
    )
    return {"opa_decision": decision, "opa_policy": policy}


def execute_node(state: AgentState) -> dict:
    """Executes the action. Only reached when OPA returns allow or audit."""
    suffix = " (logged for audit)" if state["opa_decision"] == "audit" else ""
    msg = f"✅ EXECUTED{suffix}: {state['action']} — {state['output']}"
    return {"messages": state["messages"] + [AIMessage(content=msg)]}


def human_review_node(state: AgentState) -> dict:
    """Queues the action for human approval. Reached when OPA returns escalate."""
    msg = (
        f"⏳ ESCALATED to human approval queue\n"
        f"   Action : {state['action']}\n"
        f"   Policy : {state['opa_policy']}\n"
        f"   Params : {state['params']}"
    )
    return {"messages": state["messages"] + [AIMessage(content=msg)]}


def blocked_node(state: AgentState) -> dict:
    """Blocks the action entirely. Reached when OPA returns deny."""
    msg = (
        f"❌ BLOCKED by {state['opa_policy']} policy\n"
        f"   Action : {state['action']}\n"
        f"   Reason : output/params violated compliance rule"
    )
    return {"messages": state["messages"] + [AIMessage(content=msg)]}


# ── Routing ───────────────────────────────────────────────────────────

def route_after_opa(state: AgentState) -> str:
    decision = state.get("opa_decision", "allow")
    if decision == "deny":
        return "blocked"
    if decision == "escalate":
        return "human_review"
    return "execute"  # allow or audit


# ── Build Graph ───────────────────────────────────────────────────────

def build_agent():
    graph = StateGraph(AgentState)

    graph.add_node("plan",         plan_node)
    graph.add_node("opa_check",    opa_check_node)
    graph.add_node("execute",      execute_node)
    graph.add_node("human_review", human_review_node)
    graph.add_node("blocked",      blocked_node)

    graph.set_entry_point("plan")
    graph.add_edge("plan", "opa_check")
    graph.add_conditional_edges(
        "opa_check",
        route_after_opa,
        {"execute": "execute", "human_review": "human_review", "blocked": "blocked"},
    )
    graph.add_edge("execute",      END)
    graph.add_edge("human_review", END)
    graph.add_edge("blocked",      END)

    return graph.compile()


# ── Demo Runner ───────────────────────────────────────────────────────

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
    agent = build_agent()

    print(f"\n{BOLD}{CYAN}{'=' * 65}")
    print("  LangGraph + OPA  |  Nigerian & African Fintech Agent")
    print("  agt-policies-nigeria — kingztech2019/agt-policies-nigeria")
    print(f"{'=' * 65}{RESET}\n")
    print(f"  {DIM}Graph: plan → opa_check → execute | human_review | blocked{RESET}\n")

    for i, task in enumerate(SCENARIOS, 1):
        result = agent.invoke({
            "task":         task,
            "action":       "",
            "params":       {},
            "output":       "",
            "context":      {},
            "opa_decision": "",
            "opa_policy":   "",
            "messages":     [],
        })

        decision = result["opa_decision"]
        policy   = result["opa_policy"]
        last_msg = result["messages"][-1].content if result["messages"] else ""

        print(f"{'─' * 65}")
        print(f"{BOLD}Step {i}:{RESET} {task}")
        print(f"  Decision : {DECISION_ICON.get(decision, decision)}")
        print(f"  Policy   : {DIM}{policy}{RESET}")
        for line in last_msg.splitlines():
            print(f"  {line}")

    print(f"\n{'─' * 65}")
    print(f"\n{BOLD}OPA was a node in the graph — not middleware.{RESET}")
    print(f"Jurisdiction router selected applicable policies per action.")
    print(f"NG → CBN+BVN/NIN+NDPA+NFIU  |  KE → KDPA  |  ZA → POPIA  |  NG+ZA → all 5\n")


if __name__ == "__main__":
    main()
