---
name: cdp-gemini
---

# Gemini CDP agent

Drive an already-authenticated Gemini tab through Chrome CDP.

## Modes
- Chat: `https://gemini.google.com/app`
- Spark: `https://gemini.google.com/spark/...`

## Required capabilities
- Select notebook in Chat mode
- Open Spark mode
- Select attachments
- Send prompt
- Receive completed response

## Verified Chat DOM
- Prompt: `Enter a prompt for Gemini`
- Upload: `Upload & tools`
- Notebook links: `a[href*="/notebook/"]`
- Example notebook: `Gate_DA_PH`
- Response marker: `Gemini said`

## Verified Spark DOM
- Spark opens a `/spark/chat/...` route.
- Prompt: `Enter a prompt for Gemini`
- Upload: `Upload & tools`
- Send: `Send message`
- Spark exposes task/tool UI including `Desktop Commander Remote Mcp`.
- Spark has `Recent` task list and task cards.

## Spark selection
Use the visible Spark control when Chat mode exposes it. If already on `/spark/`, do not navigate again.

## Attachments
Open `Upload & tools`, select `Upload files. Documents, data, code files`, then upload through the real `input[type="file"]` discovered on the page.

## Prompt/response
Use the semantic prompt textbox. Send with Enter or the visible `Send message` control. Take fresh snapshots while waiting and do not return while the response is still generating/thinking.

## Safety
The browser must already be authenticated. Never read or export credentials/cookies. Do not depend on generated accessibility refs across page updates.

## Python adapter
`gemini.py` uses the installed `agent-browser` binary over CDP, default port `9222`.

Examples:
- `python3 ~/.agents/skills/cdp-agents/gemini/gemini.py "hello"`
- `python3 ~/.agents/skills/cdp-agents/gemini/gemini.py --notebook Gate_DA_PH "hello"`
- `python3 ~/.agents/skills/cdp-agents/gemini/gemini.py --spark "hello"`
- `python3 ~/.agents/skills/cdp-agents/gemini/gemini.py --spark --attach /absolute/file.txt "summarize this"`
