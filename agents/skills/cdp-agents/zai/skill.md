---
name: cdp-zai
description: Drive an already-authenticated Z.ai (chat.z.ai) GLM tab through Chrome CDP.
---

# Z.ai (GLM) CDP Agent

Direct page-socket CDP adapter for `https://chat.z.ai` / `https://z.ai` (Zhipu AI GLM consumer platform) without `agent-browser` and zero window-focus stealing.

## Capabilities
- Send text prompts and stream responses to completion
- Deep Think mode toggle (`--think` or `--no-think`)
- Web Search mode toggle (`--search` or `--no-search`)
- Thought process extraction (`--show-thinking`)
- Clean final markdown answer extraction
- Attach local files via CDP `DOM.setFileInputFiles` (`--attach <path>`)
- Start fresh conversation (`--new`)
- Health check and authentication verification (`--check`)

## Verified DOM Selectors
- **Composer:** `#chat-input` (inside `.messageInputContainer`, triggers Svelte auto-grow & `input` event)
- **Send Button:** `button#send-message-button`
- **Stop Button:** `.messageInputContainer div.relative.size-7 button, .messageInputContainer button:has(span.rounded-xs)`
- **Deep Think Button:** `.messageInputContainer button[data-autothink]`
- **Web Search Button:** `.messageInputContainer button[data-selected]:not([data-autothink])`
- **File Input:** `.messageInputContainer input[type="file"], input[type="file"]`
- **Messages Container:** `#messages-container`
- **Assistant Message:** `#messages-container .chat-assistant`
- **Thinking Process:** `.thinking-block, details`
- **Completion Signal:** Action button `.copy-response-button` appears and stop button disappears
- **New Chat:** `button#new-chat-button, button.navNewChat` or `window.dispatchEvent(new CustomEvent("switchNewChat"))`

## Usage
```bash
# Check connectivity and login state
ai --zai --check
# or
python3 ~/.agents/skills/cdp-agents/zai/zai.py --check

# Standard chat prompt
ai --zai "Summarize the GLM-4 model architecture"

# Enable Deep Think mode with thought process shown
ai --zai --think --show-thinking "Solve this multi-step logic puzzle"

# Enable Web Search mode
ai --zai --search "What happened at the latest Zhipu AI conference?"

# Attach local files
ai --zai --attach ./data.csv "Analyze this dataset"

# Start fresh conversation
ai --zai --new "New topic prompt"
```

## Architecture & Safety
- Direct page-level WebSocket CDP via `cdp_page.py`.
- Fully headless and background-safe (`XOY_HEADLESS=1`), zero window-focus activation.
