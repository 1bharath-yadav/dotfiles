# kitty
> A fast GPU terminal I use for daily shell work, scrollback, search, and tight shell integration.

## Last Refreshed
2026-07-31

## Why I Use It
kitty is my primary terminal because it stays fast, renders text cleanly, and gives me useful terminal-native features without needing extra tooling: searchable scrollback, keyboard-driven tab/window management, shell integration, and kittens for focused workflows.

## Config Choices
- `font_family FiraCode Nerd Font Mono` — good ligatures and symbol coverage for my coding setup.
- `font_size 13.0` — comfortable default size on my display.
- `cursor_trail 1` — keep the cursor trail available for large jumps.
- `window_margin_width 21.75` — match the visual spacing I like across terminals.
- `confirm_os_window_close 0` — avoid close confirmation prompts.
- `shell zsh` — always open kitty in zsh.
- `include ~/.local/state/quickshell/user/generated/terminal/kitty-theme.conf` — keep colors in the generated theme layer.
- `background #1e1e1e` / `foreground #d4d4d4` — match the dark editor theme.
- `cursor #d4d4d4` / `cursor_text_color #1e1e1e` / `cursor_shape block` — high-contrast block cursor.
- `selection_background #264f78` / `selection_foreground #ffffff` — readable selection colors.

## 20% That Matters (daily usage)
| What | How |
|---|---|
| Open search | `ctrl+f` or `kitty_mod+f` launches the search kitten in a split. |
| Copy/interrupt | `ctrl+c` copies when text is selected, otherwise interrupts. |
| Scroll page | `page_up` / `page_down` move through scrollback. |
| Font zoom | `ctrl+plus`, `ctrl+minus`, `ctrl+0` adjust or reset font size. |
| Switch tabs | `ctrl+tab` and `ctrl+shift+tab` send tab navigation sequences. |

## Known Quirks
- The config intentionally sends raw tab-navigation escape sequences instead of using kitty’s default tab actions.
- `cursor_trail` is enabled but kept subtle with a low threshold.
- The margin value is intentionally non-integer to mirror the spacing used in other terminals.

## Skipped / Rejected Options
- I did not enable `auto_reload_config` explicitly because kitty already supports reload-on-change behavior and this config is small.
- I did not switch `shell` to `.` because I want kitty to stay pinned to zsh rather than inherit a different shell from the environment.
- I did not add side-tab or vertical-tab changes; those are layout preferences, not a refresh win.

## Sources
- https://sw.kovidgoyal.net/kitty/changelog/
- https://sw.kovidgoyal.net/kitty/conf/
- https://sw.kovidgoyal.net/kitty/faq/
