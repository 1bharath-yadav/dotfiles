# dotfiles

A unified, Nix-powered configuration environment for **Arch Linux**, **WSL2**, and **Android (nix-on-droid)**.

## 🚀 Quick Start

```bash
git clone https://github.com/1bharath-yadav/dotfiles ~/.dotfiles
cd ~/.dotfiles

# First-run bootstrap (detects OS and installs system packages + Nix)
./setup/bootstrap.sh <arch|wsl|android>

# Apply Home Manager user environment
./update.sh
```

## 🏗️ Structure

```text
.dotfiles/
├── flake.nix          # Home Manager + nix-on-droid entrypoint
├── nix/               # Nix modules and host definitions
│   ├── hosts/         # Host-specific settings (arch, wsl, phone)
│   └── modules/       # Domain bundles: packages/ and programs/ (configs)
├── setup/             # Bootstrap logic and OS-specific helpers
├── shell-sources/     # Topic-based Zsh aliases, functions, and paths
└── update.sh          # Idempotent refresh (HM switch + end4dots sync)
```

## 📦 Package Ownership

*   **Pacman / APT:** System bootstrap, drivers, and **KDE desktop apps** on Arch (Dolphin, Ark, etc.) for native plugin/service stability.
*   **Home Manager:** Portable user environment, CLI tools, and core app configurations (Neovim, Tmux, Zsh, Yazi).
*   **Python:** Managed via `uv`. `uv tool` for global CLIs; project-local dependencies via `pyproject.toml`.

## 🔄 Updating

Run `~/.dotfiles/update.sh` to:
1. Sync `end4dots` (Arch/Hyprland) with upstream using a two-branch rebase strategy.
2. Perform a smart Home Manager rebuild (only runs if `.nix` files have changed).
3. Propagate the environment to the systemd user session and reload Hyprland.

## 🤖 Agents & Automation

See [AGENTS.md](./AGENTS.md) for detailed architecture decisions, working agreements, and the mission statement for the custom automation tools included in this repository.
