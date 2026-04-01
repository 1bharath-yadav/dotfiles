# AGENTS.md

The single source of truth for architecture decisions, working agreements, and automation tools. Read at session start; update at session end.

---

## 🌎 Environment Overview

| Component       | Primary: Arch Linux (Desktop) | Secondary: WSL2 (Dev) | Mobile: nix-on-droid |
| --------------- | ----------------------------- | --------------------- | -------------------- |
| **Shell**       | zsh + Starship                | zsh + Starship        | zsh + Starship       |
| **Window Mgr**  | Hyprland (end4dots)           | N/A                   | N/A                  |
| **Editor**      | Neovim                        | Neovim                | Neovim               |
| **Nix Manager** | Home Manager (`nh`)           | Home Manager (`nh`)   | nix-on-droid         |

## 🔑 Secrets Management

`secrets` (GPG-anchored CLI) is the single source of truth for credentials.

| Secret      | Key       | Used by                          |
| ----------- | --------- | -------------------------------- |
| `letta_key` | Letta API | `voice-assistant.py` (auto-load) |

- Store: `secrets store letta_key "sk-let-..."`
- `voice-assistant.py` calls `secrets get letta_key` at startup if `LETTA_API_KEY` is not already in env. No key needs to be set in Hyprland env or zsh rc.
- All other scripts should follow same pattern: call `secrets get <n>` lazily, never hardcode or store keys in config files.

---

## 📁 Dotfiles Layout

```text
~/.dotfiles/
├── nix/                # Home Manager + nix-on-droid configurations
│   ├── hosts/          # Entrypoints: archer-arch, archer-wsl, archer-phone
│   └── modules/        # Domain-driven bundles: packages/, programs/ (configs)
├── setup/              # OS-agnostic bootstrap: lib.sh, bootstrap.sh, main.sh
├── shell-sources/      # Cached Zsh: aliases/, functions/, paths/ (NOT stowed)
├── update.sh           # Rebuild logic: HM switch + end4dots rebase (Arch)
└── AGENTS.md           # This file (State & Design decisions)
```

---

## 🤖 Core Automation (Agents)

All scripts reside in `nix/modules/programs/bin/scripts/` and link to `~/.local/bin/`.

| Agent                 | Purpose                                                                                                                                                                               |
| --------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `aicommit`            | AI git commits (Copilot/Gemini/Ollama) with interactive review loop.                                                                                                                  |
| `daydream`            | Research idea generator using `o4-mini` + `recall`.                                                                                                                                   |
| `update-agent-skills` | Installs/updates `agency-agents`, `smithery`, and `antigravity-skills`.                                                                                                               |
| `voice-assistant`     | Wrapper: bootstraps venv at `~/.local/state/voice-assistant/venv` (first run), injects `LETTA_API_KEY` via `secrets get letta_key`, then execs `voice-assistant.py` with venv Python. |
| `voice-assistant.py`  | Plain Python 3 script (no uv). Letta-backed brain with persistent memory, archival search, recall. Errors surfaced via IPC as `response:[Error]…`.                                    |
| `whisper-assistant`   | Hold SUPER+;: ffmpeg record → whisper-cli STT → voice-assistant.py pipe.                                                                                                              |
| `piper-speak`         | Reusable TTS. stdin or $1. Env: `PIPER_MODEL`. Uses piper + aplay.                                                                                                                    |
| `check-drift`         | Audits package ownership between Nix and Pacman.                                                                                                                                      |
| `refresh-apps`        | Rebuilds desktop caches + signals Quickshell.                                                                                                                                         |
| `dev.sh`              | Default environment diagnostics entrypoint.                                                                                                                                           |

---

## 🖥️ Voice Assistant — Quickshell UI

The end4dots Quickshell config lives at `~/.config/quickshell/ii/` (symlinked from `~/linux/ii/`). The assistant panel is at `modules/ii/sidebarLeft/assistant/`.

### IPC event flow

```
voice-assistant.py
  → qs ipc call voiceAssistant <event> [payload]
  → SidebarLeft.qml  IpcHandler{target:"voiceAssistant"}
  → sidebarContent.relayAssistantEvent(event, payload)
  → SidebarLeftContent.qml → AssistantPanel.qml receiveEvent()
```

### IPC events (all handled end-to-end as of this session)

| Event           | Payload              | Effect                                              |
| --------------- | -------------------- | --------------------------------------------------- |
| `userMessage`   | text                 | Push user bubble, set processing=true               |
| `status`        | thinking/ready/error | Update processing flag                              |
| `response`      | text                 | Push assistant bubble (batch mode)                  |
| `streamStart`   | —                    | Push empty streaming bubble with blinking cursor    |
| `token`         | chunk                | Append chunk to last bubble (typewriter effect)     |
| `streamEnd`     | —                    | Finalise bubble (hide cursor), set processing=false |
| `thinkingStart` | first chunk          | Open think bubble (lazy — only if model thinks)     |
| `thinking`      | chunk                | Append to think bubble (streaming)                  |
| `thinkingEnd`   | —                    | Collapse think bubble, set completed=true           |
| `agentId`       | id string            | Store agent ID for display                          |

### Key design decisions (streaming & thinking)

- `thinkingStart` is fired **lazily** — only when a chunk with a real `reasoning/thought/summary` field arrives; never pre-fired with a static string
- `_THINKING_KINDS` set in `_stream_response` causes `continue` on non-reply chunk kinds so thinking text never bleeds into `on_token` / the reply bubble
- `streamStart` fires _before_ `_stream_response` so the reply bubble opens immediately even if thinking precedes the first token
- `_extract_chunk_text(chunk)` is the canonical Letta stream parser: `assistant_message` → reply token (unwraps `content[0].text`); `internal_monologue`/`reasoning`/`thinking` → think token; everything else (tool_call, tool_return, ping, usage_statistics) → `("", "")` — skipped entirely
- `micProc` is a dedicated `Process` for `whisper-assistant start` — separate from `vaProc` so its fast exit doesn't clear `listening`; `stopProc.onExited` clears `listening` (not `vaProc`)
- Mic button stop handler no longer calls `vaProc.running = false` (would abort in-flight voice-assistant)
- `_agent_model_name(agent)` checks `agent.model` first (skips `letta/auto`), then `agent.llm_config.handle/model/model_name`, returns best available string
- Bubble width is `parent.width - 8` for all user/assistant messages (full available width); `parent.width - 16` for system/error/command (centred with margins)
- `receiveEvent("userMessage")` suppresses the IPC echo only when `lastSentUserText != ""` (typed messages); whisper-sourced messages (where `lastSentUserText` is empty) pass through and push a bubble

### QML file status

| File                  | Status | Notes                                                                                                                          |
| --------------------- | ------ | ------------------------------------------------------------------------------------------------------------------------------ |
| `SidebarLeft.qml`     | ✅     | streamStart/token/streamEnd IPC handlers added                                                                                 |
| `AssistantPanel.qml`  | ✅     | triggerMic fixed (no sleep 8); slash commands + interrupt button; model name IPC wired; bottom pills stay gray                 |
| `AssistantChat.qml`   | ✅     | MessageTextBlock for all bubbles incl. think box; transparent inner frame for user bubbles; Repeater modelData shadowing fixed |
| `AssistantMemory.qml` | ✅     | editable memory blocks + real markdown file contents from `~/.letta/agents/<id>/memory/system/` + recursive file tree          |
| `AssistantStatus.qml` | ✅     | lightweight listening/thinking pill only; no daemon health row                                                                 |

### Python package (`va/`)

| File                 | Purpose                                                                                                        |
| -------------------- | -------------------------------------------------------------------------------------------------------------- |
| `va/__init__.py`     | Package marker                                                                                                 |
| `va/config.py`       | Config, keyring constants                                                                                      |
| `va/client.py`       | make_client, ipc(), speak(), stream_chunks() (emits token IPC per chunk)                                       |
| `va/agent.py`        | Agent/conversation, memory, archival, recall, send/stream                                                      |
| `va/commands.py`     | All /cmd handlers (agents, models, files, mcp, etc.)                                                           |
| `va/modes.py`        | run_pipe() streams with streamStart/token/streamEnd; run_pipe_set() fires memoryUpdate; run_interactive() REPL |
| `voice-assistant.py` | Thin 20-line dispatcher (old monolith backed up as .bak)                                                       |

### Key design decisions

- `triggerMic()` only calls `whisper-assistant start`; the mic button's `onClicked` when `listening` calls `whisper-assistant stop` via `stopProc` — no hardcoded sleep
- Streaming is the default (`streamMode: true`); `/stream` toggles to batch; `va/modes.py` must check this flag server-side via a config or env var
- `piper-speak` and `whisper-assistant` are direct one-shot wrappers; keep them simple and avoid background daemons for TTS/STT
- Assistant chat bubbles should mirror `AiChat.qml` controls and markdown behavior; user bubbles are left-aligned in the assistant panel
- Assistant memory should reflect the actual agent workspace tree under `~/.letta/agents/<agent_id>/memory`, not a hardcoded label list, and the active markdown editor should expand upward while collapsing the other memory cards
- Agent selection is explicit: first launch prompts for an existing agent or a new one, and later switching must go through `/agents use` or `/agents new`; the backend must not auto-create a hidden agent on startup
- `voice-assistant.py text` is used by the sidebar for slash commands, so it must remain non-blocking in non-tty contexts and must not pause for an interactive agent prompt
- SidebarLeftContent should instantiate assistant pages as direct `SwipeView` children with a stable `assistantPage` reference; avoid the older `contentChildren` assignment for the assistant stack
- Quickshell IPC callers should use the absolute `/usr/bin/quickshell` path from voice/whisper wrappers to avoid PATH-dependent failures in the sidebar
- `/key <provider> <value>` calls `secrets store` via cmdProc — never writes keys to files
