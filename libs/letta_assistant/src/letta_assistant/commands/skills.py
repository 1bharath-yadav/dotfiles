"""Skills & MCP commands: /mcp, /secret, /skill"""

from __future__ import annotations

from letta_client import Letta


# ===== MCP SERVERS COMMAND =====

def cmd_mcp(client: Letta, args: str = "") -> str:
    """Manage MCP servers. Usage: /mcp [list|tools]"""
    subcommand = args.split()[0] if args.strip() else "list"
    
    try:
        if subcommand == "list":
            response = client.mcp_servers.list()
            if not response.items or len(response.items) == 0:
                return "[MCP_SERVERS] No MCP servers connected."
            lines = ["[MCP_SERVERS] Connected MCP Servers:"]
            for server in response.items:
                lines.append(f"  • {server.name} (ID: {server.id}, Status: {server.status})")
            return "\n".join(lines)
        elif subcommand == "tools":
            response = client.mcp_servers.list()
            if not response.items or len(response.items) == 0:
                return "[MCP_TOOLS] No MCP servers connected."
            lines = ["[MCP_TOOLS] Available Tools:"]
            for server in response.items:
                try:
                    tools_response = client.mcp_servers.tools.list(mcp_server_id=server.id)
                    if tools_response.items and len(tools_response.items) > 0:
                        for tool in tools_response.data:
                            lines.append(f"  • {tool.name} (via {server.name})")
                            if tool.description:
                                lines.append(f"      {tool.description}")
                except Exception:
                    pass
            return "\n".join(lines) if len(lines) > 1 else "[MCP_TOOLS] No tools found."
        else:
            return "Usage: /mcp [list|tools]"
    except Exception as e:
        return f"[ERROR] MCP Error: {str(e)}"


# ===== SECRETS COMMAND =====

def cmd_secret(client: Letta, args: str = "") -> str:
    """Manage secrets. Usage: /secret [list|set|delete]"""
    subcommand = args.split()[0] if args.strip() else "list"
    
    try:
        if subcommand == "list":
            response = client.secrets.list()
            if not response.items or len(response.items) == 0:
                return "[SECRETS] No secrets stored."
            lines = ["[SECRETS] Stored Secrets:"]
            for secret in response.items:
                lines.append(f"  • {secret.name} (ID: {secret.id})")
            return "\n".join(lines)
        elif subcommand == "set":
            parts = args.split(maxsplit=2)
            if len(parts) < 3:
                return "Usage: /secret set <name> <value>"
            _, name, value = parts[0], parts[1], " ".join(parts[2:])
            client.secrets.create(name=name, value=value)
            return f"[OK] Secret '{name}' created."
        elif subcommand == "delete":
            parts = args.split(maxsplit=1)
            if len(parts) < 2:
                return "Usage: /secret delete <secret_id>"
            secret_id = parts[1]
            client.secrets.delete(secret_id)
            return f"[OK] Secret deleted."
        else:
            return "Usage: /secret [list|set|delete]"
    except Exception as e:
        return f"[ERROR] Secret Error: {str(e)}"


# ===== SKILL COMMAND =====

def cmd_skill(client: Letta, agent_id: str, args: str = "") -> str:
    """Create custom skill. Usage: /skill <description>"""
    if not agent_id:
        return "[ERROR] No active agent. Use /resume <id> first."
    if not args.strip():
        return "Usage: /skill <description>"
    
    description = args.strip()
    return f"[SKILLS] Skill mode entered.\nDescription: {description}\n(Interactive mode - generate function code)"


# ===== SKILLS LIST COMMAND =====

def cmd_skills_list(client: Letta, args: str = "") -> str:
    """List available skills/tools. Usage: /skills"""
    try:
        response = client.tools.list()
        if not response.items or len(response.items) == 0:
            return "[SKILLS] No tools available."
        lines = ["[SKILLS] Available Tools:"]
        for tool in response.items:
            lines.append(f"  • {tool.name}")
            if tool.description:
                lines.append(f"      {tool.description}")
        return "\n".join(lines)
    except Exception as e:
        return f"[ERROR] Skills Error: {str(e)}"
