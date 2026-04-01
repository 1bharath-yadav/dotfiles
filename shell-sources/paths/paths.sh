#!/usr/bin/env bash

#***************   DEFAULT PATHS   ******************

# Prefer user-managed bins first so Home Manager/Nix apps win over system copies.
# Order: nix-profile → local/bin → cargo → system
export PATH="${HOME}/.nix-profile/bin:${HOME}/.local/bin:${HOME}/.cargo/bin:${PATH}:/usr/local/bin:/usr/local/sbin:/usr/bin:/bin:/sbin"

#**************   CUSTOM PATHS   *********************

export PATH="${HOME}/.npm/bin:${PATH}"                             


