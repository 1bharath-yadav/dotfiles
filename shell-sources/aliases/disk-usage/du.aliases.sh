#!/usr/bin/env bash

# Author: Sebastien Rousseau
# Copyright (c) 2015-2025. All rights reserved
# Description: Sets Disk Usage Aliases
# License: MIT
# Script: du.aliases.sh
# Version: 0.2.470
# Website: https://dotfiles.io

# 🅳🅸🆂🅺 🆄🆂🅰🅶🅴 🅰🅻🅸🅰🆂🅴🆂

if command -v 'du' >/dev/null; then

  # Display the disk usage of the current directory.
  alias du="du -h"

  # File size of files and directories in current directory.
  alias du1='du -hxd 1 | sort -h'

  # Top 10 largest files and directories in current directory.
  alias ducks="du -cks * .* | sort -rn | head -n 10"

  # File size of files and directories.
  alias duh='du'

  # File size human readable output sorted by size.
  alias dus='du -hs *'

  # File size of files and directories in current directory including
  # symlinks.
  alias dusym="du * -hsLc"

  # Total file size of current directory.
  alias dut='dus'
