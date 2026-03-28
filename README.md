# dotfiles

Managed with Home Manager for userland and a small amount of GNU Stow for Arch-only GUI overlays. Supports **Arch Linux**, **Ubuntu in WSL2 (no GUI)**, and **Android via nix-on-droid**.

## Quick Start

```bash
git clone https://github.com/yourusername/dotfiles ~/.dotfiles
cd ~/.dotfiles
chmod +x setup/auto.sh
./setup/auto.sh
```

Preferred flow:
```bash
./setup/bootstrap.sh arch      # first-run bootstrap for Arch
./setup/bootstrap.sh wsl       # first-run bootstrap for Ubuntu in WSL
./setup/bootstrap.sh android   # first-run bootstrap inside nix-on-droid
./setup/main.sh arch     # Arch bootstrap + overlays + Home Manager
./setup/main.sh wsl      # Ubuntu in WSL bootstrap + Home Manager
./setup/auto.sh          # detect current OS and run setup/main.sh
```

## Structure

```
.dotfiles/
├── flake.nix          # Home Manager + nix-on-droid entrypoint
├── nix/               # Nix modules and host definitions
├── setup/             # setup scripts
│   ├── lib.sh         # shared helpers (bootstrap, stow, Home Manager, detect_os)
│   ├── bootstrap.sh   # shared bootstrap entry for arch / wsl / android
│   ├── main.sh        # unified setup entry for arch / wsl / auto
│   └── auto.sh        # thin wrapper to setup/main.sh auto
├── shell-sources/     # sourced via .zshrc cache (NOT stowed)
│   ├── aliases/       # aliases organised by topic
│   ├── functions/     # helper functions
│   └── paths/         # PATH additions
│
├── # ── end4dots graphical additions (GNU Stow) ──
├── hypr/              # Hyprland config  [arch only]
└── kitty/             # Kitty terminal   [arch only]
```

## Updating

```bash
~/.dotfiles/update.sh   # restow for current OS, pull end4dots (Arch)
```

`update.sh` intentionally keeps the `end4dots` Arch workflow intact. Nix does not replace that upstream Hyprland base.

## Package ownership

- `pacman` / `apt`: system bootstrap only
- Home Manager: user-level packages and common user config links
- `nix/modules/profiles/`: host package bundles (`common-linux`, `arch-desktop`, `wsl`)
- `nix-on-droid`: Android user environment
- Stow: Arch-only `hypr` and `kitty`

## Key files

| File | Purpose |
|------|---------|
| `flake.nix` | Single source of truth for Nix user environments |
| `setup/lib.sh` | Shared bash helpers for bootstrap, overlays, and Home Manager |
| `setup/bootstrap.sh` | First-run bootstrap entry for all supported OS targets |
| `setup/main.sh` | Unified setup entry for Arch and Ubuntu in WSL |
| `update.sh` | Idempotent restow for current OS + end4dots pull on Arch |
