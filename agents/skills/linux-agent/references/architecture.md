# Linux Agent Architecture (M01–M10)

## High-Level Modules

- **M01 Filesystem Governance:** Enforce clean hierarchy (`~/projects`, `~/workspace`, `~/til`, `~/datasets`, `~/documents`, `~/downloads`, `~/archive`). Detect orphaned directories, broken symlinks, and unclassified root files.
- **M02 Configuration Governance:** One clear source of truth. Dual-source chezmoi (`~/.dotfiles` public, `~/.private-dotfiles` private). Detect competing configs and `.pacnew`/`.pacsave` files.
- **M03 Package Governance:** Complete visibility into explicitly installed packages (`pacman -Qqe`), AUR packages (`pacman -Qm`), and orphans (`pacman -Qtdq`). Enforce full upgrades (`pacman -Syu` / `omarchy update`).
- **M04 Storage & Garbage Collection:** Categorized cache lifecycle management. Regenerable build artifacts vs protected application data.
- **M05 Service Governance:** Audit active/failed system and user systemd units (`systemctl --failed`), background timers, and startup resource consumption.
- **M06 Performance & Hardware:** Monitor CPU load, RAM pressure, swap, disk I/O, boot bottlenecks (`systemd-analyze blame`), and NVIDIA RTX 4050 GPU status (`nvidia-smi`).
- **M07 Security Governance:** SUID/SGID audit, file permissions on sensitive files (`.ssh`, `.gnupg`), open listening ports (`ss -tulpn`), and secrets leak prevention.
- **M08 Development Environment Governance:** Track Git repositories, worktrees, language toolchains (`mise`), Python virtualenvs (`uv`), and Node stores (`pnpm`).
- **M09 Reproducibility & Recovery:** Manifests of installed packages, dotfiles commit tracking, and environment recreation instructions.
- **M10 Weekly Maintenance:** Automated read-only weekly audit producing a structured health report without unsolicited mutations.
