# Bharath's Dotfiles

Chezmoi-managed dotfiles for Arch Linux, WSL2 (Ubuntu), and Termux.
Auto-refreshed every ~4 months per package via `config-refresh` agent skill.

## Stack

| Layer    | Tool       | Scope                            |
|----------|------------|----------------------------------|
| System   | pacman     | native packages + desktop apps   |
| AUR      | yay        | non-repo packages                |
| Runtimes | mise       | node, python, go + global CLIs   |
| JS       | pnpm       | project deps                     |
| Python   | uv / uvx   | project deps / one-shots         |
| Secrets  | rage/age   | encrypted credentials (*.age)    |

## Quick Start

```bash
git clone https://github.com/1bharath-yadav/dotfiles.git ~/.dotfiles
chezmoi init --source ~/.dotfiles && chezmoi apply
```

See [setup guide](setup.md) for full Arch bootstrap.

## Structure

```
~/.dotfiles/
├── dot_config/          # XDG config files (chezmoi-managed)
├── dot_local/bin/       # shell scripts / workflows
├── dot_zsh/             # zsh snippets
├── agents/              # agent skills (*.skill.md)
├── docs/                # this site
│   ├── packages/        # per-package usage.md files
│   └── refresh-log.md   # config refresh history
├── setup/               # bootstrap guides
└── AGENTS.md            # agent session rules + state
```
