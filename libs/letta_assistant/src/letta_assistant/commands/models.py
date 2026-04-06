"""Model management commands: /model

All SDK calls verified against letta-client 1.10.1:
  - client.models.list()       → list[Model]
  - Model fields: .model (id), .name, .display_name, .handle,
                  .context_window, .max_tokens, .temperature,
                  .provider_name, .tier, .enable_reasoner
  - client.agents.update(agent_id, model=..., max_tokens=...,
                         context_window_limit=..., reasoning=...,
                         parallel_tool_calls=..., temperature=...)

Usage:
  /model                    → show current model
  /model list               → list all available models (paginated)
  /model list <filter>      → filter by provider or name substring
  /model use <ref|handle>   → switch agent to model (index, listed handle, or any custom handle)
  /model set temp <float>   → set temperature (0.0–2.0)
  /model set max_tokens <n> → set max output tokens
  /model set ctx <n>        → set context window limit
  /model set reasoning on|off → enable/disable extended thinking
  /model set parallel on|off  → enable/disable parallel tool calls
  /model info <ref>         → show full model details
  /model embed              → show embedding config
  /model embed set <key> <val> → set embedding_model or embedding_endpoint
  /model embed unset <key>  → revert embedding key to default
"""

from __future__ import annotations

from letta_client import Letta
from letta_client import APIStatusError as ApiError

from letta_assistant.services import letta_service as svc
from letta_assistant.utils import state
from letta_assistant import config as app_cfg

# Session-scoped cache — reset when model list might change
_MODELS_CACHE: list | None = None


def _load_models(client: Letta) -> list:
    """Return list of Model objects. Cached for session lifetime."""
    global _MODELS_CACHE
    if _MODELS_CACHE is None:
        _MODELS_CACHE = list(client.models.list())
    return _MODELS_CACHE


def _resolve(ref: str, models: list):
    """Find model by 1-based index, handle (letta/auto), or name substring."""
    ref = ref.strip()
    if not ref:
        return None
    # Numeric index
    try:
        idx = int(ref) - 1
        if 0 <= idx < len(models):
            return models[idx]
        return None
    except ValueError:
        pass
    # Exact handle match first (e.g. "anthropic/claude-sonnet-4-5")
    for m in models:
        if (m.handle or "").lower() == ref.lower():
            return m
    # Exact model id match
    for m in models:
        if (m.model or "").lower() == ref.lower():
            return m
    # Substring match on name/handle
    ref_lo = ref.lower()
    for m in models:
        if ref_lo in (m.handle or "").lower() or ref_lo in (m.name or "").lower():
            return m
    return None


def _model_line(i: int, m, active_handle: str) -> str:
    """Single formatted list line for a model."""
    marker = " ◀" if (m.handle or m.model) == active_handle else ""
    ctx = f"{m.context_window // 1000}k" if m.context_window else "?"
    return (
        f"  {i:3d}. {(m.handle or m.model):<45}"
        f"  ctx={ctx:<7} tier={m.tier or '?':<10}"
        f"  temp={m.temperature or 1.0}{marker}"
    )


# ── /model (show current) ─────────────────────────────────────────────────────

def cmd_model_show(client: Letta, agent_id: str) -> str:
    """Show active agent's current model. Falls back to listing if no agent."""
    if not agent_id:
        return cmd_model_list(client, agent_id)
    try:
        agent = svc.get_agent(client, agent_id)
        lines = ["[CURRENT MODEL]", f"  model   : {agent.model}"]
        models = _load_models(client)
        m = _resolve(agent.model, models)
        if m:
            lines += [
                f"  handle  : {m.handle or 'N/A'}",
                f"  provider: {m.provider_name or 'N/A'}",
                f"  ctx     : {m.context_window or 'N/A'}",
                f"  max_tok : {m.max_tokens or 'N/A'}",
                f"  temp    : {m.temperature or 1.0}",
                f"  tier    : {m.tier or 'N/A'}",
                f"  reasoner: {m.enable_reasoner}",
            ]
        return "\n".join(lines)
    except ApiError as e:
        return f"[ERROR] {e.status_code}: {e.body}"
    except Exception as e:
        return f"[ERROR] {e}"


# ── /model list ───────────────────────────────────────────────────────────────

def cmd_model_list(client: Letta, agent_id: str, args: str = "") -> str:
    """List available models, optionally filtered.

    Does NOT require an active agent — agent_id is used only to mark the
    currently active model with a ◀ indicator.
    Usage: /model list [filter]
    """
    try:
        models = _load_models(client)
    except ApiError as e:
        return f"[ERROR] {e.status_code}: {e.body}"
    except Exception as e:
        return f"[ERROR] {e}"

    filt = args.strip().lower()
    filtered = [
        m for m in models
        if not filt
        or filt in (m.handle or "").lower()
        or filt in (m.name or "").lower()
        or filt in (m.provider_name or "").lower()
    ] if filt else models

    if not filtered:
        return f"[MODELS] No models matching '{args.strip()}'"

    # Active marker — best-effort, silently skip if no agent
    active_handle = ""
    if agent_id:
        try:
            agent = svc.get_agent(client, agent_id)
            active_handle = agent.model or ""
        except Exception:
            pass

    header = f"[MODELS] {len(filtered)}" + (f" matching '{args.strip()}'" if filt else "")
    lines = [header]
    for i, m in enumerate(filtered, 1):
        lines.append(_model_line(i, m, active_handle))
    if not filt:
        lines.append(f"\nShowing all {len(models)} models.")
    lines.append("Use /model use <index|handle> to switch.")
    return "\n".join(lines)


# ── /model use ────────────────────────────────────────────────────────────────

def cmd_model_use(client: Letta, agent_id: str, args: str = "") -> str:
    """Switch agent to a model.

    Usage: /model use <index|handle|any-provider/model-name>

    If <ref> matches a listed model, uses its handle.
    Otherwise, passes <ref> directly to the API (supports BYOK or unlisted models).
    """
    ref = args.strip()
    if not ref:
        return "Usage: /model use <index|handle>"
    if not agent_id:
        return "[ERROR] No active agent — run /agent use <ref> first, then /model use."

    try:
        models = _load_models(client)
        m = _resolve(ref, models)

        if m:
            handle = m.handle or m.model
            provider_info = f"  provider: {m.provider_name}  tier: {m.tier}  ctx: {m.context_window}"
        else:
            # Unknown handle — pass through directly (BYOK / unlisted model)
            handle = ref
            provider_info = "  (unlisted model — passed directly to API)"

        agent = client.agents.update(agent_id=agent_id, model=handle)
        saved = state.load_state()
        state.save_state(agent_id, saved.get("conversation_id"), handle)
        return f"[OK] Switched to {handle}\n{provider_info}"
    except ApiError as e:
        return f"[ERROR] {e.status_code}: {e.body}"
    except Exception as e:
        return f"[ERROR] {e}"


# ── /model set ────────────────────────────────────────────────────────────────

def cmd_model_set(client: Letta, agent_id: str, args: str = "") -> str:
    """Adjust model settings on the active agent.

    Usage:
      /model set temp <float>          set temperature (0.0–2.0)
      /model set max_tokens <int>      set max output tokens
      /model set ctx <int>             set context window limit
      /model set reasoning on|off      enable/disable extended thinking
      /model set parallel on|off       enable/disable parallel tool calls
    """
    if not agent_id:
        return "[ERROR] No active agent — run /agent use <ref> first to set model settings."

    parts = args.strip().split(maxsplit=1)
    if len(parts) < 2:
        return (
            "Usage:\n"
            "  /model set temp <0.0–2.0>\n"
            "  /model set max_tokens <int>\n"
            "  /model set ctx <int>\n"
            "  /model set reasoning on|off\n"
            "  /model set parallel on|off"
        )

    setting, value = parts[0].lower(), parts[1].strip()

    kwargs: dict = {}

    if setting in ("temp", "temperature"):
        try:
            v = float(value)
            if not 0.0 <= v <= 2.0:
                return "[ERROR] Temperature must be between 0.0 and 2.0"
            kwargs["temperature"] = v
            label = f"temperature={v}"
        except ValueError:
            return "[ERROR] Temperature must be a float (e.g. 0.7)"

    elif setting in ("max_tokens", "maxtokens", "max"):
        try:
            v = int(value)
            if v < 1:
                return "[ERROR] max_tokens must be a positive integer"
            kwargs["max_tokens"] = v
            label = f"max_tokens={v}"
        except ValueError:
            return "[ERROR] max_tokens must be an integer"

    elif setting in ("ctx", "context_window", "context"):
        try:
            v = int(value)
            if v < 1000:
                return "[ERROR] Context window must be at least 1000 tokens"
            kwargs["context_window_limit"] = v
            label = f"context_window_limit={v}"
        except ValueError:
            return "[ERROR] context_window_limit must be an integer"

    elif setting in ("reasoning", "think", "extended_thinking"):
        val = value.lower()
        if val in ("on", "true", "yes", "1"):
            kwargs["reasoning"] = True
            label = "reasoning=enabled"
        elif val in ("off", "false", "no", "0"):
            kwargs["reasoning"] = False
            label = "reasoning=disabled"
        else:
            return "[ERROR] Use 'on' or 'off'"

    elif setting in ("parallel", "parallel_tool_calls"):
        val = value.lower()
        if val in ("on", "true", "yes", "1"):
            kwargs["parallel_tool_calls"] = True
            label = "parallel_tool_calls=enabled"
        elif val in ("off", "false", "no", "0"):
            kwargs["parallel_tool_calls"] = False
            label = "parallel_tool_calls=disabled"
        else:
            return "[ERROR] Use 'on' or 'off'"

    else:
        return (
            f"[ERROR] Unknown setting '{setting}'\n"
            "Available: temp · max_tokens · ctx · reasoning · parallel"
        )

    try:
        client.agents.update(agent_id=agent_id, **kwargs)
        return f"[OK] Set {label}"
    except ApiError as e:
        return f"[ERROR] {e.status_code}: {e.body}"
    except Exception as e:
        return f"[ERROR] {e}"


# ── /model info ───────────────────────────────────────────────────────────────

def cmd_model_info(client: Letta, agent_id: str, args: str = "") -> str:
    """Show full details for a model. Does not require an active agent.
    Usage: /model info <index|handle>
    """
    ref = args.strip()
    if not ref:
        return "Usage: /model info <index|handle>"

    try:
        models = _load_models(client)
        m = _resolve(ref, models)
        if not m:
            return f"[ERROR] Model not found: '{ref}'"
        lines = [
            "[MODEL INFO]",
            f"  handle        : {m.handle or 'N/A'}",
            f"  name          : {m.display_name or m.name or 'N/A'}",
            f"  model id      : {m.model}",
            f"  provider      : {m.provider_name or 'N/A'}",
            f"  provider type : {m.provider_type or 'N/A'}",
            f"  tier          : {m.tier or 'N/A'}",
            f"  context window: {m.context_window or 'N/A'} tokens",
            f"  max tokens    : {m.max_tokens or 'N/A'}",
            f"  temperature   : {m.temperature or 1.0}",
            f"  enable_reason : {m.enable_reasoner}",
        ]
        return "\n".join(lines)
    except ApiError as e:
        return f"[ERROR] {e.status_code}: {e.body}"
    except Exception as e:
        return f"[ERROR] {e}"


# ── /model embed ─────────────────────────────────────────────────────────────

_EMBED_KEYS = {"embedding_model", "embedding_endpoint"}


def cmd_model_embed(client: Letta, agent_id: str, args: str = "") -> str:
    """View or configure embedding model settings.

    /model embed                         → show current embedding config
    /model embed set <key> <value>       → persist embedding_model or embedding_endpoint
    /model embed unset <key>             → revert to agent default

    Keys: embedding_model · embedding_endpoint
    Example: /model embed set embedding_model openai/text-embedding-3-small
    """
    parts = args.strip().split(maxsplit=2)
    sub = parts[0].lower() if parts else ""

    if not sub or sub == "show":
        emb = app_cfg.get_embedding_config()
        return "\n".join([
            "[EMBEDDING CONFIG]",
            f"  embedding_model   : {emb['embedding_model'] or '(agent default)'}",
            f"  embedding_endpoint: {emb['embedding_endpoint'] or '(agent default)'}",
            "  Set with: /model embed set <key> <value>",
        ])

    if sub == "set":
        if len(parts) < 3:
            return "Usage: /model embed set <key> <value>\nKeys: " + " · ".join(sorted(_EMBED_KEYS))
        key, value = parts[1].lower(), parts[2]
        if key not in _EMBED_KEYS:
            return f"[ERROR] Unknown key '{key}'. Valid: {', '.join(sorted(_EMBED_KEYS))}"
        app_cfg.set_key(key, value)
        return f"[OK] Set {key} = {value}"

    if sub == "unset":
        if len(parts) < 2:
            return "Usage: /model embed unset <key>"
        key = parts[1].lower()
        if key not in _EMBED_KEYS:
            return f"[ERROR] Unknown key '{key}'. Valid: {', '.join(sorted(_EMBED_KEYS))}"
        app_cfg.unset_key(key)
        return f"[OK] Unset {key} (reverted to agent default)."

    return "Usage: /model embed [set <key> <val> | unset <key>]"


# ── dispatcher ────────────────────────────────────────────────────────────────

def cmd_model(client: Letta, agent_id: str, args: str = "") -> str:
    """Dispatch /model subcommands.

    /model               → show current
    /model list [filter] → browse models
    /model use <ref>     → switch model (index, handle, or any provider/model string)
    /model set <k> <v>   → adjust model settings
    /model info <ref>    → full model details
    /model embed [...]   → view/set embedding config
    """
    parts = args.strip().split(maxsplit=1)
    sub = parts[0].lower() if parts and parts[0] else ""
    rest = parts[1] if len(parts) > 1 else ""

    if not sub:
        return cmd_model_show(client, agent_id)
    if sub == "list":
        return cmd_model_list(client, agent_id, rest)
    if sub in ("use", "set_model", "switch"):
        return cmd_model_use(client, agent_id, rest)
    if sub == "set":
        return cmd_model_set(client, agent_id, rest)
    if sub in ("info", "show", "detail"):
        return cmd_model_info(client, agent_id, rest)
    if sub in ("embed", "embedding"):
        return cmd_model_embed(client, agent_id, rest)
    # Bare handle/index — treat as /model use
    return cmd_model_use(client, agent_id, args.strip())
