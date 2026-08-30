# yazi
> Fast terminal file manager with rich previews, metadata, and a keyboard-first workflow.

## Last Refreshed
2026-08-30

## Why I Use It
Yazi is the primary terminal file manager for fast navigation, previews, batch operations, and editor/shell integration.

## Config Choices
- `mgr.linemode = "size_and_mtime"` — useful size/time context in the list.
- `mgr.show_hidden = false` — keeps normal browsing clean.
- `tasks.image_alloc = 1073741824` — supports large image previews.
- `full-border` — rounded pane borders.
- `smart-enter` — `l`/Enter opens directories or files intelligently.
- `yatline` + Catppuccin Macchiato — compact status/header UI.
- `mediainfo`, `glow`, `starship` — metadata, Markdown preview, contextual status.
- Official `git`, `smart-filter`, `smart-paste`, `toggle-pane`, `zoom` — high-value workflow extensions.

## 20% That Matters (daily usage)
| What | How |
|---|---|
| Open directory/file | `l` / `Enter` |
| Parent | `Backspace` |
| Preview scroll | `Ctrl-e` / `Ctrl-y` |
| Toggle/max preview | `T` |
| Smart filter | `f` |
| Smart paste | `p` |
| Preview zoom | `z` / `Z` |
| Downloads | `g d` |
| Config | `g c` |
| Home | `g h` |

## Known Quirks
- Yazi 26.8.15 deprecates `File:icon()`; local Yatline now uses `Icon:match(file)`.
- `yazi --debug` is deprecated; use `ya env`.
- Media metadata preview rules should not unnecessarily replace native previews.

## Skipped / Rejected Options
Mount/VCS-heavy and niche preview plugins were left out to avoid unnecessary workflow complexity.

## Sources
- https://yazi-rs.github.io/docs/
- https://github.com/yazi-rs/plugins
