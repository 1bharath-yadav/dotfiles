# CDP Agents

Provider adapters for authenticated AI web apps over Chrome CDP (`cdp_page.py`).
Direct RFC 6455 WebSocket communication to specific page targets, completely bypassing high-level CLI wrappers like `agent-browser` and guaranteeing **zero window-focus stealing**.

---

## Provider Capabilities Matrix

| Provider | Chat | Project / Container | Attachments | Live Voice / STT | TTS (Read Aloud) | Image Gen (`--imgen`) | Reasoning / Thinking | Web Search Toggle | CLI Alias / Flag |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **ChatGPT** | ✅ | ✅ Projects (`--project`) | ✅ (`DOM.setFileInputFiles`) | ✅ (Super+H / Super+Alt+H) | ✅ (`--tts` Read Aloud) | ✅ DALL-E 3 canvas (`-o`) | — | — | `ai` / `ai --chatgpt` |
| **Claude** | ✅ | ✅ Projects (`--project`) | ✅ (`DOM.setFileInputFiles`) | — | — | — (No image gen) | — | — | `ai --claude` / `claude-ai` |
| **Gemini** | ✅ | ✅ Gems / Notebooks (`--gem`) | ✅ (`DOM.setFileInputFiles`) | — | ✅ (`--tts` Listen) | ✅ Imagen 3 (`-o`) | ✅ Thinking | — | `ai --gemini` / `gemini-ai` |
| **DeepSeek** | ✅ | — | ✅ (`DOM.setFileInputFiles`) | — | — | — (No image gen) | ✅ DeepThink R1 (`--think`) | ✅ (`--search`) | `ai --deepseek` / `deepseek-ai` |
| **Z.ai** | ✅ | — | ✅ (`DOM.setFileInputFiles`) | — | — | — | ✅ Deep Think (`--think`) | ✅ (`--search`) | `ai --zai` / `zai-ai` |

---

## Common Contract & Architecture

1. **Direct V8/DOM Execution vs OS Input Simulation:**
   - Evaluates atomic JavaScript within the page's execution context via `Runtime.evaluate(..., {userGesture: true})`.
   - Native `.click()`, `execCommand('insertText')`, and input events execute in a single round-trip without cross-process latency or race conditions.
2. **Zero Focus Stealing (Hyprland / Wayland safe):**
   - Direct page-socket CDP never sends `Page.bringToFront`, `Target.activateTarget`, or OS input events. The browser remains completely quiet in the background without stealing focus or triggering workspace jumps.
3. **Programmatic File Uploads:**
   - Files are attached directly via CDP's `DOM.setFileInputFiles` against target `<input type="file">` elements, completely bypassing OS file-picker dialogues.
4. **Pure Python Stdlib:**
   - Implemented via `cdp_page.py` using standard `socket`, `struct`, `urllib`, and `json`, with zero external dependencies.

---

## Headless & Background Runtime

The XOY Chrome session runs as a user systemd service (`xoy-cdp.service` -> `~/.local/bin/start-xoy-cdp.sh`):
- **Headless Mode (`XOY_HEADLESS=1`):** Launches with `--headless=new`, `--use-fake-ui-for-media-stream`, and custom User-Agent spoofing to bypass Cloudflare Turnstile bot challenges while maintaining authenticated cookies and full WebRTC microphone/audio routing through PipeWire/PulseAudio.
- **Headed Background Mode (`XOY_HEADLESS=0`):** Can be placed silently on a scratchpad or hidden workspace in Hyprland; even in headed mode, direct page CDP never triggers activation or focus jumps.

---

## Quick Reference CLI Usage

```bash
# Default (ChatGPT)
ai "Hello ChatGPT"
ai --imgen "cyberpunk city" -o city.png
ai --tts "Read this aloud"

# Claude
ai --claude "Analyze this repository architecture"
ai --claude --project hisual "Draft the next section"
ai --claude --artifacts "Create a responsive sidebar"

# Gemini
ai --gemini "Explain transformers in simple terms"
ai --gemini --imgen "watercolor hummingbird" -o bird.png
ai --gemini --tts "Narrate this summary"
ai --gemini --gem Gate_DA_PH "Linear algebra question"

# DeepSeek
ai --deepseek "Solve this dynamic programming problem"
ai --deepseek --think --show-thinking "Prove the prime number theorem"
ai --deepseek --search "Latest AI open weights benchmarks"

# Z.ai (GLM)
ai --zai "Summarize GLM-5 capabilities"
ai --zai --think --show-thinking "Complex multi-hop puzzle"
ai --zai --search "Recent news in robotics"
```
