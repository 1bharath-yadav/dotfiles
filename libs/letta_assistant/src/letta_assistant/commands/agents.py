"""Agent management: /agents, /new, /retrieve, /update, /delete, /pin, /unpin"""

from letta_client import Letta


def cmd_agents_list(client: Letta, args: str = "") -> str:
    """List all agents. Usage: /agents"""
    page = client.agents.list()
    lines = ["[AGENTS]"]
    for agent in page.items:
        lines.append(f"  {agent.name} (ID: {agent.id}, model: {agent.model})")
    return "\n".join(lines) if page.items else "No agents found"


def cmd_new_agent(client: Letta, args: str = "") -> str:
    """Create agent. Usage: /new <name>"""
    name = args.strip()
    if not name:
        return "Usage: /new <agent_name>"
    agent = client.agents.create(name=name)
    return f"[OK] Created: {agent.name} (ID: {agent.id})"


def cmd_retrieve(client: Letta, args: str = "") -> str:
    """Get agent. Usage: /retrieve <agent_id>"""
    agent_id = args.strip()
    if not agent_id:
        return "Usage: /retrieve <agent_id>"
    agent = client.agents.retrieve(agent_id=agent_id)
    return f"Agent: {agent.name}\nID: {agent.id}\nModel: {agent.model}"


def cmd_update(client: Letta, args: str = "") -> str:
    """Update agent. Usage: /update <agent_id> --name <name> --system <prompt>"""
    parts = args.split(maxsplit=1)
    if not parts:
        return "Usage: /update <agent_id> --name <name>"
    agent_id = parts[0]
    kwargs = {}
    if len(parts) > 1:
        # Parse flags like --name "New Name"
        rest = parts[1]
        while "--" in rest:
            idx = rest.index("--")
            rest = rest[idx+2:].strip()
            key_end = rest.find(" ") if " " in rest else len(rest)
            key = rest[:key_end].strip()
            rest = rest[key_end:].strip()
            if rest.startswith('"'):
                val_end = rest.find('"', 1)
                val = rest[1:val_end] if val_end > 0 else rest[1:]
                rest = rest[val_end+1:].strip()
            else:
                val = rest.split()[0] if rest else ""
                rest = rest[len(val):].strip()
            kwargs[key] = val
    if not kwargs:
        return "Provide --name or --system flags"
    agent = client.agents.update(agent_id=agent_id, **kwargs)
    return f"[OK] Updated: {agent.name}"


def cmd_delete(client: Letta, args: str = "") -> str:
    """Delete agent. Usage: /delete <agent_id>"""
    agent_id = args.strip()
    if not agent_id:
        return "Usage: /delete <agent_id>"
    client.agents.delete(agent_id=agent_id)
    return f"[OK] Deleted agent {agent_id}"


def cmd_pin(client: Letta, args: str = "") -> str:
    """Pin agent. Usage: /pin <agent_id>"""
    agent_id = args.strip()
    if not agent_id:
        return "Usage: /pin <agent_id>"
    return f"[PENDING] Pin not yet implemented in SDK for {agent_id}"


def cmd_unpin(client: Letta, args: str = "") -> str:
    """Unpin agent. Usage: /unpin <agent_id>"""
    agent_id = args.strip()
    if not agent_id:
        return "Usage: /unpin <agent_id>"
    return f"[PENDING] Unpin not yet implemented in SDK for {agent_id}"
