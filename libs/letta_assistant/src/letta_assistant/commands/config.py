"""Configuration: /system, /sleeptime, /init, /doctor, /statusline, /config"""

from __future__ import annotations

from letta_client import Letta
from letta_client import APIStatusError as ApiError

from letta_assistant.services import letta_service as svc
from letta_assistant import config as app_cfg

# ===== /config =====

_SETTABLE_KEYS = {"base_url", "embedding_model", "embedding_endpoint"}


def cmd_config(client: Letta, agent_id: str, args: str = "") -> str:
    """View or set persistent app config.

    /config                       — show all config
    /config show                  — same
    /config set <key> <value>     — persist a value
    /config unset <key>           — revert to default

    Keys: base_url · embedding_model · embedding_endpoint
    Note: api_key is read-only (set via LETTA_API_KEY env or keyring).
    """
    parts = args.strip().split(maxsplit=2)
    sub = parts[0].lower() if parts else ""

    if not sub or sub == "show":
        return app_cfg.show()

    if sub == "set":
        if len(parts) < 3:
            return "Usage: /config set <key> <value>\nKeys: " + " · ".join(sorted(_SETTABLE_KEYS))
        key, value = parts[1].lower(), parts[2]
        if key not in _SETTABLE_KEYS:
            return f"[ERROR] Unknown key '{key}'. Valid: {', '.join(sorted(_SETTABLE_KEYS))}"
        app_cfg.set_key(key, value)
        return f"[OK] Set {key} = {value}\n  Restart assistant for base_url changes to take effect."

    if sub == "unset":
        if len(parts) < 2:
            return "Usage: /config unset <key>"
        key = parts[1].lower()
        if key not in _SETTABLE_KEYS:
            return f"[ERROR] Unknown key '{key}'. Valid: {', '.join(sorted(_SETTABLE_KEYS))}"
        app_cfg.unset_key(key)
        return f"[OK] Unset {key} (reverted to default)."

    return (
        "Usage:\n"
        "  /config                  show all config\n"
        "  /config set <key> <val>  persist a value\n"
        "  /config unset <key>      revert to default\n"
        "Keys: base_url · embedding_model · embedding_endpoint"
    )
# ===== /system =====

def cmd_system(client: Letta, agent_id: str, args: str = "") -> str:
    """View or update the agent system prompt.

    /system          — show current system prompt
    /system <text>   — replace with <text>
    """
    if not agent_id:
        return "[ERROR] No active agent. Use /resume <id> first."

    if not args.strip():
        try:
            agent = client.agents.retrieve(agent_id)
            prompt = agent.system or "(none)"
            return f"[SYSTEM]\n{prompt}"
        except ApiError as e:
            return f"[ERROR] {e.status_code}: {e.body}"

    try:
        client.agents.update(agent_id=agent_id, system=args.strip())
        return "[OK] System prompt updated."
    except ApiError as e:
        return f"[ERROR] {e.status_code}: {e.body}"


# ===== /sleeptime =====

def cmd_sleeptime(client: Letta, agent_id: str, args: str = "") -> str:
    """Configure or inspect background sleeptime processing.

    /sleeptime              — show current status
    /sleeptime on           — enable sleeptime agent
    /sleeptime off          — disable sleeptime agent
    /sleeptime freq <n>     — set run frequency (every n conversations)
    """
    if not agent_id:
        return "[ERROR] No active agent. Use /resume <id> first."

    parts = args.strip().split(maxsplit=1)
    sub = parts[0] if parts else ""

    if sub == "on":
        try:
            client.agents.update(agent_id=agent_id, enable_sleeptime=True)
            return "[OK] Sleeptime enabled."
        except ApiError as e:
            return f"[ERROR] {e.status_code}: {e.body}"

    if sub == "off":
        try:
            client.agents.update(agent_id=agent_id, enable_sleeptime=False)
            return "[OK] Sleeptime disabled."
        except ApiError as e:
            return f"[ERROR] {e.status_code}: {e.body}"

    if sub == "freq":
        if len(parts) < 2 or not parts[1].strip().isdigit():
            return "Usage: /sleeptime freq <n>"
        n = int(parts[1].strip())
        try:
            client.agents.update(agent_id=agent_id, sleeptime_agent_frequency=n)
            return f"[OK] Sleeptime frequency set to {n}."
        except ApiError as e:
            return f"[ERROR] {e.status_code}: {e.body}"

    if sub and sub not in ("on", "off", "freq"):
        return "Usage: /sleeptime [on|off|freq <n>]"

    # /sleeptime — show status
    try:
        agent = client.agents.retrieve(agent_id)
        enabled = agent.enable_sleeptime
        freq = agent.sleeptime_agent_frequency
        status = "enabled" if enabled else "disabled"
        lines = [
            f"[SLEEPTIME] {status}",
            f"  enable_sleeptime:          {enabled}",
            f"  sleeptime_agent_frequency: {freq}",
        ]
        return "\n".join(lines)
    except ApiError as e:
        return f"[ERROR] {e.status_code}: {e.body}"


# ===== /doctor =====

_BLOCK_WARN_CHARS = 4000

def cmd_doctor(client: Letta, agent_id: str, args: str = "") -> str:
    """Full agent health check: agent info, blocks, tools, passage count.

    /doctor
    """
    if not agent_id:
        return "[ERROR] No active agent. Use /resume <id> first."

    lines = ["[DOCTOR]"]

    # Agent summary
    try:
        agent = client.agents.retrieve(agent_id)
        lines.append(f"  name:  {agent.name}")
        lines.append(f"  id:    {agent.id}")
        lines.append(f"  model: {agent.model}")
    except ApiError as e:
        return f"[ERROR] retrieving agent: {e.status_code}: {e.body}"

    # Memory blocks
    try:
        blocks = list(client.agents.blocks.list(agent_id=agent_id))
        lines.append(f"\n  blocks: {len(blocks)}")
        for block in blocks:
            chars = len(block.value)
            warn = "  [WARN] near limit" if chars >= _BLOCK_WARN_CHARS else ""
            lines.append(f"    • {block.label:<20}  {chars:>5} chars{warn}")
    except ApiError as e:
        lines.append(f"  blocks: [ERROR] {e.status_code}: {e.body}")

    # Attached tools
    try:
        tools = list(client.agents.tools.list(agent_id))
        lines.append(f"\n  tools: {len(tools)}")
        for tool in tools:
            lines.append(f"    • {tool.name}")
    except ApiError as e:
        lines.append(f"  tools: [ERROR] {e.status_code}: {e.body}")

    # Archival passages (count via limit=1000; report total seen)
    try:
        passages = list(client.agents.passages.list(agent_id=agent_id, limit=1000))
        lines.append(f"\n  passages: {len(passages)}")
    except ApiError as e:
        lines.append(f"  passages: [ERROR] {e.status_code}: {e.body}")

    return "\n".join(lines)


# ===== /init =====

def cmd_init(client: Letta, agent_id: str, args: str = "") -> str:
    """Reset agent message history to clean defaults.

    /init   — confirm then wipe all messages via agents.messages.reset()
    """
    if not agent_id:
        return "[ERROR] No active agent. Use /resume <id> first."

    # Count messages before reset
    try:
        before = list(client.agents.messages.list(agent_id=agent_id, limit=1000))
        before_count = len(before)
    except ApiError as e:
        return f"[ERROR] Could not read messages: {e.status_code}: {e.body}"

    try:
        confirm = input(
            f"Reset all {before_count} messages for agent {agent_id}? [y/N] "
        ).strip().lower()
    except (EOFError, KeyboardInterrupt):
        return "[CANCELLED]"

    if confirm != "y":
        return "[CANCELLED]"

    try:
        client.agents.messages.reset(agent_id=agent_id)
    except ApiError as e:
        return f"[ERROR] {e.status_code}: {e.body}"

    return f"[OK] Reset complete. {before_count} message(s) cleared."


# ===== /statusline =====

def cmd_statusline(client: Letta, agent_id: str, args: str = "") -> str:
    """List available models. Usage: /statusline"""
    try:
        page = client.models.list()
        models = list(page.items)
    except ApiError as e:
        return f"[ERROR] {e.status_code}: {e.body}"

    if not models:
        return "[MODELS] No models available."

    lines = [f"[MODELS] {len(models)} available"]
    for model in models:
        lines.append(f"  • {model.identifier}")
    return "\n".join(lines)
