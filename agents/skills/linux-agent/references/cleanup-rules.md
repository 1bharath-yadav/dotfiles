# Canonical Cleanup Rules & Cache Classifications

## Cache Classification Matrix

| Tier | Category | Path / Tool | Safe Action | Frequency |
| :--- | :--- | :--- | :--- | :--- |
| **System** | Pacman Cache | `/var/cache/pacman/pkg` | `paccache -rk3` (retains last 3 versions) | Weekly |
| **System** | AUR Cache | `~/.cache/yay`, `~/.cache/paru` | `yay -Sc` / `paru -Sc --noconfirm` | Weekly |
| **System** | Package Orphans | `pacman -Qtdq` | Propose list; remove only on approval | Weekly |
| **System** | Journals | System & User Journal | `journalctl --vacuum-time=7d` | Bi-weekly |
| **Developer** | Mise | `~/.cache/mise` | `mise cache clear && mise prune` | Bi-weekly |
| **Developer** | Python (uv) | `~/.cache/uv` | `uv cache clean` | Monthly |
| **Developer** | Node (pnpm) | `~/.local/share/pnpm/store` | `pnpm store prune` | Monthly |
| **Developer** | Node (npm) | `~/.npm` | `npm cache clean --force` | As needed |
| **Developer** | Rust (cargo) | `~/.cargo/registry`, `~/.cargo/git` | Prune or rm cached git checkouts | Monthly |
| **Developer** | Go | Go build/mod cache | `go clean -cache -modcache -testcache` | As needed |
| **Desktop** | Thumbnails | `~/.cache/thumbnails` | Remove files older than 30 days | Monthly |
| **Desktop** | Browser | `~/.cache/google-chrome`, `zen`, etc. | Prune cache directories | Monthly |
| **Storage** | User Trash | `~/.local/share/Trash` | Empty trash on user confirmation | Weekly |
| **Storage** | `/tmp` | `/tmp` | Clean files owned by user older than 7 days | Weekly |
| **Containers**| Docker/Podman | Docker daemon storage | `docker system prune -f` | On demand |

## Protected & Immutable Paths
- **Never touch without explicit, isolated plan:**
  - `~/.local/share/` (except Trash, pnpm store, and known caches)
  - `~/.config/` (configuration source of truth)
  - `~/.dotfiles` and `~/.private-dotfiles`
  - Active virtual environments (`.venv` in active projects)
  - Git repositories in `~/projects/`
  - Security credentials (`~/.ssh`, `~/.gnupg`)
