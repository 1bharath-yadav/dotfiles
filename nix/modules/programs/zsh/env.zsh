export DOTFILES_DIR="$HOME/.dotfiles"
export EDITOR="$HOME/.nix-profile/bin/nvim"
export SUDO_EDITOR="$HOME/.nix-profile/bin/nvim"
export MANPAGER="$HOME/.nix-profile/bin/nvim +Man!"
export NH_FLAKE="$HOME/.dotfiles"
export NH_HOME_FLAKE="$HOME/.dotfiles"
export NH_NOM=1
export PNPM_HOME="$HOME/.local/share/pnpm"

path=(
  "$HOME/.nix-profile/bin"
  "$HOME/.local/bin"
  "$HOME/.local/share/pnpm"
  "$HOME/.cargo/bin"
  "$HOME/.bun/bin"
  "/nix/var/nix/profiles/system/bin"
  $path
)
