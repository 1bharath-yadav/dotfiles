"""Persistent state management for agent and conversation selection."""

from __future__ import annotations

import json
import os
import sys
from pathlib import Path


def get_state_dir() -> Path:
    """Get state directory following XDG spec."""
    state_home = os.getenv("XDG_STATE_HOME", os.path.expanduser("~/.local/state"))
    state_dir = Path(state_home) / "letta_assistant"
    state_dir.mkdir(parents=True, exist_ok=True)
    return state_dir


def get_state_file() -> Path:
    """Get state file path."""
    return get_state_dir() / "session.json"


def load_state() -> dict:
    """Load saved agent_id, conversation_id, and model_id from state file.
    
    Returns: {"agent_id": str, "conversation_id": str, "model_id": str}
    """
    state_file = get_state_file()
    if not state_file.exists():
        return {"agent_id": None, "conversation_id": None, "model_id": None}
    
    try:
        with open(state_file, "r") as f:
            data = json.load(f)
        return {
            "agent_id": data.get("agent_id"),
            "conversation_id": data.get("conversation_id"),
            "model_id": data.get("model_id"),
        }
    except (json.JSONDecodeError, IOError):
        return {"agent_id": None, "conversation_id": None, "model_id": None}


def save_state(agent_id: str, conversation_id: str, model_id: str | None = None) -> None:
    """Save agent_id, conversation_id, and model_id to state file."""
    state_file = get_state_file()
    try:
        with open(state_file, "w") as f:
            json.dump(
                {
                    "agent_id": agent_id,
                    "conversation_id": conversation_id,
                    "model_id": model_id,
                },
                f,
                indent=2,
            )
    except IOError as e:
        # Fail silently on state write errors
        print(f"[WARN] Could not save state: {e}", file=sys.stderr)


def save_model(model_id: str) -> None:
    """Update only the model_id in saved state. Preserves agent_id and conversation_id."""
    state = load_state()
    if state.get("agent_id") and state.get("conversation_id"):
        save_state(state["agent_id"], state["conversation_id"], model_id)


def clear_state() -> None:
    """Clear saved state."""
    state_file = get_state_file()
    try:
        state_file.unlink(missing_ok=True)
    except IOError:
        pass
