if [[ $- == *i* ]] \
  && [[ -z "$TMUX" ]] \
  && [[ -z "$DOTFILES_DISABLE_AUTO_TMUX" ]] \
  && [[ -z "$SSH_CONNECTION$SSH_CLIENT$SSH_TTY" ]] \
  && [[ -t 0 && -t 1 ]] \
  && [[ "$TERM" != "dumb" ]] \
  && [[ "${TERM_PROGRAM:-}" != "vscode" ]] \
  && [[ -z "$INSIDE_EMACS" ]] \
  && has tmux \
  && ! tmux list-clients -F '#{client_pid}' 2>/dev/null | grep -q .; then
  exec tmux new-session -A -s "${TMUX_AUTO_SESSION:-main}"
fi
