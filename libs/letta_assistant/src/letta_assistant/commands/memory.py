"""Memory commands: /blocks, /archival, /passages search"""

from __future__ import annotations

from letta_client import Letta
from letta_assistant.services import letta_service as svc


# ===== BLOCKS COMMAND =====

def cmd_blocks(client: Letta, agent_id: str, args: str = "") -> str:
    """View memory blocks. Usage: /blocks [label]"""
    if not agent_id:
        return "[ERROR] No active agent. Use /resume <id> first."
    
    try:
        if args.strip():
            label = args.strip()
            block = svc.get_block(client, agent_id, label)
            return f"[MEMORY] {block.label}:\n{block.value}"
        
        blocks_response = svc.get_blocks(client, agent_id)
        if not blocks_response.items or len(blocks_response.items) == 0:
            return "No memory blocks found."
        
        lines = ["[MEMORY_BLOCKS]"]
        for block in blocks_response.items:
            lines.append(f"  • {block.label}: {block.value[:50]}...")
        return "\n".join(lines)
    except Exception as e:
        return f"[ERROR] {str(e)}"


# ===== UPDATE BLOCK COMMAND =====

def cmd_block_update(client: Letta, agent_id: str, args: str = "") -> str:
    """Update memory block. Usage: /blocks update <label> <value>"""
    if not agent_id:
        return "[ERROR] No active agent. Use /resume <id> first."
    if not args.strip():
        return "Usage: /blocks update <label> <value>"
    
    parts = args.strip().split(maxsplit=1)
    if len(parts) < 2:
        return "Usage: /blocks update <label> <value>"
    
    label, value = parts[0], parts[1]
    try:
        svc.update_block(client, agent_id, label, value)
        return f"[OK] Updated {label}."
    except Exception as e:
        return f"[ERROR] {str(e)}"


# ===== PASSAGES COMMAND =====

def cmd_passages(client: Letta, agent_id: str, args: str = "") -> str:
    """View archival memory passages. Usage: /passages [query]"""
    if not agent_id:
        return "[ERROR] No active agent. Use /resume <id> first."
    
    try:
        if args.strip():
            results = svc.search_passages(client, agent_id, args.strip(), limit=5)
            if not results.items:
                return "No passages found."
            lines = ["[SEARCH_RESULTS]"]
            for passage in results.items:
                lines.append(f"  • {passage.text[:60]}...")
            return "\n".join(lines)
        
        passages_response = svc.get_passages(client, agent_id, limit=10)
        if not passages_response.items:
            return "No passages found."
        
        lines = ["[ARCHIVAL_MEMORY]"]
        for passage in passages_response.items:
            lines.append(f"  • {passage.text[:60]}...")
        return "\n".join(lines)
    except Exception as e:
        return f"[ERROR] {str(e)}"
