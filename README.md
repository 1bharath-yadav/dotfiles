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
