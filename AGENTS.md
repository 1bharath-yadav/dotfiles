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
| `whisper-assistant`   | ffmpeg record → whisper-cli STT → `voiceAssistantOverlay transcript <text>`. No direct Letta piping.                                                                                  |
| `kokoro-speak`        | Reusable TTS. stdin or $1. Env: `KOKORO_*`. Uses `kokoro-tts` + the installed Kokoro models.                                                                                          |
| `check-drift`         | Audits package ownership between Nix and Pacman.                                                                                                                                      |
| `refresh-apps`        | Rebuilds desktop caches + signals Quickshell.                                                                                                                                         |
| `dev.sh`              | Default environment diagnostics entrypoint.                                                                                                                                           |

Use ~/.local/state/quickshell/.venv for Quickshell's Python dependencies. This keeps it isolated from the voice assistant and other scripts, which may have different requirements. The `update-agent-skills` script can be extended to manage this venv as well, ensuring all agents stay up-to-date with their dependencies.
