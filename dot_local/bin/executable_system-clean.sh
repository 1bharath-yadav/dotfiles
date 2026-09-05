#!/usr/bin/env bash
set -uo pipefail
IFS=$'\n\t'

readonly HR='────────────────────────────────────────────────────────'
FAILED=0

hr() { printf '%s\n' "$HR"; }
ask() {
  local answer=''
  while true; do
    read -r -p "$1 [y/N] " answer || return 1
    case "$answer" in
      y|Y|yes|YES|Yes) return 0 ;;
      n|N|no|NO|No|'') return 1 ;;
      *) printf 'Please answer y or n.\n' ;;
    esac
  done
}
size() { du -sh -- "$1" 2>/dev/null | awk '{print $1}' || printf '0B'; }
exists() { [[ -e "$1" ]]; }
show_path() { exists "$1" && printf '  %-34s %8s  %s\n' "$2" "$(size "$1")" "$1"; }
run_user() { "$@"; local rc=$?; ((rc)) && { FAILED=$((FAILED+1)); printf '  [!] failed: %s (exit %d)\n' "$1" "$rc" >&2; }; return 0; }
run_root() { sudo "$@"; local rc=$?; ((rc)) && { FAILED=$((FAILED+1)); printf '  [!] privileged failed: %s (exit %d)\n' "$1" "$rc" >&2; }; return 0; }
clean_dir() { [[ -d "$1" ]] && find "$1" -mindepth 1 -maxdepth 1 -exec rm -rf -- {} + 2>/dev/null || true; }

if sudo -v; then SUDO_OK=1; else SUDO_OK=0; printf '[!] sudo unavailable; privileged actions will be skipped.\n' >&2; fi

hr
printf 'SYSTEM CLEAN — interactive, safe-by-default\n'
printf 'Every detected cleanup target is offered separately.\n'
df -h / | awk 'NR==1 || $NF=="/"'

hr
printf '[Pacman package cache]\n'
if [[ -d /var/cache/pacman/pkg ]]; then
  show_path /var/cache/pacman/pkg 'package cache'
  if command -v paccache >/dev/null && ask 'Prune old cached package versions?'; then
    if ((SUDO_OK)); then
      run_root paccache -rk3
    else
      printf '  [!] skipped: sudo unavailable\n'
    fi
  fi
fi

hr
printf '[AUR build caches]\n'
for aur in yay paru; do
  case "$aur" in yay) path="$HOME/.cache/yay";; paru) path="$HOME/.cache/paru";; esac
  if command -v "$aur" >/dev/null && [[ -d "$path" ]]; then
    show_path "$path" "$aur cache"
    ask "Clean $aur build cache?" && run_user "$aur" -Sc --noconfirm
  fi
done

hr
printf '[Orphaned packages]\n'
if command -v pacman >/dev/null; then
  orphans=$(pacman -Qtdq 2>/dev/null || true)
  if [[ -n "$orphans" ]]; then
    printf '%s\n' "$orphans" | sed 's/^/  /'
    if ask 'Remove orphaned packages?'; then
      ((SUDO_OK)) && run_root pacman -Rns --noconfirm $orphans || printf '  [!] skipped: sudo unavailable\n'
    fi
  else printf '  none\n'; fi
fi

hr
printf '[Developer/tool caches]\n'
show_path "$HOME/.cache/pnpm" 'pnpm cache/store'
show_path "$HOME/.local/share/pnpm/store" 'pnpm store'
show_path "$HOME/.npm" 'npm cache'
show_path "$HOME/.cache/mise" 'Mise cache'
show_path "$HOME/.cache/uv" 'uv cache'
show_path "$HOME/.cache/pip" 'pip cache'
show_path "$HOME/.cargo/registry" 'Cargo registry'
show_path "$HOME/.cargo/git" 'Cargo git'
show_path "$HOME/.cache/go-build" 'Go build cache'
show_path "$HOME/go/pkg/mod" 'Go module cache'
show_path "$HOME/.gradle/caches" 'Gradle cache'
show_path "$HOME/.cache/JetBrains" 'JetBrains cache'

if command -v pnpm >/dev/null && { [[ -d "$HOME/.cache/pnpm" ]] || [[ -d "$HOME/.local/share/pnpm/store" ]]; } && ask 'Prune pnpm store/cache?'; then run_user pnpm store prune; fi
if command -v npm >/dev/null && [[ -d "$HOME/.npm" ]] && ask 'Clean npm cache?'; then run_user npm cache clean --force; fi
if command -v mise >/dev/null && [[ -d "$HOME/.cache/mise" ]] && ask 'Clear Mise cache?'; then run_user mise cache clear; fi
if command -v uv >/dev/null && [[ -d "$HOME/.cache/uv" ]] && ask 'Clean uv cache?'; then run_user uv cache clean; fi
if command -v pip >/dev/null && [[ -d "$HOME/.cache/pip" ]] && ask 'Purge pip cache?'; then run_user pip cache purge; fi
if command -v cargo >/dev/null && { [[ -d "$HOME/.cargo/registry" ]] || [[ -d "$HOME/.cargo/git" ]]; } && ask 'Remove Cargo registry/git caches?'; then run_user rm -rf -- "$HOME/.cargo/registry" "$HOME/.cargo/git"; fi
if command -v go >/dev/null && ask 'Clean Go build/module/test caches?'; then run_user go clean -cache -modcache -testcache; fi
if [[ -d "$HOME/.gradle/caches" ]] && ask 'Clean Gradle caches?'; then clean_dir "$HOME/.gradle/caches"; fi
if [[ -d "$HOME/.cache/JetBrains" ]] && ask 'Clean JetBrains caches?'; then clean_dir "$HOME/.cache/JetBrains"; fi

hr
printf '[Runtime/toolchain cleanup]\n'
if command -v rustup >/dev/null && [[ -d "$HOME/.rustup/toolchains" ]]; then
  rustup toolchain list 2>/dev/null | sed 's/^/  /'
  if ask 'Remove non-default Rust toolchains?'; then
    while read -r toolchain; do
      [[ -z "$toolchain" ]] && continue
      run_user rustup toolchain uninstall "$toolchain"
    done < <(rustup toolchain list 2>/dev/null | awk '$0 !~ /\(default\)/ && NF {print $1}')
  fi
fi
if command -v mise >/dev/null && ask 'Run Mise prune for unused installed runtimes?'; then run_user mise prune; fi

hr
printf '[Desktop/browser caches]\n'
for d in "$HOME/.cache/thumbnails" "$HOME/.cache/fontconfig" "$HOME/.cache/mesa_shader_cache" "$HOME/.cache/mesa_shader_cache_db" "$HOME/.cache/google-chrome" "$HOME/.cache/chromium" "$HOME/.cache/zen" "$HOME/.cache/mozilla"; do
  if [[ -e "$d" ]]; then show_path "$d" 'cache'; ask "Clean cache: $d?" && clean_dir "$d"; fi
done

hr
printf '[Container storage]\n'
if command -v docker >/dev/null && docker info >/dev/null 2>&1; then docker system df 2>/dev/null || true; ask 'Prune unused Docker data and build cache?' && run_user docker system prune -af; fi
if command -v podman >/dev/null && podman info >/dev/null 2>&1; then podman system df 2>/dev/null || true; ask 'Prune unused Podman data?' && run_user podman system prune -af; fi

hr
printf '[Journals — root/system + user]\n'
if command -v journalctl >/dev/null; then
  printf '  system: '; journalctl --disk-usage 2>/dev/null || printf 'unavailable\n'
  printf '  user:   '; journalctl --user --disk-usage 2>/dev/null || printf 'unavailable\n'
  if ((SUDO_OK)) && ask 'Delete ALL root/system journal entries?'; then
    run_root journalctl --rotate
    run_root journalctl --vacuum-time=1s
    run_root journalctl --vacuum-size=1K
  fi
  if journalctl --user --disk-usage >/dev/null 2>&1 && ask 'Delete ALL your user journal entries?'; then
    run_user journalctl --user --rotate
    run_user journalctl --user --vacuum-time=1s
    run_user journalctl --user --vacuum-size=1K
  fi
fi

hr
printf '[Trash and temporary files]\n'
if [[ -e "$HOME/.local/share/Trash" ]]; then show_path "$HOME/.local/share/Trash" 'user trash'; ask 'Empty user trash?' && clean_dir "$HOME/.local/share/Trash"; fi
if [[ -d /tmp ]]; then printf '  %-34s %8s  /tmp\n' 'your old /tmp files' "$(size /tmp)"; ask 'Delete your /tmp files older than 7 days?' && find /tmp -xdev -user "$(id -u)" -mindepth 1 -mtime +7 -delete 2>/dev/null || true; fi

hr
printf '[Other detected ~/.cache directories]\n'
while IFS= read -r -d '' d; do
  case "$d" in
    "$HOME/.cache/pnpm"|"$HOME/.cache/yay"|"$HOME/.cache/paru"|"$HOME/.cache/mise"|"$HOME/.cache/uv"|"$HOME/.cache/pip"|"$HOME/.cache/thumbnails"|"$HOME/.cache/fontconfig"|"$HOME/.cache/mesa_shader_cache"|"$HOME/.cache/mesa_shader_cache_db"|"$HOME/.cache/google-chrome"|"$HOME/.cache/chromium"|"$HOME/.cache/zen"|"$HOME/.cache/mozilla"|"$HOME/.cache/JetBrains") continue;;
  esac
  printf '  %-34s %8s  %s\n' 'cache candidate' "$(size "$d")" "$d"
  ask 'Delete this cache directory completely?' && run_user rm -rf -- "$d"
done < <(find "$HOME/.cache" -mindepth 1 -maxdepth 1 -type d -print0 2>/dev/null | sort -z)

hr
printf 'FINAL STATUS\n'
df -h / | awk 'NR==1 || $NF=="/"'
show_path "$HOME/.cache" '~/.cache'
show_path "$HOME/.npm" '~/.npm'
show_path "$HOME/.rustup" '~/.rustup'
((SUDO_OK)) && journalctl --disk-usage 2>/dev/null || true
hr
if ((FAILED == 0)); then printf '[✓] Cleanup finished.\n'; else printf '[!] Cleanup finished with %d non-fatal failure(s).\n' "$FAILED"; fi
