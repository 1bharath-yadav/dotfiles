# Bharath's Linux Dotfiles

Reproducible Arch Linux workstation configuration managed with **chezmoi**. The repository is the source of truth; live files under `~/.config`, `~/.local`, and `~/.ssh` are generated or synchronized from it.

## Repository model

```text
~/.dotfiles  ──chezmoi──>  $HOME
     │
     ├─ dot_config/       ~/.config/*
     ├─ dot_local/         ~/.local/*
     ├─ dot_zsh*           zsh configuration
     ├─ dot_tmux.conf     tmux configuration
     ├─ private_*         private-mode files
     ├─ agents/            agent skills and workflows
     └─ setup/             bootstrap documentation
```

**Rule:** edit the source under `~/.dotfiles`, then run `chezmoi apply`. Do not hand-edit managed files unless debugging; pull the change back into the source immediately.

## Chezmoi workflow

```bash
chezmoi source-path
chezmoi status
chezmoi diff
chezmoi apply
chezmoi verify
```

For a new machine:

```bash
git clone https://github.com/1bharath-yadav/dotfiles.git ~/.dotfiles
chezmoi init --source ~/.dotfiles
chezmoi apply
```

After changes:

```bash
git -C ~/.dotfiles status --short
git -C ~/.dotfiles add <specific-files>
git -C ~/.dotfiles commit -m "type: why"
git -C ~/.dotfiles push origin chizmoi
```

## Package ownership

| Layer | Owner | Use |
|---|---|---|
| System | `pacman` | OS packages and desktop dependencies |
| AUR | `paru` | Arch User Repository packages |
| Runtimes/global CLIs | `mise` | language runtimes and global developer tools |
| JavaScript projects | `pnpm` | project-local Node dependencies |
| Python projects | `uv` | project environments and one-shots |
| Rust projects | `cargo` | Rust crates and project tooling |
| Secrets | `rage`/`age` + `sops` | encrypted structured secrets |

Do not mix global package ownership without a reason. Global developer binaries should preferably be declared in `dot_config/mise/config.toml`.

## Core workstation

- **Hyprland + Wayland** desktop
- **Zsh + tmux** shell workflow
- **Neovim** IDE/editor
- **Yazi** terminal file manager
- **Mise** runtime and CLI manager
- **Chezmoi** configuration management
- Git/GitHub workflows and local automation

## Neovim

The Neovim setup includes Snacks, Which-Key, Harpoon, Persistence, DAP, Neotest, Treesitter, LSP, formatting/linting, Yazi integration, Markdown/Obsidian tooling, and project-wide search/replace.

Useful discovery commands inside Neovim:

```text
<leader>?   Which-Key hierarchy
:checkhealth
:Lazy
:LspInfo
:Mason
```

## Yazi

Yazi is the daily terminal file manager. The native three-pane layout is intentionally preserved; plugins add functionality without owning the layout.

```text
?           keymap/help overlay
```

## Secrets

- Never commit plaintext secrets or private keys.
- Store encrypted repository secrets as `*.age`.
- Use the configured `rage`/`age` key at `~/.config/rage/key.txt`.
- Never encrypt a file in place; create a new encrypted artifact.

## Maintenance

Run this before committing configuration changes:

```bash
chezmoi diff
chezmoi verify
nvim --headless +'qa!'
yazi --version
mise doctor
```

Keep generated caches, timestamped backups, plugin worktrees, and machine-local artifacts out of the source repository. Update `AGENTS.md` whenever ownership or workflow changes.
