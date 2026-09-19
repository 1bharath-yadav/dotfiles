---
name: cdp-claude
description: Drive an already-authenticated Claude.ai tab through Chrome CDP.
---

# Claude CDP Agent

Direct page-socket CDP adapter for `https://claude.ai` without `agent-browser` and zero window-focus stealing.

## Capabilities
- Select project container (`--project <name_or_uuid>`)
- Attach local files via CDP `DOM.setFileInputFiles` (`--attach <path>`)
- Send text prompts and stream responses to completion
- Extract code artifacts from split-screen panel (`--artifacts`)
- List discovered projects in sidebar (`--list-projects`)
- Start fresh conversation (`--new`)
- Health check and authentication verification (`--check`)
- Note: Claude does **not** generate images or support live voice mode.

## Verified DOM Selectors
- **Composer:** `div.ProseMirror[contenteditable="true"]` (focus-safe input via `document.execCommand('insertText')`)
- **Send Button:** `button[aria-label="Send message"], button[data-testid="send-button"]`
- **Stop Button:** `button[aria-label*="Stop response" i], button[data-testid="stop-button"]`
- **Attachment Trigger:** `button[aria-label*="Add files" i]`
- **File Input:** `input[type="file"]`
- **Projects Links:** `a[href*="/project/"]` with project name in `span.min-w-0.truncate`
- **Artifact Panel:** `div[data-testid="artifact-panel"], aside`
- **Artifact Code Tab:** `button[role="tab"][aria-label*="Code" i]`
- **Assistant Message:** `.font-claude-response, .font-claude-message, [data-testid="ai-message"]`
- **Response Markdown:** `.standard-markdown, .progressive-markdown, .markdown, .prose`
- **Streaming Indicator:** `[data-is-streaming="true"]` or stop button presence
- **New Chat:** `a[href="/new"]` or navigate to `https://claude.ai/new`

## Usage
```bash
# Check connectivity and login state
ai --claude --check
# or
python3 ~/.agents/skills/cdp-agents/claude/claude.py --check

# List available projects
python3 ~/.agents/skills/cdp-agents/claude/claude.py --list-projects

# Send prompt to Claude
ai --claude "Analyze this codebase architecture"
# or
python3 ~/.agents/skills/cdp-agents/claude/claude.py "hello Claude"

# Send prompt within a specific Project
ai --claude --project hisual "Refine the chapter draft"

# Attach files
ai --claude --attach ./data.json "Summarize this data"

# Extract generated artifact code
ai --claude --artifacts "Create a React timer component"

# Start fresh conversation
ai --claude --new "New topic prompt"
```

## Architecture & Safety
- Operates directly over page-level WebSockets via `cdp_page.py`.
- Never calls `Page.bringToFront` or `Target.activateTarget`; safely runs in background or headless (`XOY_HEADLESS=1`).
- Quota handling: Detects `You are out of free messages` and reports exhaustion immediately.
