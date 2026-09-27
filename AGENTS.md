# AGENTS.md

- branch: chizmoi
- mode: chezmoi-first
- roots: dot*\*, private*\*
- package-manifests: dot_config/pacman/Packages, dot_config/mise/config.toml
- agent-workspace: dot_agen/
- workflows: dot_local/bin
- exclude: end4dots, quickshell, hyprland-base
- exclude: flake, nix, setup, libs
- package-owners: pacman system, mise runtimes+global-clis, pnpm js-projects, uv python-projects, cargo rust-projects
- prefer pnpm over npm
- secrets: rage/age, sops+age for structured files
- rage-key: ~/.config/rage/key.txt
- ssh-private: ~/.ssh/\* 600
- ssh-public: ~/.ssh/\*.pub 644
- never commit plaintext secrets
- never commit private keys
- encrypt repo secrets as \*.age
- native age first, ssh fallback only
- never encrypt in place
- scripts must stay small and composable
- remote: https://github.com/1bharath-yadav/dotfiles.git
- commit:
- git status --short
- git add <specific-files>
- git commit -m "<type>: <why>"
- git push origin chizmoi
- agents-dir: ~/.dotfiles/agents/ (symlinked ~/.agents/) — .skill.md files only
- chezmoiignore: any new root file/folder not prefixed dot*/private* must be added to .chezmoiignore
- current-state:
- cdp-engine: direct page-socket CDP for 12 frontier AI web platforms.
- speech: Super+H live voice, Super+Alt+H stt (wtype+Quickshell HUD), and --tts narration.
- providers: 12 web AI platforms (ChatGPT, Claude, Gemini, DeepSeek, Z.ai, MiniMax, Kimi, Grok, Qwen, Mistral, Meta, Copilot).
- cli: ~/.local/bin/ai multi-provider router with dedicated shims.
- imgen: --imgen with auto-download (-o) for ChatGPT, Gemini, Mistral, Meta, Copilot.



## Mitham boot execution

`~/.dotfiles/dot_config/systemd/user/mitham/mitham.target` is the canonical user-systemd source for Mitham services. Keep Mitham service units under `dot_config/systemd/user/mitham/`; do not add a repository-local `systemd-local/` service tree.

`mitham-agy-worker.service` is an executor only. `Mitham Daily Agy` in ChatGPT remains the sole scheduler and prioritization authority. The boot worker may execute only durable lanes explicitly authorized by the control plane; it must not create queues, refill work, reprioritize tasks, or use Agy `/schedule`.

Mitham production is phase-gated: continuously advance the canonical content pipeline across all configured subjects first (planning → teaching brief → concept/visualization → assessment → validation/publication). Do not begin the general video factory until the content completion gate is satisfied across the configured curriculum. After that gate, advance video work through script/narration → measured audio → director/scene/asset work → render/assembly → QA → publication. Both phases use the existing specialist roles and repository contracts; never invent duplicate workers or schedulers.

For systemd changes, edit the chezmoi source under `dot_config/systemd/user/mitham/`, reload the user manager, and verify enablement/activation. Preserve unrelated dotfiles changes and never commit plaintext secrets.
