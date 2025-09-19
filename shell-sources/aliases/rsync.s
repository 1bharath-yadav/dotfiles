#!/usr/bin/env bash


if command -v 'rsync' >/dev/null; then

  # Rsync with verbose and progress.
  alias rs='rsync -avz'

  # Rsync with verbose and progress.
  alias rsync='rs'
fi
