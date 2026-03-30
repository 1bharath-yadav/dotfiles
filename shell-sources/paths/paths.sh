#!/usr/bin/env bash

#***************   DEFAULT PATHS   ******************

# Prefer user-managed bins first so Home Manager/Nix apps win over system copies.
# Order: nix-profile → local/bin → cargo → node → system
export PATH="${HOME}/.nix-profile/bin:${HOME}/.local/bin:${HOME}/.cargo/bin:${HOME}/.node_modules/bin:${PATH}:/usr/local/bin:/usr/local/sbin:/usr/bin:/bin:/sbin"

#**************   CUSTOM PATHS   *********************
# NOTE: venv bins are NOT in PATH.
# Services  → systemd user units (start/stop via svc-* aliases)
# Dev tools → uvx / uv run inside project
# Global CLI tools → uv tool install → land in ~/.local/bin (already above)
