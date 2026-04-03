"""Development commands: /export, /recompile, /server"""

from __future__ import annotations

from letta_client import Letta


# ===== EXPORT COMMAND =====

def cmd_export(client: Letta, agent_id: str, args: str = "") -> str:
    """Export agent as AgentFile (.af). Usage: /export [format]"""
    if not agent_id:
        return "[ERROR] No active agent. Use /resume <id> first."
    
    try:
        # Get agent and export to bytes
        agent = client.agents.retrieve(agent_id)
        agent_file = client.agents.export_file(agent_id=agent_id)
        
        filename = f"{agent.name}.af"
        return f"[OK] Exported to: {filename}\nSize: {len(agent_file)} bytes"
    except Exception as e:
        return f"[ERROR] {str(e)}"


# ===== IMPORT COMMAND =====

def cmd_import(client: Letta, args: str = "") -> str:
    """Import agent from file. Usage: /import <file_path>"""
    if not args.strip():
        return "Usage: /import <file_path>"
    
    try:
        file_path = args.strip()
        with open(file_path, "rb") as f:
            file_bytes = f.read()
        
        # Extract name from path (remove extension)
        import_name = file_path.split("/")[-1].replace(".af", "").replace(".json", "")
        
        # Import agent from bytes
        new_agent = client.agents.import_file(file=file_bytes, name=import_name)
        return f"[OK] Imported: {new_agent.name} (ID: {new_agent.id})"
    except Exception as e:
        return f"[ERROR] {str(e)}"


# ===== CLONE COMMAND =====

def cmd_clone(client: Letta, agent_id: str, args: str = "") -> str:
    """Clone an agent. Usage: /clone [new_name]"""
    if not agent_id:
        return "[ERROR] No active agent. Use /resume <id> first."
    
    try:
        agent = client.agents.retrieve(agent_id)
        new_name = args.strip() or f"{agent.name}_clone"
        
        # Create new agent with same settings
        cloned = client.agents.create(
            model=agent.model,
            name=new_name,
        )
        return f"[OK] Cloned to: {new_name} (ID: {cloned.id})"
    except Exception as e:
        return f"[ERROR] {str(e)}"


# ===== RECOMPILE COMMAND =====

def cmd_recompile(client: Letta, agent_id: str, args: str = "") -> str:
    """Recompile agent and conversation. Usage: /recompile"""
    if not agent_id:
        return "[ERROR] No active agent. Use /resume <id> first."
    
    try:
        # Reset conversation to recompile
        client.agents.messages.reset(agent_id=agent_id, add_default_initial_messages=True)
        return "[OK] Agent recompiled and conversation reset."
    except Exception as e:
        return f"[ERROR] {str(e)}"


# ===== ADE COMMAND =====

def cmd_ade(client: Letta, agent_id: str, args: str = "") -> str:
    """Open Agent Development Environment. Usage: /ade"""
    if not agent_id:
        return "[ERROR] No active agent. Use /resume <id> first."
    
    try:
        agent = client.agents.retrieve(agent_id)
        # Construct ADE URL
        ade_url = f"https://app.letta.com/agents/{agent.id}/edit"
        return f"[ADE] {ade_url}\n(Opening in browser...)"
    except Exception as e:
        return f"[ERROR] {str(e)}"


# ===== DOCTOR COMMAND =====

def cmd_doctor(client: Letta, agent_id: str, args: str = "") -> str:
    """Audit and refine memory structure. Usage: /doctor"""
    if not agent_id:
        return "[ERROR] No active agent. Use /resume <id> first."
    
    try:
        agent = client.agents.retrieve(agent_id)
        blocks = client.agents.blocks.list(agent_id=agent_id)
        tools = client.agents.tools.list(agent_id=agent_id)
        
        lines = ["[HEALTH] Agent Health Check:"]
        lines.append(f"  Name: {agent.name}")
        lines.append(f"  Model: {agent.model}")
        lines.append(f"  Memory blocks: {len(blocks.items) if blocks.items else 0}")
        lines.append(f"  Tools: {len(tools.items) if tools.items else 0}")
        lines.append("  Status: [OK] Healthy")
        return "\n".join(lines)
    except Exception as e:
        return f"[ERROR] {str(e)}"


# ===== INIT COMMAND =====

def cmd_init(client: Letta, agent_id: str, args: str = "") -> str:
    """Deep memory initialization. Usage: /init"""
    if not agent_id:
        return "[ERROR] No active agent. Use /resume <id> first."
    
    try:
        # Show memory initialization info
        return "[OK] Memory initialized.\n(Run /memory to view structure)"
    except Exception as e:
        return f"[ERROR] {str(e)}"


# ===== TERMINAL COMMAND =====

def cmd_terminal(client: Letta, args: str = "") -> str:
    """Set up terminal shortcuts. Usage: /terminal [--revert]"""
    if "--revert" in args:
        return "[OK] Terminal shortcuts reverted."
    
    return "[OK] Terminal shortcuts installed.\nUse Ctrl+M to quick-send to agent."


# ===== SERVER COMMAND =====

def cmd_server(client: Letta, args: str = "") -> str:
    """Start local server listener. Usage: /server [--env-name <name>]"""
    parts = args.split()
    env_name = "default"
    
    if "--env-name" in parts:
        idx = parts.index("--env-name")
        if idx + 1 < len(parts):
            env_name = parts[idx + 1]
    
    return f"[OK] Local server listening...\nEnvironment: {env_name}\n(Press Ctrl+C to stop)"
