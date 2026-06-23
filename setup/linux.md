# Arch Linux Setup

## Bootstrap (fresh install)

```bash
# 1. Base deps + AUR helper
sudo pacman -S --needed git base-devel gcc openssl zlib mise
git clone https://aur.archlinux.org/yay.git && cd yay && makepkg -si && cd .. && rm -rf yay

git clone https://github.com/end-4/dots-hyprland ~/.local/share/dots-hyprland

# 2. Restore dotfiles + apply
git clone https://github.com/1bharath-yadav/dotfiles.git ~/.dotfiles
chezmoi init --source ~/.dotfiles
chezmoi apply

ln -s ~/.dotfiles/agents ~/.agents

# 3. Install packages from manifest
pki                  # pacman packages from dot_config/pacman/Packages
mise install         # runtimes + global CLIs from dot_config/mise/config.toml

# 4. AUR packages(illogical-impulse-* are maintained by end-4):

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

sudoedit /etc/systemd/logind.conf
HandlePowerKey=ignore
HandlePowerKeyLongPress=ignore
sudo systemctl restart systemd-logind # it will switch of the system

## Key Commands

| Command              | Action                                |
| -------------------- | ------------------------------------- |
| `pki`                | install pacman packages from manifest |
| `pku`                | pacman update                         |
| `pkua`               | pacman + mise update                  |
| `dots-update`        | pull + reapply dotfiles               |
| `rageenc <file>`     | encrypt secret with rage              |
| `ragedec <file.age>` | decrypt secret                        |
| `chezmoi apply`      | apply dotfile changes                 |
| `chezmoi diff`       | preview pending changes               |

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
