"""Approval commands for tool execution: /approve"""

from __future__ import annotations

import json
from letta_client import Letta
from letta_client import APIStatusError as ApiError

def cmd_approve(client: Letta, agent_id: str, conversation_id: str, args: str) -> str:
    """Approve or deny a tool call request.
    Usage: /approve <tool_call_id> <approve|deny> [optional textual feedback]
    """
    if not agent_id:
        return "[ERROR] No active agent. Use /resume <id> first."
    
    parts = args.split(maxsplit=2)
    if len(parts) < 2:
        return "[ERROR] Usage: /approve <tool_call_id> <approve|deny> [message]"
        
    tool_call_id = parts[0]
    action = parts[1].lower()
    
    status = "success" if action in ["approve", "allow", "yes", "true", "success"] else "error"
    
    tool_return = "Tool execution approved by user." if status == "success" else "Tool execution denied by user."
    if len(parts) > 2:
        tool_return = parts[2]
        
    try:
        response = client.agents.messages.create(
            agent_id=agent_id,
            messages=[{
                "type": "approval",
                "approvals": [{
                    "type": "tool",
                    "tool_call_id": tool_call_id,
                    "tool_return": tool_return,
                    "status": status,
                }]
            }]
        )
        return "[OK] Approval sentiment captured."
    except ApiError as e:
        return f"[ERROR] {e.status_code}: {e.body}"
    except Exception as e:
        return f"[ERROR] {e}"
