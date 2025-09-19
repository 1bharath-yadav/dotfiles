#!/usr/bin/env bash


# 🅵🅸🅽🅳 🅰🅻🅸🅰🆂🅴🆂

if command -v fd &>/dev/null; then
  # fd: a simple, fast and user-friendly alternative to find
  # Always colorize output by default.
  alias fd='fd --color always'

  # List all files with absolute path.
  alias fda='fd --absolute-path'

  # List all files with case-insensitive search.
  alias fdc='fd --ignore-case'

  # List all files with details.
  alias fdd='fd --list-details'

  # List all files with extension.
  alias fde='fd --extension'

  # List all files with follow symlinks.
  alias fdf='fd --follow'

  # List all files with help.
  alias fdh='fd --help'

  # List all files, including hidden files.
  alias fdh='fd --hidden'

  # List all files with glob.
  alias fdn='fd --glob'

  # List all files with owner.
  alias fdo='fd --owner'

  # List all files with size.
  alias fds='fd --size'

  # List all files with exclude.
  alias fdu='fd --exclude'

  # List all files with version.
  alias fdv='fd --version'

  # Execute a command for each search result.
  alias fdx='fd --exec'

  alias duplicate='find -not -empty -type f -printf "%s\n" | sort -rn | uniq -d | xargs -I{} -n1 find -type f -size {}c -print0 | xargs -0 md5sum | sort | uniq -w32 --all-repeated=separate'

fi
