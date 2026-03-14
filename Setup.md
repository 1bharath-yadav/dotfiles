# Setup Guide

Detailed setup instructions for all three supported environments.

---

## Prerequisites (all OSes)

```bash
git clone https://github.com/1bharath-yadav/dotfiles ~/.dotfiles
cd ~/.dotfiles
```

---

## Arch Linux

### 1. Bootstrap & install everything

```bash
chmod +x setup/auto.sh
./setup/auto.sh
# or directly:
./setup/arch.sh
```

**What it does, step by step:**

1. `pacman -Syu` + installs `base-devel curl git jq stow zsh`
2. Installs **Oh My Zsh** + `zsh-autosuggestions` + `zsh-syntax-highlighting`
3. Installs all **official pacman** packages from `pkgs.json` (`.common[]` + `.arch.official[]`), skipping any that are AUR-only
4. Installs **yay** (AUR helper) if not present
5. Installs all **AUR** packages from `pkgs.json` (`.arch.aur[]`)
6. Installs **fnm** (fast Node.js version manager)
7. Installs **npm global** packages from `pkgs.json` (`.npm[]`)
8. Sets **zsh as default shell**
9. **Stows** all packages: `bin hypr kitty nvim starship tmux yazi zsh`

### 2. Manual post-install steps

````bash
# Set up Hyprland (end4dots)
cd ~/linux/dots-hyprland && ./setup install

# Enable services
sudo systemctl enable --now bluetooth
sudo systemctl enable --now tlp

### 3. Stow only (re-link configs after editing)

```bash
./stow/arch.sh
# or full update:
./update.sh
````

---

## Ubuntu / WSL

### 1. Bootstrap & install everything

```bash
chmod +x setup/auto.sh
./setup/auto.sh
# or directly:
./setup/ubuntu.sh
```

**What it does, step by step:**

1. `apt-get update` + installs `jq` for JSON parsing
2. Installs all **apt** packages from `pkgs.json` (`.common[]` + `.ubuntu.apt[]`)
   - Arch→Ubuntu name mappings handled automatically (`fd→fd-find`, `python-pip→python3-pip`)
   - Packages unavailable in apt are skipped with a warning
3. Installs **fnm** via curl (not in apt)
4. Installs **Oh My Zsh** + plugins
5. Installs extras via curl (not in apt):
   - **starship** — cross-shell prompt
   - **zoxide** — smarter cd
   - **yazi** — prebuilt musl binary → `~/.local/bin/`
6. Installs **npm global** packages
7. Sets **zsh as default shell**
8. **Stows** CLI-only packages: `bin nvim starship tmux yazi zsh`

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

### 3. Adding packages not in apt

Edit `pkgs.json` → `.ubuntu.apt[]` for apt packages.
For binary installs (like yazi), add a block to `install_extras()` in `setup/ubuntu.sh`.

---

## Termux (Android)

### 1. Bootstrap & install everything

```bash
# In Termux:
pkg install git
git clone https://github.com/1bharath-yadav/dotfiles ~/.dotfiles
cd ~/.dotfiles
chmod +x setup/termux.sh
./setup/termux.sh
```

**What it does, step by step:**

1. `pkg update && pkg upgrade`
2. Installs all packages from `pkgs.json` (`.termux[]`)
3. `pip install trash-cli`
4. Installs **Oh My Zsh** + plugins
5. Installs **npm globals** from `pkgs.json` (`.npm[]`)
6. Sets **zsh as default shell** via `chsh -s zsh`
7. Reloads Termux style (colors, font)
8. **Stows**: `bin nvim starship tmux zsh-termux termux`
   - `zsh-termux` → `~/.zshrc` (Termux-specific, sources dotfiles cache)
   - `termux` → `~/.termux/` (colors, font, properties, widgets)

### 2. Termux-specific extras

```bash
# Storage access
termux-setup-storage

# SSH server
pkg install openssh
sshd
# Connect from PC: ssh -p 8022 <phone-ip>

# Widget shortcut for SSH IP
# Already included in termux/.termux/widget/dynamic_shortcuts/ssh_command
```

### 3. Termux package management aliases (set in zsh-termux)

| Alias     | Command                     |
| --------- | --------------------------- |
| `i`       | `pkg install`               |
| `rp`      | `pkg uninstall`             |
| `upd`     | `pkg update && pkg upgrade` |
| `rsearch` | `pkg search`                |
| `lsearch` | `pkg list-installed`        |

---

## Maintaining dotfiles

### Adding a new config package

```
# 1. Create the stow package directory
mkdir -p ~/.dotfiles/myapp/.config/myapp

# 2. Put configs inside
cp ~/.config/myapp/config ~/.dotfiles/myapp/.config/myapp/config

# 3. Add to the relevant stow script
#    e.g. stow/arch.sh → PACKAGES=(... myapp)

# 4. Stow it
cd ~/.dotfiles && stow --no-folding -t ~ myapp
```

### Adding a package to pkgs.json

```json
// common (all OSes):
{ "name": "ripgrep", "description": "Fast grep" }

// Arch official:
// .arch.official[]

// Arch AUR:
// .arch.aur[]

// Ubuntu apt:
// .ubuntu.apt[]

// Termux pkg:
// .termux[]

// npm global:
// .npm[]
```

### Invalidating the zsh dotfiles cache

```bash
rm ~/.zsh_dotfiles_cache
# Next shell launch rebuilds it
```

### Updating everything

```bash
~/.dotfiles/update.sh
```
