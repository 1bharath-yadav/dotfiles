#!/usr/bin/env bash

# Dotfiles 
cd ~/.dotfiles || exit 1

git add .

DIFF="$(git diff --cached)"
[ -z "$DIFF" ] && exit 0

MSG="$(echo "$DIFF" | gemini --prompt 'Generate a concise commit message:')"

# If gemini fails or returns empty, notify the user and exit
if [ -z "$MSG" ]; then
  echo "Failed to generate commit message."
  exit 1
fi

git commit -m "$MSG"
git push origin master



