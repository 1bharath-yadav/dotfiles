# AGENTS.md

read this file at the **start** of every session and updated at the **end**.
It is the single source of truth for architecture decisions, working agreements, and current state.

---

## Environment

| Key            | Value                 |
| -------------- | --------------------- |
| Primary OS     | Arch Linux + Hyprland |
| Secondary OS   | Ubuntu in WSL2 (no GUI) |
| Mobile         | nix-on-droid (Android) |
| Shell          | zsh                   |
| Prompt         | Starship              |
| Editor         | Neovim                |
| Package linker | GNU Stow              |
| Base dotfiles  | end4dots (Hyprland)   |

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
│       ├── core/          ← home-base and CLI base packages
│       ├── programs/      ← app configs (nvim, yazi, git, tmux, zsh, starship, bin)
│       ├── profiles/      ← host package bundles (common-linux / arch-desktop / wsl)
│       └── android/       ← Android-specific packaging
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
├── # ── end4dots graphical additions (GNU Stow) ──
├── hypr/                  ← ~/.config/hypr/          [Arch only]
└── kitty/                 ← ~/.config/kitty/         [Arch only]
```

---

## Key Design Decisions

### Stow strategy

- `stow --no-folding -t ~ <pkg>` — always use `--no-folding` so stow never folds a directory into a symlink (safer for `.config/`)
- `restow_pkg` = `stow --no-folding -D` then `stow_pkg` — atomic unlink+relink
- Conflict resolution in `stow_pkg`: dry-run first, parse conflict lines, `rm` them, then stow

### Stow safety — non-package dirs never stowed (3 layers)

1. **Explicit overlay list** in `apply_stow_overlays()` (`setup/lib.sh`) — only named packages are ever passed to stow. No globbing.
2. **`_STOW_BLOCKLIST`** in `setup/lib.sh` — `stow_pkg` and `restow_pkg` both call `_stow_blocked()` first and `die` if given a non-package dir (`setup shell-sources .git .spaces`).
3. **Script-only stow usage** — stow is only invoked through `setup/lib.sh`, which always passes explicit package names and `--no-folding`.

Dirs that will never be stowed: `setup/` `stow/` `shell-sources/` `.git/` `.spaces/` `nix/`

### OS detection (`setup/lib.sh: detect_os`)

- WSL: `/proc/version` contains `microsoft|wsl`
- Arch: `/etc/arch-release` exists
- Ubuntu: `/etc/os-release` contains `ubuntu`

### end4dots fork strategy (`~/linux/dots-hyprland`)

Two-branch model — keeps upstream sync clean and your changes rebased on top:

| Branch | Purpose | Rule |
|--------|---------|------|
| `main` | Clean mirror of `upstream/main` | **Never commit here** |
| `archer` | Your modifications to end4dots files | Only branch you commit to |

- `update.sh` handles the full sync: `main` rebases onto `upstream/main`, then `archer` rebases onto `main`
- Always remain on `archer` after `update.sh` completes
- Conflict on `main` → `git rebase --abort`, fix upstream divergence, re-run
- Conflict on `archer` → `git rebase --continue` after resolving

**What goes where:**

| Change type | Location |
|-------------|----------|
| Modifies an existing end4dots file (AGS widget, theme, hyprland.conf) | `archer` branch commit |
| Pure addition end4dots leaves for users (keybinds, execs, window rules) | `~/.dotfiles/hypr/custom/` (stowed) |
| Machine-specific (monitor layout, app exec paths) | `~/.dotfiles/hypr/custom/` (stowed) |

---

## Working Agreement

- **Always read this file at session start** before touching any files
- **Always update this file at session end** with any structural/architectural changes
- Conservative edits — small, reviewable, targeted
- Prefer `edit_block` for targeted edits; `write_file` in chunks for new/rewritten files
- `stow --no-folding` always — never omit this flag
- Never manually copy configs; always use stow
- `shell-sources/` is never stowed — it's loaded via the dotfiles cache in `.zshrc`
- In `shell-sources/`, `*.sh` means active/loaded and `*.s` means parked/disabled reference snippets; do not change the loader to source `.s` files by default
- Hyprland/end4dots configs live in `~/linux/dots-hyprland/` on branch `archer`, not here
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
cd ~/linux/dots-hyprland
git checkout archer            # always work here
git rebase main               # after manual main update
git rebase --continue         # after resolving archer conflict
```

## Current State

### Package ownership model

Clear three-layer boundary (established 2026-03-28):

| Layer | Manager | Tracked in |
|---|---|---|
| System / kernel / AUR | `pacman` | `setup/arch_linux/pacman-explicit.txt` |
| User environment (all hosts) | Nix Home Manager | `nix/modules/` |
| Android | nix-on-droid | `nix/hosts/archer-phone.nix` |

**Key rule:** if it needs a systemd service, `/etc` integration, or is AUR-only → pacman. Everything else → Nix.

### Nix module layout (post-refactor)

```
nix/modules/
  core/packages.nix          ← universal CLI tools on ALL hosts (bat, eza, fzf, ripgrep, jq, gh…)
  profiles/
    common-linux.nix         ← targets.genericLinux.enable + lazygit + yazi imports
    arch-desktop.nix         ← Arch-specific CLI + GUI apps + fonts; has ownership comment block
    wsl.nix                  ← minimal WSL additions on top of common-linux
    extras.nix               ← optional/niche tools (security, rare utils); NOT imported by default
```

**extras.nix** contains: `aircrack-ng`, `john`, `fcrackzip`, `f3`, `gogcli`, `httrack`, `nyx`, `tor`, `lynx`, `monolith`, `goaccess`, `payload-dumper-go`, `netcat-openbsd`, `msmtp`, `sshfs`, `traceroute`, `acpi`, `ent`, `fq`, `speedtest-cli`, `antigravity`, `smartmontools`.
To enable on a host: `imports = [ ../profiles/extras.nix ];`

**pacman-explicit.txt** (`setup/arch_linux/pacman-explicit.txt`) — git-tracked list of system packages pacman explicitly owns, with audit command: `pacman -Qe | awk '{print $1}' | sort`

### Packages / Stow

- Repository root is clean. All user configurations (neovim, yazi, tmux, zsh, lazygit, starship, bin) are strictly grouped inside `nix/modules/programs/`.
- `git` and `zsh` configs are fully declared natively inside Nix. `programs.zsh.dotDir` uses an absolute path (`config.home.homeDirectory`) to avoid deprecation warnings. Oh My Zsh is enabled with a default theme (robbyrussell) and several productivity plugins (git, sudo, docker, etc.). Zsh autosuggestions are configured with `history` and `completion` strategies and an explicit highlight style for visibility. Tools with native config directories (like Neovim and Tmux) are mounted via `xdg.configFile` alongside their `.nix` module files.
- The zsh module is split into a small `default.nix` plus `env.zsh` and ordered `init/*.zsh` snippets for tools, cached shell-sources loading, Yazi helper, keybindings, and optional secrets.
- Stow remains only for Arch-specific `hypr/` and `kitty/`

### Nix current state

- `flake.nix` defines:
  - `homeConfigurations.archer-arch`
  - `homeConfigurations.archer-wsl`
  - `nixOnDroidConfigurations.archer-phone`
- Linux setup is now unified in `setup/main.sh`; OS-specific logic lives in `setup/lib.sh`
- First-run bootstrap is handled by `setup/bootstrap.sh <arch|wsl|android>`
- Android target is `nix-on-droid`; Termux-specific setup/config has been removed
- Host package ownership is split through profile modules: `common-linux` for shared non-NixOS behavior, `arch-desktop` for Arch GUI/dev packages, and `wsl` for a lighter terminal-focused WSL set
- User-level Home Manager config avoids restricted Nix daemon settings such as `trusted-public-keys`; custom binary caches belong in system Nix config, not Home Manager
- `apply-dotfiles` stages the repo then runs `home-manager switch --flake ~/.dotfiles#archer-arch` directly; avoid floating `nix run home-manager/<branch>` aliases
- Yazi uses per-file Home Manager links for static config, while `~/.config/yazi/package.toml` stays writable and is seeded once from the repo so `ya pkg install` can manage plugins/flavors at runtime
- Shell snippet convention is intentional: only `shell-sources/**/*.sh` participates in normal shell startup; `*.s` files are archival/manual snippets
- `nvim`, `lazygit`, and `starship` use `config.lib.file.mkOutOfStoreSymlink` → editing files in `nix/modules/programs/*/config/` takes effect immediately with no HM rebuild required
- `desktop-file-utils` added to `core/packages.nix` to provide `update-desktop-database`
- `nix-index` added alongside `pay-respects` in both `arch-desktop.nix` and `wsl.nix` — `pay-respects` requires `nix-locate` (from `nix-index`) to suggest Nix packages for unknown commands

### Nix app visibility in Quickshell / fuzzel

**Root cause**: end4dots `./setup install` uses `cp -f` (not symlinks), so it overwrites `~/.config/hypr/hyprland.conf` with the upstream version every run. The upstream version is missing `source=custom/env.conf`, so `custom/env.conf` (which sets `XDG_DATA_DIRS` and `PATH` for Nix) never loads.

**Fix applied (2025-03-28)**:
1. `hypr/.config/hypr/custom/env.conf` (stowed) — sets `XDG_DATA_DIRS` to include `~/.nix-profile/share`, adds `~/.nix-profile/bin` to `PATH`, sets `NIX_PATH`
2. `update.sh` now re-copies `hyprland.conf` from the archer branch after every end4dots `setup install`, ensuring `source=custom/env.conf` is always present; `local` keyword bug fixed (was `local hconf=...` at top level, now plain `_hconf=`)
3. `bin/scripts/refresh-apps` — rebuild desktop cache + signal Quickshell reload without full restart; manually linked to `~/bin` pending next HM switch
4. **To activate**: log out and back in once; thereafter `refresh-apps` is sufficient after new Nix installs

**Key insight**: `~/.config/hypr/hyprland.conf` must always come from the archer branch of `dots-hyprland` (which has `source=custom/env.conf`). The `update.sh` patch guard ensures this survives future upstream syncs.

**Nix apps invisible in fuzzel/Quickshell (root cause confirmed 2026-03-28)**: Root cause: SDDM starts the systemd user instance *before* Hyprland processes `env =` directives. So Quickshell and other user services launch with `XDG_DATA_DIRS` from PAM (no `~/.nix-profile/share`). `~/.config/environment.d/10-home-manager.conf` sets it correctly but systemd doesn't read it when SDDM is the session manager. Fix: `custom/execs.conf` runs `exec-once = systemctl --user import-environment XDG_DATA_DIRS PATH ...` + `dbus-update-activation-environment` immediately after Hyprland starts, pushing the Hyprland-processed env into the live user session. `update.sh` does the same after each reload. **To fix current session without logout**: `export XDG_DATA_DIRS="$HOME/.nix-profile/share:..."` then `systemctl --user import-environment XDG_DATA_DIRS`.

**Hyprland inotify mid-flight reload (fixed 2026-03-28)**: `setup install` writes `hyprland.conf` which triggers an immediate inotify reload before stow has re-linked `custom/` — causing `source= globbing error: found no match` on lines 10, 20-23. Fixed by adding Phase 4 to `update.sh`: explicit `hyprctl reload` after all stow + patching is complete, so Hyprland always reads the fully settled state. Also added cleanup of `*.new` files left behind by end4dots install.

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
