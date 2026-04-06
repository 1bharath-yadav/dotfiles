"""Agent management commands.

All SDK calls taken directly from letta-api-client skill examples.
No getattr/hasattr/isinstance — access SDK object fields directly.
"""

from __future__ import annotations

from letta_client import Letta
from letta_client import APIStatusError as ApiError

from letta_assistant.services import letta_service as svc
from letta_assistant.utils import state


# ── helpers ──────────────────────────────────────────────────────────────────

def _agents_list(client: Letta) -> list:
    """Return flat list of agents from client.agents.list()."""
    page = client.agents.list()
    # SDK returns iterable page; collect once
    return list(page)


def _resolve(ref: str, agents: list):
    """Find agent by 1-based index, exact id, or name (case-insensitive)."""
    ref = ref.strip()
    try:
        idx = int(ref) - 1
        if 0 <= idx < len(agents):
            return agents[idx]
    except ValueError:
        pass
    for a in agents:
        if a.id == ref:
            return a
    ref_lo = ref.lower()
    for a in agents:
        if a.name and a.name.lower() == ref_lo:
            return a
    return None


# ── /agents list ─────────────────────────────────────────────────────────────

def cmd_agents_list(client: Letta, args: str = "") -> str:
    """List all agents.
    Usage: /agents [--pinned]
    """
    try:
        agents = _agents_list(client)
    except ApiError as e:
        return f"[ERROR] {e.status_code}: {e.message}"

    if not agents:
        return "[AGENTS] None found. Use /new <name> to create one."

    saved = state.load_state()
    active_id = saved.get("agent_id", "")

    lines = [f"[AGENTS] {len(agents)}"]
    for i, a in enumerate(agents, 1):
        active = " ◀ active" if a.id == active_id else ""
        lines.append(f"  {i}. {a.name}  id={a.id}  model={a.model}{active}")

    lines.append("\nUse /use <index|name|id> to switch.")
    return "\n".join(lines)


# ── /new ─────────────────────────────────────────────────────────────────────

def cmd_new_agent(client: Letta, args: str = "") -> str:
    """Create a new agent and immediately activate it.
    Usage: /new <name> [--model <provider/model>]
    """
    if not args.strip():
        return "Usage: /new <name> [--model anthropic/claude-sonnet-4-5-20250929]"

    parts = args.split()
    name = parts[0]
    model_id = None

    if "--model" in parts:
        mi = parts.index("--model")
        if mi + 1 < len(parts):
            model_id = parts[mi + 1]

    if not model_id:
        saved = state.load_state()
        model_id = saved.get("model_id")

    if not model_id:
        return (
            "[ERROR] No model specified and none saved.\n"
            "Usage: /new <name> --model <provider/model>\n"
            "Run /models to list options."
        )

    try:
        # Matches example 02_create_agent.py
        agent = client.agents.create(
            name=name,
            model=model_id,
            embedding="openai/text-embedding-3-small",
            memory_blocks=[
                {"label": "persona", "value": "I am a helpful assistant."},
                {"label": "human", "value": "User information will be stored here."},
            ],
        )
        conv = client.conversations.create(agent_id=agent.id)
        state.save_state(agent.id, conv.id, model_id)
        return (
            f"[OK] Created '{agent.name}'\n"
            f"  id={agent.id}\n"
            f"  model={agent.model}\n"
            f"  conversation={conv.id}\n"
            f"Now active."
        )
    except ApiError as e:
        return f"[ERROR] {e.status_code}: {e.message}"


# ── /use ─────────────────────────────────────────────────────────────────────

def cmd_use_agent(client: Letta, args: str = "") -> str:
    """Switch active agent, creating a fresh conversation.
    Usage: /use <index|name|id>
    """
    ref = args.strip()
    if not ref:
        return "Usage: /use <index|name|id>"

    try:
        agents = _agents_list(client)
    except ApiError as e:
        return f"[ERROR] {e.status_code}: {e.message}"

    agent = _resolve(ref, agents)
    if not agent:
        return f"[ERROR] Agent not found: '{ref}'. Run /agents to list."

    try:
        conv = client.conversations.create(agent_id=agent.id)
        state.save_state(agent.id, conv.id, agent.model)
        return (
            f"[OK] Switched to '{agent.name}'\n"
            f"  id={agent.id}  model={agent.model}\n"
            f"  new conversation={conv.id}"
        )
    except ApiError as e:
        return f"[ERROR] {e.status_code}: {e.message}"


# ── /retrieve ─────────────────────────────────────────────────────────────────

def cmd_retrieve(client: Letta, args: str = "") -> str:
    """Show full agent detail.
    Usage: /retrieve <index|name|id>
    """
    ref = args.strip()
    if not ref:
        return "Usage: /retrieve <index|name|id>"

    try:
        agents = _agents_list(client)
        obj = _resolve(ref, agents)
        if not obj:
            return f"[ERROR] Agent not found: '{ref}'"
        agent = client.agents.retrieve(agent_id=obj.id)
    except ApiError as e:
        return f"[ERROR] {e.status_code}: {e.message}"

    lines = [
        "[AGENT]",
        f"  name  = {agent.name}",
        f"  id    = {agent.id}",
        f"  model = {agent.model}",
    ]
    if agent.description:
        lines.append(f"  desc  = {agent.description}")
    if agent.tags:
        lines.append(f"  tags  = {', '.join(agent.tags)}")
    return "\n".join(lines)


# ── /update ──────────────────────────────────────────────────────────────────

def cmd_update(client: Letta, args: str = "") -> str:
    """Update agent name or description.
    Usage: /update <index|name|id> --name <n> | --desc <text>
    """
    parts = args.split(maxsplit=1)
    if not parts:
        return "Usage: /update <index|name|id> --name <n> | --desc <text>"

    ref, rest = parts[0], (parts[1] if len(parts) > 1 else "")

    try:
        agents = _agents_list(client)
        obj = _resolve(ref, agents)
        if not obj:
            return f"[ERROR] Agent not found: '{ref}'"
    except ApiError as e:
        return f"[ERROR] {e.status_code}: {e.message}"

    kwargs: dict = {}
    for token in rest.split("--"):
        token = token.strip()
        if not token:
            continue
        sp = token.split(maxsplit=1)
        key = sp[0].strip()
        val = sp[1].strip().strip('"').strip("'") if len(sp) > 1 else ""
        if key == "name":
            kwargs["name"] = val
        elif key in ("desc", "description"):
            kwargs["description"] = val

    if not kwargs:
        return "Provide --name or --desc"

    try:
        agent = client.agents.update(agent_id=obj.id, **kwargs)
        changed = ", ".join(f"{k}={v!r}" for k, v in kwargs.items())
        return f"[OK] Updated '{agent.name}': {changed}"
    except ApiError as e:
        return f"[ERROR] {e.status_code}: {e.message}"


# ── /delete ──────────────────────────────────────────────────────────────────

def cmd_delete(client: Letta, args: str = "") -> str:
    """Delete an agent (prompts confirmation).
    Usage: /delete <index|name|id>
    """
    ref = args.strip()
    if not ref:
        return "Usage: /delete <index|name|id>"

    try:
        agents = _agents_list(client)
        obj = _resolve(ref, agents)
        if not obj:
            return f"[ERROR] Agent not found: '{ref}'"
    except ApiError as e:
        return f"[ERROR] {e.status_code}: {e.message}"

    try:
        confirm = input(f"Delete '{obj.name}' ({obj.id})? [y/N] ").strip().lower()
    except (EOFError, KeyboardInterrupt):
        return "[CANCELLED]"

    if confirm != "y":
        return "[CANCELLED]"

    try:
        client.agents.delete(agent_id=obj.id)
        saved = state.load_state()
        if saved.get("agent_id") == obj.id:
            state.clear_state()
        return f"[OK] Deleted '{obj.name}'"
    except ApiError as e:
        return f"[ERROR] {e.status_code}: {e.message}"


# ── /pin / /unpin ─────────────────────────────────────────────────────────────
# Letta Cloud supports pinning via client.agents.update(pinned=True/False)

def cmd_pin(client: Letta, args: str = "") -> str:
    """Pin an agent (keeps it at top of list).
    Usage: /pin <index|name|id>
    """
    ref = args.strip()
    if not ref:
        return "Usage: /pin <index|name|id>"

    try:
        agents = _agents_list(client)
        obj = _resolve(ref, agents)
        if not obj:
            return f"[ERROR] Agent not found: '{ref}'"
        client.agents.update(agent_id=obj.id, pinned=True)
        return f"[OK] Pinned '{obj.name}'"
    except ApiError as e:
        return f"[ERROR] {e.status_code}: {e.message}"


def cmd_unpin(client: Letta, args: str = "") -> str:
    """Unpin an agent.
    Usage: /unpin <index|name|id>
    """
    ref = args.strip()
    if not ref:
        return "Usage: /unpin <index|name|id>"

    try:
        agents = _agents_list(client)
        obj = _resolve(ref, agents)
        if not obj:
            return f"[ERROR] Agent not found: '{ref}'"
        client.agents.update(agent_id=obj.id, pinned=False)
        return f"[OK] Unpinned '{obj.name}'"
    except ApiError as e:
        return f"[ERROR] {e.status_code}: {e.message}"
