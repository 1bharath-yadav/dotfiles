#!/usr/bin/env bash
set -euo pipefail
COLORS="$HOME/.local/state/omarchy/current/theme/colors.toml"
[[ -f "$COLORS" ]] || exit 0
command -v tmux >/dev/null && tmux list-sessions >/dev/null 2>&1 || exit 0
color() { omarchy-theme-color --file "$COLORS" "$1"; }
bg=$(color background)
fg=$(color foreground)
accent=$(color accent)
muted=$(color muted)
selection=$(color selection)
[[ -n "$bg" && -n "$fg" && -n "$accent" && -n "$muted" && -n "$selection" ]] || exit 1

tmux set-option -g status-style "bg=$bg,fg=$fg"
tmux set-option -g status-left-length 30
tmux set-option -g status-right-length 50
tmux set-option -g window-status-separator ""
tmux set-option -g status-left "#[fg=$bg,bg=$accent,bold] #S #[fg=$fg,bg=$bg] "
tmux set-option -g status-right "#[fg=$accent]#{?pane_in_mode,COPY ,}#{?client_prefix,PREFIX ,}#{?window_zoomed_flag,ZOOM ,}#[fg=$muted]#h "
tmux set-option -g window-status-format "#[fg=$muted] #I:#W "
tmux set-option -g window-status-current-format "#[fg=$accent,bold] #I:#W "
tmux set-option -g pane-border-style "fg=$muted"
tmux set-option -g pane-active-border-style "fg=$accent"
tmux set-option -g message-style "bg=$selection,fg=$fg"
tmux set-option -g message-command-style "bg=$selection,fg=$fg"
tmux set-option -g mode-style "bg=$accent,fg=$bg"
tmux set-window-option -g clock-mode-colour "$accent"
tmux refresh-client -S 2>/dev/null || true
