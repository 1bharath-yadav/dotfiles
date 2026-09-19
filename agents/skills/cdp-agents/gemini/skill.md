---
name: cdp-gemini
description: Drive an already-authenticated Google Gemini tab through Chrome CDP.
---

# Google Gemini CDP Agent

Direct page-socket CDP adapter for `https://gemini.google.com/app` without `agent-browser` and zero window-focus stealing.

## Capabilities
- Select Gem or Notebook container (`--gem <name>`)
- Attach local files via CDP `DOM.setFileInputFiles` (`--attach <path>`)
- Send text prompts and stream responses to completion
- Listen to responses via native TTS (`--tts "..."`)
- Generate images via native Imagen 3 and download to local disk (`--imgen "..." -o <path>`)
- Start fresh conversation (`--new`)
- Health check and authentication verification (`--check`)

## Verified DOM Selectors
- **Composer:** `rich-textarea .ql-editor[contenteditable="true"]` (dispatches `input` and `change` events)
- **Send Button:** `button[aria-label*="Send message" i], button.send-button`
- **Stop Button:** `button[aria-label*="Stop" i], button.stop-button, [data-test-id="stop-button"]`
- **TTS / Listen Button:** `model-response button[aria-label*="Listen" i], [data-test-id="listen-button"]`
- **Imagen 3 Output Images:** `model-response img[src*="googleusercontent.com"], generated-image img`
- **Attachment Trigger:** `button[aria-label*="Upload" i], button[aria-label*="Add files" i]`
- **File Input:** `input[type="file"]`
- **Gems / Notebooks:** `a[href*="/gem/"], a[href*="/notebook/"]`
- **Model Response Container:** `<model-response>, <gmp-model-response>`
- **Response Content:** `<message-content>, .model-response-text, .markdown`
- **New Chat:** `a[href="/app"]` or navigate to `https://gemini.google.com/app`

## Usage
```bash
# Check connectivity and login state
ai --gemini --check
# or
python3 ~/.agents/skills/cdp-agents/gemini/gemini.py --check

# Send text prompt
ai --gemini "Explain quantum entanglement in 2 sentences"

# Select Gem or Notebook
ai --gemini --gem Gate_DA_PH "Solve this linear algebra question"

# Text-to-Speech (Listen via native Gemini TTS)
ai --gemini --tts "Read this summary aloud"

# Image Generation via Imagen 3 (auto-download to local disk)
ai --gemini --imgen "A futuristic city in watercolors" -o ./city.png

# Attach local files
ai --gemini --attach ./report.pdf "Summarize key findings"

# Start fresh conversation
ai --gemini --new "New topic"
```

## Architecture & Safety
- Direct page-level WebSocket CDP via `cdp_page.py`.
- No `agent-browser`, no `Page.bringToFront`; runs completely silent in background or headless (`XOY_HEADLESS=1`).
- Imagen 3 images are fetched via in-browser authenticated session `fetch(img.src)` into base64, preserving high resolution.
