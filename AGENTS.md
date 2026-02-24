# AGENTS.md

This repository contains custom dotfiles based on Arch Linux, Hyprland, and the Ends4 dotfiles.

## Environment

- OS: Arch Linux
- WM/Compositor: Hyprland
- Shell: zsh
- Base dotfiles: Ends4
- Package manager: GNU Stow (see `.stowrc`, `update.sh`)

## Working Agreement

- Be conservative with changes; prefer small, reviewable edits.
- Preserve existing style, formatting, and directory layout.
- Avoid adding new dependencies unless asked.
- Do not delete user customizations unless explicitly requested.
- Be careful with Stow operations: `update.sh` removes conflicts before restowing.

## Common Locations

- Hyprland config: `hypr/`
- Shell config: `zsh/`
- Neovim config: `nvim/`
- Kitty config: `kitty/`
- Tmux config: `tmux/`
- Setup notes: `Setup.md`
- Update workflow: `update.sh`

## Notes

- This is the user’s custom dotfiles directory; treat it as the source of truth.
- Prefer GNU Stow for linking; do not manually copy configs unless asked.
- If instructions conflict, ask before proceeding.
