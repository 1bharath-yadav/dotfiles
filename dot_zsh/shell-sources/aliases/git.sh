#!/usr/bin/env bash
# git.sh — shell-level git shortcuts
# NOTE: Core git aliases (lg, st, co, cb, d, etc.) live in nix/modules/programs/git/default.nix
# This file is for shell-function aliases that can't live in gitconfig, and lazygit.

command -v git >/dev/null 2>&1 || return 0

# ── lazygit ───────────────────────────────────────────────────────────────────
alias lg='lazygit'

# ── shell helpers (need subshell expansion or functions) ─────────────────────

# push current branch to origin
alias gitpb='git push --set-upstream origin $(git rev-parse --abbrev-ref HEAD)'

# delete all local branches merged into main/master
alias gitcode='git checkout main && git branch --merged | grep -v "main\|master\|\*" | xargs git branch -d'

# hard sync local main to origin
alias gitcom='git checkout main && git fetch origin --prune && git reset --hard origin/main'

# print remote origin URL as https
alias gitrprint='git remote -v | sed -n "/github.com.*push/{ s/^[^[:space:]]\+[[:space:]]\+//; s|git@github.com:|https://github.com/|; s/\.git.*//; p }"'

# Remove .DS_Store from index
alias gitrmds='find . -name .DS_Store -exec git rm --ignore-unmatch --cached {} +'

export GITHUB_TOKEN=$(gh auth token)

#export OPENAI_API_KEY="$(secret-tool lookup service openai account default)"
#export GEMINI_API_KEY="$(secret-tool lookup service gemini account default)"
