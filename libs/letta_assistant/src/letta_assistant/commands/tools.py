"""Tool management: /tools, /attached, /attach, /detach"""

from __future__ import annotations

from letta_client import Letta
from letta_client import APIStatusError as ApiError


# ===== INDEX RESOLUTION =====

def _resolve_tool(ref: str, tools: list) -> tuple:
    """Resolve a 1-based index or name string to a tool object.

    Returns (tool, None) on success, (None, error_str) on failure.
    """
    if ref.isdigit():
        idx = int(ref) - 1
        if idx < 0 or idx >= len(tools):
            return None, f"[ERROR] Index {ref} out of range (1–{len(tools)})."
        return tools[idx], None
    matches = [t for t in tools if t.name.lower() == ref.lower()]
    if not matches:
        return None, f"[ERROR] No tool named '{ref}'."
    return matches[0], None


# ===== /tools =====

def cmd_tools_list(client: Letta, args: str = "") -> str:
    """List all tools or show detail for one.

    /tools                 — index, name, description[:60]
    /tools <index|name>    — full detail (name, description, source_code preview)
    """
    ref = args.strip()
    try:
        page = client.tools.list()
        tools = list(page.items)
    except ApiError as e:
        return f"[ERROR] {e.status_code}: {e.body}"

    if not tools:
        return "No tools available."

    if ref:
        tool, err = _resolve_tool(ref, tools)
        if err:
            return err
        src_preview = ""
        if tool.source_code:
            lines = tool.source_code.strip().splitlines()
            src_preview = "\n".join(lines[:10])
            if len(lines) > 10:
                src_preview += f"\n  ... ({len(lines) - 10} more lines)"
        return (
            f"[TOOL] {tool.name}\n"
            f"  id:          {tool.id}\n"
            f"  description: {tool.description or '(none)'}\n"
            f"  source:\n{src_preview}"
        )

    lines = [f"[TOOLS] {len(tools)} available"]
    for i, tool in enumerate(tools, 1):
        desc = (tool.description or "")[:60]
        lines.append(f"  {i:>2}.  {tool.name:<28}  {desc}")
    return "\n".join(lines)


# ===== /attached =====

def cmd_attached(client: Letta, agent_id: str, args: str = "") -> str:
    """List tools attached to the active agent.

    /attached
    """
    if not agent_id:
        return "[ERROR] No active agent. Use /resume <id> first."
    try:
        tools = list(client.agents.tools.list(agent_id))
    except ApiError as e:
        return f"[ERROR] {e.status_code}: {e.body}"

    if not tools:
        return "No tools attached to this agent."

    lines = [f"[ATTACHED] {len(tools)} tool(s)"]
    for i, tool in enumerate(tools, 1):
        desc = (tool.description or "")[:60]
        lines.append(f"  {i:>2}.  {tool.name:<28}  {desc}")
    return "\n".join(lines)


# ===== /attach =====

def cmd_attach_tool(client: Letta, agent_id: str, args: str = "") -> str:
    """Attach a tool from the global list to the active agent.

    /attach <index|name>   — resolves from /tools list
    """
    if not agent_id:
        return "[ERROR] No active agent. Use /resume <id> first."
    ref = args.strip()
    if not ref:
        return "Usage: /attach <index|name>"

    try:
        page = client.tools.list()
        tools = list(page.items)
    except ApiError as e:
        return f"[ERROR] {e.status_code}: {e.body}"

    tool, err = _resolve_tool(ref, tools)
    if err:
        return err

    try:
        client.agents.tools.attach(agent_id=agent_id, tool_id=tool.id)
    except ApiError as e:
        return f"[ERROR] {e.status_code}: {e.body}"

    return f"[OK] Attached '{tool.name}' (id={tool.id})."


# ===== /detach =====

def cmd_detach_tool(client: Letta, agent_id: str, args: str = "") -> str:
    """Detach a tool from the active agent.

    /detach <index|name>   — resolves from /attached list
    """
    if not agent_id:
        return "[ERROR] No active agent. Use /resume <id> first."
    ref = args.strip()
    if not ref:
        return "Usage: /detach <index|name>"

    try:
        tools = list(client.agents.tools.list(agent_id))
    except ApiError as e:
        return f"[ERROR] {e.status_code}: {e.body}"

    tool, err = _resolve_tool(ref, tools)
    if err:
        return err

    try:
        client.agents.tools.detach(agent_id=agent_id, tool_id=tool.id)
    except ApiError as e:
        return f"[ERROR] {e.status_code}: {e.body}"

    return f"[OK] Detached '{tool.name}' (id={tool.id})."
