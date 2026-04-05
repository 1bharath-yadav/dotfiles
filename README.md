# dotfiles

A declarative personal environment for **Arch Linux**, **WSL2**, and **Termux**.

## Quick Start

```bash
git clone https://github.com/1bharath-yadav/dotfiles ~/.dotfiles
cd ~/.dotfiles

# First-run bootstrap
./setup/bootstrap.sh <arch|wsl|termux>

# Overall update
./update.sh

# Individual layer
./setup/main.sh apply <pacman|home|system|external|all> [os]
```

## Structure

```text
.dotfiles/
├── flake.nix              # Home Manager flake entrypoint
├── nix/
│   ├── hosts/             # archer-arch.nix, archer-wsl.nix
│   ├── modules/
│   │   ├── packages/      # common.nix, arch-home.nix, wsl.nix, external.txt
│   │   └── programs/      # per-tool configs + bin/scripts/
│   └── system/            # arch-system.nix, apply.sh, diff.sh
├── setup/
│   ├── arch/packages/     # pacman/AUR manifests (native-core, desktop, services, aur)
│   ├── lib.sh             # shared helpers
│   └── main.sh            # bootstrap/apply/update dispatcher
├── shell-sources/         # zsh aliases, functions, paths
└── update.sh              # overall sync wrapper
```

## Package Ownership

| Layer | What | Source |
|-------|------|--------|
| pacman/AUR | kernel, drivers, Wayland, system services, KDE/GTK desktop | `setup/arch/packages/*.txt` |
| system nix | GPU tools, ollama, hardware-heavy binaries | `nix/system/arch-system.nix` |
| Home Manager | user CLI, shell/editor config, portable apps | `nix/modules/packages/*.nix` |
| external | mise runtimes, uv/cargo/npm CLIs | `nix/modules/packages/external.txt` |

Runtime versions (Python, Node, Rust, Bun) are pinned in `nix/modules/programs/mise/default.nix`.

## Commands

| Command | Action |
|---------|--------|
| `./update.sh` | overall sync: end4dots + HM rebuild + session reload |
| `./setup/main.sh apply all arch` | apply all layers for Arch |
| `./setup/main.sh apply home` | rebuild Home Manager only |
| `dots-apply arch` | wrapper: apply all for Arch |
| `sync-external-tools` | install mise runtimes + uv/cargo/npm CLIs |

## Agents

See [AGENTS.md](./AGENTS.md) for architecture decisions, working agreements, and automation details.
