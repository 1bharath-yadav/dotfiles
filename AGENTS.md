# AGENTS.md
# Single source of truth for architecture, working agreements, and automation.
# Read at session start; update at session end.

---

## Environment Overview

| Component   | Arch Linux (Desktop)      | WSL2 (Dev)              | Termux (Android)          |
| ----------- | ------------------------- | ----------------------- | ------------------------- |
| Shell       | zsh + Starship            | zsh + Starship          | zsh + Starship            |
| Window Mgr  | Hyprland (end4dots)       | N/A                     | N/A                       |
| Editor      | Neovim                    | Neovim                  | Neovim                    |
| User pkgs   | Home Manager (`nh`)       | Home Manager (`nh`)     | N/A (plain pkg)           |
| System pkgs | `nix/system/apply.sh`     | N/A                     | N/A                       |
| Bootstrap   | `setup/bootstrap.sh arch` | `setup/bootstrap.sh wsl`| `setup/bootstrap.sh termux` |

nix-on-droid removed — Termux uses plain `pkg` only.

---

## Two Nix Package Layers (Arch)

```
User layer   → Home Manager   → ~/.nix-profile          → nh home switch
System layer → Nix profile    → /nix/var/nix/profiles/system → sudo sys-nix-apply
```

**User layer** (`nix/modules/packages/common.nix`, `arch-home.nix`, `wsl.nix`): CLI tools, apps, fonts, configs.
**System layer** (`nix/system/arch-system.nix`): GPU tools, media tooling, ollama, root-needed bins, pre-login shells.
Never mix: GPU tools go in system layer, user apps go in HM.

---

## Package Manager Decision Table

| Manager              | When to use                                                              |
| -------------------- | ------------------------------------------------------------------------ |
| pacman / AUR         | Kernel, drivers, display stack, root services, illogical-impulse, KDE/GTK apps |
| **Nix system layer** | GPU/media tools, ollama, shared heavy binaries, pre-login shells         |
| **Nix Home Manager** | Portable user CLI tools available in nixpkgs                             |
| **mise**             | Primary runtime (Python, Node, Rust, Go) & global CLI tool manager       |
| **uv**               | Preferred Python project manager (use with mise for runtime sync)        |
| `uvx`                | Ephemeral one-shot Python tools (duckdb, manim)                          |
| `pkg` (Termux)       | Termux-native Android packages                                           |

See `nix/modules/packages/external.txt` for machine-readable external tools.

---

## Dotfiles Layout

```text
~/.dotfiles/
├── .ai/                        # Agent prompts (setup-agent.md)
├── nix/
│   ├── hosts/                  # archer-arch.nix, archer-wsl.nix
│   ├── modules/
│   │   ├── packages/           # common.nix, arch-home.nix, wsl.nix, optional.nix, external.txt
│   │   └── programs/           # per-tool configs + bin/scripts/
│   └── system/
│       ├── arch-system.nix     # declarative system package list (root profile)
│       ├── apply.sh            # sudo apply.sh → /nix/var/nix/profiles/system
│       └── diff.sh             # audit declared vs installed system packages
├── setup/
│   ├── arch/                   # packages/*.txt, pacman.conf, manifest.yaml
│   ├── termux/                 # bootstrap.sh (Android, plain pkg)
│   ├── lib.sh                  # shared helpers + OS detection
│   ├── bootstrap.sh            # thin wrapper → setup/main.sh bootstrap
│   └── main.sh                 # single source of truth for bootstrap/apply/update
├── shell-sources/
│   └── aliases/                # nix.sh, pacman.sh, python.sh, termux.sh ...
├── update.sh                   # thin wrapper → setup/main.sh update
├── flake.nix                   # inputs: nixpkgs-unstable + home-manager only
└── AGENTS.md
```

---

## Flake Structure

- `nixpkgs` → `nixpkgs-unstable`
- `home-manager` follows nixpkgs
- `formatter` / `devShells` use `nixfmt-rfc-style`
- `homeHosts` map drives `mkHome` — new machine = one entry + one host file
- `systemPackages` flake output = inspectable set from `nix/system/arch-system.nix`
- Convenience aliases: `archer@arch`, `archer@zero-book`, `archer@wsl`

---

## Scripts in `~/.local/bin` (deployed by HM)

| Script            | Purpose                                                              |
| ----------------- | -------------------------------------------------------------------- |
| `sys-nix-apply`   | apply system package list                                            |
| `sys-nix-diff`    | compare declared system profile store path vs current system profile  |
| `check-drift`     | audit pacman explicit vs dotfiles ownership                          |
| `dots-apply`      | apply one package/config layer                                       |
| `dots-update`     | overall update wrapper                                               |
| `aicommit`        | AI git commits (Copilot/Gemini/Ollama)                               |
| `voice-assistant` | venv bootstrap + Letta-backed assistant                              |
| `whisper-hold`    | hold-to-record → whisper-cli → type at cursor                       |
| `kokoro-speak`    | TTS via kokoro-tts                                                   |
| `refresh-apps`    | rebuild desktop caches + signal Quickshell                           |
| `dev.sh`          | environment diagnostics                                              |

## letta_assistant REPL — agent & conversation commands

| Command | Accepts | Effect |
|---|---|---|
| `/agents` | — | List all agents (index, name, id, model, active marker) |
| `/new <n>` | `--model` | Create agent + conversation, activate immediately |
| `/use <ref>` | index\|name\|id | Switch active agent, creates fresh conversation |
| `/retrieve <ref>` | index\|name\|id | Full agent detail (name, id, model, tags) |
| `/update <ref>` | `--name` `--desc` | Rename or describe an agent |
| `/pin <ref>` / `/unpin <ref>` | index\|name\|id | `client.agents.update(pinned=True/False)` |
| `/delete <ref>` | index\|name\|id | Confirm-prompt then delete; clears saved state if active |
| `/resume` | — | List conversations with active marker |
| `/resume <ref>` | index\|id | Switch conversation; saves to state file |
| `/new [name]` (no model flag) | optional name | Create named conversation; activate |
| `/clear` | — | `agents.messages.reset()` after confirm |
| `/compact` | `sliding_window`\|`summary` | `agents.messages.compact(method=…)` |
| `/search <q>` | text | Client-side search over `conversations.messages.list()` |
| `/context` | — | Count messages by type in active conversation |

`_resolve(ref, agents)` accepts 1-based index, exact id, or case-insensitive name everywhere.
State is always persisted via `state.save_state(agent_id, conv_id, model_id)` after a switch.

---

## Nix Aliases (`shell-sources/aliases/nix.sh`)

| Alias       | Action                                            |
| ----------- | ------------------------------------------------- |
| `hmu`       | smart HM rebuild (wraps overall update flow)      |
| `hms`       | `nh home switch`                                  |
| `hmb`       | `nh home build` (no activate)                     |
| `hmd`       | `home-manager generations`                        |
| `hmr`       | `home-manager rollback`                           |
| `nsp`       | `nix search nixpkgs`                              |
| `nsh`       | `nix-shell -p` (ephemeral)                        |
| `nrn`       | `nix run nixpkgs#`                                |
| `ngc`       | `nix-collect-garbage -d` (user)                   |
| `nsgc`      | `sudo nix-collect-garbage -d` (system)            |
| `nup`       | `nix flake update`                                |
| `ncheck`    | `nix flake check`                                 |

---

- Never use emojis 

## Secrets Management

`secret-tool` (GNOME Keyring / libsecret) is the single source of truth.
All secrets stored with `service=sensvault, username=<key-name>`.
Scripts call `secret-tool lookup service sensvault username <key>` lazily — never hardcode keys.

Sync to/from rclone remote (GDrive etc.) via `secrets-sync` (`~/.local/bin/secrets-sync`).
Per-project env injection via `secrets-inject` (`~/.local/bin/secrets-inject`) + `~/.secrets/projects/<project>.map`.

| Secret            | Key               | Used by           |
| ----------------- | ----------------- | ----------------- |
| `letta_key`       | Letta API         | voice-assistant   |
| `bw_client_id`    | Bitwarden CLI     | keys.sh bwlogin   |
| `bw_client_secret`| Bitwarden CLI     | keys.sh bwlogin   |
| `bw_password`     | Bitwarden vault   | keys.sh bwunlock  |

Store a new secret:
```zsh
secret-tool store --label="My key" service sensvault username my_key_name
```

---

This system uses end-4's dots-hyprland as the base shell config (https://github.com/end-4/dots-hyprland.git). The Quickshell UI lives at ~/.local/share/end4dots/dots/.config/quickshell/ii/. The voice assistant module is at modules/ii/assistant/ and communicates with the Python backend via IPC target "voiceAssistant". The Letta assistant backend lives at ~/.dotfiles/libs/letta_assistant/ and is invoked by ~/.local/bin/voice-assistant-daemon.

---

## Key Learnings

- `nh home switch` copies, not symlinks — script changes need a rebuild to deploy.
- `config.lib.file.mkOutOfStoreSymlink` preferred for live-edited configs.
- System Nix profile (`/nix/var/nix/profiles/system`) is completely separate from HM.
- `btop`, `nvtopPackages.intel`, `ollama`, and hardware/media-heavy tools belong in `nix/system/arch-system.nix`.
- System Nix profile PATH/XDG wiring: `apply.sh` writes `/etc/profile.d/nix-system.sh` (login shells), patches `/etc/environment` (pam_env/SDDM), and writes `/etc/sudoers.d/nix-system-path` (so `sudo btop` etc. work). Without the sudoers drop-in, `sudo` strips PATH via `secure_path` and can't find system-profile binaries.
- btop GPU box: Intel Xe GPU detected via `/dev/dri/card1`; `shown_boxes` must include `gpu0` explicitly — btop does not auto-show it even when compiled with `-DBTOP_GPU=ON`.
- `.s` files in `shell-sources/` are intentional — unsourced reference snippets. Only `*.sh` files are sourced by `20-dotfiles-cache.zsh`.
- `letta-code` is an npm package (`@letta-ai/letta-code`), installed via pnpm global. `PNPM_HOME=~/.local/share/pnpm` is the global bin dir; added to PATH in `env.zsh`.
- `setup/arch_linux/` (ghost folder, only had `pacman.conf`) merged into `setup/arch/` and deleted.
- end4dots `setup install` uses `cp -f` — overwrites hyprland.conf; `update.sh` patches this.

---

## Session Log

### 2026-04-04 (session 1)
- Added `shell-sources/aliases/nix.sh`, `termux.sh`.
- Added `setup/termux/bootstrap.sh`, patched `bootstrap.sh` and `lib.sh`.
- Replaced legacy external package notes with `nix/modules/packages/external.txt`.
- Updated `flake.nix`: `nixfmt-rfc-style`, per-host `homeDirectory`, `homeHosts` map.

### 2026-04-04 (session 2)
- Removed nix-on-droid: deleted `nix/hosts/archer-phone.nix`, `nix/modules/packages/2.droid-packages.nix`, `nix-on-droid` flake input and output.
- Added `nix/system/arch-system.nix`: declarative system Nix package list (root profile).
- Added `nix/system/apply.sh`: builds env + links to `/nix/var/nix/profiles/system`.
- Added `nix/system/diff.sh`: audits declared vs installed system packages.
- Added `sys-nix-apply`, `sys-nix-diff` scripts to `bin/scripts/` (HM-deployed).
- Moved hardware/system-heavy packages out of the old HM Linux package file into `nix/system/arch-system.nix`.
- Updated `flake.nix`: removed nix-on-droid, added `systemPackages` inspectable output.
- Updated `.ai/setup-agent.md`: added Phase 4 (system packages) and two-layer table.

### 2026-04-06 (session 6)
- Produced `implementation.md` at `~/.dotfiles/implementation.md`: full plan for two-mode centered AgentWindow UI.
- Architecture: `AgentWindow.qml` replaces `AssistantWindow.qml`; adds `AgentChatColumn`, `AgentWorkspacePane`, `AgentToolFeed`, `AgentMemoryView`, `AgentStatusBar`. All existing controller/session/streaming files unchanged.
- Mode A (chat): 42% width, centered, height debounced. Mode B (agent, Ctrl+O): 88% width fixed height, chat column stays 40% left, workspace pane right.
- Flicker fixes: debounced height timer (64ms), AGENT mode uses fixed height (no binding), single geometry state machine via QML `states`/`transitions` (no competing `Behavior`), GlobalShortcut for Ctrl+O (not Keys.onPressed).
- GlobalStates: add `agentModeActive: bool`. AssistantRoot: swap sourceComponent to AgentWindow.
- New files go into `~/.dotfiles/config/quickshell/ii/` stow package (not upstream end4dots path).
- Implementation ordered in 12 steps; Steps 1–3 are load-bearing (state, window, geometry); Steps 4–9 are incremental feature additions.

### 2026-04-06 (session 5)
- **letta_assistant config module** (`config/__init__.py`): new persistent app config layer at
  `~/.local/state/letta_assistant/config.json`. Manages `base_url`, `embedding_model`,
  `embedding_endpoint`. `api_key` is runtime-only (env/keyring, never written to disk).
  Env vars (`LETTA_API_KEY`, `LETTA_BASE_URL`) always take priority over persisted values.
- **`letta_service.py`**: `init_client` / `init_async_client` now read `base_url` from
  `app_cfg.get_base_url()` (env → config.json → SDK default) instead of hardcoding.
- **`commands/config.py`**: added `cmd_config` — `/config show|set <key> <val>|unset <key>`.
  Keys: `base_url · embedding_model · embedding_endpoint`. Routed via `/config set|unset|show`
  in `run_command_line`; agent-level subcommands (`system`, `doctor`, etc.) unchanged.
- **`commands/models.py`**: `/model use` now accepts any `provider/model` handle even if not
  in the listed models (BYOK / unlisted). Added `/model embed [set|unset <key>]` for
  `embedding_model` and `embedding_endpoint` config.
- **`letta_assistant.py`**: imports `app_cfg`; `/config set|unset|show` intercepted before
  COMMANDS dispatch; HELP_TEXT updated with `/model embed` and `/config set/unset` docs.
- **`AssistantController.qml`**: updated `commandSubcommands` for `config` (added show/set/unset)
  and `model` (added embed); updated `commandCatalog` description for config; updated
  `helpText` to document new `/model embed` and `/config set/unset` commands.
  All slash commands continue to go through `daemonBin text` — no IPC changes needed.
- Fixed mise config: `@letta-ai/letta-code` is npm (not pnpm/pip), requires `node = "lts"`. Corrected to `"npm:@letta-ai/letta-code"`. Removed bogus `pnpm:letta` and pip entries that were never installable.
- Removed ghost `setup/arch_linux/` folder (only had `pacman.conf`); merged into `setup/arch/`.
- `.s` files in `shell-sources/` are intentional unsourced reference snippets — do not rename.
- Restructured package ownership into 4 clear layers: pacman/AUR, system nix, Home Manager, external managers.
- Split `setup/arch_linux/pacman-explicit.txt` into `setup/arch/packages/{native-core,native-desktop,native-services,aur}.txt`.
- Renamed numbered HM package files to semantic names: `common.nix`, `arch-home.nix`, `wsl.nix`, `optional.nix`.
- Centralized all setup/update logic into `setup/main.sh` with `bootstrap|apply|update` subcommands.
- Fixed `dots-apply` to accept either `arch` or `all arch` patterns.
- Fixed `sync-external-tools` for HM-managed mise config: now uses `mise install` instead of `mise use -g`.
- Pinned mise runtime versions (Python 3.12.13, Node 25.9.0, Rust 1.94.0, Bun 1.3.11) in `nix/modules/programs/mise/default.nix`.
- Added real `uv:`, `cargo:`, `npm:` entries to `external.txt` based on current installed tools.
- Updated `AGENTS.md`, `README.md`, `.ai/setup-agent.md` to reflect new structure.

### 2026-04-06 (session 7)
- Fixed Quickshell load error: `AgentSettingsPane is not a type` caused entire error chain
  (IllogicalImpulseFamily → VoiceAssistant.Assistant → AssistantRoot → AgentWindow).
- Root cause: `AgentSettingsPane.qml` existed in the assistant module directory but was
  missing from `qmldir` — so Quickshell's module loader couldn't resolve it as a type.
- Fix: added `AgentSettingsPane 1.0 AgentSettingsPane.qml` to
  `~/.config/quickshell/ii/modules/ii/assistant/qmldir`.
- Lesson: every new .qml file added to a Quickshell module directory MUST have a
  corresponding entry in that directory's `qmldir` — the file alone is not enough.

### 2026-04-06 (session 8 — Git Recovery & Dotfiles Management)
- **Recovered scheduler work from reflog** after rebase loss in end4dots.
  Used `git reflog` → `git reset --soft f2e0a4bd` → committed at `ac7470d4`.
  Learned: commits are never actually deleted; they live in reflog until garbage collected.
- **Moved `.letta/` out of git** to `~/.local/state/letta_assistant/` (XDG-compliant).
  Reason: `.letta/` contains local runtime state (API keys, conversation history), not config.
  letta_assistant `config/__init__.py` already uses correct XDG path.
- **Created `.gitattributes` in end4dots** with `merge=ours` rules to protect:
  - `dots/.config/quickshell/ii/modules/ii/assistant/**` (your scheduler)
  - `dots/.config/starship.toml` (kept deleted; you use ~/.dotfiles version via symlink)
  - `.letta/` (export-ignore, won't sync)
- **Changed `sync_end4dots()` in lib.sh from rebase to merge** strategy (lines 211-256):
  - Old: `git rebase upstream/main` (linear but risky—lost commits if it fails)
  - New: `git merge upstream/main` (safe—both histories preserved, conflicts are explicit)
  - Removed `--force` push; merges create safe merge commits, no history rewriting
  - Added `git config merge.ours.driver true` for automatic conflict resolution on protected files
- **Created `bharath-dotfiles-management` skill** at `~/.agents/skills/`:
  - Documents your three competing goals: keep scheduler, merge upstream, manage local state
  - Includes deep git learning on rebase vs. merge semantics, reflog recovery, merge strategies
  - Provides checklist for safe update.sh runs and conflict resolution patterns
  - Intended as persistent reference for similar conflicts in the future
- **Key insight**: merge-based sync is safer for personal forks with custom work.
  Rebase keeps history linear but orphans commits on failure; merge preserves both histories.
- **Next**: Test `update.sh` to verify scheduler + upstream features merge cleanly.
