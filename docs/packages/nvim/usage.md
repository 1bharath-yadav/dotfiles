# nvim
> Modern Modal Text Editor configured for high-productivity development in Lua.

## Last Refreshed
2026-08-04

## Why I Use It
Primary code editor for terminal-driven development, dotfiles maintenance, and lightning-fast text manipulation with rich LSP/Treesitter integration.

## Config Choices
- `lazydev.nvim` — modern Neovim Lua API completion engine replacing deprecated `neodev.nvim`.
- `vim.diagnostic.jump()` — Neovim 0.12 native diagnostic navigation API.
- `opt.smoothscroll = true` — smooth line scrolling for viewports.
- `opt.undofile = true` — persistent undo history across buffer & editor reopens.
- `loaded_netrw = 1` — disabled legacy netrw in favor of `snacks.picker` / `snacks.explorer`.
- `suppressed_dirs` — updated auto-session configuration key for v3+.

## 20% That Matters (daily usage)
| What | How |
|---|---|
| Find files / buffers / grep | `<leader>f...` (snacks.picker) |
| Git status & lazygit | `<leader>gg` / `<leader>gl` |
| Diagnostics & Trouble | `<leader>xw` / `[d` / `]d` |
| Format file | `<leader>fm` |
| Code actions & rename | `<leader>ca` / `<leader>rn` |

## Known Quirks
- `lazy-lock.json` is updated live by Neovim during plugin updates; re-add to chezmoi when locking versions.

## Skipped / Rejected Options
- `neodev.nvim` — deprecated upstream; replaced by `lazydev.nvim`.
- `g:netrw_liststyle` — obsolete with netrw disabled.

## Sources
- https://neovim.io/doc/user/news-0.12.html
- https://github.com/folke/lazydev.nvim
