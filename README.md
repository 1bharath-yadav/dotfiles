# dotfiles

Chezmoi-managed personal dotfiles for Arch Linux, WSL2 (Ubuntu), and Termux.

## Structure

```
~/.dotfiles/
├── dot_config/
│   ├── pacman/Packages      # pacman package manifest
│   └── mise/config.toml     # runtimes + global dev CLIs
├── dot_local/bin/           # shell scripts / workflows
├── dot_zsh/                 # zsh config snippets (conf.d/)
├── dot_zshenv               # ZDOTDIR + env bootstrap
├── dot_zshrc                # zsh main config
├── dot_tmux.conf            # tmux config
├── setup/
│   ├── linux.md             # Arch bootstrap guide
│   └── aur-packages.txt     # AUR package backup (non-debug)
├── AGENTS.md                # agent rules + current state
└── README.md
```

## Package Strategy

| Layer | Tool | Purpose |
|---|---|---|
| System | pacman | native packages, desktop apps, deps |
| Runtimes | mise | node, python, go, rust + global CLIs |
| JS | pnpm | project deps |
| Python | uv / uvx | project deps / one-shots |
| AUR | yay | non-repo packages |
| Secrets | rage/age | encrypted credentials (*.age) |

## Quick Start

```bash
git clone https://github.com/1bharath-yadav/dotfiles.git ~/.dotfiles
chezmoi init --source ~/.dotfiles && chezmoi apply
```

See `setup/linux.md` for full bootstrap.

## Secrets

- Key at `~/.config/rage/key.txt`
- Encrypt: `rageenc <file>` → `<file>.age`
- Decrypt: `ragedec <file.age>`
- Never commit plaintext secrets or private keys
