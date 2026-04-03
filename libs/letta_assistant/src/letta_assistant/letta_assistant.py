"""Letta Assistant REPL - Main CLI entrypoint.

Usage:
    python -m letta_assistant
    
Startup:
    1. Check LETTA_API_KEY environment variable
    2. Initialize client
    3. Load available models
    4. Load agents list
    5. Load active agent (most recent)
    6. Start REPL with tab completion
"""

from __future__ import annotations

import os
import re
import subprocess
import sys
from typing import Callable

from letta_client import Letta

from letta_assistant.services import letta_service as svc
from letta_assistant.commands import agents, conversations, config, memory, messages, tools, skills, dev
from letta_assistant.utils import state

# ===== STARTUP SEQUENCE =====

def get_api_key() -> str:
    """Get API key from environment, secret-tool, or prompt user.
    
    Priority:
    1. LETTA_API_KEY environment variable (if valid)
    2. secret-tool lookup (letta_key) - if valid
    3. User prompt (stores in secret-tool for future sessions)
    """
    # Check environment first
    key = os.getenv("LETTA_API_KEY", "").strip()
    if key and key.startswith("sk-"):
        return key
    
    # Try to get from secret-tool
    try:
        result = subprocess.run(
            ["secret-tool", "lookup", "letta_key", "sk"],
            capture_output=True,
            text=True,
            check=False,
            timeout=5,
        )
        if result.returncode == 0:
            key = result.stdout.strip()
            if key and key.startswith("sk-"):
                return key
    except (FileNotFoundError, subprocess.TimeoutExpired):
        pass
    
    # Prompt user for key
    print("\n[API KEY SETUP]")
    print("Get your key at: https://app.letta.com/settings")
    print("")
    try:
        key = input("Enter your Letta API key (sk-...): ").strip()
        if not key:
            print("[ERROR] API key cannot be empty.")
            sys.exit(1)
        
        if not key.startswith("sk-"):
            print("[WARN] API key should start with 'sk-'. Using anyway...")
        
        # Store in secret-tool for future sessions
        try:
            subprocess.run(
                ["secret-tool", "store", "--label=Letta API Key", "letta_key", "sk"],
                input=key,
                capture_output=True,
                text=True,
                check=True,
                timeout=5,
            )
            print("[OK] API key saved to system keyring.")
        except (subprocess.CalledProcessError, FileNotFoundError, subprocess.TimeoutExpired):
            print("[WARN] Could not save to keyring. Set LETTA_API_KEY environment variable instead.")
        
        return key
    except KeyboardInterrupt:
        print("\n[ERROR] Setup cancelled.")
        sys.exit(1)


def bootstrap() -> tuple[Letta, str, str]:
    """Initialize client: select agent, then conversation.
    
    Returns: (client, agent_id, conversation_id)
    """
    api_key = get_api_key()
    print("🔑 Initializing Letta client...")
    client = svc.init_client(api_key)
    
    # Try to load saved state
    saved_state = state.load_state()
    saved_agent_id = saved_state.get("agent_id")
    saved_conversation_id = saved_state.get("conversation_id")
    
    # Get agents list
    agents_page = svc.get_agents(client)
    agents_list = list(agents_page)
    
    if not agents_list:
        print("[ERROR] No agents found.")
        print("Create one using: /new <name>")
        sys.exit(1)
    
    # Check if saved agent exists and is valid
    agent = None
    if saved_agent_id:
        for a in agents_list:
            if a.id == saved_agent_id:
                agent = a
                break
    
    # Check if saved conversation exists and is valid
    conversation_id = None
    if agent and saved_conversation_id:
        conversations_page = client.conversations.list(agent_id=agent.id)
        conversations_list = list(conversations_page)
        for conv in conversations_list:
            if conv.id == saved_conversation_id:
                conversation_id = conv.id
                break
    
    # If both are valid, use them without prompting
    if agent and conversation_id:
        print(f"[OK] Resuming: Agent={agent.name}, Conversation={saved_conversation_id}")
        state.save_state(agent.id, conversation_id)
        return client, agent.id, conversation_id
    
    # Otherwise, prompt for agent
    print("\n[SELECT AGENT]")
    default_agent = agent
    default_agent_idx = 0
    
    for i, agent in enumerate(agents_list):
        if default_agent and agent.id == default_agent.id:
            default_agent_idx = i
    
    for i, a in enumerate(agents_list, 1):
        marker = " <-- (saved)" if default_agent and a.id == default_agent.id else ""
        print(f"  {i}. {a.name} (ID: {a.id}, Model: {a.model}){marker}")
    
    try:
        default_display = f"{default_agent_idx + 1}" if default_agent else ""
        if default_display:
            choice = input(f"\nSelect agent (1-{len(agents_list)}) [default: {default_display}]: ").strip()
        else:
            choice = input(f"\nSelect agent (1-{len(agents_list)}): ").strip()
        
        if not choice and default_agent:
            agent = default_agent
        else:
            idx = int(choice) - 1
            if not (0 <= idx < len(agents_list)):
                raise ValueError("Invalid selection")
            agent = agents_list[idx]
    except (ValueError, IndexError):
        print("[ERROR] Invalid selection")
        sys.exit(1)
    
    agent_id = agent.id
    print(f"[OK] Selected: {agent.name}")
    
    # Prompt for conversation
    print(f"\n[SELECT CONVERSATION] for {agent.name}:")
    conversations_page = client.conversations.list(agent_id=agent_id)
    conversations_list = list(conversations_page)
    
    # Check if saved conversation exists for this agent
    default_conversation = None
    default_conversation_idx = 0
    if saved_conversation_id and saved_agent_id == agent_id:
        for i, conv in enumerate(conversations_list):
            if conv.id == saved_conversation_id:
                default_conversation = conv
                default_conversation_idx = i
                break
    
    if conversations_list:
        for i, conv in enumerate(conversations_list, 1):
            marker = " <-- (saved)" if default_conversation and conv.id == default_conversation.id else ""
            print(f"  {i}. Conversation {conv.id}{marker}")
        print(f"  {len(conversations_list) + 1}. Create new conversation")
        
        try:
            default_display = f"{default_conversation_idx + 1}" if default_conversation else ""
            if default_display:
                choice = input(f"\nSelect conversation (1-{len(conversations_list) + 1}) [default: {default_display}]: ").strip()
            else:
                choice = input(f"\nSelect conversation (1-{len(conversations_list) + 1}): ").strip()
            
            if not choice and default_conversation:
                conversation_id = default_conversation.id
                print(f"[OK] Selected conversation: {conversation_id}")
            else:
                idx = int(choice) - 1
                if not (0 <= idx <= len(conversations_list)):
                    raise ValueError("Invalid selection")
                
                if idx == len(conversations_list):
                    print("Creating new conversation...")
                    conv = client.conversations.create(agent_id=agent_id)
                    conversation_id = conv.id
                    print(f"[OK] Created conversation: {conversation_id}")
                else:
                    conversation_id = conversations_list[idx].id
                    print(f"[OK] Selected conversation: {conversation_id}")
        except (ValueError, IndexError):
            print("[ERROR] Invalid selection")
            sys.exit(1)
    else:
        print("No conversations found. Creating new conversation...")
        conv = client.conversations.create(agent_id=agent_id)
        conversation_id = conv.id
        print(f"[OK] Created conversation: {conversation_id}")
    
    # Save state for next session
    state.save_state(agent_id, conversation_id)
    
    return client, agent_id, conversation_id


# ===== COMMAND REGISTRY =====

COMMANDS: dict[str, Callable] = {
    # Agents (from agents.py)
    "agents": agents.cmd_agents_list,
    "new": agents.cmd_new_agent,
    "retrieve": agents.cmd_retrieve,
    "update": agents.cmd_update,
    "delete": agents.cmd_delete,
    "pin": agents.cmd_pin,
    "unpin": agents.cmd_unpin,
    
    # Conversations (from conversations.py)
    "resume": conversations.cmd_resume,
    "clear": conversations.cmd_clear,
    "compact": conversations.cmd_compact,
    "search": conversations.cmd_search,
    "context": conversations.cmd_context,
    
    # Configuration (from config.py)
    "system": config.cmd_system,
    "init": config.cmd_init,
    "doctor": config.cmd_doctor,
    "statusline": config.cmd_statusline,
    "sleeptime": config.cmd_sleeptime,
    
    # Messages
    "ask": messages.cmd_ask,
    "stream": messages.cmd_stream,
    "history": messages.cmd_history,
    
    # Memory
    "blocks": memory.cmd_blocks,
    "passages": memory.cmd_passages,
    
    # Tools
    "tools": tools.cmd_tools_list,
    "attached": tools.cmd_attached,
    "attach": tools.cmd_attach_tool,
    "detach": tools.cmd_detach_tool,
    
    # Skills & MCP
    "mcp": skills.cmd_mcp,
    "secret": skills.cmd_secret,
    "skill": skills.cmd_skill,
    "skills": skills.cmd_skills_list,
    
    # Development
    "export": dev.cmd_export,
    "import": dev.cmd_import,
    "clone": dev.cmd_clone,
    "recompile": dev.cmd_recompile,
    "ade": dev.cmd_ade,
    "terminal": dev.cmd_terminal,
    "server": dev.cmd_server,
    
}

HELP_TEXT = """
[LETTA ASSISTANT COMMANDS]

AGENTS
  /agents          List all agents
  /new <name>      Create new agent
  /retrieve <id>   Get agent details
  /update <id>     Update agent
  /delete <id>     Delete agent
  /pin <id>        Pin agent
  /unpin <id>      Unpin agent
  /agent           Show active agent
  /model [id]      Show or set active model

CONVERSATIONS
  /resume [id]     List/resume conversations
  /clear           Clear all messages
  /compact [mode]  Summarize history
  /search <text>   Search messages
  /context         Show context window
  /new             Create conversation

MESSAGES
  /ask <text>      Send message (single)
  /stream <text>   Send message (stream)
  /history [n]     Show last n messages

MEMORY
  /blocks [label]  View memory blocks
  /passages [q]    Search archival memory

FILES
  /files list      List folders
  /files add       Upload file to folder
  /files attach    Folder attach (pending)

TOOLS
  /tools           List available tools
  /attached        List attached tools
  /attach <id>     Add tool
  /detach <id>     Remove tool

CONFIGURATION
  /system [text]   View/set system prompt
  /status          Show active agent status
  /init            Reinitialize memory
  /doctor          Audit memory
  /statusline      Configure status bar
  /sleeptime       Configure reflection

SKILLS & MCP
  /mcp [action]    Manage MCP servers
  /secret [cmd]    Manage secrets
  /skill <desc>    Create custom skill
  /skills          List available skills

DEVELOPMENT
  /export          Export as file
  /import <file>   Import from file
  /clone [name]    Clone agent
  /recompile       Reset and recompile
  /ade             Open editor
  /terminal        Setup shortcuts
  /server          Start listener

SYSTEM
  /help            Show this help
  /exit, /quit     Exit REPL
""".strip()

CONVERSATION_COMMANDS = {"clear", "compact", "search"}
CONTEXT_ONLY_COMMANDS = {"context"}
AGENT_COMMANDS = {
    "system", "init", "doctor", "statusline", "sleeptime",
    "ask", "stream", "history",
    "blocks", "passages",
    "attached", "attach", "detach",
    "skill",
    "export", "clone", "recompile", "ade",
}
GLOBAL_COMMANDS = {
    "agents", "retrieve", "update", "delete", "pin", "unpin",
    "tools", "mcp", "secret", "skills",
    "import", "terminal", "server",
}


def get_help_text() -> str:
    """Return CLI help text."""
    return HELP_TEXT


def _extract_created_id(result: str) -> str | None:
    match = re.search(r"\[OK\]\s+Created:\s+([^\s]+)", result)
    return match.group(1) if match else None


def _extract_agent_id(result: str) -> str | None:
    match = re.search(r"\(ID:\s*([^)]+)\)", result)
    if match:
        return match.group(1).strip()
    match = re.search(r"\bagent-[A-Za-z0-9-]+\b", result)
    return match.group(0) if match else None


def _split_subcommand(args: str) -> tuple[str, str]:
    parts = args.strip().split(maxsplit=1)
    if not parts:
        return "", ""
    return parts[0], parts[1] if len(parts) > 1 else ""


def _cmd_model(client: Letta, agent_id: str, args: str = "") -> str:
    """Show or set active agent model. Usage: /model [model_id]"""
    if not agent_id:
        return "[ERROR] No active agent. Use /resume <id> first."
    if not args.strip():
        agent = svc.get_agent(client, agent_id)
        return f"[MODEL] {agent.model}"
    model_id = args.strip()
    svc.update_agent(client, agent_id, model=model_id)
    return f"[OK] Model set to: {model_id}"


def _cmd_agent(client: Letta, agent_id: str, args: str = "") -> str:
    """Show active agent id. Usage: /agent"""
    if not agent_id:
        return "[ERROR] No active agent. Use /resume <id> first."
    if args.strip():
        return "Usage: /agent"
    return f"[AGENT] {agent_id}"


def _cmd_status(client: Letta, agent_id: str, conversation_id: str, args: str = "") -> str:
    """Show active agent status. Usage: /status"""
    if not agent_id:
        return "[ERROR] No active agent. Use /resume <id> first."
    agent = svc.get_agent(client, agent_id)
    lines = [
        "[STATUS]",
        f"  Agent: {agent.name}",
        f"  ID: {agent.id}",
        f"  Model: {agent.model}",
    ]
    if conversation_id:
        lines.append(f"  Conversation: {conversation_id}")
    return "\n".join(lines)


def _cmd_files(client: Letta, agent_id: str, args: str = "") -> str:
    """File/folder helpers. Usage: /files [list|add|attach]"""
    subcmd, rest = _split_subcommand(args)
    if subcmd == "list":
        page = svc.get_folders(client)
        if not page.items:
            return "[FILES] No folders found."
        lines = ["[FILES] Folders:"]
        for folder in page.items:
            name = getattr(folder, "name", "") or "unnamed"
            lines.append(f"  {folder.id}  {name}")
        return "\n".join(lines)
    if subcmd == "add":
        parts = rest.split(maxsplit=1)
        if len(parts) < 2:
            return "Usage: /files add <folder_id> <file_path>"
        folder_id, file_path = parts[0], parts[1]
        if not os.path.exists(file_path):
            return f"[ERROR] File not found: {file_path}"
        svc.upload_file(client, folder_id, file_path)
        return f"[OK] Uploaded file to folder: {folder_id}"
    if subcmd == "attach":
        return "[PENDING] Folder attachment not yet exposed in backend."
    return "Usage: /files [list|add|attach]"


def run_command_line(
    client: Letta,
    current_agent: str,
    current_conversation: str,
    line: str,
    on_thinking: callable = None,
    on_token: callable = None,
    on_stream_start: callable = None,
    on_event: callable = None,
    should_cancel: callable = None,
    echo: bool = True,
) -> tuple[str, str, str, dict]:
    """Execute one raw CLI/daemon line against the active Letta session."""
    meta = {"exit_requested": False, "streamed": False}

    if not line.startswith("/"):
        result = messages.cmd_stream(
            client,
            current_agent,
            line,
            conversation_id=current_conversation,
            on_thinking=on_thinking,
            on_token=on_token,
            on_stream_start=on_stream_start,
            on_event=on_event,
            should_cancel=should_cancel,
            echo=echo,
        )
        meta["streamed"] = True
        return result, current_agent, current_conversation, meta

    parts = line[1:].split(maxsplit=1)
    cmd = parts[0]
    args = parts[1] if len(parts) > 1 else ""

    # Grouped command aliases (UI sugar).
    subcmd, rest = _split_subcommand(args)
    if cmd == "resume" and subcmd:
        if subcmd == "list":
            args = ""
        elif subcmd == "use":
            args = rest
    elif cmd == "agents" and subcmd:
        if subcmd == "list":
            args = ""
        elif subcmd == "show":
            cmd, args = "retrieve", rest
        elif subcmd == "new":
            cmd, args = "new", rest
        elif subcmd == "delete":
            cmd, args = "delete", rest
        elif subcmd == "export":
            cmd, args = "export", rest
        elif subcmd == "import":
            cmd, args = "import", rest
        elif subcmd == "use":
            if not rest.strip():
                return "Usage: /agents use <agent_id>", current_agent, current_conversation, meta
            try:
                svc.get_agent(client, rest.strip())
            except Exception:
                return f"[ERROR] Agent not found: {rest.strip()}", current_agent, current_conversation, meta
            current_agent = rest.strip()
            try:
                conversation = client.conversations.create(agent_id=current_agent)
                current_conversation = conversation.id
                return (
                    f"[OK] Using agent: {current_agent}\n[OK] Created conversation: {current_conversation}",
                    current_agent,
                    current_conversation,
                    meta,
                )
            except Exception as exc:
                return (
                    f"[OK] Using agent: {current_agent}\n[WARN] Could not create conversation: {exc}",
                    current_agent,
                    current_conversation,
                    meta,
                )
    elif cmd == "messages" and subcmd in {"ask", "stream", "history"}:
        cmd, args = subcmd, rest
    elif cmd == "memory" and subcmd in {"blocks", "passages"}:
        cmd, args = subcmd, rest
    elif cmd == "config" and subcmd in {"system", "init", "doctor", "statusline", "sleeptime"}:
        cmd, args = subcmd, rest
    elif cmd == "models" and subcmd:
        if subcmd == "list":
            cmd, args = "statusline", ""
        elif subcmd == "current":
            cmd, args = "model", ""
        elif subcmd == "set":
            cmd, args = "model", rest
    elif cmd == "skills" and subcmd == "create":
        cmd, args = "skill", rest
    elif cmd == "dev" and subcmd:
        if subcmd in {"export", "import", "clone", "recompile", "ade", "terminal", "server"}:
            cmd, args = subcmd, rest
    elif cmd == "sleep" and subcmd in {"on", "off"}:
        cmd, args = "sleeptime", subcmd
    elif cmd == "secret" and subcmd:
        cmd, args = "secret", f"{subcmd} {rest}".strip()

    if cmd in {"exit", "quit"}:
        meta["exit_requested"] = True
        return "[OK] Goodbye!", current_agent, current_conversation, meta

    if cmd == "help":
        return get_help_text(), current_agent, current_conversation, meta

    if cmd == "model":
        return _cmd_model(client, current_agent, args), current_agent, current_conversation, meta

    if cmd == "agent":
        return _cmd_agent(client, current_agent, args), current_agent, current_conversation, meta

    if cmd == "status":
        return _cmd_status(client, current_agent, current_conversation, args), current_agent, current_conversation, meta

    if cmd == "files":
        return _cmd_files(client, current_agent, args), current_agent, current_conversation, meta

    if cmd == "new":
        if args.strip():
            result = agents.cmd_new_agent(client, args)
            new_agent_id = _extract_agent_id(result)
            if new_agent_id:
                current_agent = new_agent_id
                try:
                    conversation = client.conversations.create(agent_id=current_agent)
                    current_conversation = conversation.id
                    result = f"{result}\n[OK] Created conversation: {current_conversation}"
                except Exception as exc:
                    result = f"{result}\n[WARN] Could not create conversation: {exc}"
            return result, current_agent, current_conversation, meta

        result = conversations.cmd_new_conversation(client, current_agent, args)
        created_conversation = _extract_created_id(result)
        if created_conversation:
            current_conversation = created_conversation
        return result, current_agent, current_conversation, meta

    if cmd == "resume":
        result = conversations.cmd_resume(client, current_agent, args)
        if args.strip() and "[OK]" in result:
            current_conversation = args.strip()
        return result, current_agent, current_conversation, meta

    if cmd not in COMMANDS:
        return f"[ERROR] Unknown command: /{cmd}", current_agent, current_conversation, meta

    handler = COMMANDS[cmd]

    if cmd in CONVERSATION_COMMANDS:
        result = handler(client, current_agent, current_conversation, args)
    elif cmd in CONTEXT_ONLY_COMMANDS:
        result = handler(client, current_agent, current_conversation)
    elif cmd in {"ask", "stream", "history"}:
        result = handler(client, current_agent, args, conversation_id=current_conversation)
    elif cmd in AGENT_COMMANDS:
        result = handler(client, current_agent, args)
    elif cmd in GLOBAL_COMMANDS:
        result = handler(client, args)
    else:
        result = handler(client, args)

    return result, current_agent, current_conversation, meta


# ===== REPL =====

def repl(client: Letta, agent_id: str, conversation_id: str) -> None:
    """Interactive REPL loop."""
    print(f"\n[LETTA ASSISTANT]")
    print(f"Agent: {agent_id}")
    print(f"Conversation: {conversation_id}")
    print("Type /help for commands. Ctrl+D to exit.\n")

    current_agent = agent_id
    current_conversation = conversation_id

    try:
        while True:
            try:
                agent = svc.get_agent(client, current_agent)
                prompt = f"@{agent.name}> "

                line = input(prompt).strip()

                if not line:
                    continue

                if line == "/exit" or line == "/quit":
                    state.save_state(current_agent, current_conversation)
                    print("[OK] Goodbye!")
                    break

                result, current_agent, current_conversation, meta = run_command_line(
                    client,
                    current_agent,
                    current_conversation,
                    line,
                )

                state.save_state(current_agent, current_conversation)

                if meta["exit_requested"]:
                    print(result)
                    break

                # Streaming output is already printed token-by-token.
                if not meta["streamed"] or ("[ERROR]" in result or "[PENDING]" in result):
                    print(result)

            except KeyboardInterrupt:
                state.save_state(current_agent, current_conversation)
                print("\n[OK] Interrupted.")
                break
            except EOFError:
                state.save_state(current_agent, current_conversation)
                print("\n[OK] Goodbye!")
                break
            except Exception as e:
                print(f"[ERROR] {e}")

    except KeyboardInterrupt:
        print("\n[OK] Goodbye!")


def print_help() -> None:
    """Print help message."""
    print(get_help_text())


# ===== MAIN =====

def main() -> None:
    """Main entry point."""
    try:
        client, agent_id, conversation_id = bootstrap()
        repl(client, agent_id, conversation_id)
    except KeyboardInterrupt:
        print("\n[OK] Interrupted.")
        sys.exit(0)
    except Exception as e:
        print(f"[ERROR] Fatal error: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
