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
Use `find label "Chat with ChatGPT" fill <prompt>` and press Enter.
Wait until generation finishes and extract the new assistant content.

Usage:
`python3 ~/.agents/skills/cdp-agents/chatgpt/chatgpt.py --check`
`python3 ~/.agents/skills/cdp-agents/chatgpt/chatgpt.py --project hisual "hello"`
`python3 ~/.agents/skills/cdp-agents/chatgpt/chatgpt.py --project hisual --attach /absolute/file.txt "summarize this"`

Safety:
The browser must already be authenticated. Do not read or export cookies/tokens.
Prefer semantic labels and live snapshots over generated refs because refs change.

Research notes:
`vercel-labs/agent-browser` documents CDP, semantic locators, and file upload support. Public ChatGPT browser automation projects use fallback selector strategies because the UI changes frequently. `DOM.setFileInputFiles` is the standard CDP mechanism for file inputs. 
