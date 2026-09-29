#!/usr/bin/env bash
set -euo pipefail
umask 077
DST='/run/media/archer/Local Disk/Users/byadh/archer-backup'
HOME_DIR="$HOME"
mkdir -p "$DST"/{home,config,system,projects,meta}
printf 'Backup started: %s\n' "$(date -Is)" | tee "$DST/meta/backup.log"
rsync -a --delete "$HOME_DIR/.dotfiles/" "$DST/home/dotfiles/"
rsync -a --exclude='**/Cache/**' --exclude='**/Code Cache/**' --exclude='**/GPUCache/**' --exclude='**/DawnGraphiteCache/**' --exclude='**/DawnWebGPUCache/**' --exclude='**/Crashpad/**' "$HOME_DIR/.config/" "$DST/config/"
for p in .ssh .gnupg .codex .claude .gemini .hermes .mcp-auth .cloudflared .desktop-commander .desktop-commander-device .paperclip .screenpipe; do
  [ -e "$HOME_DIR/$p" ] && rsync -a "$HOME_DIR/$p" "$DST/home/"
done
for f in .bashrc .zshrc .zshenv .gitconfig .env .mcp.json AGENTS.md; do
  [ -e "$HOME_DIR/$f" ] && rsync -a "$HOME_DIR/$f" "$DST/home/"
done
rsync -a "$HOME_DIR/.config/systemd/user/" "$DST/system/user-systemd/"
printf '%s\n' "$(pacman -Qqe)" > "$DST/system/pacman-explicit.txt"
pacman -Qm > "$DST/system/pacman-foreign.txt"
(systemctl --user list-unit-files --type=service --no-legend 2>/dev/null || true) > "$DST/system/user-services.txt"
(systemctl list-unit-files --type=service --state=enabled --no-legend 2>/dev/null || true) > "$DST/system/enabled-system-services.txt"
(cat /etc/fstab 2>/dev/null || true) > "$DST/system/fstab.txt"
(git -C "$HOME_DIR/.dotfiles" status --short; git -C "$HOME_DIR/.dotfiles" log -1 --oneline) > "$DST/meta/dotfiles-git-state.txt"
find "$HOME_DIR/projects" -type d -name .git -prune -print | sed 's#/.git$##' > "$DST/meta/project-repositories.txt"
while IFS= read -r repo; do
  name="${repo#$HOME_DIR/projects/}"; safe="${name//\//__}"
  { printf '### %s\n' "$repo"; git -C "$repo" status --short; git -C "$repo" branch --show-current; git -C "$repo" remote -v; } > "$DST/projects/$safe.git-state.txt"
done < "$DST/meta/project-repositories.txt"
printf 'Backup finished: %s\n' "$(date -Is)" | tee -a "$DST/meta/backup.log"
