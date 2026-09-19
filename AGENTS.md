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


