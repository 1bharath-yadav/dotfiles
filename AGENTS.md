# AGENTS.md

The single source of truth for architecture decisions, working agreements, and automation tools. Read at session start; update at session end.

---

## 🌎 Environment Overview

| Component      | Primary: Arch Linux (Desktop) | Secondary: WSL2 (Dev) | Mobile: nix-on-droid |
| -------------- | ----------------------------- | --------------------- | -------------------- |
| **Shell**      | zsh + Starship                | zsh + Starship        | zsh + Starship       |
| **Window Mgr** | Hyprland (end4dots)           | N/A                   | N/A                  |
| **Editor**     | Neovim                        | Neovim                | Neovim               |
| **Nix Manager**| Home Manager (`nh`)           | Home Manager (`nh`)   | nix-on-droid         |

---

## 🏗️ Repository Architecture

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

| Agent                | Purpose                                                                 |
| -------------------- | ----------------------------------------------------------------------- |
| `aicommit`           | AI git commits (Copilot/Gemini/Ollama) with interactive review loop.    |
| `daydream`           | Research idea generator using `o4-mini` + `recall`.                     |
| `recall`             | Spaced-recall CLI for notes in `Dropbox/notes` and `code/til`.          |
| `update-agent-skills`| Installs/updates `agency-agents`, `smithery`, and `antigravity-skills`. |
| `check-drift`        | Audits package ownership between Nix and Pacman.                        |
| `refresh-apps`       | Rebuilds desktop caches (`sycoca`, `desktop-db`) + signals Quickshell.  |
| `dev.sh`             | Default environment diagnostics entrypoint.                             |

---

## 🛠️ Key Design Decisions

### 1. Package Ownership Model (Established 2026-03-31)
*   **System (Pacman/APT):** Kernel, drivers, bootstrap tools, and **KDE desktop integrations** (Dolphin, Ark, etc.) on Arch to ensure stable plugin/service behavior.
*   **User (Nix Home Manager):** CLI tools, dev envs, portable apps.
*   **Node.js & Globals:** Declarative via Home Manager in `nix/modules/programs/npm/default.nix`. No more manual `npm-global` bin pathing.
*   **Python:** `uv` handles everything. `uv tool` for CLIs, `uvx` for ephemeral, `systemd --user` for services. **Never add venv bins to PATH.**

### 2. Configuration Strategy
*   **Stow is retired.** All configs are managed by Nix via `xdg.configFile`.
*   **Out-of-Store Symlinks:** `nvim`, `lazygit`, `starship`, and `hypr/custom` use `mkOutOfStoreSymlink` for instant edits without rebuilding.
*   **Shell Loading:** `shell-sources/` is NOT linked. It's loaded via a custom cache in `.zshrc`. `*.sh` is active; `*.s` is disabled/parked.

### 3. end4dots Fork Model (Arch only)
*   `main`: Mirror of upstream. **Never commit here.**
*   `archer`: Personal modifications. `update.sh` handles rebasing this on top of `main`.

---

## 🚀 Common Operations

```bash
# Apply changes / Rebuild environment
./update.sh                     # Smart rebuild (skips if no Nix changes)
hms                             # Alias for 'nh home switch'

# Sync shell sources (after editing shell-sources/)
rm ~/.zsh_dotfiles_cache && zsh

# Maintenance
system-clean.sh                 # Prune Nix generations + system caches
check-drift                     # Ensure package ownership hasn't drifted

# AI / Research
aicommit gemini                 # Stage files first
daydream "topic"                # Generate research fusions
recall                          # Practice spaced-repetition
```

---

## 📊 Current State (2026-03-31)
*   **Zsh:** Auto-execs `tmux` on local interactive sessions (Guarded: skips SSH/VSCode/Secondary).
*   **PATH:** `~/.nix-profile/bin` and `~/.local/bin` are prepended for CLI tool precedence.
*   **Hyprland:** Scratchpads for `Obsidian` (`SUPER+O`) and `Terminal` (`SUPER+ENTER`) established.
*   **Yazi:** Full plugin/flavor management integrated into Home Manager.
