# Dotfiles

Personal Arch Linux dotfiles based on Ends4, tuned for Hyprland and managed with GNU Stow.

## What’s Inside
- `hypr/` Hyprland config
- `zsh/` shell config
- `nvim/` Neovim config
- `kitty/` terminal config
- `tmux/` tmux config
- `shell-sources/` shared shell sources

## Workflow
- Use GNU Stow for linking.
- `update.sh` updates the base (end4dots) and restows all packages.
- See `Setup.md` for system setup notes.

## Notes
- Be conservative with changes; preserve layout and existing customizations.
- Avoid new dependencies unless explicitly intended.
