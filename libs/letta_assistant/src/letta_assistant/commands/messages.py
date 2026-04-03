"""Message commands: /stream, /ask, /history"""

from __future__ import annotations

import sys

from letta_client import Letta
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
        
        # Extract last assistant message from response.messages
        assistant_message = None
        for msg in response.messages:
            if msg.message_type == "assistant_message":
                assistant_message = msg
        
        if assistant_message and assistant_message.content:
            return assistant_message.content
        return "No response"
    except Exception as e:
        return f"[ERROR] Error: {str(e)}"


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
    """Send message with streaming. Usage: /stream <text>"""
    if not agent_id:
        return "[ERROR] No active agent. Use /resume <id> first."
    if not args.strip():
        return "Usage: /stream <text>"
    
    try:
        reply = ""
        stop_code = None
        stream_started = False

        def extract_reasoning_text(event: object) -> str:
            reasoning = getattr(event, "reasoning", "") or ""
            if reasoning:
                return reasoning

            hidden_reasoning = getattr(event, "hidden_reasoning", "") or ""
            if hidden_reasoning:
                return hidden_reasoning

            content = getattr(event, "content", None)
            if content is not None:
                return content_to_text(content)

            return ""

        stream = svc.stream_message(
            client,
            agent_id,
            args.strip(),
            conversation_id=conversation_id,
            enable_thinking="true",
            stream_tokens=True,
            include_pings=False,
        )

        for event in stream:
            if should_cancel and should_cancel():
                stop_code = "cancelled"
                break

            if on_event:
                on_event(event)

            event_type = event.message_type
            
            # Agent's internal reasoning (print live)
            if event_type == "reasoning_message":
                # Print reasoning in real-time
                reasoning_text = extract_reasoning_text(event)
                if reasoning_text:
                    if echo:
                        print(f"[THINKING] {reasoning_text}", flush=True)
                        sys.stdout.flush()
                if on_thinking:
                    on_thinking(reasoning_text)
            
            # Tool invocation
            elif event_type == "tool_call_message":
                for tool_call in event.tool_calls:
                    if echo:
                        print(f"[TOOL] Calling {tool_call.name}...", flush=True)
                        sys.stdout.flush()
                    if on_token:
                        on_token(f"\n[TOOL] Calling {tool_call.name}...\n")
            
            # Tool results
            elif event_type == "tool_return_message":
                for tool_return in event.tool_returns:
                    status = "[OK]" if tool_return.status == "success" else "[ERROR]"
                    if echo:
                        print(f"{status} Tool returned", flush=True)
                        sys.stdout.flush()
                    if on_token:
                        on_token(f"{status} Tool returned\n")
            
            # Assistant response text (stream tokens live)
            elif event_type == "assistant_message":
                if not stream_started:
                    stream_started = True
                    if on_stream_start:
                        on_stream_start()
                # Print and accumulate
                text = content_to_text(event.content)
                if echo:
                    print(text, end="", flush=True)
                    sys.stdout.flush()
                reply += text
                if on_token:
                    on_token(text)
            
            # Execution stopped (check for errors)
            elif event_type == "stop_reason":
                stop_code = event.stop_reason
            
            # Execution error
            elif event_type == "error_message":
                err_msg = f"[ERROR] {event.error_type}: {event.message}"
                if echo:
                    print(err_msg, flush=True)
                    sys.stdout.flush()
                return err_msg
        
        # Newline after streaming content
        if echo:
            print(flush=True)
            sys.stdout.flush()
        
        # Check final stop reason
        if stop_code and stop_code != "end_turn":
            return f"[PENDING] Execution stopped: {stop_code}"
        
        return reply if reply else "No response"
    except Exception as e:
        return f"[ERROR] Error: {str(e)}"


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
        messages = svc.get_messages(
            client,
            agent_id,
            limit=limit,
            conversation_id=conversation_id,
        )
        
        if not messages.items or len(messages.items) == 0:
            return "No messages in history."
        
        lines = [f"[HISTORY] Last {limit} messages:"]
        for msg in messages.items:
            # Use message_type to determine the sender
            sender = msg.message_type.replace("_message", "").title()
            # Content is string or list of content parts
            content = content_to_text(msg.content)
            lines.append(f"  {sender}: {str(content)[:60]}...")
        return "\n".join(lines)
    except ValueError:
        return "Usage: /history [limit]"
    except Exception as e:
        return f"[ERROR] Error: {str(e)}"
