#!/usr/bin/env bash
# termux.sh — Termux-specific aliases and helpers
# Loaded only inside Termux (Android) environment
[[ -d /data/data/com.termux ]] || return 0

# ── Package management ────────────────────────────────────────────────────────
alias pkgi='pkg install'
alias pkgu='pkg upgrade'
alias pkgr='pkg uninstall'
alias pkgs='pkg search'
alias pkgl='pkg list-installed'

# ── Storage access ────────────────────────────────────────────────────────────
alias storage='cd /storage/emulated/0'
alias dl='cd /storage/emulated/0/Download'
alias sd='cd /sdcard'

# ── Shortcuts ─────────────────────────────────────────────────────────────────
alias termux-fix-cursor='printf "\e[5 q"'
alias wifi='termux-wifi-connectioninfo'
alias battery='termux-battery-status'
alias clipboard='termux-clipboard-get'
alias notify='termux-notification --title'

# ── dotfiles update (Termux = no nix-on-droid, pure pkg) ─────────────────────
alias dots-sync='cd ~/.dotfiles && git pull'
