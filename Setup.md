# Setup Guide

Detailed setup instructions for the current setup:
- Arch and Ubuntu in WSL: system bootstrap with `pacman` or `apt`, userland with Home Manager
- Android: `nix-on-droid`
- Host-specific package bundles now live in `nix/modules/packages/`

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

### Enable Sudo access to Nix Profile

Required for `sudo` to find packages installed via Home Manager (like `systemctl-tui` or `nvim`):

```bash
echo 'Defaults secure_path="/home/archer/.nix-profile/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"' | sudo tee /etc/sudoers.d/nix-profile
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
2. Applies the `archer-arch` Home Manager config if `nix` is installed
3. Leaves Hyprland base updates to `update.sh` and `~/.local/share/end4dots`

### 2. Manual post-install steps

````bash
# Set up Hyprland (end4dots)
git clone https://github.com/productive-pro/dots-hyprland.git ~/.local/share/end4dots
cd ~/.local/share/end4dots && ./setup install

# Enable services
sudo systemctl enable --now tlp

### 3. Re-apply configs after editing

```bash
./setup/main.sh arch
# or full update:
./update.sh
````


```bash
npm config set prefix '~/.npm-global'
mkdir -p ~/.npm-global
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

- All user configurations go directly into `nix/modules/programs/`
- Use `xdg.configFile."app".source = ./app;` to link native directories
- Rebuild via `nh home switch` or `./update.sh`

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
