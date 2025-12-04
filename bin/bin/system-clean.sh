#!/usr/bin/env bash
# Arch Linux system cleanup script

ask() { read -p "$1 [y/N] " -n 1 -r; echo; [[ $REPLY =~ ^[Yy]$ ]]; }

echo "=== System Cleanup ==="
df -h / | grep -v tmpfs

# Pacman cache
echo -e "\n[Pacman cache: $(du -sh /var/cache/pacman/pkg 2>/dev/null | awk '{print $1}')]"
ask "Clean pacman cache (keep last 2 versions)?" && paccache -rk2

# Yay cache
[[ -d ~/.cache/yay ]] && echo "[Yay cache: $(du -sh ~/.cache/yay 2>/dev/null | awk '{print $1}')]" && \
ask "Clean yay cache?" && yay -Sc --noconfirm

# Orphaned packages
orphans=$(pacman -Qtdq 2>/dev/null)
[[ -n "$orphans" ]] && echo -e "\n[Orphaned packages: $(echo "$orphans" | wc -l)]\n$orphans" && \
ask "Remove orphaned packages?" && sudo pacman -Rns $orphans --noconfirm

# Docker
command -v docker &>/dev/null && systemctl is-active docker &>/dev/null && \
echo -e "\n$(docker system df 2>/dev/null)" && ask "Clean Docker?" && docker system prune -a --volumes -f

# Podman
command -v podman &>/dev/null && echo -e "\n$(podman system df 2>/dev/null)" && \
ask "Clean Podman?" && podman system prune -a --volumes -f

# User cache
echo -e "\n[Cache: $(du -sh ~/.cache 2>/dev/null | awk '{print $1}')]"
ask "Clean browser caches?" && rm -rf ~/.cache/{zen,google-chrome/Default/Cache}/* 2>/dev/null
ask "Clean thumbnails?" && rm -rf ~/.cache/thumbnails/* 2>/dev/null

# Journals
echo -e "\n$(sudo journalctl --disk-usage 2>/dev/null)"
ask "Clean journals (keep 2 weeks)?" && sudo journalctl --vacuum-time=2weeks

# Trash
[[ -d ~/.local/share/Trash ]] && echo "[Trash: $(du -sh ~/.local/share/Trash 2>/dev/null | awk '{print $1}')]" && \
ask "Empty trash?" && rm -rf ~/.local/share/Trash/*

echo -e "\n=== Done ==="
df -h / | grep -v tmpfs
