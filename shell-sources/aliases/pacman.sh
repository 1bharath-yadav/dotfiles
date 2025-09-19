#!/usr/bin/env bash

alias i='~/bin/pkg-log.sh i'
alias rp='~/bin/pkg-log.sh rp'
alias upd="sudo pacman -Syu"
alias pS='sudo pacman -S'
alias pR='sudo pacman -R'                  # Remove package(s)
alias pRs='sudo pacman -Rs'                # Remove package(s) + unused dependencies
alias pQ='pacman -Q'                       # Query installed packages
alias pQs='pacman -Qs'                     # Search installed & repo packages
alias pQe='pacman -Qe'                     # List explicitly installed packages
alias pQdt='pacman -Qdt'                   # List orphaned packages
alias pU='sudo pacman -U'                  # Install local package file
alias pSc='sudo pacman -Sc'                # Remove old package caches (safe)
alias pScc='sudo pacman -Scc'              # Clear ALL caches (danger: no rollback)
alias pFiles='pacman -Ql'                  # List files owned by a package
# Yay aliases (AUR helper)
alias ySyu='yay -Syu'                      # Sync & upgrade system (repos + AUR)
alias yS='yay -S'                          # Install package(s) from repo or AUR
alias yR='yay -R'                          # Remove package(s)
alias yRs='yay -Rs'                        # Remove + deps
alias ySs='yay -Ss'                        # Search repos + AUR
alias ySi='yay -Si'                        # Show package info (repo or AUR)
alias yQi='yay -Qi'                        # Show installed package info
alias yQe='yay -Qe'                        # List explicitly installed packages
alias yQdt='yay -Qdt'                      # List orphans
alias yG='yay -G'                          # Get PKGBUILD from AUR

alias pc='yay -Sc' # remove all cached packages
alias po='yay -Qtdq | sudo pacman -Rns -' # remove orphaned packages