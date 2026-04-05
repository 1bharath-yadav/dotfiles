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
| **mise**             | Runtime/version management for Python, Node, Rust, Bun                   |
| `uv tool install`    | Python CLI apps (marimo, jupyter, piper-tts)                             |
| `uvx`                | Ephemeral one-shot Python tools (duckdb, manim)                          |
| `cargo install`      | Rust tools not in nixpkgs or needing latest                              |
| `pnpm -g`            | Preferred Node CLI installer                                              |
| `npm -g`             | Node CLI fallback only when pnpm is not viable                           |
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

## Secrets Management

`secrets` (GPG-anchored CLI) is the single source of truth.
Scripts call `secret-tool lookup <key>` lazily — never hardcode keys.

| Secret      | Key       | Used by          |
| ----------- | --------- | ---------------- |
| `letta_key` | Letta API | voice-assistant  |

---

## Key Learnings

- `nh home switch` copies, not symlinks — script changes need a rebuild to deploy.
- `config.lib.file.mkOutOfStoreSymlink` preferred for live-edited configs.
- System Nix profile (`/nix/var/nix/profiles/system`) is completely separate from HM.
- `btop`, `nvtopPackages.intel`, `ollama`, and hardware/media-heavy tools belong in `nix/system/arch-system.nix`.
- nix-on-droid removed; Termux uses plain `pkg` + `setup/termux/bootstrap.sh`.
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

### 2026-04-05 (session 3)
- Restructured package ownership into 4 clear layers: pacman/AUR, system nix, Home Manager, external managers.
- Split `setup/arch_linux/pacman-explicit.txt` into `setup/arch/packages/{native-core,native-desktop,native-services,aur}.txt`.
- Renamed numbered HM package files to semantic names: `common.nix`, `arch-home.nix`, `wsl.nix`, `optional.nix`.
- Centralized all setup/update logic into `setup/main.sh` with `bootstrap|apply|update` subcommands.
- Fixed `dots-apply` to accept either `arch` or `all arch` patterns.
- Fixed `sync-external-tools` for HM-managed mise config: now uses `mise install` instead of `mise use -g`.
- Pinned mise runtime versions (Python 3.12.13, Node 25.9.0, Rust 1.94.0, Bun 1.3.11) in `nix/modules/programs/mise/default.nix`.
- Added real `uv:`, `cargo:`, `npm:` entries to `external.txt` based on current installed tools.
- Updated `AGENTS.md`, `README.md`, `.ai/setup-agent.md` to reflect new structure.
