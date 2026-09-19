---
name: cdp-chatgpt
description: Drive an already-authenticated ChatGPT tab through Chrome CDP.
---

# ChatGPT CDP agent

Required capabilities:
- Select project
- Select attachments
- Send prompt
- Receive completed response

Verified against the live ChatGPT DOM:
- Composer: `Chat with ChatGPT`
- Project home: project row contains `button[aria-label="Open project home"]`
- Project name: visible text such as `hisual`
- Attachment control: `button[aria-label="Add files and more"]`
- Upload inputs: `input[type="file"]`; live page exposed multiple file inputs
- Attachment chip: selected filename plus `Remove file ...`
- Response: main chat content; latest response appears after prompt

Project flow:
1. Inspect the Projects list.
2. Find the row whose visible text is the requested project name.
3. Click its `Open project home` button.
4. Verify the resulting URL/name before sending.

Attachment flow:
1. Click `Add files and more`.
2. Discover `input[type="file"]`.
3. Upload absolute local paths with CDP file-input upload.
4. Verify the filename chip appears before sending.

Prompt flow:
Uses `document.execCommand('insertText')` on `#prompt-textarea`, clicks `button[data-testid="send-button"]`, and polls for the new assistant response turn until generation completes.

Voice / Dictation flow:
Uses atomic `_voice_js` script via `Runtime.evaluate(..., {userGesture: true})` to toggle, start, stop, or query voice mode/dictation without window focus.

TTS (Text-to-Speech) flow:
Uses `build_tts_prompt()` to format text with the educator-narrator prompt template, sends to ChatGPT, and clicks `Read aloud` on the response to trigger audio playback.

Image Generation flow:
Uses `generate_image()` to route to project `images` (fallback `tmp`), submits prompt, waits for generation to complete, extracts the generated image from the assistant response, and downloads it in-browser via authenticated fetch to the specified output file (`-o`).

Usage:
`ai --check`
`ai --livemode toggle`
`ai --livemode status`
`ai --stt toggle`
`ai --stt status`
`ai --tts "Your phone buzzes twice..."`
`ai --imgen "a neon cybernetic cat" -o cat.png`
`ai --new "start fresh conversation"`
`ai --list-projects`
`ai "prompt"`
`ai --project tmp "hello"`
`ai --attach /absolute/file.txt "summarize this"`

Safety:
The browser must already be authenticated. Do not read or export cookies/tokens.
All actions run over page-level CDP WebSockets with zero window focus calls (`Page.bringToFront` is strictly forbidden).

Architecture notes:
Uses `cdp_page.py` directly for all operations without `agent-browser`. Operates seamlessly with both headed and headless (`XOY_HEADLESS=1`) Chrome browser instances.
 
