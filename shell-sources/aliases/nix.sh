#!/usr/bin/env bash
# nix.sh — Nix Home Manager + system Nix aliases
# Strategy:
#   Home Manager (user packages) → hmu / nh home switch
#   Nix system profile (root)    → nsp-* (shared binaries needing no HM)
#   Nix shell / temp tools       → nsh / nrn
#   Nix maintenance              → ngc / ncheck / nwhy

DOTFILES="${DOTFILES:-$HOME/.dotfiles}"
_HM_HOST="${NIX_HOST:-$(hostname)}"

# ── Home Manager user environment ────────────────────────────────────────────
# hmu: rebuild Home Manager (detects host; NIX_FORCE=1 to skip dirty check)
hmu() {
  local host="${1:-}"
  [[ -z "$host" ]] && host="$( \
    grep -oP '(?<=hosts/)[^.]+' "$DOTFILES/nix/hosts/"*.nix 2>/dev/null \
    | head -1 || echo "$_HM_HOST" \
  )"
  NIX_FORCE=1 bash "$DOTFILES/update.sh"
}

alias hmb='nh home build "$DOTFILES"'         # build only, no activate
alias hms='nh home switch "$DOTFILES"'        # switch (current host auto-detected by nh)
alias hmn='nh home news "$DOTFILES"'          # show pending HM changelog
alias hmd='home-manager generations'           # list generations
alias hmr='home-manager rollback'              # roll back one generation
alias hmdr='home-manager expire-generations -30days'  # drop gens older than 30 days
alias hmpath='echo "${HOME}/.nix-profile"'    # where HM links land

# ── Nix package search & info ─────────────────────────────────────────────────
alias nsp='nix search nixpkgs'                 # search: nsp ripgrep
alias nsi='nix-env -qa'                        # query available (legacy)
alias ninfo='nix-env -qa --description'        # show descriptions
alias nwhy='nix why-depends nixpkgs#'          # why is pkg in closure?

# ── Nix system profile (root-level, shared) ───────────────────────────────────
# Use for tools that need GPU/root/system services — btop, ollama, etc.
alias nspi='sudo nix profile install nixpkgs#'  # install to system profile
alias nspl='sudo nix profile list'              # list system-profile pkgs
alias nspu='sudo nix profile upgrade'           # upgrade system profile
alias nspr='sudo nix profile remove'            # remove from system profile

# ── Nix shell / ephemeral ─────────────────────────────────────────────────────
alias nsh='nix-shell -p'                        # temp shell with pkg: nsh ripgrep
alias nrn='nix run nixpkgs#'                    # run without installing: nrn cowsay

# ── Nix maintenance ───────────────────────────────────────────────────────────
alias ngc='nix-collect-garbage -d'             # GC all old generations
alias nsgc='sudo nix-collect-garbage -d'       # GC system store
alias ncheck='nix flake check "$DOTFILES"'     # validate flake
alias nup='nix flake update "$DOTFILES"'       # update all flake inputs
alias nstore='du -sh /nix/store'               # store size
alias ndiag='nix-shell -p nix-info --run "nix-info -m"'  # Nix diagnostics
