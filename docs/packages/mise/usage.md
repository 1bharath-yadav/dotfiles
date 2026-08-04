# mise
> A fast tool and environment manager for languages, CLIs, and project-specific version files.

## Last Refreshed
2026-07-31

## Why I Use It
mise keeps my runtime and CLI tool versions in one place. I use it for global installs, project tool pinning, and light automation around node, rust, pnpm, and the other developer CLIs I rely on daily.

## Config Choices
- `node = "latest"` and `rust = "stable"` — keep the main runtimes current without pinning them too hard.
- `pnpm = "latest"` — keep package-manager behavior aligned with the node toolchain.
- `npm:@openai/codex`, `npm:@google/gemini-cli`, `npm:@googleworkspace/cli`, `npm:llm-wiki-compiler` — manage global JS CLIs through mise.
- `github:rtk-ai/rtk`, `copilot-cli`, `github:mudler/LocalAI` — install GitHub-backed binaries directly.
- `experimental = true` — opt into newer mise behavior.
- `jobs = 4` — keep installs parallel but not overly aggressive.
- `legacy_version_file = true` — keep compatibility with existing version files.
- `idiomatic_version_file_enable_tools = ["python", "node", "rust", "uv", "pnpm"]` — read the version files I actually use.
- `[settings.cargo].binstall = true` — prefer cargo-binstall when available.

## Daily Usage
| What | How |
|---|---|
| Install config tools | `mise install` |
| Update config versions | `mise use` |
| Check current tool versions | `mise ls --current` |
| Inspect loaded config | `mise cfg` |
| See health and warnings | `mise doctor` |

## Notes
- mise is already recognizing this config cleanly in the current install.
- The current `latest` and `stable` entries are intentional, not placeholders.
- I keep idiomatic version files enabled only for the tools I actually use.

## Sources
- https://mise.jdx.dev/configuration.html
- https://mise.jdx.dev/configuration/settings.html
- https://mise.jdx.dev/dev-tools/comparison-to-asdf.html
- https://mise.jdx.dev/faq.html