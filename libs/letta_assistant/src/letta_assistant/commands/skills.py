"""Skills & MCP commands: /mcp, /secret, /skill, /skills"""

from __future__ import annotations

from letta_client import Letta
from letta_client import APIStatusError as ApiError


# ===== MCP INDEX RESOLUTION =====

def _resolve_server(ref: str, servers: list) -> tuple:
    """Resolve 1-based index or name to an MCP server object.

    Returns (server, None) on success, (None, error_str) on failure.
    """
    if ref.isdigit():
        idx = int(ref) - 1
        if idx < 0 or idx >= len(servers):
            return None, f"[ERROR] Index {ref} out of range (1–{len(servers)})."
        return servers[idx], None
    matches = [s for s in servers if s.name.lower() == ref.lower()]
    if not matches:
        return None, f"[ERROR] No MCP server named '{ref}'."
    return matches[0], None


# ===== /mcp =====

def cmd_mcp(client: Letta, agent_id: str, args: str = "") -> str:
    """Manage MCP servers and tools.

    /mcp list                              — list all MCP servers
    /mcp tools <server_index|name>         — list tools on a server
    /mcp attach <server_index|name> <tool> — attach MCP tool to active agent
    """
    parts = args.strip().split(maxsplit=2)
    sub = parts[0] if parts else "list"

    # /mcp list
    if sub == "list":
        try:
            servers = list(client.mcp_servers.list())
        except ApiError as e:
            return f"[ERROR] {e.status_code}: {e.body}"
        if not servers:
            return "[MCP] No MCP servers connected."
        lines = [f"[MCP] {len(servers)} server(s)"]
        for i, s in enumerate(servers, 1):
            lines.append(f"  {i:>2}.  {s.name:<24}  {s.server_type:<12}  {s.url or ''}")
        return "\n".join(lines)

    # /mcp tools <server>
    if sub == "tools":
        if len(parts) < 2:
            return "Usage: /mcp tools <server_index|name>"
        try:
            servers = list(client.mcp_servers.list())
        except ApiError as e:
            return f"[ERROR] {e.status_code}: {e.body}"
        server, err = _resolve_server(parts[1], servers)
        if err:
            return err
        try:
            tools = list(client.mcp_servers.tools.list(mcp_server_id=server.id))
        except ApiError as e:
            return f"[ERROR] {e.status_code}: {e.body}"
        if not tools:
            return f"[MCP] No tools on '{server.name}'."
        lines = [f"[MCP] Tools on '{server.name}': {len(tools)}"]
        for tool in tools:
            lines.append(f"  • {tool.name}")
        return "\n".join(lines)

    # /mcp attach <server> <tool_name>
    if sub == "attach":
        if not agent_id:
            return "[ERROR] No active agent. Use /resume <id> first."
        if len(parts) < 3:
            return "Usage: /mcp attach <server_index|name> <tool_name>"
        try:
            servers = list(client.mcp_servers.list())
        except ApiError as e:
            return f"[ERROR] {e.status_code}: {e.body}"
        server, err = _resolve_server(parts[1], servers)
        if err:
            return err
        tool_name = parts[2]
        try:
            client.agents.tools.attach_mcp_tool(
                agent_id,
                server_name=server.name,
                tool_name=tool_name,
            )
        except ApiError as e:
            return f"[ERROR] {e.status_code}: {e.body}"
        return f"[OK] Attached MCP tool '{tool_name}' from '{server.name}'."

    return "Usage: /mcp [list|tools <server>|attach <server> <tool>]"


# ===== /secret =====

def cmd_secret(client: Letta, args: str = "") -> str:
    """Manage Letta secrets (never shows values).

    /secret list             — list secret names only
    /secret set <name> <val> — create or overwrite a secret
    """
    parts = args.strip().split(maxsplit=2)
    sub = parts[0] if parts else "list"

    if sub == "list":
        try:
            secrets = list(client.secrets.list())
        except ApiError as e:
            return f"[ERROR] {e.status_code}: {e.body}"
        if not secrets:
            return "[SECRETS] No secrets stored."
        lines = [f"[SECRETS] {len(secrets)} secret(s)"]
        for s in secrets:
            lines.append(f"  • {s.name}")
        return "\n".join(lines)

    if sub == "set":
        if len(parts) < 3:
            return "Usage: /secret set <name> <value>"
        name, value = parts[1], parts[2]
        try:
            client.secrets.create(name=name, value=value)
        except ApiError as e:
            return f"[ERROR] {e.status_code}: {e.body}"
        return f"[OK] Secret '{name}' stored."

    return "Usage: /secret [list|set <name> <value>]"


# ===== /skill create =====

def cmd_skill(client: Letta, args: str = "") -> str:
    """Create a custom tool from interactively entered source code.

    /skill create <name>   — prompts for multiline source until EOF (Ctrl-D)

    Requirements enforced before upload:
      - function named <name>
      - docstring present with an Args: section
      - all imports inside the function body
    """
    parts = args.strip().split(maxsplit=1)
    if not parts or parts[0] != "create":
        return "Usage: /skill create <name>"
    if len(parts) < 2:
        return "Usage: /skill create <name>"

    func_name = parts[1].strip()
    print(f"Enter source code for '{func_name}' (Ctrl-D to finish):\n")

    lines = []
    try:
        while True:
            line = input()
            lines.append(line)
    except EOFError:
        pass

    source_code = "\n".join(lines).strip()

    # --- validation ---
    if not source_code:
        return "[ERROR] No source code entered."

    if f"def {func_name}" not in source_code:
        return f"[ERROR] Source must define a function named '{func_name}'."

    if '"""' not in source_code and "'''" not in source_code:
        return "[ERROR] Function must have a docstring."

    if "Args:" not in source_code:
        return "[ERROR] Docstring must contain an Args: section (required for schema generation)."

    # check imports are inside the function, not at top level
    top_lines = [ln for ln in source_code.splitlines()
                 if ln.startswith("import ") or ln.startswith("from ")]
    if top_lines:
        return (
            "[ERROR] Top-level imports detected — move all imports inside the function body.\n"
            + "\n".join(f"  {ln}" for ln in top_lines)
        )

    try:
        tool = client.tools.create(source_code=source_code)
    except ApiError as e:
        return f"[ERROR] {e.status_code}: {e.body}"

    return f"[OK] Tool '{tool.name}' created (id={tool.id})."


# ===== /skills =====

def cmd_skills_list(client: Letta, args: str = "") -> str:
    """List all custom tools (skills) registered on the server.

    /skills              — list all tools (index, name, description)
    /skills <filter>     — filter by partial name match
    """
    filter_text = args.strip().lower()
    try:
        tools = list(client.tools.list())
    except ApiError as e:
        return f"[ERROR] {e.status_code}: {e.body}"

    if not tools:
        return "[SKILLS] No custom tools registered."

    if filter_text:
        tools = [t for t in tools if filter_text in t.name.lower()]
        if not tools:
            return f"[SKILLS] No tools matching '{filter_text}'."

    lines = [f"[SKILLS] {len(tools)} tool(s)"]
    for i, t in enumerate(tools, 1):
        desc = (t.description or "")[:60]
        lines.append(f"  {i:>2}.  {t.name:<32}  {desc}")
    return "\n".join(lines)
