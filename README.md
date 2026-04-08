# dotfiles

simple chezmoi-first personal dotfiles.

## package strategy

- pacman: system packages, base build deps, mise itself
- mise: node/python/rust runtimes and tool versions
- pnpm: js/ts packages
- uv: python deps, venvs, tools
- cargo: rust crates and project deps

## install base

```bash
sudo pacman -S mise git base-devel gcc openssl zlib
```

then activate mise in shell and run:

```bash
tool-bootstrap
```

## chezmoi

```bash
chezmoi init /home/archer/dotfiles
chezmoi diff
chezmoi apply
```

## useful commands

- `pku` → system update
- `pkua` → pacman + mise update
- `tb` → install runtime tools from mise
- `tu` → upgrade runtime/tooling layer
- `mdoc` → inspect toolchain health
- `mug node@22` → set global node
- `mug python@3.12` → set global python
- `pna <pkg>` → add js dependency
- `uva <pkg>` → add python dependency
- `ciu <crate>` / `cib <crate>` → install rust cli
