"""Persistent app configuration backed by XDG_STATE_HOME JSON.

Manages: base_url, embedding_model, embedding_endpoint.
api_key is runtime-only (env var or keyring) — never written to disk.

Priority resolution:
  api_key  → LETTA_API_KEY env → secret-tool keyring → interactive prompt
  base_url → LETTA_BASE_URL env → config.json → None (SDK default)
"""

from __future__ import annotations

import json
import os
from pathlib import Path

_CONFIG_FILE = "config.json"

_DEFAULTS: dict = {
    "base_url": None,           # None → SDK default (https://api.letta.com)
    "embedding_model": None,    # None → agent-level default
    "embedding_endpoint": None,
}


def get_config_file() -> Path:
    """XDG path: ~/.local/state/letta_assistant/config.json"""
    state_home = os.getenv("XDG_STATE_HOME", os.path.expanduser("~/.local/state"))
    config_dir = Path(state_home) / "letta_assistant"
    config_dir.mkdir(parents=True, exist_ok=True)
    return config_dir / _CONFIG_FILE


def load() -> dict:
    """Load config; missing keys fall back to _DEFAULTS."""
    path = get_config_file()
    if not path.exists():
        return dict(_DEFAULTS)
    try:
        data = json.loads(path.read_text())
    except (json.JSONDecodeError, OSError):
        return dict(_DEFAULTS)
    return {**_DEFAULTS, **data}


def save(cfg: dict) -> None:
    """Persist config (api_key is never written — stays in keyring/env)."""
    safe = {k: v for k, v in cfg.items() if k != "api_key"}
    get_config_file().write_text(json.dumps(safe, indent=2))


def get(key: str, fallback=None):
    """Get a single persisted config value."""
    return load().get(key, fallback)


def set_key(key: str, value) -> None:
    """Set a single config key and persist."""
    cfg = load()
    cfg[key] = value if value != "" else None
    save(cfg)


def unset_key(key: str) -> None:
    """Remove a key from persisted config (revert to default)."""
    cfg = load()
    cfg.pop(key, None)
    save(cfg)


def get_api_key() -> str | None:
    """env var only — never persisted to disk."""
    env = os.getenv("LETTA_API_KEY", "").strip()
    return env if env else None


def get_base_url() -> str | None:
    """LETTA_BASE_URL env takes priority over persisted config."""
    env = os.getenv("LETTA_BASE_URL", "").strip()
    if env:
        return env
    return load().get("base_url")


def get_embedding_config() -> dict:
    """Return {embedding_model, embedding_endpoint} from persisted config."""
    cfg = load()
    return {
        "embedding_model": cfg.get("embedding_model"),
        "embedding_endpoint": cfg.get("embedding_endpoint"),
    }


def show() -> str:
    """Human-readable config summary."""
    cfg = load()
    api_key = get_api_key()
    key_display = f"{api_key[:8]}…" if api_key else "(not set — will prompt on launch)"
    base_url = get_base_url() or "(default: https://api.letta.com)"
    return "\n".join([
        "[CONFIG]",
        f"  api_key           : {key_display}  [env: LETTA_API_KEY]",
        f"  base_url          : {base_url}",
        f"  embedding_model   : {cfg.get('embedding_model') or '(agent default)'}",
        f"  embedding_endpoint: {cfg.get('embedding_endpoint') or '(agent default)'}",
        "",
        f"  config file: {get_config_file()}",
        "  Set with /config set <key> <value>  |  Unset with /config unset <key>",
    ])
