"""Configuration: /system, /statusline, /sleeptime, /init, /doctor"""

from letta_client import Letta
from letta_assistant.services import letta_service as svc


def cmd_system(client: Letta, agent_id: str, args: str = "") -> str:
    """View/switch system prompt. Usage: /system [prompt]"""
    if not args.strip():
        agent = client.agents.retrieve(agent_id=agent_id)
        return f"[SYSTEM PROMPT]\n{agent.system}"
    
    new_prompt = args.strip()
    client.agents.update(agent_id=agent_id, system=new_prompt)
    return "[OK] Updated system prompt"


def cmd_init(client: Letta, agent_id: str, args: str = "") -> str:
    """Initialize memory blocks for agent. Usage: /init"""
    # Would reset agent memory to defaults
    return "[PENDING] Memory reinitialization not yet implemented"


def cmd_doctor(client: Letta, agent_id: str, args: str = "") -> str:
    """Audit memory blocks. Usage: /doctor"""
    page = svc.get_blocks(client, agent_id)
    if not page.items:
        return "No memory blocks"
    
    lines = ["[MEMORY AUDIT]"]
    lines.append(f"  Total blocks: {len(page.items)}")
    for block in page.items:
        val_len = len(str(block.value))
        lines.append(f"  • {block.label}: {val_len} chars")
    
    return "\n".join(lines)


def cmd_statusline(client: Letta, agent_id: str, args: str = "") -> str:
    """List configured models. Usage: /statusline"""
    models = client.models.list()
    if not models.items:
        return "[ERROR] No models available"
    
    lines = ["[AVAILABLE MODELS]"]
    for model in models.items:
        lines.append(f"  • {model.identifier}")
    
    return "\n".join(lines)


def cmd_sleeptime(client: Letta, agent_id: str, args: str = "") -> str:
    """Configure reflection. Usage: /sleeptime"""
    return "[PENDING] Sleeptime configuration (feature in progress)"
