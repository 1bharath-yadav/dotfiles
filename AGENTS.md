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
│       ├── programs/      ← apps (nvim, yazi, git, tmux, zsh, starship, bin)
│       └── linux|android/ ← OS-specific packaging
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

### Packages / Stow

- Repository root is clean. All user configurations (neovim, yazi, tmux, zsh, lazygit, starship, bin) are strictly grouped inside `nix/modules/programs/`.
- `git` and `zsh` configs are fully declared natively inside Nix, while tools with native config directories (like Neovim) are mounted via `xdg.configFile` alongside their `.nix` module files.
- Stow remains only for Arch-specific `hypr/` and `kitty/`

### Nix current state

- `flake.nix` defines:
  - `homeConfigurations.archer-arch`
  - `homeConfigurations.archer-wsl`
  - `nixOnDroidConfigurations.archer-phone`
- Linux setup is now unified in `setup/main.sh`; OS-specific logic lives in `setup/lib.sh`
- First-run bootstrap is handled by `setup/bootstrap.sh <arch|wsl|android>`
- Android target is `nix-on-droid`; Termux-specific setup/config has been removed

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
