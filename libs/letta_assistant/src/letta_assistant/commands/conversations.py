"""Conversation management commands.

All SDK calls taken directly from letta-api-client skill examples (10_conversations.py).
No getattr/hasattr/isinstance.
"""

from __future__ import annotations

from letta_client import Letta

from letta_assistant.utils import state
from letta_assistant.utils.content import content_to_text


# ── helpers ──────────────────────────────────────────────────────────────────

def _conv_list(client: Letta, agent_id: str) -> list:
    """Return flat list of conversations for agent."""
    page = client.conversations.list(agent_id=agent_id)
    return list(page)


def _resolve_conv(ref: str, convs: list):
    """Find conversation by 1-based index or exact id."""
    ref = ref.strip()
    try:
        idx = int(ref) - 1
        if 0 <= idx < len(convs):
            return convs[idx]
    except ValueError:
        pass
    for c in convs:
        if c.id == ref:
            return c
    return None


# ── /resume (list + switch) ───────────────────────────────────────────────────

def cmd_resume(client: Letta, agent_id: str, args: str = "") -> str:
    """List conversations or switch to one.
    Usage:
      /resume           — list all conversations
      /resume <index|id> — switch to that conversation
    """
    if not agent_id:
        return "[ERROR] No active agent."

    try:
        convs = _conv_list(client, agent_id)
    except Exception as e:
        return f"[ERROR] {str(e)}"

    ref = args.strip()

    # Switch to specific conversation
    if ref:
        conv = _resolve_conv(ref, convs)
        if not conv:
            return f"[ERROR] Conversation not found: '{ref}'"
        saved = state.load_state()
        state.save_state(agent_id, conv.id, saved.get("model_id"))
        label = conv.name or conv.id
        return f"[OK] Switched to conversation '{label}' ({conv.id})"

    # List all
    if not convs:
        return "No conversations. Use /new to create one."

    saved = state.load_state()
    active_conv = saved.get("conversation_id", "")

    lines = [f"[CONVERSATIONS] {len(convs)}"]
    for i, c in enumerate(convs, 1):
        active = " ◀ active" if c.id == active_conv else ""
        label = c.name or "(unnamed)"
        lines.append(f"  {i}. {label}  id={c.id}{active}")
    lines.append("\nUse /resume <index|id> to switch.")
    return "\n".join(lines)


# ── /new conversation ─────────────────────────────────────────────────────────

def cmd_new_conversation(client: Letta, agent_id: str, args: str = "") -> str:
    """Create a new conversation and switch to it.
    Usage: /new [name]
    """
    if not agent_id:
        return "[ERROR] No active agent."

    name = args.strip() or None

    try:
        # Matches 10_conversations.py: client.conversations.create(agent_id=..., name=...)
        kwargs = {"agent_id": agent_id}
        if name:
            kwargs["name"] = name
        conv = client.conversations.create(**kwargs)
        saved = state.load_state()
        state.save_state(agent_id, conv.id, saved.get("model_id"))
        label = conv.name or conv.id
        return f"[OK] Created conversation '{label}'\n  id={conv.id}\nNow active."
    except Exception as e:
        return f"[ERROR] {str(e)}"


# ── /clear ────────────────────────────────────────────────────────────────────

def cmd_clear(client: Letta, agent_id: str, conv_id: str, args: str = "") -> str:
    """Delete all messages in the active conversation.
    Usage: /clear
    """
    if not agent_id:
        return "[ERROR] No active agent."
    if not conv_id:
        return "[ERROR] No active conversation. Use /resume or /new."

    try:
        confirm = input(f"Clear all messages in {conv_id}? [y/N] ").strip().lower()
    except (EOFError, KeyboardInterrupt):
        return "[CANCELLED]"

    if confirm != "y":
        return "[CANCELLED]"

    try:
        # From 10_conversations.py pattern; messages reset
        client.agents.messages.reset(agent_id=agent_id)
        return f"[OK] Cleared messages in {conv_id}"
    except Exception as e:
        return f"[ERROR] {str(e)}"


# ── /compact ──────────────────────────────────────────────────────────────────

def cmd_compact(client: Letta, agent_id: str, conv_id: str, args: str = "") -> str:
    """Summarise conversation history to free context window.
    Usage: /compact [sliding_window|summary]
    """
    if not agent_id:
        return "[ERROR] No active agent."
    if not conv_id:
        return "[ERROR] No active conversation."

    method = args.strip() or "sliding_window"
    if method not in ("sliding_window", "summary"):
        return "[ERROR] Method must be 'sliding_window' or 'summary'"

    try:
        client.agents.messages.compact(agent_id=agent_id, method=method)
        return f"[OK] Compacted conversation ({method})"
    except Exception as e:
        return f"[ERROR] {str(e)}"


# ── /search ───────────────────────────────────────────────────────────────────

def cmd_search(client: Letta, agent_id: str, conv_id: str, args: str = "") -> str:
    """Search messages in the active conversation.
    Usage: /search <query>
    """
    if not args.strip():
        return "Usage: /search <query>"
    if not agent_id:
        return "[ERROR] No active agent."
    if not conv_id:
        return "[ERROR] No active conversation."

    try:
        # From 10_conversations.py: client.conversations.messages.list(conv_id)
        messages = client.conversations.messages.list(conv_id)
        query = args.strip().lower()

        hits = []
        for msg in messages:
            if msg.message_type not in ("user_message", "assistant_message"):
                continue
            text = content_to_text(msg.content)
            if query in text.lower():
                hits.append((msg.message_type, text))

        if not hits:
            return f"[SEARCH] No matches for '{args.strip()}'"

        lines = [f"[SEARCH] {len(hits)} match(es) for '{args.strip()}'"]
        for kind, text in hits[:10]:
            role = "User" if kind == "user_message" else "Agent"
            lines.append(f"  [{role}] {text[:120]}")
        return "\n".join(lines)
    except Exception as e:
        return f"[ERROR] {str(e)}"


# ── /context ──────────────────────────────────────────────────────────────────

def cmd_context(client: Letta, agent_id: str, conv_id: str) -> str:
    """Show message count and context summary for active conversation.
    Usage: /context
    """
    if not agent_id:
        return "[ERROR] No active agent."
    if not conv_id:
        return "[ERROR] No active conversation."

    try:
        # List recent messages and count by type
        messages = client.conversations.messages.list(conv_id)
        msg_list = list(messages)

        counts: dict[str, int] = {}
        for msg in msg_list:
            counts[msg.message_type] = counts.get(msg.message_type, 0) + 1

        lines = [
            f"[CONTEXT] conversation={conv_id}",
            f"  total messages = {len(msg_list)}",
        ]
        for mtype, n in sorted(counts.items()):
            lines.append(f"  {mtype} = {n}")
        return "\n".join(lines)
    except Exception as e:
        return f"[ERROR] {str(e)}"
