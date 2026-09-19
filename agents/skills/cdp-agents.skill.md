# cdp-agents.skill.md
# Direct Chrome DevTools Protocol (CDP) Multi-Provider AI Agent Router
# Project location: ~/projects/cdp-agents
# Stored at: ~/.dotfiles/agents/ (symlinked from ~/.agents/)

## Purpose
Enables deterministic, zero-focus-stealing automation of web AI frontier models (ChatGPT, Claude, Gemini, DeepSeek, Z.ai, MiniMax, Kimi, Grok, Qwen) via RFC 6455 WebSockets over Chrome CDP (headless or headed).

## Project Source & CLI
- **Source Repository**: `~/projects/cdp-agents` (GitHub: `1bharath-yadav/cdp-agents`)
- **CLI Router**: `~/.local/bin/ai` (or `cdp-agents`)
- **Dedicated Shims**: `claude-ai`, `gemini-ai`, `deepseek-ai`, `zai-ai`

## Capabilities Matrix
- **ChatGPT**: Live voice mode (`--livemode`), STT (`--stt`), TTS narration (`--tts`), DALL-E 3 image generation (`--imgen ... -o <path>`), project container routing (`--project`).
- **Claude**: Projects (`--project`), code artifacts extraction (`--artifacts`), attachments (`--attach`).
- **Gemini**: Native Imagen 3 image generation (`--imgen ... -o <path>`), Listen TTS (`--tts`), Gems/Notebooks (`--gem`).
- **DeepSeek**: DeepThink R1 reasoner toggle (`--think`), web search toggle (`--search`), thinking chain output (`--show-thinking`).
- **Z.ai**: Deep Think mode (`--think`), search toggle (`--search`), GLM model outputs.
- **MiniMax / Kimi / Grok / Qwen**: Frontier agent adapters hosted in `~/projects/cdp-agents`.

## Quick CLI Reference
```bash
# ChatGPT (Default)
ai "Prompt"
ai --imgen "Image prompt" -o output.png
ai --tts "Text to read aloud"

# Claude
ai --claude "Prompt"
ai --claude --project hisual "Project prompt"
ai --claude --artifacts "Generate component"

# Gemini
ai --gemini "Prompt"
ai --gemini --imgen "Watercolor landscape" -o art.png
ai --gemini --tts "Read this summary"
ai --gemini --gem Gate_DA_PH "Question"

# DeepSeek
ai --deepseek "Prompt"
ai --deepseek --think --show-thinking "Complex problem"
ai --deepseek --search "Latest benchmarks"

# Z.ai (GLM)
ai --zai "Prompt"
ai --zai --think "Multi-step puzzle"
ai --zai --search "Recent news"
```
