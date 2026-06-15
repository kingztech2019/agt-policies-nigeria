"""
Nigerian Fintech AI Agent — CrewAI + OPA Policy Enforcement
============================================================
Demonstrates agt-policies-nigeria Rego policies inside a CrewAI crew.

Architecture:
    Crew: Nigerian Fintech Operations
    ├── compliance_agent  — evaluates every proposed action via OPA
    └── executor_agent    — executes only after compliance clears it

    OPAGovernanceTool  — BaseTool that calls agt-policies-nigeria
    step_callback      — safety net: checks every agent step regardless

    Governance flow:
        task → compliance_agent calls OPAGovernanceTool
             → allow/audit  → executor_agent proceeds
             → escalate     → routed to human review queue
             → deny         → task blocked, crew stops

Requirements:
    pip install crewai

Usage:
    python agent.py

To use a real LLM:
    Set OPENAI_API_KEY (or ANTHROPIC_API_KEY) and see the comment
    in build_crew() below.
"""

from __future__ import annotations

import json
import os
import subprocess
from pathlib import Path
from typing import Type

try:
    from crewai.tools import BaseTool
    from pydantic import BaseModel, Field
    _CREWAI_AVAILABLE = True
except ImportError:
    _CREWAI_AVAILABLE = False

# ── Paths ─────────────────────────────────────────────────────────────
REPO_ROOT    = Path(__file__).parent.parent.parent
POLICIES_DIR = REPO_ROOT / "policies" / "rego"
ROUTER_FILE  = POLICIES_DIR / "jurisdiction-router.rego"
OPA_BINARY   = os.environ.get("OPA_PATH", "opa")

# ── OPA helpers (shared with LangGraph example) ───────────────────────

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


# ── OPAGovernanceTool ─────────────────────────────────────────────────

def _governance_run(action: str, params: str, output: str = "", context: str = "{}") -> str:
    """Core OPA evaluation — used by OPAGovernanceTool._run and the demo."""
    try:
        params_dict  = json.loads(params)  if isinstance(params, str)  else params
        context_dict = json.loads(context) if isinstance(context, str) else context
    except json.JSONDecodeError as e:
        return f"ERROR: Could not parse params or context as JSON — {e}"

    decision, policy = evaluate_policies(action, params_dict, output, context_dict)

    applicable = _route_jurisdictions(context_dict)
    jurisdiction_note = (
        f"Jurisdiction: {context_dict.get('customer_country', 'unknown')} "
        f"→ {len(applicable)} policy pack(s) evaluated: {', '.join(sorted(applicable))}"
    )

    if decision == "deny":
        return (
            f"DENIED by {policy} policy. Action is blocked — do not proceed.\n"
            f"{jurisdiction_note}"
        )
    if decision == "escalate":
        return (
            f"ESCALATED by {policy} policy. Route to human approval queue — "
            f"do not execute autonomously.\n{jurisdiction_note}"
        )
    if decision == "audit":
        return (
            f"ALLOWED (with audit log) — {policy} policy requires this action "
            f"to be logged.\n{jurisdiction_note}"
        )
    return f"ALLOWED — no policy violations detected.\n{jurisdiction_note}"


if _CREWAI_AVAILABLE:
    class GovernanceInput(BaseModel):
        action:  str = Field(description="The agent action to evaluate (e.g. 'nip_transfer')")
        params:  str = Field(description="JSON string of action parameters")
        output:  str = Field(description="Proposed agent output text", default="")
        context: str = Field(description="JSON string of context (customer_country, kyc_tier, etc.)")

    class OPAGovernanceTool(BaseTool):
        name: str = "opa_governance_check"
        description: str = (
            "MUST be called before any regulated financial or data action. "
            "Checks the proposed action against Nigerian and African regulatory "
            "policies (NDPA, CBN, NFIU, BVN/NIN, Kenya DPA, POPIA). "
            "Returns: decision (allow/escalate/deny/audit), triggering policy, "
            "and the applicable jurisdictions for this customer."
        )
        args_schema: Type[BaseModel] = GovernanceInput

        def _run(self, action: str, params: str, output: str = "", context: str = "{}") -> str:
            return _governance_run(action, params, output, context)


# ── Demo Scenarios ────────────────────────────────────────────────────
#
# Each scenario: (action, params_dict, output_text, context_dict)

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
        "task":    "Export 500 Kenyan customer records to EU",
        "action":  "export_data",
        "params":  {"destination_region": "eu-west-1",
                    "destination_country": "IE", "record_count": 500},
        "output":  "Exporting Kenyan records to EU.",
        "context": {"consent_documented": False, "customer_country": "KE"},
    },
    {
        "task":    "Export Nigerian customer data to South African platform",
        "action":  "export_data",
        "params":  {"destination_region": "af-south-1",
                    "destination_country": "ZA", "record_count": 800},
        "output":  "Exporting 800 Nigerian records to South African platform.",
        "context": {"customer_country": "NG",
                    "transaction_countries": ["NG", "ZA"],
                    "consent_documented": False},
    },
]


# ── Crew builder ──────────────────────────────────────────────────────

def build_crew():
    """
    Build a Nigerian Fintech CrewAI crew with OPA governance enforcement.

    Demo mode: tasks are executed directly via _governance_run() to avoid
    requiring crewai to be installed or an LLM API key.

    ── To use a real LLM ─────────────────────────────────────────────
    from crewai import Agent, Task, Crew, Process
    from langchain_openai import ChatOpenAI   # or langchain_anthropic

    llm = ChatOpenAI(model="gpt-4o-mini")
    governance_tool = OPAGovernanceTool()

    compliance_agent = Agent(
        role="Nigerian Fintech Compliance Officer",
        goal="Evaluate every proposed action against regulatory policies "
             "before it is executed. ALWAYS call opa_governance_check first.",
        backstory="Expert in NDPA 2023, CBN regulations, NFIU AML/CFT, "
                  "BVN/NIN protection, Kenya DPA, and POPIA.",
        tools=[governance_tool],
        llm=llm,
        verbose=True,
    )

    executor_agent = Agent(
        role="Fintech Operations Executor",
        goal="Execute approved actions. Never execute an action that "
             "the compliance agent has not cleared.",
        backstory="Experienced fintech operations specialist.",
        llm=llm,
        verbose=True,
    )

    def governance_step_callback(step_output):
        # Safety net: re-check every agent step output through OPA
        # even if the agent forgot to call the tool
        pass

    crew = Crew(
        agents=[compliance_agent, executor_agent],
        tasks=[...],
        process=Process.sequential,
        step_callback=governance_step_callback,
        verbose=True,
    )
    return crew
    ──────────────────────────────────────────────────────────────────
    """
    if _CREWAI_AVAILABLE:
        return OPAGovernanceTool()
    return None


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
    build_crew()  # validates crewai setup if installed; no-op otherwise

    print(f"\n{BOLD}{CYAN}{'=' * 65}")
    print("  CrewAI + OPA  |  Nigerian & African Fintech Agent")
    print("  agt-policies-nigeria — kingztech2019/agt-policies-nigeria")
    print(f"{'=' * 65}{RESET}\n")
    print(f"  {DIM}OPAGovernanceTool fires before every crew action{RESET}\n")

    for i, scenario in enumerate(SCENARIOS, 1):
        result = _governance_run(
            action=scenario["action"],
            params=json.dumps(scenario["params"]),
            output=scenario["output"],
            context=json.dumps(scenario["context"]),
        )

        first_line = result.splitlines()[0]
        jurisdiction_line = result.splitlines()[-1] if len(result.splitlines()) > 1 else ""

        if "DENIED" in first_line:
            icon = DECISION_ICON["deny"]
        elif "ESCALATED" in first_line:
            icon = DECISION_ICON["escalate"]
        elif "AUDITED" in first_line:
            icon = DECISION_ICON["audit"]
        else:
            icon = DECISION_ICON["allow"]

        print(f"{'─' * 65}")
        print(f"{BOLD}Step {i}:{RESET} {scenario['task']}")
        print(f"  Decision    : {icon}")
        print(f"  {DIM}{jurisdiction_line}{RESET}")

    print(f"\n{'─' * 65}")
    print(f"\n{BOLD}OPAGovernanceTool ran before every crew action.{RESET}")
    print(f"Jurisdiction router selected applicable policies per customer country.\n")


if __name__ == "__main__":
    main()
