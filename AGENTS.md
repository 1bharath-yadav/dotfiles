# AGENTS.md

read this file at the **start** of every session and updated at the **end**.
It is the single source of truth for architecture decisions, working agreements, and current state.

---

## Environment

| Key            | Value                 |
| -------------- | --------------------- |
| Primary OS     | Arch Linux + Hyprland |
| Secondary OS   | Ubuntu / WSL2         |
| Mobile         | Termux (Android)      |
| Shell          | zsh (Oh My Zsh)       |
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
├── pkgs.json              ← single source of truth for ALL packages
│                            keys: common / arch.official / arch.aur / ubuntu.apt / termux / npm
├── .stowrc                ← global stow config (target=~, ignores)
├── update.sh              ← idempotent restow for current OS + end4dots pull (Arch)
│
├── setup/                 ← OS setup scripts
│   ├── lib.sh             ← shared helpers: log/warn/die, detect_os, stow_pkg,
│   │                         restow_pkg, install_omz, install_zsh_plugin, set_zsh_default
│   ├── auto.sh            ← entry point: detect_os → exec setup/<os>.sh
│   ├── arch.sh            ← Arch: pacman base → omz → pacman pkgs → yay → AUR → fnm → npm → stow
│   ├── ubuntu.sh          ← Ubuntu/WSL: apt → fnm → omz → extras (starship/zoxide/yazi) → npm → stow
│   ├── termux.sh          ← Termux: pkg → pip → omz → npm → stow
│   └── cleanup_root_orphans.sh  ← one-time: removes old setup scripts from ~/
│
├── stow/                  ← stow manifests (PACKAGES array per OS)
│   ├── arch.sh            ← bin hypr kitty nvim starship tmux yazi zsh
│   ├── ubuntu.sh          ← bin nvim starship tmux yazi zsh
│   └── termux.sh          ← bin nvim starship tmux zsh-termux termux
│
├── shell-sources/         ← NOT stowed; sourced via dotfiles cache in .zshrc
│   ├── aliases/           ← topic aliases (pacman.sh is Arch-only guarded)
│   ├── functions/         ← helper functions
│   └── paths/             ← PATH exports
│
├── # ── stow packages (each dir stowed → $HOME) ──
├── bin/                   ← ~/bin/ personal scripts
├── hypr/                  ← ~/.config/hypr/          [Arch only]
├── kitty/                 ← ~/.config/kitty/          [Arch only]
├── nvim/                  ← ~/.config/nvim/
├── starship/              ← ~/.config/starship.toml
├── tmux/                  ← ~/.tmux.conf
├── yazi/                  ← ~/.config/yazi/
├── zsh/                   ← ~/.zshrc + ~/.zshenv      [Arch + Ubuntu]
├── zsh-termux/            ← ~/.zshrc                  [Termux override]
└── termux/                ← ~/.termux/                [Termux]
    └── .termux/
        ├── termux.properties
        ├── colors.properties
        ├── colors/tokyonight.properties
        ├── bin/termux-url-opener
        └── widget/dynamic_shortcuts/ssh_command
```

---

## Key Design Decisions

### Stow strategy

- `stow --no-folding -t ~ <pkg>` — always use `--no-folding` so stow never folds a directory into a symlink (safer for `.config/`)
- `--no-folding` is now also set in `.stowrc` globally so it applies even to manual stow calls
- `restow_pkg` = `stow --no-folding -D` then `stow_pkg` — atomic unlink+relink
- Conflict resolution in `stow_pkg`: dry-run first, parse conflict lines, `rm` them, then stow

### Stow safety — non-package dirs never stowed (3 layers)

1. **Explicit PACKAGES arrays** in `stow/arch.sh`, `stow/ubuntu.sh`, `stow/termux.sh` — only named packages are ever passed to stow. No globbing.
2. **`_STOW_BLOCKLIST`** in `setup/lib.sh` — `stow_pkg` and `restow_pkg` both call `_stow_blocked()` first and `die` if given a non-package dir (`setup stow shell-sources .git .spaces`).
3. **`.stowrc` `--ignore` patterns** — defence-in-depth: if someone runs `stow .` manually, these name-based patterns prevent the non-package dirs from being linked. Note: stow ignores match basenames, not full paths.

Dirs that will never be stowed: `setup/` `stow/` `shell-sources/` `.git/` `.spaces/`

### pkgs.json keys

- `common[]` — installed on Arch + Ubuntu (common CLI tools)
- `arch.official[]` — pacman packages (Arch only, skips if also in aur)
- `arch.aur[]` — AUR packages via yay
- `ubuntu.apt[]` — apt packages (Ubuntu/WSL only, name-mapped from Arch names)
- `termux[]` — pkg packages (Termux only)
- `npm[]` — npm -g packages (all OSes with Node)

### OS detection (`setup/lib.sh: detect_os`)

- Termux: `$TERMUX_VERSION` set OR `/data/data/com.termux` exists (checked first, no `/etc/os-release`)
- WSL: `/proc/version` contains `microsoft|wsl`
- Arch: `/etc/arch-release` exists
- Ubuntu: `/etc/os-release` contains `ubuntu`

---

## Working Agreement

- **Always read this file at session start** before touching any files
- **Always update this file at session end** with any structural/architectural changes
- Conservative edits — small, reviewable, targeted
- Prefer `edit_block` for targeted edits; `write_file` in chunks for new/rewritten files
- `stow --no-folding` always — never omit this flag
- Never manually copy configs; always use stow
- `shell-sources/` is never stowed — it's loaded via the dotfiles cache in `.zshrc`
- Hyprland/end4dots configs live in `~/linux/dots-hyprland/`, not here

---

## Common Operations

```bash
# Full setup on new machine
~/.dotfiles/setup/auto.sh

# Re-stow after editing configs
~/.dotfiles/update.sh

# Re-stow specific OS
~/.dotfiles/stow/arch.sh       # Arch
~/.dotfiles/stow/ubuntu.sh     # Ubuntu/WSL
~/.dotfiles/stow/termux.sh     # Termux

# Invalidate dotfiles cache (picks up shell-sources changes)
rm ~/.zsh_dotfiles_cache

# Add new package to all OSes
# 1. Edit pkgs.json
# 2. Edit stow/<os>.sh PACKAGES array if it's a new stow package
# 3. Run ./update.sh
```

## Current State

### Packages / Stow

- `git` stow package → `git/.gitconfig` (all OSes including termux)
- `lazygit` stow package → `lazygit/.config/lazygit/config.yml` (arch + ubuntu; termux excluded)

### bin/aicommit

- Providers: `copilot | codex | gemini | ollama` (default: copilot) — priority order: copilot first
- Copilot uses `opencode run --model github-copilot/gpt-4.1 --format json` via stdin; text extracted with `jq -r 'select(.type=="text") | .part.text'`; exit code via `PIPESTATUS[1]`
- Flags: `--edit` opens `$EDITOR` to review/tweak message before printing
- Env: `OLLAMA_COMMIT_MODEL` overrides model (default: `granite3.3:latest`)
- Guards: fails cleanly if not in git repo or nothing staged
- Provider stderr captured to `/tmp/aicommit-<provider>-<pid>.log`; surfaced only on failure
- No functions used — flat case statement dispatch

### lazygit config shape

- `git.pagers` array (not `git.paging`) — current API
- delta: `--paging=never` required (prevents "terminal not fully functional") + `--hyperlinks` (click line→nvim)
- `os.shellFunctionsFile`: `~/.dotfiles/shell-sources/aliases/git.sh` — git aliases in `:` prompt
- No keybinding overrides; `output: terminal` on all customCommands
- customCommands: `<c-c>` copilot · `<c-g>` gemini · `<c-x>` codex · `<c-l>` ollama · `<c-A>` fzf picker+edit
- Extras: `O` open on GitHub · `Y` yank SHA · `I` rebase last N via fzf
