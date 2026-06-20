# dotfiles

chezmoi-first personal dotfiles.

## structure
- `dot_config/pacman/Packages` → system/global apps
- `dot_config/mise/config.toml` → runtimes + global dev CLIs
- `dot_local/bin/` → workflows
- `AGENTS.md` → agent rules + current state

## package strategy
- pacman: system packages, desktop apps, native deps, mise itself
- mise: runtimes + reproducible global developer CLIs
- pnpm: project js deps
- uv: project python deps / uvx one-shots
- cargo: project rust deps

## bootstrap
```bash
sudo pacman -S mise git base-devel gcc openssl zlib
pacman-install-list
mise install
```

## sync
```bash
pkg-sync
```

## key commands
- `pki` install packages from manifest
- `pku` pacman update
- `pkua` pacman + mise update
- `tb` bootstrap tooling
- `tu` update tooling
- `mdoc` doctor
- `mug <tool@ver>` set global mise tool
- `pna <pkg>` add js dep
- `uva <pkg>` add python dep
- `rageenc <file>` encrypt secret
- `ragedec <file.age>` decrypt secret


# Arch Linux Post-Install Setup

## 1. Network + Update

```bash
sudo systemctl enable --now NetworkManager
sudo pacman -Syu
```

## 2. Essential Packages

```bash
sudo pacman -S --needed \
git base-devel neovim fastfetch \
zsh starship yazi tmux \
github-cli chezmoi docker
```

## 3. AUR Helper (yay)

```bash
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si
cd ..
rm -rf yay
```

## 4. Install Daily Apps

```bash
yay -S google-chrome visual-studio-code-bin
```

## 5. Zsh + Oh My Zsh

```bash
chsh -s $(which zsh)

sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

## 6. Zsh Plugins

```bash
git clone https://github.com/zsh-users/zsh-autosuggestions \
${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions

git clone https://github.com/zsh-users/zsh-syntax-highlighting \
${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
```

## 7. Login to GitHub

```bash
gh auth login
```

## 8. Restore Dotfiles

```bash
git clone https://github.com/1bharath-yadav/dotfiles.git ~/.dotfiles
```

## 9. Setup Chezmoi

```bash
chezmoi init --source ~/.dotfiles
chezmoi apply
```

## 10. Verify

```bash
chezmoi doctor
chezmoi status
```

## 11. Enable Docker

```bash
sudo systemctl enable --now docker
sudo usermod -aG docker $USER
```

## 12. Reboot

```bash
reboot
```
