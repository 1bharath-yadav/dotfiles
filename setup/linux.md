# Arch Linux Setup

## Bootstrap (fresh install)

```bash
# 1. Base deps + AUR helper
sudo pacman -S --needed git base-devel gcc openssl zlib mise
git clone https://aur.archlinux.org/yay.git && cd yay && makepkg -si && cd .. && rm -rf yay

# 2. Restore dotfiles + apply
git clone https://github.com/1bharath-yadav/dotfiles.git ~/.dotfiles
chezmoi init --source ~/.dotfiles
chezmoi apply

# 3. Install packages from manifest
pki                  # pacman packages from dot_config/pacman/Packages
mise install         # runtimes + global CLIs from dot_config/mise/config.toml

# 4. AUR packages
yay -S google-chrome visual-studio-code-bin claude-desktop-bin \
       pacseek-bin wlogout ngrok koodo-reader-bin appflowy-bin \
       adw-gtk-theme-git darkly-bin breeze-plus \
       otf-space-grotesk ttf-readex-pro ttf-rubik-vf ttf-twemoji \
       ttf-material-symbols-variable-git qt6-avif-image-plugin \
       illogical-impulse-audio illogical-impulse-backlight \
       illogical-impulse-basic illogical-impulse-bibata-modern-classic-bin \
       illogical-impulse-fonts-themes illogical-impulse-hyprland \
       illogical-impulse-kde illogical-impulse-portal illogical-impulse-python \
       illogical-impulse-quickshell-git illogical-impulse-screencapture \
       illogical-impulse-toolkit illogical-impulse-widgets \
       illogical-impulse-microtex-git antigravity-ide antigravity-tools-bin

# 5. Shell
chsh -s $(which zsh)
```

## Post-Bootstrap

```bash
gh auth login                        # GitHub auth
gh auth refresh --scopes copilot     # enable copilot scope
tmux                                 # start tmux; prefix+I to install tpm plugins
chezmoi doctor && chezmoi status     # verify
```

## Zsh Plugins (if not via pacman)

```bash
# pacman preferred:
sudo pacman -S zsh-autosuggestions zsh-syntax-highlighting

# fallback (oh-my-zsh custom):
git clone https://github.com/zsh-users/zsh-autosuggestions \
  ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting \
  ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
```

## Key Commands

| Command | Action |
|---|---|
| `pki` | install pacman packages from manifest |
| `pku` | pacman update |
| `pkua` | pacman + mise update |
| `dots-update` | pull + reapply dotfiles |
| `rageenc <file>` | encrypt secret with rage |
| `ragedec <file.age>` | decrypt secret |
| `chezmoi apply` | apply dotfile changes |
| `chezmoi diff` | preview pending changes |

## System Services

```bash
sudo systemctl enable --now NetworkManager docker reflector.timer
sudo usermod -aG docker $USER
sudo systemctl enable --now hyprpolkitagent   # if not autostarted by Hyprland
sudo timedatectl set-timezone Asia/Kolkata
```

## AUR Backup

Snapshot installed AUR packages (run periodically and commit):

```bash
pacman -Qm | grep -v '\-debug$' | awk '{print $1}' \
  > ~/.dotfiles/setup/aur-packages.txt
```
