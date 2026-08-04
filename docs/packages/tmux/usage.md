# tmux
> A terminal multiplexer for organizing persistent sessions, panes, and workflows across long-running tasks.

## Last Refreshed
2026-07-31

## Why I Use It
Tmux keeps my terminal work persistent across disconnects and lets me organize projects into named sessions with split panes and fast navigation.

## Config Choices
- `set -g prefix C-a` — uses a more comfortable leader key than the default Ctrl-b.
- `set -g mouse on` — makes pane and window selection easier in local terminal sessions.
- `set -g history-limit 20000` — preserves more scrollback for debugging and long logs.
- `set -g renumber-windows on` — keeps window numbering tidy after closing windows.
- `set -g set-clipboard on` — makes copy-mode work naturally with the system clipboard.
- `set -g @sessionx-*` — enables quick session switching and project discovery with sessionx.

## 20% That Matters (daily usage)
| What | How |
|---|---|
| Reload config | `prefix + r` |
| Split vertically | `prefix + -` |
| Split horizontally | `prefix + \` |
| Resize panes | `prefix + h/j/k/l` |
| Open session picker | `prefix + o` |

## Known Quirks
- TPM plugins need an initial `prefix + I` install after a new machine setup.
- Some plugin options are intentionally conservative until the plugin set is updated.

## Skipped / Rejected Options
- Full-screen session restore plugins were left disabled because they add more moving parts than I need daily.

## Sources
- tmux upstream docs
- tmux plugin documentation
