# Setup Guide

Detailed setup instructions for the current setup:
- Arch and Ubuntu in WSL: system bootstrap with `pacman` or `apt`, userland with Home Manager
- Android: `nix-on-droid`

---

## Prerequisites (all OSes)

```bash
git clone https://github.com/1bharath-yadav/dotfiles ~/.dotfiles
cd ~/.dotfiles
```

### Enable Nix experimental features

Required before running any `nix run` or `nix flake` command:

```bash
echo "experimental-features = nix-command flakes" | sudo tee -a /etc/nix/nix.conf
```

---

## Arch Linux

### 1. Bootstrap system packages + stow + Home Manager

```bash
chmod +x setup/bootstrap.sh
./setup/bootstrap.sh arch
```

**What it does, step by step:**

1. Installs bootstrap packages with `pacman`
2. Stows only Arch GUI overlays still kept outside Home Manager
3. Applies the `archer-arch` Home Manager config if `nix` is installed
4. Leaves Hyprland base updates to `update.sh` and `~/linux/dots-hyprland`

### 2. Manual post-install steps

````bash
# Set up Hyprland (end4dots)
cd ~/linux/dots-hyprland && ./setup install

# Enable services
sudo systemctl enable --now bluetooth
sudo systemctl enable --now tlp

### 3. Re-apply configs after editing

```bash
./setup/main.sh arch
# or full update:
./update.sh
````

---

## Ubuntu In WSL

### 1. Bootstrap system packages + stow + Home Manager

```bash
chmod +x setup/bootstrap.sh
./setup/bootstrap.sh wsl
```

**What it does, step by step:**

1. Installs bootstrap packages with `apt`
2. Applies the `archer-wsl` Home Manager config if `nix` is installed
3. Leaves no common user config under Stow on Ubuntu in WSL

### 2. WSL-specific notes

```bash
# Open Windows files from WSL
explorer.exe .

# WSL utilities (wslu package)
wslview https://example.com    # open in Windows browser
wslpath 'C:\Users\...'         # convert Windows path

# Access Windows PATH (add to .zshrc if needed)
# export PATH="$PATH:/mnt/c/Windows/System32"
```

---

## Android via nix-on-droid

### 1. Install nix-on-droid

- Install the `nix-on-droid` app from the official project
- Clone this repo inside the app environment
- Bootstrap everything:

```bash
chmod +x setup/bootstrap.sh
./setup/bootstrap.sh android
```

### 2. Notes

- This is the only supported mobile path now

---

## Maintaining dotfiles

### Adding a new config package

```
# 1. Create the stow package directory
mkdir -p ~/.dotfiles/myapp/.config/myapp

# 2. Put configs inside
cp ~/.config/myapp/config ~/.dotfiles/myapp/.config/myapp/config

# 3. Add it only if it is an Arch-only overlay
#    edit apply_stow_overlays() in setup/lib.sh

# 4. Stow it
cd ~/.dotfiles && stow --no-folding -t ~ myapp
```

### Adding a user package

- Add it to the relevant Nix module under `nix/modules/`
- Rebuild with `setup/main.sh <arch|wsl>` or `nix-on-droid switch`

### Adding a system package

- Add it to `install_system_pkgs()` in [`setup/lib.sh`](/home/archer/.dotfiles/setup/lib.sh) only if it is bootstrap or system-level

### Invalidating the zsh dotfiles cache

```bash
rm ~/.zsh_dotfiles_cache
# Next shell launch rebuilds it
```

### Updating everything

```bash
~/.dotfiles/update.sh
```
