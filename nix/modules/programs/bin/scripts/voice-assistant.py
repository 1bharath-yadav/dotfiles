#!/usr/bin/env python3
"""
voice-assistant.py — Letta-backed personal assistant with verified Python SDK usage.

Verified against docs.letta.com for:
- client.models.list()
- client.agents.create(..., tools=[...], memory_blocks=[...], model_settings=...)
- client.agents.update(..., model=..., model_settings=...)
- client.conversations.create(agent_id=...)
- client.conversations.messages.create(conversation_id, messages=[...])
- client.conversations.messages.stream(conversation_id, messages=[...])
- client.agents.import_file(...) -> response.agent_ids

Modes:
  text          interactive REPL (default)
  pipe          stdin → Letta → IPC + TTS (called by whisper-assistant)
  cancel        cancel the active streamed run
  pipe-set L V  directly update memory block label L to value V, then exit
"""

import json
import subprocess
import sys
from pathlib import Path
from collections import Counter, defaultdict


CONFIG_PATH = Path.home() / ".ai" / "config.json"
AGENT_ID_FILE = Path.home() / ".ai" / "agent_id.txt"
ACTIVE_AGENT_FILE = Path.home() / ".ai" / "active_agent_id.txt"
ACTIVE_RUN_ID_FILE = Path.home() / ".ai" / "active_run_id.txt"
CONVERSATION_ID_FILE = Path.home() / ".ai" / "conversation_id.txt"

_KEYRING_APP = "illogical-impulse"
_KEYRING_LABEL = "illogical-impulse Safe Storage"
_KEYRING_KEY = "letta"
QUICKSHELL_BIN = "/usr/bin/quickshell"

_BLOCKS = ("persona", "human", "goals", "projects", "habits")
DEFAULT_MODEL = "openai/gpt-4o-mini"
DEFAULT_EMBEDDING = "openai/text-embedding-3-small"
DEFAULT_TOOLS = ["web_search", "run_code"]


def load_config() -> dict:
    if CONFIG_PATH.exists():
        return json.loads(CONFIG_PATH.read_text())
    return {}


def save_config(cfg: dict) -> None:
    CONFIG_PATH.parent.mkdir(parents=True, exist_ok=True)
    CONFIG_PATH.write_text(json.dumps(cfg, indent=2))


_cfg = load_config()
_letta_cfg = _cfg.get("letta", {})
_persona_cfg = _cfg.get("persona", {})


def _keyring_load() -> dict:
    try:
        result = subprocess.run(
            ["secret-tool", "lookup", "application", _KEYRING_APP],
            capture_output=True, text=True, timeout=5,
        )
        data = result.stdout.strip()
        if data.startswith("{"):
            return json.loads(data)
    except Exception:
        pass
    return {}


def _keyring_save(blob: dict) -> None:
    try:
        proc = subprocess.Popen(
            [
                "secret-tool", "store",
                f"--label={_KEYRING_LABEL}",
                "application", _KEYRING_APP,
                "explanation", "For storing API keys and other sensitive information",
            ],
            stdin=subprocess.PIPE,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
        proc.communicate(input=json.dumps(blob).encode(), timeout=10)
    except Exception as e:
        print(f"[voice-assistant] Warning: could not save to keyring: {e}", file=sys.stderr)


def get_api_key() -> str | None:
    blob = _keyring_load()
    return blob.get("apiKeys", {}).get(_KEYRING_KEY, "").strip() or None


def save_api_key(key: str) -> None:
    blob = _keyring_load()
    blob.setdefault("apiKeys", {})[_KEYRING_KEY] = key.strip()
    _keyring_save(blob)


def prompt_for_api_key(pipe_mode: bool = False) -> str:
    if pipe_mode:
        _ipc("voiceAssistant", "status", "error")
        _ipc("voiceAssistant", "response", "[Error] No Letta API key set. Run: voice-assistant text")
        sys.exit(1)

    print("\n┌─ First-run setup ───────────────────────────────────────────┐")
    print("│  No Letta API key found in keyring.                         │")
    print("│  Get yours at: https://app.letta.com → Settings → API Keys  │")
    print("└─────────────────────────────────────────────────────────────┘")
    try:
        import getpass
        key = getpass.getpass("Letta API key (sk-let-...): ").strip()
    except (EOFError, KeyboardInterrupt):
        print("\nAborted.")
        sys.exit(1)
    if not key:
        print("No key entered. Exiting.")
        sys.exit(1)
    save_api_key(key)
    print("✓ Key saved to keyring. Change later with /key in the REPL.\n")
    return key


def make_client(api_key: str | None = None):
    from letta_client import Letta
    if api_key is None:
        api_key = get_api_key()
    kwargs = {}
    if api_key:
        kwargs["api_key"] = api_key
    base_url = _letta_cfg.get("base_url")
    if base_url:
        kwargs["base_url"] = base_url
    return Letta(**kwargs)


def _ipc(target: str, event: str, payload: str = "") -> None:
    try:
        subprocess.Popen(
            [QUICKSHELL_BIN, "-c", "ii", "ipc", "call", target, event, payload],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
    except FileNotFoundError:
        pass


def _speak(text: str) -> None:
    piper = Path.home() / ".local" / "bin" / "piper-speak"
    if piper.exists():
        subprocess.run([str(piper), text], check=False)


def get_active_agent_id() -> str | None:
    cfg_id = _letta_cfg.get("agent_id", "").strip()
    if cfg_id:
        return cfg_id
    for path in (ACTIVE_AGENT_FILE, AGENT_ID_FILE):
        if path.exists():
            val = path.read_text().strip()
            if val:
                return val
    return None


def set_active_agent_id(aid: str) -> None:
    _letta_cfg["agent_id"] = aid
    _cfg["letta"] = _letta_cfg
    save_config(_cfg)
    ACTIVE_AGENT_FILE.parent.mkdir(parents=True, exist_ok=True)
    ACTIVE_AGENT_FILE.write_text(aid)
    AGENT_ID_FILE.parent.mkdir(parents=True, exist_ok=True)
    AGENT_ID_FILE.write_text(aid)
    CONVERSATION_ID_FILE.unlink(missing_ok=True)


def get_active_conversation_id() -> str | None:
    if CONVERSATION_ID_FILE.exists():
        cid = CONVERSATION_ID_FILE.read_text().strip()
        if cid:
            return cid
    return None


def set_active_conversation_id(cid: str) -> None:
    CONVERSATION_ID_FILE.parent.mkdir(parents=True, exist_ok=True)
    CONVERSATION_ID_FILE.write_text(cid)


def get_active_run_id() -> str | None:
    if ACTIVE_RUN_ID_FILE.exists():
        rid = ACTIVE_RUN_ID_FILE.read_text().strip()
        if rid:
            return rid
    return None


def set_active_run_id(run_id: str) -> None:
    ACTIVE_RUN_ID_FILE.parent.mkdir(parents=True, exist_ok=True)
    ACTIVE_RUN_ID_FILE.write_text(run_id)


def clear_active_run_id() -> None:
    ACTIVE_RUN_ID_FILE.unlink(missing_ok=True)


def create_conversation(client, agent_id: str) -> str:
    conv = client.conversations.create(agent_id=agent_id)
    set_active_conversation_id(conv.id)
    return conv.id


def resolve_conversation_id(client, agent_id: str) -> str:
    cid = get_active_conversation_id()
    if cid:
        try:
            conv = client.conversations.retrieve(conversation_id=cid)
            if getattr(conv, "agent_id", None) == agent_id:
                return cid
        except Exception:
            pass
    return create_conversation(client, agent_id)


def _default_model_settings_for_provider(provider_type: str | None) -> dict | None:
    if provider_type == "openai":
        return {"provider_type": "openai", "parallel_tool_calls": True, "temperature": 0.2}
    if provider_type == "anthropic":
        return {"provider_type": "anthropic", "temperature": 0.2, "thinking": {"type": "enabled", "budget_tokens": 2048}}
    if provider_type in ("google_ai", "google_vertex"):
        return {"provider_type": provider_type, "temperature": 0.2, "thinking_config": {"thinking_budget": 2048, "include_thoughts": True}}
    if provider_type == "chatgpt_oauth":
        return {"provider_type": "chatgpt_oauth", "temperature": 0.2, "reasoning_effort": "medium"}
    if provider_type == "zai":
        return {"provider_type": "zai", "temperature": 0.2, "thinking": {"type": "enabled", "clear_thinking": False}}
    if provider_type:
        return {"provider_type": provider_type, "temperature": 0.2}
    return None


def _find_model(client, model_handle: str):
    models = client.models.list()
    return next((m for m in models if getattr(m, "handle", None) == model_handle), None)


def _model_summary_line(model) -> str:
    handle = getattr(model, "handle", None) or getattr(model, "name", None) or "(unknown)"
    display_name = getattr(model, "display_name", None) or getattr(model, "name", None) or handle
    provider_type = getattr(model, "provider_type", None) or "unknown"
    provider_name = getattr(model, "provider_name", None) or provider_type
    ctx = getattr(model, "max_context_window", None) or getattr(model, "context_window", None) or "?"
    return f"{handle}  [{provider_name}]  ctx={ctx}  name={display_name}"


def _create_agent_with_prompt(client, name: str | None = None, activate: bool = False) -> str | None:
    name = name or input("Agent name: ").strip()
    if not name:
        print("Name required.")
        return None

    model = _letta_cfg.get("model", DEFAULT_MODEL)
    m = _find_model(client, model)
    provider_type = getattr(m, "provider_type", None) if m else None
    persona = input("Persona (short): ").strip() or "You are a helpful assistant."
    human = input("Human profile (short): ").strip() or "User prefers concise answers."
    agent = client.agents.create(
        name=name,
        model=model,
        embedding=_letta_cfg.get("embedding", DEFAULT_EMBEDDING),
        model_settings=_default_model_settings_for_provider(provider_type),
        memory_blocks=[
            {"label": "persona", "value": persona},
            {"label": "human", "value": human},
            {"label": "goals", "value": ""},
            {"label": "projects", "value": ""},
            {"label": "habits", "value": ""},
        ],
        tools=DEFAULT_TOOLS,
    )
    print(f"Created agent: {agent.id} ({name})")
    if activate:
        set_active_agent_id(agent.id)
        print(f"Active agent set to {agent.id}")
    return agent.id


def _choose_agent_interactively(client) -> str | None:
    agents = list(client.agents.list())
    if not agents:
        print("No agents found.")
        choice = input("Create a new agent now? [y/N]: ").strip().lower()
        if choice != "y":
            return None
        return _create_agent_with_prompt(client, activate=True)

    print("Choose an agent:")
    for idx, agent in enumerate(agents, 1):
        marker = " (active)" if agent.id == get_active_agent_id() else ""
        print(f"{idx}. {agent.id}  {getattr(agent, 'name', None) or '(unnamed)'}  {getattr(agent, 'model', None) or '(unknown)'}{marker}")

    while True:
        choice = input("Select by number, id, name, or 'new': ").strip()
        if not choice:
            continue
        if choice.lower() in {"new", "n"}:
            return _create_agent_with_prompt(client, activate=True)
        if choice.isdigit() and 1 <= int(choice) <= len(agents):
            agent = agents[int(choice) - 1]
        else:
            agent = _get_agent_by_ref(client, choice)
        if agent:
            set_active_agent_id(agent.id)
            print(f"Active agent set to {agent.id} ({getattr(agent, 'name', None) or 'unnamed'})")
            return agent.id
        print("Agent not found.")


def resolve_agent_id(client, interactive: bool = False) -> str | None:
    aid = get_active_agent_id()
    if aid:
        agent = _get_agent_by_ref(client, aid)
        if agent:
            return aid
        print("Saved active agent not found.")
    if not interactive:
        return None
    return _choose_agent_interactively(client)


def get_memory_blocks(client, agent_id: str) -> dict:
    out = {}
    for label in _BLOCKS:
        try:
            b = client.agents.blocks.retrieve(agent_id=agent_id, block_label=label)
            out[label] = b.value or ""
        except Exception:
            out[label] = ""
    return out


def update_memory_block(client, agent_id: str, label: str, value: str) -> bool:
    try:
        client.agents.blocks.update(agent_id=agent_id, block_label=label, value=value)
        return True
    except Exception:
        return False


def search_archival(client, agent_id: str, query: str, limit: int = 5) -> list[str]:
    try:
        results = client.agents.archival_memory.list(agent_id=agent_id, query=query, limit=limit)
        return [r.text for r in results if hasattr(r, "text")]
    except Exception:
        return []


def insert_archival(client, agent_id: str, text: str) -> bool:
    try:
        client.agents.archival_memory.create(agent_id=agent_id, text=text)
        return True
    except Exception:
        return False


def search_recall(client, agent_id: str, query: str, limit: int = 5) -> list[str]:
    try:
        results = client.agents.messages.search(agent_id=agent_id, query=query, limit=limit)
        return [getattr(r, "content", str(r)) for r in results]
    except Exception:
        return []


def extract_text(messages) -> str:
    parts = []
    for msg in messages:
        c = getattr(msg, "content", None)
        if isinstance(c, str) and c.strip():
            role = getattr(msg, "role", None)
            mtype = getattr(msg, "message_type", None)
            if role == "assistant" or mtype == "assistant_message":
                parts.append(c.strip())
    return "\n".join(parts)


def run_pipe_set(label: str, value: str) -> None:
    try:
        client = make_client()
        agent_id = resolve_agent_id(client)
        if not agent_id:
            raise RuntimeError("No active agent selected.")
        update_memory_block(client, agent_id, label, value)
        _ipc("voiceAssistant", "memoryUpdate", json.dumps(get_memory_blocks(client, agent_id)))
    except Exception as e:
        print(f"pipe-set error: {e}", file=sys.stderr)

def send_message(client, agent_id: str, text: str):
    return client.agents.messages.create(
        agent_id=agent_id,
        messages=[{"role": "user", "content": text}],
        streaming=False,
    )


def stream_message(client, agent_id: str, text: str):
    return client.agents.messages.create(
        agent_id=agent_id,
        messages=[{"role": "user", "content": text}],
        streaming=True,
        stream_tokens=True,
        include_pings=True,
    )


def cancel_active_run(client, agent_id: str, run_id: str | None = None):
    if run_id:
        return client.agents.messages.cancel(agent_id=agent_id, run_ids=[run_id])
    return client.agents.messages.cancel(agent_id=agent_id)


def _chunk_attr(chunk, *names):
    for name in names:
        value = getattr(chunk, name, None)
        if value is None:
            continue
        if isinstance(value, str):
            if value.strip():
                return value
        else:
            return str(value)
    return ""


def _extract_chunk_text(chunk) -> tuple[str, str]:
    """
    Return (reply_token, thinking_token) from a Letta streaming chunk.

    Letta SDK chunk types (message_type field):
      assistant_message   — the actual reply; .content is list[TextContent]
      internal_monologue  — inner thoughts; .content is str or list
      reasoning           — some models emit this for CoT
      tool_call_message   — tool invocation (skip)
      tool_return_message — tool result (skip)
      usage_statistics    — token counts (skip)
      heartbeat / ping    — keepalive (skip)
    """
    mtype = (getattr(chunk, "message_type", None) or
             getattr(chunk, "event", None) or
             getattr(chunk, "type", None) or
             getattr(chunk, "kind", None) or "").lower()

    # ── Assistant reply ──────────────────────────────────────────────────
    if mtype in ("assistant_message",):
        c = getattr(chunk, "content", None)
        if isinstance(c, str):
            return c, ""
        if isinstance(c, list) and c:
            # SDK wraps text in TextContent objects
            parts = []
            for item in c:
                t = getattr(item, "text", None)
                if isinstance(t, str):
                    parts.append(t)
            return "".join(parts), ""
        return "", ""

    # ── Inner thoughts / reasoning ───────────────────────────────────────
    if mtype in ("internal_monologue", "reasoning", "thinking"):
        c = getattr(chunk, "content", None)
        if isinstance(c, str) and c.strip():
            return "", c
        if isinstance(c, list) and c:
            parts = []
            for item in c:
                t = getattr(item, "text", None)
                if isinstance(t, str):
                    parts.append(t)
            return "", "".join(parts)
        # Also check dedicated reasoning field
        r = getattr(chunk, "reasoning", None) or getattr(chunk, "thought", None) or ""
        return "", str(r) if r else ""

    # ── Skip everything else (tool calls, pings, usage stats, etc.) ──────
    return "", ""


def _stream_response(client, agent_id: str, message: str, on_token=None, on_thinking=None):
    stream = stream_message(client, agent_id, message)
    final_parts = []
    for chunk in stream:
        # Track run_id for cancel support
        run_id = _chunk_attr(chunk, "run_id", "message_id", "messageId", "id")
        if run_id:
            set_active_run_id(run_id)

        reply_token, think_token = _extract_chunk_text(chunk)

        if think_token and on_thinking:
            on_thinking(think_token)

        if reply_token:
            final_parts.append(reply_token)
            if on_token:
                on_token(reply_token)

    return "".join(final_parts).strip()

def run_pipe() -> None:
    query = sys.stdin.read().strip()
    if not query:
        return
    api_key = get_api_key()
    if not api_key:
        prompt_for_api_key(pipe_mode=True)

    client = None
    agent_id = None
    try:
        client = make_client(api_key)
        agent_id = resolve_agent_id(client)
        if not agent_id:
            raise RuntimeError("No active agent selected. Open voice-assistant text mode and run /agents use or /agents new.")
        _ipc("voiceAssistant", "userMessage", query)
        _ipc("voiceAssistant", "status", "thinking")
        _ipc("voiceAssistant", "agentId", agent_id)
        agent = _get_agent_by_ref(client, agent_id)
        if agent:
            _ipc("voiceAssistant", "modelName", _agent_model_name(agent))

        # Lazy thinking bubble: opened on the first real thinking chunk,
        # subsequent chunks stream via "thinking", closed before reply starts.
        _thinking_open = [False]
        def _on_thinking(chunk: str) -> None:
            if not _thinking_open[0]:
                _ipc("voiceAssistant", "thinkingStart", chunk)
                _thinking_open[0] = True
            else:
                _ipc("voiceAssistant", "thinking", chunk)

        _ipc("voiceAssistant", "streamStart")
        text = _stream_response(
            client,
            agent_id,
            query,
            on_token=lambda chunk: _ipc("voiceAssistant", "token", chunk),
            on_thinking=_on_thinking,
        )
        if _thinking_open[0]:
            _ipc("voiceAssistant", "thinkingEnd")
        _ipc("voiceAssistant", "streamEnd")
        _ipc("voiceAssistant", "status", "ready")
        _ipc("voiceAssistant", "memoryUpdate", json.dumps(get_memory_blocks(client, agent_id)))
        if text:
            _speak(text)
    except KeyboardInterrupt:
        run_id = get_active_run_id()
        try:
            if client and agent_id:
                cancel_active_run(client, agent_id, run_id)
        except Exception:
            pass
        _ipc("voiceAssistant", "streamEnd")
        _ipc("voiceAssistant", "status", "interrupted")
    except Exception as e:
        err_msg = str(e)
        _ipc("voiceAssistant", "streamEnd")
        _ipc("voiceAssistant", "status", "error")
        _ipc("voiceAssistant", "response", f"[Error] {err_msg}")
        print(f"pipe error: {err_msg}", file=sys.stderr)
    finally:
        clear_active_run_id()


HELP = """\
Commands:
  /help                    This help
  /key [VALUE]             Show or set the Letta API key
  /clear                   Clear display (memory kept)

  Agent management:
    /agents list|show|new|use|delete|export|import
    /models list|current|set
    /new                   Start a new conversation on current agent
    /skill-creator <name>
    /clone <agent_name_or_id>

  Chat:
    /chat <message>        One-off message
    /stream <message>      Streaming response
    /interrupt             Cancel the active run

  Memory:
    /blocks                Show all memory blocks
    /memory <label>        Show one block
    /set <label> <value>   Update a memory block
    /remember <text>       Store in archival memory
    /search <query>        Search archival memory
    /recall <query>        Search past messages

  Usage & runs:
    /usage                 Message & token usage summary
    /runs                  List recent background runs

  Files & MCP:
    /files add|attach|list
    /mcp add|list|tools|attach

  Advanced:
    /agent                 Show active agent ID
    /info                  Config summary
    /sleep on|off          Enable/disable sleeptime on active agent
    /exit                  Quit
"""


def _agent_model_name(agent) -> str:
    """Extract the best human-readable model name from an agent object."""
    # Try top-level .model field first
    m = getattr(agent, "model", None)
    if m and isinstance(m, str) and m.strip() and m != "letta/auto":
        return m.strip()
    # Fall back to llm_config sub-object
    llm = getattr(agent, "llm_config", None)
    if llm:
        for attr in ("handle", "model", "model_name"):
            v = getattr(llm, attr, None)
            if v and isinstance(v, str) and v.strip():
                return v.strip()
    # Last resort: return whatever .model has even if it's letta/auto
    return (m or "").strip() or "letta"


def _get_agent_by_ref(client, agent_ref: str):
    agents = client.agents.list()
    return next((a for a in agents if a.id == agent_ref or getattr(a, "name", None) == agent_ref), None)


def cmd_agents(client, subcmd, args):
    if subcmd == "list":
        agents = client.agents.list()
        if not agents:
            print("No agents found.")
            return
        active = get_active_agent_id()
        for a in agents:
            marker = " (active)" if a.id == active else ""
            print(f"{a.id}  {getattr(a, 'name', None) or '(unnamed)'}  {getattr(a, 'model', None) or '(unknown)'}{marker}")
        return

    if subcmd == "show":
        if not args:
            print("Usage: /agents show <agent_id_or_name>")
            return
        agent = _get_agent_by_ref(client, args[0])
        if not agent:
            print("Agent not found.")
            return
        print(f"ID        : {agent.id}")
        print(f"Name      : {getattr(agent, 'name', None) or '(unnamed)'}")
        print(f"Model     : {getattr(agent, 'model', None) or '(unknown)'}")
        print(f"Embedding : {getattr(agent, 'embedding', None) or getattr(agent, 'embedding_model', None) or '(unknown)'}")
        print(f"Tools     : {getattr(agent, 'tools', None) or '[]'}")
        print(f"Sleeptime : {getattr(agent, 'enable_sleeptime', None)}")
        blocks = get_memory_blocks(client, agent.id)
        print("\nMemory blocks:")
        for lbl, val in blocks.items():
            print(f"  {lbl}: {val or '(empty)'}")
        return

    if subcmd == "new":
        agent_id = _create_agent_with_prompt(client, name=args[0] if args else None, activate=False)
        if not agent_id:
            return
        if input("Use this agent now? [y/N]: ").strip().lower() == "y":
            set_active_agent_id(agent_id)
            print(f"Active agent set to {agent_id}")
        return

    if subcmd == "use":
        if not args:
            print("Usage: /agents use <agent_id_or_name>")
            return
        agent = _get_agent_by_ref(client, args[0])
        if not agent:
            print("Agent not found.")
            return
        set_active_agent_id(agent.id)
        print(f"Active agent set to {agent.id} ({getattr(agent, 'name', None) or 'unnamed'})")
        return

    if subcmd == "delete":
        if not args:
            print("Usage: /agents delete <agent_id_or_name>")
            return
        agent = _get_agent_by_ref(client, args[0])
        if not agent:
            print("Agent not found.")
            return
        confirm = input(f"Delete agent {agent.id}? Type YES to confirm: ").strip()
        if confirm != "YES":
            print("Aborted.")
            return
        client.agents.delete(agent.id)
        print(f"Agent {agent.id} deleted.")
        if get_active_agent_id() == agent.id:
            ACTIVE_AGENT_FILE.unlink(missing_ok=True)
            AGENT_ID_FILE.unlink(missing_ok=True)
            CONVERSATION_ID_FILE.unlink(missing_ok=True)
            _letta_cfg.pop("agent_id", None)
            _cfg["letta"] = _letta_cfg
            save_config(_cfg)
            print("Active agent cleared.")
        return

    if subcmd == "export":
        if len(args) < 2:
            print("Usage: /agents export <agent_id_or_name> <output_path.af>")
            return
        agent = _get_agent_by_ref(client, args[0])
        if not agent:
            print("Agent not found.")
            return
        blob = client.agents.export_file(agent_id=agent.id)
        out_file = Path(args[1]).expanduser()
        out_file.parent.mkdir(parents=True, exist_ok=True)
        out_file.write_bytes(blob)
        print(f"Exported {agent.id} to {out_file}")
        return

    if subcmd == "import":
        if not args:
            print("Usage: /agents import <file.af>")
            return
        in_path = Path(args[0]).expanduser()
        if not in_path.exists():
            print(f"File not found: {in_path}")
            return
        response = client.agents.import_file(file=in_path.read_bytes())
        print("Imported agent IDs:")
        for aid in response.agent_ids:
            print(f"  {aid}")
        if response.agent_ids and input("Use first imported agent now? [y/N]: ").strip().lower() == "y":
            set_active_agent_id(response.agent_ids[0])
            print(f"Active agent set to {response.agent_ids[0]}")
        return

    print("Usage: /agents list|show|new|use|delete|export|import")


def cmd_models(client, subcmd, args):
    if subcmd == "list":
        models = client.models.list()
        if not models:
            print("No models returned by Letta.")
            return
        print("Available Letta models:")
        for m in models:
            print(_model_summary_line(m))
        return

    if subcmd == "current":
        aid = get_active_agent_id()
        if not aid:
            print("No active agent.")
            return
        agent = _get_agent_by_ref(client, aid)
        if not agent:
            print("Active agent not found.")
            return
        model_handle = getattr(agent, "model", None)
        print(f"Active agent: {agent.id}")
        print(f"Model       : {model_handle}")
        m = _find_model(client, model_handle) if model_handle else None
        if m:
            print(f"Provider    : {getattr(m, 'provider_name', None) or getattr(m, 'provider_type', None) or 'unknown'}")
            print(f"Context     : {getattr(m, 'max_context_window', None) or getattr(m, 'context_window', None) or 'unknown'}")
            print(f"Display     : {getattr(m, 'display_name', None) or getattr(m, 'name', None) or '(none)'}")
            pt = getattr(m, 'provider_type', None)
            if pt == 'openai':
                print("Thinking    : configurable via reasoning / reasoning_effort")
            elif pt == 'anthropic':
                print("Thinking    : configurable via thinking + budget_tokens")
            elif pt in ('google_ai', 'google_vertex'):
                print("Thinking    : configurable via thinking_config")
            elif pt == 'zai':
                print("Thinking    : configurable via thinking {type, clear_thinking}")
            else:
                print("Thinking    : provider-specific / standard")
        ms = getattr(agent, 'model_settings', None)
        if ms:
            print(f"ModelSettings: {ms}")
        return

    if subcmd == "set":
        if not args:
            print("Usage: /models set <model_handle>")
            return
        model_handle = args[0]
        m = _find_model(client, model_handle)
        if not m:
            print(f"Model not found: {model_handle}")
            return
        provider_type = getattr(m, "provider_type", None)
        model_settings = _default_model_settings_for_provider(provider_type)
        aid = get_active_agent_id()
        if not aid:
            print("No active agent.")
            return
        client.agents.update(agent_id=aid, model=model_handle, model_settings=model_settings)
        _letta_cfg["model"] = model_handle
        _cfg["letta"] = _letta_cfg
        save_config(_cfg)
        print(f"Model updated to {model_handle}")
        print(f"Provider: {getattr(m, 'provider_name', None) or provider_type or 'unknown'}")
        print(f"Context : {getattr(m, 'max_context_window', None) or getattr(m, 'context_window', None) or 'unknown'}")
        if provider_type == 'openai':
            print("Thinking behavior: reasoning_effort=medium, parallel_tool_calls=True")
        elif provider_type == 'anthropic':
            print("Thinking behavior: thinking enabled, budget_tokens=2048")
        elif provider_type in ('google_ai', 'google_vertex'):
            print("Thinking behavior: thinking_config enabled, budget=2048, include_thoughts=True")
        elif provider_type == 'chatgpt_oauth':
            print("Thinking behavior: reasoning_effort=medium")
        elif provider_type == 'zai':
            print("Thinking behavior: thinking enabled, clear_thinking=False")
        else:
            print("Thinking behavior: standard provider defaults with temperature=0.2")
        return

    print("Usage: /models list|current|set")


def cmd_skill_creator(client, args):
    if not args:
        print("Usage: /skill-creator <skill_name>")
        return
    skill_name = args[0]
    description = input(f"Primary function of {skill_name}: ").strip() or f"Specialized assistant for {skill_name} tasks."
    tools_str = input("Tools (comma-separated, e.g. web_search,run_code): ").strip()
    tools = [t.strip() for t in tools_str.split(",") if t.strip()] if tools_str else []
    model = _letta_cfg.get("model", DEFAULT_MODEL)
    m = _find_model(client, model)
    provider_type = getattr(m, "provider_type", None) if m else None
    agent = client.agents.create(
        name=skill_name,
        model=model,
        embedding=_letta_cfg.get("embedding", DEFAULT_EMBEDDING),
        model_settings=_default_model_settings_for_provider(provider_type),
        memory_blocks=[
            {"label": "persona", "value": f"You are {skill_name}, a specialized assistant. Primary function: {description}. Be concise, reliable, and use tools only when necessary."},
            {"label": "human", "value": "User prefers technical and direct help."},
            {"label": "goals", "value": ""},
            {"label": "projects", "value": ""},
            {"label": "habits", "value": ""},
        ],
        tools=tools,
    )
    print(f"Created skill agent: {agent.id} ({skill_name})")
    if input("Use this agent now? [y/N]: ").strip().lower() == "y":
        set_active_agent_id(agent.id)
        print(f"Active agent set to {agent.id}")


def cmd_chat(client, agent_id, message):
    result = send_message(client, agent_id, message)
    print(extract_text(result.messages) or "(no response)")


def cmd_stream(client, agent_id, message):
    try:
        text = _stream_response(
            client,
            agent_id,
            message,
            on_token=lambda chunk: print(chunk, end="", flush=True),
            on_thinking=lambda chunk: print(f"\n[thinking] {chunk}", flush=True),
        )
        if text:
            print()
    except KeyboardInterrupt:
        run_id = get_active_run_id()
        try:
            cancel_active_run(client, agent_id, run_id)
        except Exception as e:
            print(f"\n[cancel failed: {e}]", flush=True)
        print("\n[interrupted]")
    finally:
        clear_active_run_id()


def cmd_interrupt(client, agent_id):
    run_id = get_active_run_id()
    cancel_active_run(client, agent_id, run_id)
    clear_active_run_id()
    print("Interrupted active run.")


def cmd_usage(client, agent_id):
    msgs = client.agents.messages.list(agent_id=agent_id)
    counts = Counter()
    sizes = defaultdict(int)
    for m in msgs:
        t = getattr(m, "message_type", "unknown")
        counts[t] += 1
        text = ""
        if getattr(m, "content", None):
            text = str(m.content)
        elif getattr(m, "reasoning", None):
            text = str(m.reasoning)
        elif getattr(m, "tool_return", None):
            text = json.dumps(m.tool_return, default=str)
        elif getattr(m, "tool_call", None):
            text = json.dumps(m.tool_call, default=str)
        sizes[t] += len(text)
    rough_tokens = {k: v // 4 for k, v in sizes.items()}
    print("Message counts:")
    for t, c in counts.items():
        print(f"  {t}: {c}")
    print("\nRough token estimate by type:")
    for t, tok in rough_tokens.items():
        print(f"  {t}: ~{tok}")
    print(f"\nRough total tokens: ~{sum(rough_tokens.values())}")


def cmd_runs(client, agent_id):
    runs = client.runs.list(agent_id=agent_id)
    if not runs:
        print("No background runs found.")
        return
    for r in runs[:20]:
        rid = getattr(r, "id", None) or getattr(r, "run_id", None)
        status = getattr(r, "status", None)
        print(f"{rid}  {status}")


def cmd_files(client, agent_id, subcmd, args):
    if subcmd == "list":
        folders = client.folders.list()
        if not folders:
            print("No folders found.")
            return
        for f in folders:
            print(f"{f.id}  {getattr(f, 'name', '(unnamed)')}")
        return

    if subcmd == "add":
        if len(args) < 2:
            print("Usage: /files add <folder_name> <file_path>")
            return
        folder_name, file_path = args[0], args[1]
        folders = client.folders.list()
        folder = next((f for f in folders if getattr(f, "name", None) == folder_name), None)
        if not folder:
            folder = client.folders.create(name=folder_name)
            print(f"Created folder: {folder.id} ({folder_name})")
        fpath = Path(file_path).expanduser()
        if not fpath.exists():
            print(f"File not found: {fpath}")
            return
        with open(fpath, "rb") as f:
            client.folders.files.upload(file=f, folder_id=folder.id)
        print(f"Uploaded {fpath.name} to folder {folder.id}")
        return

    if subcmd == "attach":
        if not args:
            print("Usage: /files attach <folder_name_or_id> [agent_id]")
            return
        ref = args[0]
        target_aid = args[1] if len(args) > 1 else agent_id
        folders = client.folders.list()
        folder = next((f for f in folders if f.id == ref or getattr(f, "name", None) == ref), None)
        if not folder:
            print("Folder not found.")
            return
        client.agents.folders.attach(agent_id=target_aid, folder_id=folder.id)
        print(f"Attached folder {folder.id} to agent {target_aid}")
        return

    print("Usage: /files add|attach|list")


def cmd_mcp(client, agent_id, subcmd, args):
    if subcmd == "list":
        servers = client.mcp_servers.list()
        if not servers:
            print("No MCP servers configured.")
            return
        for s in servers:
            print(f"{getattr(s, 'id', None)}  {getattr(s, 'server_name', None) or '(unnamed)'}")
        return

    if subcmd == "add":
        if len(args) < 3:
            print("Usage: /mcp add <server_name> <server_type> <server_url>")
            return
        server = client.mcp_servers.create(
            server_name=args[0],
            config={"mcp_server_type": args[1], "server_url": args[2]},
        )
        print(f"Created MCP server: {server.id} ({args[0]})")
        return

    if subcmd == "tools":
        if not args:
            print("Usage: /mcp tools <server_name_or_id>")
            return
        servers = client.mcp_servers.list()
        server = next((s for s in servers if s.id == args[0] or getattr(s, "server_name", None) == args[0]), None)
        if not server:
            print("Server not found.")
            return
        tools = client.mcp_servers.tools.list(server.id)
        if not tools:
            print("No tools found for this server.")
            return
        for t in tools:
            print(f"{getattr(t, 'id', None)}  {getattr(t, 'name', None) or '(unnamed)'}")
        return

    if subcmd == "attach":
        print("MCP attach should be implemented by fetching current agent tools and updating the tool set explicitly.")
        print("This avoids guessing undocumented single-tool attach behavior.")
        return

    print("Usage: /mcp add|list|tools|attach")


def cmd_clone(client, agent_ref):
    agent = _get_agent_by_ref(client, agent_ref)
    if not agent:
        print("Agent not found.")
        return
    blob = client.agents.export_file(agent_id=agent.id)
    response = client.agents.import_file(file=blob)
    print("Cloned agent IDs:")
    for aid in response.agent_ids:
        print(f"  {aid}")
    if response.agent_ids and input("Use first cloned agent now? [y/N]: ").strip().lower() == "y":
        set_active_agent_id(response.agent_ids[0])
        print(f"Active agent set to {response.agent_ids[0]}")


def cmd_sleep(client, agent_id, on_off):
    enable = on_off.lower() == "on"
    client.agents.update(agent_id=agent_id, enable_sleeptime=enable)
    print(f"Sleeptime {'enabled' if enable else 'disabled'} for agent {agent_id}")


def run_interactive() -> None:
    print("Letta Assistant — /help for commands")
    api_key = get_api_key()
    if not api_key:
        api_key = prompt_for_api_key(pipe_mode=False)

    client = make_client(api_key)
    interactive_tty = sys.stdin.isatty()
    agent_id = resolve_agent_id(client, interactive=interactive_tty)
    if not agent_id:
        print("No active agent selected.")
        if not interactive_tty:
            print("Open a terminal and run `voice-assistant text` to choose one, or use `/agents use` after selection.")
    if agent_id:
        resolve_conversation_id(client, agent_id)
    if agent_id:
        print(f"Active agent: {agent_id}\n")
    else:
        print()

    while True:
        try:
            raw = input("You > ").strip()
        except (EOFError, KeyboardInterrupt):
            print("\nGoodbye!")
            break
        if not raw:
            continue

        if raw.startswith("/"):
            parts = raw[1:].split(None, 2)
            cmd = parts[0].lower()
            args = parts[1:] if len(parts) > 1 else []

            if cmd in ("exit", "quit"):
                print("Goodbye!")
                break
            elif cmd in ("interrupt", "cancel"):
                cmd_interrupt(client, agent_id)
            elif cmd == "help":
                print(HELP)
            elif cmd == "key":
                if args:
                    save_api_key(args[0].strip())
                    client = make_client(args[0].strip())
                    print("✓ API key updated and saved to keyring.")
                else:
                    k = get_api_key()
                    print(f"Current key: {k[:8]}…{k[-4:]}" if k else "No key set.")
            elif cmd == "clear":
                print("Display cleared. Memory blocks preserved.")
            elif cmd == "agent":
                print(agent_id)
            elif cmd == "info":
                k = get_api_key()
                key_hint = f"{k[:8]}…{k[-4:]}" if k else "(not set)"
                print(f"Active agent : {agent_id}\nConfig       : {CONFIG_PATH}\nKey          : {key_hint}")
            elif cmd == "blocks":
                for lbl, val in get_memory_blocks(client, agent_id).items():
                    print(f"\n── {lbl} ──\n{val or '(empty)'}")
            elif cmd == "memory":
                if not args:
                    print("Usage: /memory <label>")
                else:
                    print(get_memory_blocks(client, agent_id).get(args[0].lower()) or f"(block '{args[0]}' not found)")
            elif cmd == "set":
                if len(args) < 2:
                    print("Usage: /set <label> <value>")
                else:
                    ok = update_memory_block(client, agent_id, args[0].lower(), args[1])
                    print("Updated." if ok else "Failed.")
            elif cmd == "remember":
                txt = args[0] if args else ""
                if not txt:
                    print("Usage: /remember <text>")
                else:
                    print("Stored." if insert_archival(client, agent_id, txt) else "Failed.")
            elif cmd == "search":
                q = args[0] if args else ""
                if not q:
                    print("Usage: /search <query>")
                else:
                    rs = search_archival(client, agent_id, q)
                    print("\n".join(f"{i}. {r}" for i, r in enumerate(rs, 1)) or "(no results)")
            elif cmd == "recall":
                q = args[0] if args else ""
                if not q:
                    print("Usage: /recall <query>")
                else:
                    rs = search_recall(client, agent_id, q)
                    print("\n".join(f"{i}. {r}" for i, r in enumerate(rs, 1)) or "(no results)")
            elif cmd == "agents":
                if not args:
                    print("Usage: /agents list|show|new|use|delete|export|import")
                else:
                    sub = args[0].split()[0] if len(args) == 1 and " " in args[0] else args[0]
                    rest = []
                    if len(parts) >= 3:
                        rest = parts[2].split()
                    cmd_agents(client, sub.lower(), rest)
                    maybe_agent = resolve_agent_id(client)
                    if maybe_agent:
                        agent_id = maybe_agent
            elif cmd == "models":
                if not args:
                    print("Usage: /models list|current|set")
                else:
                    sub = args[0].split()[0] if len(args) == 1 and " " in args[0] else args[0]
                    rest = []
                    if len(parts) >= 3:
                        rest = parts[2].split()
                    cmd_models(client, sub.lower(), rest)
            elif cmd == "new":
                cid = create_conversation(client, agent_id)
                print(f"Started a new conversation on the same agent: {cid}")
            elif cmd == "skill-creator":
                cmd_skill_creator(client, args)
                maybe_agent = resolve_agent_id(client)
                if maybe_agent:
                    agent_id = maybe_agent
            elif cmd == "chat":
                if not args:
                    print("Usage: /chat <message>")
                else:
                    msg = raw.split(None, 1)[1]
                    cmd_chat(client, agent_id, msg)
            elif cmd == "stream":
                if not args:
                    print("Usage: /stream <message>")
                else:
                    msg = raw.split(None, 1)[1]
                    cmd_stream(client, agent_id, msg)
            elif cmd == "usage":
                cmd_usage(client, agent_id)
            elif cmd == "runs":
                cmd_runs(client, agent_id)
            elif cmd == "files":
                if not args:
                    print("Usage: /files add|attach|list")
                else:
                    sub = args[0].split()[0] if len(args) == 1 and " " in args[0] else args[0]
                    rest = []
                    if len(parts) >= 3:
                        rest = parts[2].split()
                    cmd_files(client, agent_id, sub.lower(), rest)
            elif cmd == "mcp":
                if not args:
                    print("Usage: /mcp add|list|tools|attach")
                else:
                    sub = args[0].split()[0] if len(args) == 1 and " " in args[0] else args[0]
                    rest = []
                    if len(parts) >= 3:
                        rest = parts[2].split()
                    cmd_mcp(client, agent_id, sub.lower(), rest)
            elif cmd == "clone":
                if not args:
                    print("Usage: /clone <agent_name_or_id>")
                else:
                    cmd_clone(client, args[0])
                    maybe_agent = resolve_agent_id(client)
                    if maybe_agent:
                        agent_id = maybe_agent
            elif cmd == "sleep":
                if not args:
                    print("Usage: /sleep on|off")
                else:
                    cmd_sleep(client, agent_id, args[0])
            else:
                print(f"Unknown: /{cmd}  (/help)")
            continue

        if not agent_id:
            agent_id = resolve_agent_id(client, interactive=interactive_tty)
            if not agent_id:
                print("No active agent selected. Use /agents use or /agents new.")
                continue
        print("thinking…", end="", flush=True)
        try:
            result = send_message(client, agent_id, raw)
            print(f"\rAssistant > {extract_text(result.messages)}\n")
        except Exception as e:
            print(f"\rError: {e}", file=sys.stderr)


if __name__ == "__main__":
    argv = sys.argv[1:]
    if not argv or argv[0] == "text":
        run_interactive()
    elif argv[0] == "pipe":
        run_pipe()
    elif argv[0] == "cancel":
        client = make_client()
        agent_id = resolve_agent_id(client)
        if not agent_id:
            print("No active agent selected.", file=sys.stderr)
            sys.exit(1)
        cmd_interrupt(client, agent_id)
    elif argv[0] == "pipe-set" and len(argv) >= 3:
        run_pipe_set(argv[1], argv[2])
    else:
        print("Usage: voice-assistant.py [text|pipe|cancel|pipe-set <label> <value>]", file=sys.stderr)
