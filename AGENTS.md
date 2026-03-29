# AGENTS.md

read this file at the **start** of every session and updated at the **end**.
It is the single source of truth for architecture decisions, working agreements, and current state.

---

## Environment

| Key            | Value                   |
| -------------- | ----------------------- |
| Primary OS     | Arch Linux + Hyprland   |
| Secondary OS   | Ubuntu in WSL2 (no GUI) |
| Mobile         | nix-on-droid (Android)  |
| Shell          | zsh                     |
| Prompt         | Starship                |
| Editor         | Neovim                  |
| Package linker | Nix Home Manager        |
| Base dotfiles  | end4dots (Hyprland)     |

---

## Repository Structure

```
~/.dotfiles/
├── AGENTS.md              ← this file; read at start, updated at end of session
├── README.md              ← user-facing quick-start
├── Setup.md               ← detailed per-OS setup guide
├── flake.nix              ← single source of truth for Nix user environments
├── update.sh              ← idempotent restow for current OS + end4dots two-branch sync (Arch)
├── nix/                   ← Home Manager + nix-on-droid configs
│   ├── hosts/             ← host entrypoints (archer-arch / archer-wsl / archer-phone)
│   └── modules/           ← organized by functional domain:
│       ├── packages/      ← centralized package bundles for all hosts
│       └── programs/      ← app configs (nvim, yazi, git, tmux, zsh, starship, bin)
│
├── setup/                 ← OS setup scripts
│   ├── lib.sh             ← shared helpers: logging, OS detection, bootstrap, stow
│   ├── bootstrap.sh       ← shared bootstrap entry for `arch|wsl|android`
│   └── main.sh            ← unified setup entry for `arch|wsl|auto`
│
├── shell-sources/         ← NOT stowed; sourced via dotfiles cache in .zshrc
│   ├── aliases/           ← topic aliases (pacman.sh is Arch-only guarded)
│   ├── functions/         ← helper functions
│   └── paths/             ← PATH exports
│

```

---

## Key Design Decisions

### Configuration linker strategy

All user configurations, including end4dots overrides, are managed by Nix Home Manager. `stow` has been completely retired from the user environment.

### OS detection (`setup/lib.sh: detect_os`)

- WSL: `/proc/version` contains `microsoft|wsl`
- Arch: `/etc/arch-release` exists
- Ubuntu: `/etc/os-release` contains `ubuntu`

### end4dots fork strategy (`~/.local/share/end4dots`)

Two-branch model — keeps upstream sync clean and your changes rebased on top:

| Branch   | Purpose                              | Rule                      |
| -------- | ------------------------------------ | ------------------------- |
| `main`   | Clean mirror of `upstream/main`      | **Never commit here**     |
| `archer` | Your modifications to end4dots files | Only branch you commit to |

- `update.sh` handles the full sync: `main` rebases onto `upstream/main`, then `archer` rebases onto `main`
- Always remain on `archer` after `update.sh` completes
- Conflict on `main` → `git rebase --abort`, fix upstream divergence, re-run
- Conflict on `archer` → `git rebase --continue` after resolving

**What goes where:**

| Change type                                                             | Location                                                      |
| ----------------------------------------------------------------------- | ------------------------------------------------------------- |
| Modifies an existing end4dots file (AGS widget, theme, hyprland.conf)   | `archer` branch commit                                        |
| Pure addition end4dots leaves for users (keybinds, execs, window rules) | `nix/modules/programs/hyprland/config/custom/` (Home Manager) |
| Machine-specific (monitor layout, app exec paths)                       | `nix/modules/programs/hyprland/config/custom/` (Home Manager) |

---

## Working Agreement

- **Always read this file at session start** before touching any files
- **Always update this file at session end** with any structural/architectural changes
- Conservative edits — small, reviewable, targeted
- Prefer `edit_block` for targeted edits; `write_file` in chunks for new/rewritten files
- Never manually copy configs; always use Home Manager `xdg.configFile`
- `shell-sources/` is never stowed — it's loaded via the dotfiles cache in `.zshrc`
- In `shell-sources/`, `*.sh` means active/loaded and `*.s` means parked/disabled reference snippets; do not change the loader to source `.s` files by default
- Hyprland/end4dots configs live in `~/.local/share/end4dots/` on branch `archer`, not here
- **Never commit to `main` in `dots-hyprland`** — it is a clean upstream mirror
- `update.sh` syncs `main` → upstream, rebases `archer` → `main`; Nix layers userland on top
- `pacman` / `apt` are for bootstrap and system-level packages only
- Home Manager owns Linux user-level packages and common user config links
- nix-on-droid owns Android user-level packages
- `.zshrc` should stay package-agnostic and stable; package changes belong in Nix, not shell startup

---

## Common Operations

```bash
# Full setup on new machine
~/.dotfiles/setup/auto.sh
~/.dotfiles/setup/bootstrap.sh arch
~/.dotfiles/setup/bootstrap.sh wsl
~/.dotfiles/setup/bootstrap.sh android

# Re-stow after editing configs
~/.dotfiles/update.sh

# Full setup for a specific OS
~/.dotfiles/setup/main.sh arch
~/.dotfiles/setup/main.sh wsl

# Invalidate dotfiles cache (picks up shell-sources changes)
rm ~/.zsh_dotfiles_cache

# Add new user package
# 1. Edit nix/modules/*
# 2. Run setup/main.sh <arch|wsl> or ./update.sh

# Sync end4dots with upstream (two-branch)
~/.dotfiles/update.sh          # handles everything automatically

# Manual end4dots branch ops
cd ~/.local/share/end4dots
git checkout archer            # always work here
git rebase main               # after manual main update
git rebase --continue         # after resolving archer conflict
```

## Current State

### Python environment strategy (established 2026-03-28)

`~/apps/` has been retired. The three-layer model:

| Layer                 | Tool                                 | Where                            |
| --------------------- | ------------------------------------ | -------------------------------- |
| Global CLI tools      | `uv tool install`                    | `~/.local/bin` (already in PATH) |
| Ephemeral/one-shot    | `uvx` or `, <pkg>` (comma)           | nowhere — no install             |
| Project-specific deps | project `pyproject.toml` + `uv sync` | inside the project               |
| Long-running services | systemd user units                   | `systemctl --user`               |

**Key rule:** venv `.bin` dirs are NEVER added to PATH. `paths.sh` no longer contains any `~/apps/.../.venv/bin` entries.

**Migrated data:**

- `~/apps/open-webui_env/.webui_secret_key` → `~/.config/open-webui/.webui_secret_key`
- `~/apps/credentials.json` (Google OAuth) → `~/.config/credentials/google-oauth.json`
- Dep inventory saved to `nix/modules/packages/python-apps-ref.md`

**`~/apps/` can now be deleted.** Run: `rm -rf ~/apps`

### Nix additions (2026-03-28)

- `nix-direnv` + `programs.direnv` module added — auto-activates `.envrc` on `cd` into project dirs. New module at `nix/modules/programs/direnv/default.nix`.
- `comma`, `nix-tree`, `deadnix`, `statix` added to `1.core-packages.nix`
- `direnv` module imported in `nix/modules/programs/default.nix`
- `direnv` bare package removed from `1.core-packages.nix` (HM `programs.direnv` installs it)
- `direnv` module now pre-migrates an existing `~/.config/direnv/direnv.toml` to `direnv.toml.pre-home-manager*` before `checkLinkTargets`, preventing Home Manager clobber errors while preserving legacy local settings for manual review.

### shell-sources/aliases/python.sh (2026-03-28)

Fully rewritten. New mental model:

- `uvti/uvtu/uvtl/uvtun` aliases for `uv tool` lifecycle
- `svc-*` aliases for `systemctl --user` (start/stop/status/log)
- `webui-*` shortcuts for open-webui service
- Removed all venv-activation-as-global-tool patterns

### Package ownership model

Clear three-layer boundary (established 2026-03-28):

| Layer                        | Manager          | Tracked in                             |
| ---------------------------- | ---------------- | -------------------------------------- |
| System / kernel / AUR        | `pacman`         | `setup/arch_linux/pacman-explicit.txt` |
| User environment (all hosts) | Nix Home Manager | `nix/modules/`                         |
| Android                      | nix-on-droid     | `nix/hosts/archer-phone.nix`           |

**Key rule:** if it needs a systemd service, `/etc` integration, or is AUR-only → pacman. Everything else → Nix.

### Nix module layout (post-refactor)

```
nix/modules/
  packages/
    1.core-packages.nix      ← universal Home Manager base settings + CLI tools on ALL hosts
    2.droid-packages.nix     ← Android-specific package bundle
    3.linux-packages.nix     ← Linux desktop packages + generic Linux settings + yazi/lazygit
    4.wsl.nix                ← WSL-specific packages + generic Linux settings + yazi/lazygit
    5.extra-packages.nix     ← optional/niche tools (security, rare utils); NOT imported by default
```

**5.extra-packages.nix** contains: `aircrack-ng`, `john`, `fcrackzip`, `f3`, `gogcli`, `httrack`, `nyx`, `tor`, `lynx`, `monolith`, `goaccess`, `payload-dumper-go`, `netcat-openbsd`, `sshfs`, `traceroute`, `acpi`, `ent`, `fq`, `speedtest-cli`, `smartmontools`.
To enable on a host: `imports = [ ../modules/packages/5.extra-packages.nix ];`

**pacman-explicit.txt** (`setup/arch_linux/pacman-explicit.txt`) — git-tracked list of system packages pacman explicitly owns, with audit command: `pacman -Qe | awk '{print $1}' | sort`

### Packages / Stow

- Repository root is clean. All user configurations (neovim, yazi, tmux, zsh, lazygit, starship, bin) are strictly grouped inside `nix/modules/programs/`.
- `git` and `zsh` configs are fully declared natively inside Nix. `programs.zsh.dotDir` uses an absolute path (`config.home.homeDirectory`) to avoid deprecation warnings. Oh My Zsh is enabled with a default theme (robbyrussell) and several productivity plugins (git, sudo, docker, etc.). Zsh autosuggestions are configured with `history` and `completion` strategies and an explicit highlight style for visibility. Tools with native config directories (like Neovim and Tmux) are mounted via `xdg.configFile` alongside their `.nix` module files.
- The zsh module is split into a small `default.nix` plus `env.zsh` and ordered `init/*.zsh` snippets for tools, cached shell-sources loading, Yazi helper, keybindings, and optional secrets.
- Stow is completely retired. `hypr/` and `kitty/` are managed natively using Home Manager `mkOutOfStoreSymlink`.

### Nix current state

- Home Manager flake exports canonical Linux host attrs `homeConfigurations.archer-arch` and `homeConfigurations.archer-wsl`; compatibility aliases `"archer@arch"` / `"archer@wsl"` are also kept so both `nh -c <host>` and any older explicit attr references continue to work
- `flake.nix` defines:
  - `homeConfigurations.archer-arch`
  - `homeConfigurations.archer-wsl`
  - `nixOnDroidConfigurations.archer-phone`
- Linux setup is now unified in `setup/main.sh`; OS-specific logic lives in `setup/lib.sh`
- First-run bootstrap is handled by `setup/bootstrap.sh <arch|wsl|android>`
- Android target is `nix-on-droid`; Termux-specific setup/config has been removed
- Host package ownership is split through `nix/modules/packages/`: `1.core-packages.nix` for all hosts, `3.linux-packages.nix` for the desktop Linux host, `4.wsl.nix` for WSL, and `2.droid-packages.nix` for Android
- User-level Home Manager config avoids restricted Nix daemon settings such as `trusted-public-keys`; custom binary caches belong in system Nix config, not Home Manager
- `apply-dotfiles` is now a host-aware zsh helper backed by `nh home switch` when available, with a `home-manager` fallback during bootstrap
- `nh` is the preferred Home Manager frontend on Arch/WSL. `NH_FLAKE`/`NH_HOME_FLAKE` point at `~/.dotfiles`, `NH_NOM=1` enables nix-output-monitor, zsh provides host-aware helpers (`hms`, `hmt`, `hmb`, `hme`, `nhc`), and `update.sh`/`setup/lib.sh` use `nh home switch` when available with a `home-manager` fallback for bootstrap
- Yazi now uses the Home Manager `programs.yazi` module for `init.lua`, `keymap.toml`, `yazi.toml`, `theme.toml`, vendored plugins, vendored flavors, and the `y` zsh wrapper. `package = null` keeps package ownership in `nix/modules/packages/*`, while `~/.config/yazi/package.toml` stays writable and is still seeded once from the repo so `ya pkg install` can manage runtime plugin/flavor deps when desired
- `setup/lib.sh:install_yazi_pkgs` now skips automatic `ya pkg install` whenever `~/.config/yazi/plugins/` or `~/.config/yazi/flavors/` already contains Home Manager symlinks, preventing clashes with HM-managed vendored plugin/flavor directories
- Because Yazi plugins/flavors were previously runtime-installed under `~/.config/yazi/{plugins,flavors}`, the Yazi Home Manager module now removes only the repo-managed plugin/flavor directories before `checkLinkTargets`, preventing HM clobber errors while leaving unrelated runtime entries alone
- Shell snippet convention is intentional: only `shell-sources/**/*.sh` participates in normal shell startup; `*.s` files are archival/manual snippets
- `nvim`, `lazygit`, and `starship` use `config.lib.file.mkOutOfStoreSymlink` → editing files in `nix/modules/programs/*/config/` takes effect immediately with no HM rebuild required
- `desktop-file-utils` now lives in `nix/modules/packages/3.linux-packages.nix` to provide `update-desktop-database`
- `nix-index` is paired with `pay-respects` in both `nix/modules/packages/3.linux-packages.nix` and `nix/modules/packages/4.wsl.nix` — `pay-respects` requires `nix-locate` (from `nix-index`) to suggest Nix packages for unknown commands

### end4dots AGENTS.md

A dedicated `AGENTS.md` lives at `~/.local/share/end4dots/AGENTS.md` covering:

- Sidebar tab visibility rules (Intelligence / Translator / Anime config keys)
- AI chat commands, keyboard shortcuts, and save/load path (`~/.local/state/quickshell/ii/user/ai/chats/`)
- Translator setup (`translate-shell` / `trans` CLI)
- Quickshell `Directories` singleton resolved paths
- end4dots branch strategy and working agreement

Read it at session start whenever touching end4dots / Quickshell / illogical-impulse configs.

---

### Nix app visibility in Quickshell / fuzzel

**Root cause**: end4dots `./setup install` uses `cp -f` (not symlinks), so it overwrites `~/.config/hypr/hyprland.conf` with the upstream version every run. The upstream version is missing `source=custom/env.conf`, so `custom/env.conf` (which sets `XDG_DATA_DIRS` and `PATH` for Nix) never loads.

**Fix applied (2025-03-28)**:

1. `hypr/.config/hypr/custom/env.conf` (stowed) — sets `XDG_DATA_DIRS` to include `~/.nix-profile/share`, adds `~/.nix-profile/bin` to `PATH`, sets `NIX_PATH`
2. `update.sh` now re-copies `hyprland.conf` from the archer branch after every end4dots `setup install`, ensuring `source=custom/env.conf` is always present; `local` keyword bug fixed (was `local hconf=...` at top level, now plain `_hconf=`)
3. `bin/scripts/refresh-apps` — rebuild desktop cache + signal Quickshell reload without full restart; Home Manager links it to `~/.local/bin`
4. **To activate**: log out and back in once; thereafter `refresh-apps` is sufficient after new Nix installs

**Key insight**: `~/.config/hypr/hyprland.conf` must always come from the archer branch of `dots-hyprland` (which has `source=custom/env.conf`). The `update.sh` patch guard ensures this survives future upstream syncs.

**Launcher env drift in fuzzel/Quickshell (confirmed 2026-03-28)**: Root cause: SDDM starts the systemd user instance _before_ Hyprland processes `env =` directives, so launcher-driven app starts can see a stale D-Bus/systemd activation environment. This shows up as apps launched from Quickshell/fuzzel not matching the behavior/config of the same apps launched from a terminal. Fix: `custom/execs.conf` now runs `exec-once = systemctl --user import-environment --all` + `dbus-update-activation-environment --systemd --all` immediately after Hyprland starts, pushing the full Hyprland session environment into the live user session. `update.sh` does the same after each reload.

**Hyprland inotify mid-flight reload (fixed 2026-03-28)**: `setup install` writes `hyprland.conf` which triggers an immediate inotify reload before Home Manager has linked `custom/` — causing `source= globbing error: found no match` on lines 10, 20-23. Fixed by adding Phase 4 to `update.sh`: explicit `hyprctl reload` after all Home Manager linking + patching is complete, so Hyprland always reads the fully settled state. Also added cleanup of `*.new` files left behind by end4dots install.

### update.sh smart rebuild

- Skips HM rebuild when no `.nix` / `flake.lock` files changed since last switch (tracked in `~/.local/state/home-manager/last-switch`)
- `NIX_FORCE=1 ./update.sh` forces a full rebuild regardless
- After end4dots `setup install`, auto-patches `hyprland.conf` to restore `source=custom/env.conf`

### bin/aicommit

- Providers: `copilot | codex | gemini | ollama` (default: copilot)
- Copilot uses `opencode run --model github-copilot/gpt-4.1 --format json` via stdin; text extracted with `jq -r 'select(.type=="text") | .part.text'`; exit code via `PIPESTATUS[1]`
- After generation: interactive loop shows message, prompts `[e]dit [p]ush [c]ancel` on `/dev/tty`
  - `e` → opens `$EDITOR` to tweak, re-shows message, re-prompts
  - `p` → runs `git commit -m "$msg"` directly
  - `c` → exits without committing
- `--edit` flag removed; loop replaces it
- Guards: fails cleanly if not in git repo or nothing staged
- Provider stderr captured to `/tmp/aicommit-<provider>-<pid>.log`; surfaced only on failure
- lazygit commands now call `aicommit <provider>` directly (no `git commit` wrapper needed)

### lazygit config shape

- `git.pagers` array (not `git.paging`) — current API
- delta: `--paging=never` required (prevents "terminal not fully functional") + `--hyperlinks` (click line→nvim)
- `os.shellFunctionsFile`: `~/.dotfiles/shell-sources/aliases/git.sh` — git aliases in `:` prompt
- No keybinding overrides; `output: terminal` on all customCommands
- customCommands: `<c-c>` copilot · `<c-g>` gemini · `<c-x>` codex · `<c-l>` ollama · `<c-A>` fzf provider picker
- All AI commit bindings call `aicommit <provider>` directly; the script owns the full edit→commit flow
- Extras: `O` open on GitHub · `Y` yank SHA · `I` rebase last N via fzf
