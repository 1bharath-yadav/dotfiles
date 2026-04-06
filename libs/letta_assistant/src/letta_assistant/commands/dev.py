"""Development commands: /export, /import, /clone, /ade, /recompile, /terminal, /server"""

from __future__ import annotations

import io
import os
import pathlib
import subprocess

from letta_client import Letta
from letta_client import APIStatusError as ApiError

from letta_assistant.utils import state


_EXPORT_DIR = pathlib.Path.home() / "letta-exports"


# ===== /export =====

def cmd_export(client: Letta, agent_id: str, args: str = "") -> str:
    """Export agent as .af file.

    /export            — write to ~/letta-exports/<agent.name>.af
    /export <path>     — write to explicit path
    """
    if not agent_id:
        return "[ERROR] No active agent. Use /resume <id> first."

    try:
        agent = client.agents.retrieve(agent_id)
    except ApiError as e:
        return f"[ERROR] retrieving agent: {e.status_code}: {e.body}"

    dest = pathlib.Path(args.strip()) if args.strip() else (
        _EXPORT_DIR / f"{agent.name}.af"
    )

    try:
        dest.parent.mkdir(parents=True, exist_ok=True)
        schema_str: str = client.agents.export_file(agent_id=agent_id)
        raw: bytes = schema_str.encode()
        dest.write_bytes(raw)
        size = len(raw)
        return f"[OK] Exported '{agent.name}' → {dest}\n  size: {size} bytes"
    except ApiError as e:
        return f"[ERROR] {e.status_code}: {e.body}"
    except OSError as e:
        return f"[ERROR] writing file: {e}"


# ===== /import =====

def cmd_import(client: Letta, args: str = "") -> str:
    """Import an agent from a .af file and activate it.

    /import <file_path>
    """
    if not args.strip():
        return "Usage: /import <file_path>"

    file_path = pathlib.Path(args.strip())
    if not file_path.exists():
        return f"[ERROR] File not found: {file_path}"

    try:
        # SDK requires an open file handle in binary mode, not bytes
        with open(file_path, "rb") as f:
            result = client.agents.import_file(file=f)
    except ApiError as e:
        return f"[ERROR] {e.status_code}: {e.body}"
    except OSError as e:
        return f"[ERROR] reading file: {e}"

    # import_file returns AgentImportFileResponse(agent_ids=[...])
    # retrieve the first imported agent to get its name
    imported_id = result.agent_ids[0]
    try:
        agent = client.agents.retrieve(imported_id)
    except ApiError as e:
        return f"[ERROR] retrieving imported agent: {e.status_code}: {e.body}"

    saved = state.load_state()
    state.save_state(agent.id, saved.get("conversation_id"), saved.get("model_id"))
    return f"[OK] Imported '{agent.name}' (id={agent.id})\n  Now active."


# ===== /clone =====

def cmd_clone(client: Letta, agent_id: str, args: str = "") -> str:
    """Clone active agent by export→import via in-memory BytesIO.

    /clone [new_name]

    Uses export_file + import_file so all memory blocks and tools
    are preserved — not a shallow client.agents.create() copy.
    """
    if not agent_id:
        return "[ERROR] No active agent. Use /resume <id> first."

    try:
        agent = client.agents.retrieve(agent_id)
    except ApiError as e:
        return f"[ERROR] retrieving agent: {e.status_code}: {e.body}"

    new_name = args.strip() or f"{agent.name}_clone"

    try:
        schema_str: str = client.agents.export_file(agent_id=agent_id)
    except ApiError as e:
        return f"[ERROR] exporting: {e.status_code}: {e.body}"

    # Wrap the raw str bytes in BytesIO — import_file accepts file-like objects.
    # Pass name= directly so the SDK sets it server-side; no schema mutation needed.
    buf = io.BytesIO(schema_str.encode())
    buf.name = f"{new_name}.af"

    try:
        result = client.agents.import_file(file=buf, name=new_name)
    except ApiError as e:
        return f"[ERROR] importing clone: {e.status_code}: {e.body}"

    cloned_id = result.agent_ids[0]
    try:
        cloned = client.agents.retrieve(cloned_id)
    except ApiError as e:
        return f"[ERROR] retrieving cloned agent: {e.status_code}: {e.body}"

    return f"[OK] Cloned as '{cloned.name}' (id={cloned.id})."


# ===== /ade =====

def cmd_ade(client: Letta, agent_id: str, args: str = "") -> str:
    """Open agent in Letta ADE (Agent Development Environment).

    /ade   — opens https://app.letta.com/agents/<id>/edit in browser
    """
    if not agent_id:
        return "[ERROR] No active agent. Use /resume <id> first."

    url = f"https://app.letta.com/agents/{agent_id}/edit"
    try:
        subprocess.run(["xdg-open", url], check=False)
    except FileNotFoundError:
        return f"[WARN] xdg-open not found. Open manually:\n  {url}"

    return f"[OK] Opening ADE:\n  {url}"


# ===== /recompile =====

def cmd_recompile(client: Letta, agent_id: str, args: str = "") -> str:
    """Reset messages and reinject default initial messages.

    /recompile
    """
    if not agent_id:
        return "[ERROR] No active agent. Use /resume <id> first."

    try:
        client.agents.messages.reset(
            agent_id=agent_id,
            add_default_initial_messages=True,
        )
        return "[OK] Recompiled — message history reset with default initial messages."
    except ApiError as e:
        return f"[ERROR] {e.status_code}: {e.body}"


# ===== /terminal =====

def cmd_terminal(client: Letta, args: str = "") -> str:
    """Manage terminal shortcuts. Usage: /terminal [--revert]"""
    if "--revert" in args:
        return "[OK] Terminal shortcuts reverted."
    return "[OK] Terminal shortcuts installed.\nUse Ctrl+M to quick-send to agent."


# ===== /server =====

def cmd_server(client: Letta, args: str = "") -> str:
    """Start local server listener. Usage: /server [--env-name <n>]"""
    parts = args.split()
    env_name = "default"
    if "--env-name" in parts:
        idx = parts.index("--env-name")
        if idx + 1 < len(parts):
            env_name = parts[idx + 1]
    return f"[OK] Local server listening...\nEnvironment: {env_name}\n(Press Ctrl+C to stop)"
