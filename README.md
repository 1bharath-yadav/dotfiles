# dotfiles

Managed with [GNU Stow](https://www.gnu.org/software/stow/). Supports **Arch Linux**, **Ubuntu/WSL**, and **Termux**.

## Quick Start

```bash
git clone https://github.com/yourusername/dotfiles ~/.dotfiles
cd ~/.dotfiles
chmod +x setup/auto.sh
./setup/auto.sh        # auto-detects OS
```

Or run OS-specific setup directly:
```bash
./setup/arch.sh        # Arch Linux
./setup/ubuntu.sh      # Ubuntu / WSL
./setup/termux.sh      # Termux (Android)
```

## Structure

```
.dotfiles/
├── setup/             # OS setup scripts
│   ├── lib.sh         # shared helpers (stow, log, detect_os, omz…)
│   ├── auto.sh        # entry point — detects OS, delegates
│   ├── arch.sh        # Arch Linux: pacman + yay + npm
│   ├── ubuntu.sh      # Ubuntu/WSL: apt + extras
│   └── termux.sh      # Termux: pkg + pip + npm
├── stow/              # stow manifests (which packages per OS)
│   ├── arch.sh
│   ├── ubuntu.sh
│   └── termux.sh
├── shell-sources/     # sourced via .zshrc cache (NOT stowed)
│   ├── aliases/       # aliases organised by topic
│   ├── functions/     # helper functions
│   └── paths/         # PATH additions
│
├── # ── stow packages (stowed to $HOME) ──
├── bin/               # personal scripts → ~/bin/
├── hypr/              # Hyprland config  [arch only]
├── kitty/             # Kitty terminal   [arch only]
├── nvim/              # Neovim config
├── starship/          # Starship prompt
├── tmux/              # Tmux config
├── yazi/              # Yazi file manager
├── zsh/               # Zsh config       [arch + ubuntu]
├── zsh-termux/        # Zsh config       [termux]
└── termux/            # ~/.termux/       [termux]
    └── .termux/
        ├── termux.properties
        ├── colors.properties
        ├── colors/
        ├── bin/
        └── widget/
```

## Updating

```bash
~/.dotfiles/update.sh   # restow for current OS, pull end4dots (Arch)
```

## Adding a new package

1. Add it to `pkgs.json` under the right key (`common`, `arch.official`, `arch.aur`, `ubuntu.apt`, `termux`, `npm`)
2. Add the stow package dir if needed
3. Add it to the relevant `stow/<os>.sh` PACKAGES array
4. Run `./update.sh`

## Key files

| File | Purpose |
|------|---------|
| `pkgs.json` | Single source of truth for all packages |
| `setup/lib.sh` | Shared bash helpers (stow_pkg, restow_pkg, detect_os…) |
| `.stowrc` | Global stow defaults (target=$HOME, ignores) |
| `update.sh` | Idempotent restow for current OS |
