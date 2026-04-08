# package ownership

## pacman
Owns system packages, desktop apps, native dependencies, terminal/editor binaries, and mise itself.
Source of truth: `dot_config/pacman/Packages`.

## mise
Owns language runtimes and reproducible global developer CLIs.
Source of truth: `dot_config/mise/config.toml`.

## pnpm
Owns project-local JS dependencies.
Use for repo work, not global runtime/version management.

## uv
Owns project-local Python deps/venvs.
Use `uvx` for one-shot tools.

## cargo
Owns Rust project deps.
Use cargo/binstall for exceptional standalone Rust CLIs if not declared through mise.
