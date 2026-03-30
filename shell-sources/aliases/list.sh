#!/usr/bin/env bash
# list.sh — file listing aliases using eza (falls back to ls)

if command -v eza >/dev/null 2>&1; then
  alias ls='eza'
  alias l='eza'
  alias ll='eza --long -a'
  alias la='eza -a --group-directories-first'
  alias lx='eza -a --group-directories-first --extended'
  alias tree='eza --tree'
  alias lS='eza --oneline'
  alias llm='eza --long -a --sort=modified'
else
  alias l='ls'
  alias ll='ls -lA'
  alias llm='ls -ltA'
  alias la='ls -a'
  alias lx='ls -la'
  alias lS='ls -1'
  command -v tree >/dev/null 2>&1 || alias tree='ls -R'
fi
