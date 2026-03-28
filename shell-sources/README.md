# Shell Sources

`shell-sources/` is loaded indirectly from the zsh cache builder in the Nix zsh module.

## Conventions

- `*.sh` = active snippets that are loaded into the shell
- `*.s` = parked/disabled snippets kept for reference and not loaded by default

This split is intentional: `.s` files are not part of normal shell startup.

## Layout

- `aliases/` = alias snippets
- `functions/` = function snippets
- `paths/` = PATH-related snippets

Some content originated from `dotfiles.io`, then was adapted over time.
