"""Tool management: /tools, /attached, /attach, /detach"""

from letta_client import Letta
from letta_assistant.services import letta_service as svc


def cmd_attached(client: Letta, agent_id: str, args: str = "") -> str:
    """List attached tools. Usage: /attached"""
    if not agent_id:
        return "[ERROR] No active agent. Use /resume <id> first."
    
    page = svc.get_tools(client, agent_id)
    if not page.items:
        return "No tools attached."
    
    lines = ["[ATTACHED TOOLS]"]
    for tool in page.items:
        lines.append(f"  {tool.name}: {tool.description[:50]}")
    return "\n".join(lines)


def cmd_tools_list(client: Letta, args: str = "") -> str:
    """List all available tools. Usage: /tools"""
    page = client.tools.list()
    if not page.items:
        return "No tools available."
    
    lines = ["[AVAILABLE TOOLS]"]
    for tool in page.items:
        lines.append(f"  {tool.name}: {tool.description[:50]}")
    return "\n".join(lines)


def cmd_attach_tool(client: Letta, agent_id: str, args: str = "") -> str:
    """Attach tool. Usage: /attach <tool_id>"""
    if not agent_id:
        return "[ERROR] No active agent."
    if not args.strip():
        return "Usage: /attach <tool_id>"
    
    tool_id = args.strip()
    svc.attach_tool(client, agent_id, tool_id)
    return f"[OK] Attached: {tool_id}"


def cmd_detach_tool(client: Letta, agent_id: str, args: str = "") -> str:
    """Detach tool. Usage: /detach <tool_id>"""
    if not agent_id:
        return "[ERROR] No active agent."
    if not args.strip():
        return "Usage: /detach <tool_id>"
    
    tool_id = args.strip()
    svc.detach_tool(client, agent_id, tool_id)
    return f"[OK] Detached: {tool_id}"
