# cdp-agents.skill.md
# Direct Chrome DevTools Protocol (CDP) Multi-Provider AI Agent Router
# Project location: ~/projects/cdp-agents
# Stored at: ~/.dotfiles/agents/ (symlinked from ~/.agents/)

## Purpose
Enables deterministic, zero-focus-stealing automation of web AI frontier models (ChatGPT, Claude, Gemini, DeepSeek, Z.ai, MiniMax, Kimi, Grok, Qwen, Mistral, Meta AI, Microsoft Copilot) via RFC 6455 WebSockets over Chrome CDP (headless or headed).

## Project Source & CLI
- **Source Repository**: `~/projects/cdp-agents` (GitHub: `1bharath-yadav/cdp-agents`)
- **CLI Router**: `~/.local/bin/ai` (or `cdp-agents`)
- **Dedicated Shims**: `claude-ai`, `gemini-ai`, `deepseek-ai`, `zai-ai`, `minimax-ai`, `kimi-ai`, `grok-ai`, `qwen-ai`, `mistral-ai`, `meta-ai`, `copilot-ai`

## Capabilities Matrix
- **ChatGPT**: Live voice mode (`--livemode`), STT (`--stt`), TTS narration (`--tts`), DALL-E 3 image generation (`--imgen ... -o <path>`), project container routing (`--project`).
- **Claude**: Projects (`--project`), code artifacts extraction (`--artifacts`), attachments (`--attach`).
- **Gemini**: Native Imagen 3 image generation (`--imgen ... -o <path>`), Listen TTS (`--tts`), Gems/Notebooks (`--gem`).
- **DeepSeek**: DeepThink R1 reasoner toggle (`--think`), web search toggle (`--search`), thinking chain output (`--show-thinking`).
- **Z.ai**: Deep Think mode (`--think`), search toggle (`--search`), GLM model outputs.
- **MiniMax**: Hailuo Video & Image scenes (`--scene video|image`), workspace tasks.
- **Kimi**: Kimi K3 Agent Swarm, search toggle (`--search`).
- **Grok**: Grok 4.6, attachments (`--attach`).
- **Qwen**: Qwen3.8-Max, thinking toggle (`--think`).
- **Mistral**: Fast/Think/Research modes (`-m`), native Voice Mode (`--voice`), Read aloud TTS (`--tts`), Flux Imagegen (`--imgen ... -o`).
- **Meta AI**: Thinking vs Instant mode (`--think`), Meta Imagine image generation (`--imgen ... -o`), Dictation STT (`--dictate`).
- **Microsoft Copilot**: Smart/Think deeper/Study/Search modes (`-m`), Voice Mode audio call (`--voice`), Designer DALL-E 3 (`--imgen ... -o`).

## Quick CLI Reference
```bash
# Multi-Provider Routing
ai "Prompt"                                    # ChatGPT (default)
ai --claude "Analyze codebase"                 # Claude
ai --gemini --tts "Listen to summary"          # Gemini
ai --deepseek --think "Math proof"             # DeepSeek
ai --zai --search "AI news"                    # Z.ai
ai --minimax --scene video "Drone shot"        # MiniMax
ai --kimi --search "Agent swarm"               # Kimi
ai --grok "Physics derivation"                 # Grok
ai --qwen --think "Algorithm design"           # Qwen
ai --mistral -m think "Complex logic"          # Mistral
ai --meta --imgen "Synthwave car" -o car.png   # Meta AI
ai --copilot -m think "Quadratic formula"      # Copilot
```
