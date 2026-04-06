"""Message commands: /stream, /ask, /history"""

from __future__ import annotations

import sys

from letta_client import Letta
from letta_client import APIStatusError as ApiError
from letta_assistant.services import letta_service as svc
from letta_assistant.utils.content import content_to_text


# ===== ASK COMMAND (non-streaming) =====

def cmd_ask(
    client: Letta,
    agent_id: str,
    args: str = "",
    conversation_id: str | None = None,
) -> str:
    """Send message (non-streaming). Usage: /ask <text>"""
    if not agent_id:
        return "[ERROR] No active agent. Use /resume <id> first."
    if not args.strip():
        return "Usage: /ask <text>"

    try:
        response = svc.send_message(client, agent_id, args.strip())
        for msg in response.messages:
            if msg.message_type == "assistant_message":
                return content_to_text(msg.content)
        return "No response"
    except ApiError as e:
        return f"[ERROR] {e.status_code}: {e.body}"
    except Exception as e:
        return f"[ERROR] {e}"


# ===== STREAM COMMAND (streaming) =====

def cmd_stream(
    client: Letta,
    agent_id: str,
    args: str = "",
    conversation_id: str | None = None,
    on_thinking: callable = None,
    on_token: callable = None,
    on_stream_start: callable = None,
    on_event: callable = None,
    should_cancel: callable = None,
    echo: bool = True,
) -> str:
    """Send message with streaming. Usage: /stream <text>

    Returns the full assistant reply as a string.
    Tokens are printed to stdout as they arrive when echo=True.
    Callbacks on_thinking/on_token/on_stream_start fire per chunk.
    Models without extended thinking silently skip reasoning chunks.
    Models without tool support silently skip tool_call/tool_return chunks.
    """
    if not agent_id:
        return "[ERROR] No active agent. Use /resume <id> first."
    if not args.strip():
        return "Usage: /stream <text>"

    try:
        reply = ""
        stream_started = False

        stream = client.agents.messages.stream(
            agent_id=agent_id,
            messages=[{"role": "user", "content": args.strip()}],
            include_pings=True,
        )

        for chunk in stream:
            if should_cancel and should_cancel():
                break

            if on_event:
                on_event(chunk)

            msg_type = chunk.message_type

            if msg_type == "ping":
                continue

            elif msg_type == "reasoning_message":
                # Only present on models with extended thinking — skip silently if absent
                text = chunk.reasoning
                if text:
                    if echo:
                        print(f"[THINKING] {text}", flush=True)
                    if on_thinking:
                        on_thinking(text)

            elif msg_type == "tool_call_message":
                # tool_calls is a list; may be empty or absent on some models
                tool_calls_list = chunk.tool_calls
                if tool_calls_list:
                    for tc in tool_calls_list:
                        if echo:
                            print(f"[TOOL] {tc.name}({tc.arguments})", flush=True)
                        if on_token:
                            on_token(f"\n[TOOL] {tc.name}({tc.arguments})\n")

            elif msg_type == "tool_return_message":
                # tool_returns is a list; may be empty or absent on some models
                tool_returns_list = chunk.tool_returns
                if tool_returns_list:
                    for tr in tool_returns_list:
                        if echo:
                            print(f"[RETURN:{tr.status}] {tr.tool_return}", flush=True)
                        if on_token:
                            on_token(f"[RETURN:{tr.status}] {tr.tool_return}\n")

            elif msg_type == "assistant_message":
                if not stream_started:
                    stream_started = True
                    if on_stream_start:
                        on_stream_start()
                text = content_to_text(chunk.content)
                if echo:
                    print(text, end="", flush=True)
                reply += text
                if on_token:
                    on_token(text)

        if echo:
            print(flush=True)

        return reply if reply else "No response"

    except ApiError as e:
        return f"[ERROR] {e.status_code}: {e.body}"
    except Exception as e:
        return f"[ERROR] {e}"


# ===== HISTORY COMMAND =====

def cmd_history(
    client: Letta,
    agent_id: str,
    args: str = "",
    conversation_id: str | None = None,
) -> str:
    """View conversation history. Usage: /history [limit]"""
    if not agent_id:
        return "[ERROR] No active agent. Use /resume <id> first."

    try:
        limit = int(args.strip()) if args.strip() else 10
    except ValueError:
        return "Usage: /history [limit]"

    try:
        result = svc.get_messages(client, agent_id, limit=limit, conversation_id=conversation_id)
        msgs = list(result)
        if not msgs:
            return "No messages in history."
        lines = [f"[HISTORY] Last {limit} messages:"]
        for msg in msgs:
            role = msg.message_type.replace("_message", "").title()
            text = content_to_text(msg.content)
            lines.append(f"  {role}: {text[:60]}...")
        return "\n".join(lines)
    except ApiError as e:
        return f"[ERROR] {e.status_code}: {e.body}"
    except Exception as e:
        return f"[ERROR] {e}"
