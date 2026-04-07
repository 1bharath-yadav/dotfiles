"""letta_assistant.daemon.runner — voice-assistant daemon streaming core.

Entry point: python -m letta_assistant.daemon <mode> <text>
  mode = "pipe"  → send text to agent, stream response via QS IPC
  mode = "text"  → if text starts with "/" run as REPL command (stdout);
                   otherwise stream chat response to stdout

IPC event contract (pipe mode):
  status thinking         → assistant is working
  agentId / modelName     → identity (before any chunks)
  streamStart             → first token arriving (always emitted before "token")
  token <text>            → assistant reply chunk
  streamEnd               → reply finished
  thinkingStart <text>    → first reasoning chunk (ONLY on models with extended thinking)
  thinking <text>         → subsequent reasoning chunks
  thinkingEnd             → reasoning phase complete (ONLY after thinkingStart)
  toolCall / toolReturn   → tool activity
  usageStatistics <json>  → token counts (may be absent on some models)
  stopReason <json>       → stop cause
  error <json>            → error payload
  status ready|error      → final state

Models without extended thinking never emit thinkingStart/thinking/thinkingEnd.
Models without tool support never emit toolCall/toolReturn.
Frontend must handle the case where none of these optional events arrive.
"""

from __future__ import annotations

import json
import os
import subprocess
import sys
import traceback
from pathlib import Path

from letta_assistant.services import letta_service as svc
from letta_assistant.utils.state import load_state, save_state
from letta_assistant.letta_assistant import run_command_line

# ── paths ────────────────────────────────────────────────────────────────────

CANCEL_FILE = Path("/tmp/voice-assistant-cancel")

# ── IPC ──────────────────────────────────────────────────────────────────────

_QS = ["quickshell", "-c", "ii", "ipc", "call", "voiceAssistant"]


def ipc(name: str, *args: str) -> None:
    """Fire-and-forget Quickshell IPC call. Never raises."""
    try:
        subprocess.run(_QS + [name, *args], capture_output=True, timeout=5)
    except Exception:
        pass


def emit_memory_blocks(client, agent_id: str) -> None:
    """Fetch and emit the agent's memory blocks via IPC.
    
    Declarative: uses api.agents.blocks.list() to fetch all blocks,
    then emits a single structured JSON event with full block data.
    """
    try:
        from letta_assistant.services import letta_service as svc
        
        # Query API for all memory blocks (core memory)
        blocks = svc.get_blocks(client, agent_id)
        
        # Structure: list of {label: str, value: str}
        blocks_data = []
        
        # also sync local file system
        local_dir = Path.home() / ".letta" / agent_id / "memory" / "core"
        local_dir.mkdir(parents=True, exist_ok=True)
        
        for block in blocks:
            blocks_data.append({
                "label": block.label,
                "value": block.value,
            })
            # write block.value to block.label
            with open(local_dir / block.label, "w") as f:
                f.write(block.value or "")
        
        # Emit as single JSON event
        ipc("memoryBlocks", json.dumps({"blocks": blocks_data}))
    except Exception as e:
        # Silently skip if API unavailable; don't interrupt main flow
        pass


# ── event routing ─────────────────────────────────────────────────────────────

def _on_event(event, mode: str, state: dict) -> None:
    """Dispatch a stream chunk to the appropriate IPC call.

    state is a mutable dict shared across calls:
      thinking_started: bool  — set on first reasoning_message chunk
      stream_started: bool    — set on first assistant_message chunk

    We only emit thinkingStart/thinkingEnd if reasoning_message actually arrives.
    We only emit streamStart before the first token.
    Dispatch is purely on event.message_type — no getattr/hasattr/isinstance.
    """
    if mode != "pipe":
        return

    msg_type = event.message_type

    if msg_type == "tool_call_message":
        tool_calls = event.tool_calls
        if tool_calls:
            tc = tool_calls[0]
            ipc("toolCall", json.dumps({"name": tc.name, "arguments": tc.arguments}))

    elif msg_type == "tool_return_message":
        tool_returns = event.tool_returns
        if tool_returns:
            tr = tool_returns[0]
            ipc("toolReturn", json.dumps({"status": tr.status, "tool_return": tr.tool_return}))

    elif msg_type == "usage_statistics":
        ct = event.completion_tokens
        pt = event.prompt_tokens
        if ct is not None or pt is not None:
            ipc(
                "usageStatistics",
                json.dumps({
                    "completion_tokens": ct,
                    "prompt_tokens": pt,
                }),
            )

    elif msg_type == "reasoning_message":
        # Only emitted by models with extended thinking (e.g. claude-3-7-sonnet)
        reasoning = event.reasoning
        if not reasoning:
            return
        if not state["thinking_started"]:
            state["thinking_started"] = True
            ipc("thinkingStart", reasoning)
        else:
            ipc("thinking", reasoning)

    elif msg_type == "assistant_message":
        content = event.content or ""
        if not state["stream_started"]:
            state["stream_started"] = True
            ipc("streamStart")
        ipc("token", content)

    elif msg_type == "approval_request_message":
        # Handle client-side tool permission requests
        if hasattr(event, "tool_call") and event.tool_call:
            tc = event.tool_call
            tc_dict = {
                "tool_call_id": tc.tool_call_id,
                "name": tc.name,
                "arguments": tc.arguments
            }
            ipc("approvalRequest", json.dumps(tc_dict))
            ipc("status", "approval")

    elif msg_type == "stop_reason":
        ipc("stopReason", json.dumps({"stop_reason": str(event.stop_reason)}))

    elif msg_type == "error_message":
        ipc("error", json.dumps({"message": event.message}))
        ipc("status", "error")


# ── stream consumer ──────────────────────────────────────────────────────────

def _consume_stream(stream, mode: str) -> tuple[str, bool, dict]:
    """Iterate the stream, dispatch IPC/stdout per chunk.

    Returns (full_reply, was_cancelled, stream_state).
    stream_state keys: thinking_started, stream_started.
    """
    reply_parts: list[str] = []
    state = {"thinking_started": False, "stream_started": False}

    for chunk in stream:
        msg_type = chunk.message_type

        if msg_type == "ping":
            continue

        if CANCEL_FILE.exists():
            CANCEL_FILE.unlink(missing_ok=True)
            return "".join(reply_parts), True, state

        _on_event(chunk, mode, state)

        if msg_type == "assistant_message":
            text = chunk.content or ""
            reply_parts.append(text)
            if mode == "text":
                print(text, end="", flush=True)

        elif msg_type == "reasoning_message" and mode == "text":
            reasoning = chunk.reasoning
            if reasoning:
                print(f"[THINKING] {reasoning}", flush=True)

    return "".join(reply_parts), False, state


# ── public entry point ───────────────────────────────────────────────────────

def run(mode: str, text: str) -> None:
    """Main daemon logic. mode ∈ {"pipe", "text"}.

    text mode + slash command → run through REPL, print result to stdout.
    text mode + plain text    → stream chat response to stdout.
    pipe mode                 → stream chat response via QS IPC.

    agent_id from state is a cache/hint. Slash commands that don't need an
    agent (e.g. /model list, /config show) work even with no saved state.
    Only chat streaming requires a valid agent_id.
    """
    api_key = os.environ.get("LETTA_API_KEY", "")
    client = svc.init_client(api_key)

    saved = load_state()
    agent_id = saved.get("agent_id") or ""
    conversation_id = saved.get("conversation_id") or ""

    # ── text mode + slash → REPL, never requires agent_id ───────────────
    if mode == "text" and text.startswith("/"):
        result, new_agent, new_conv, _meta = run_command_line(
            client, agent_id, conversation_id, text, echo=False
        )
        if new_agent != agent_id or new_conv != conversation_id:
            save_state(new_agent, new_conv, saved.get("model_id"))
        print(result)
        return

    # ── chat streaming requires a valid agent ────────────────────────────
    if not agent_id:
        if mode == "pipe":
            ipc("status", "error")
            ipc("error", json.dumps({"message": "No active agent in saved state"}))
        else:
            print("[ERROR] No active agent in saved state", file=sys.stderr)
        sys.exit(1)

    # ── announce identity (pipe only) ────────────────────────────────────
    if mode == "pipe":
        agent = svc.get_agent(client, agent_id)
        ipc("agentId", agent_id)
        ipc("modelName", agent.model or "")
        ipc("agentName", agent.name or "")
        ipc("agentDescription", agent.description or "")
        ipc("agentTags", json.dumps({"tags": agent.tags or []}))
        ipc("status", "thinking")
        
        # Emit memory blocks immediately after agent identity
        emit_memory_blocks(client, agent_id)

    # ── stream ───────────────────────────────────────────────────────────
    stream = client.agents.messages.stream(
        agent_id=agent_id,
        messages=[{"role": "user", "content": text}],
        include_pings=True,
        stream_tokens=True,
    )

    reply, was_cancelled, stream_state = _consume_stream(stream, mode)

    # ── post-stream signals ──────────────────────────────────────────────
    if mode == "pipe":
        # Only emit thinkingEnd if thinking actually started
        if stream_state["thinking_started"]:
            ipc("thinkingEnd")

        # Only emit streamEnd if stream actually started; otherwise send response event
        if stream_state["stream_started"]:
            ipc("streamEnd")
        elif reply:
            # Non-streaming fallback: model returned full reply without streaming
            ipc("response", reply)

        final_status = "error" if was_cancelled else "ready"
        ipc("status", final_status)
    else:
        if reply:
            print()  # trailing newline after streamed tokens

    save_state(agent_id, conversation_id, saved.get("model_id"))


# ── CLI shim ─────────────────────────────────────────────────────────────────

def main() -> None:
    """python -m letta_assistant.daemon <mode> <text>"""
    if len(sys.argv) < 3:
        print("Usage: python -m letta_assistant.daemon <pipe|text> <text>", file=sys.stderr)
        sys.exit(1)

    mode = sys.argv[1]
    text = sys.argv[2]

    if mode not in ("pipe", "text"):
        print(f"[ERROR] Unknown mode: {mode!r}", file=sys.stderr)
        sys.exit(1)

    try:
        run(mode, text)
    except Exception as e:
        msg = {"message": str(e), "traceback": traceback.format_exc()}
        if mode == "pipe":
            ipc("error", json.dumps(msg))
            ipc("status", "error")
        else:
            print(f"[ERROR] {e}", file=sys.stderr)
            print(traceback.format_exc(), file=sys.stderr)
        sys.exit(1)