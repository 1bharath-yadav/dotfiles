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
- `voice-assistant.py` calls `secret-tool lookup letta_key sk` at startup if `LETTA_API_KEY` is not already in env. No key needs to be set in Hyprland env or zsh rc.
- All other scripts should follow the same pattern: call `secret-tool lookup <n>` lazily, never hardcode or store keys in config files.

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
| `voice-assistant`     | Wrapper: bootstraps venv at `~/.local/state/voice-assistant/venv` (first run), injects `LETTA_API_KEY` via `secret-tool lookup letta_key sk`, then execs `voice-assistant.py` with venv Python. Text-only assistant; no built-in STT/TTS. |
| `voice-assistant.py`  | Plain Python 3 script (no uv). Letta-backed brain with persistent memory, archival search, recall. Errors surfaced via IPC as `response:[Error]…`.                                    |
| `whisper-assistant`   | Direct `pw-record` one-shot capture → whisper-cli STT → final `transcript <text>` to `voiceAssistant` IPC. No direct Letta piping.                                               |
| `whisper-hold`        | Hold-to-record helper: start/stop `ffmpeg` capture, transcribe with `whisper-cli`, then type or copy the result at cursor.                                                     |
| `kokoro-speak`        | Reusable TTS. stdin or $1. Env: `KOKORO_*`. Uses `kokoro-tts` + the installed Kokoro models.                                                                                          |
| `check-drift`         | Audits package ownership between Nix and Pacman.                                                                                                                                      |
| `refresh-apps`        | Rebuilds desktop caches + signals Quickshell.                                                                                                                                         |
| `dev.sh`              | Default environment diagnostics entrypoint.                                                                                                                                           |

Use ~/.local/state/quickshell/.venv for Quickshell's Python dependencies. This keeps it isolated from the voice assistant and other scripts, which may have different requirements. The `update-agent-skills` script can be extended to manage this venv as well, ensuring all agents stay up-to-date with their dependencies.

- The Quickshell assistant panel (`AssistantWindow.qml`) is a bottom-anchored card: only the composer is visible on open; chat panel appears after first message and grows up to 80% screen height. No header, no status chips, no voice-assistant label, and no built-in listen button.
- `AssistantComposer.qml`: clean two-line input box (colLayer2, colPrimary border on focus). No status row or model/agent chips. Send button is circular arrow_upward / stop_circle.
- Slash suggestions are rendered by `AssistantWindow` in a `slashStrip` item above the composer — only visible when draft starts with "/".
- `AssistantChatPanel.qml`: message bubbles styled exactly like `AiMessage.qml` — `colSecondaryContainer` header pill with role icon + name + action buttons; `colLayer1` body with `AssistantMarkdownMessage`.
- `AssistantThinkingBubble.qml`: collapsible think block with psychology icon, animating dots while streaming, chevron toggle when done.

- never use emojis
