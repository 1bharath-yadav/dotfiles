"""Conversation management: /resume, /new, /clear, /compact, /search, /context"""

from letta_client import Letta


def cmd_resume(client: Letta, agent_id: str, args: str = "") -> str:
    """List/resume conversations. Usage: /resume [id]"""
    page = client.conversations.list(agent_id=agent_id)
    if not page.items:
        return "No conversations. Use /new to create"
    
    if args.strip():
        return f"[OK] Resumed: {args.strip()}"
    
    lines = ["[CONVERSATIONS]"]
    for conv in page.items[:10]:
        lines.append(f"  {conv.id}")
    lines.append("\nUse /resume <id> to switch")
    return "\n".join(lines)


def cmd_new_conversation(client: Letta, agent_id: str, args: str = "") -> str:
    """Create conversation. Usage: /new"""
    conv = client.conversations.create(agent_id=agent_id)
    return f"[OK] Created: {conv.id}"


def cmd_clear(client: Letta, agent_id: str, conv_id: str, args: str = "") -> str:
    """Clear all messages. Usage: /clear"""
    if not conv_id:
        return "No active conversation"
    client.conversations.delete_messages(agent_id=agent_id, conversation_id=conv_id)
    return f"[OK] Cleared {conv_id}"


def cmd_compact(client: Letta, agent_id: str, conv_id: str, args: str = "") -> str:
    """Summarize conversation. Usage: /compact [all|sliding_window]"""
    if not conv_id:
        return "No active conversation"
    mode = args.strip() or "sliding_window"
    # Requires conversation context in REPL
    return f"[PENDING] Compact mode: {mode} (requires active conversation)"


def cmd_search(client: Letta, agent_id: str, conv_id: str, args: str = "") -> str:
    """Search messages. Usage: /search <query>"""
    if not args.strip():
        return "Usage: /search <query>"
    if not conv_id:
        return "No active conversation"
    # Search would use client.conversations.messages.list() with filters
    return f"[PENDING] Searching: {args.strip()}"


def cmd_context(client: Letta, agent_id: str, conv_id: str) -> str:
    """Show context window. Usage: /context"""
    if not conv_id:
        return "No active conversation"
    return "[PENDING] Context window info not yet exposed"
