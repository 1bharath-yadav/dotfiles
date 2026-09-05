---
name: cdp-claude
description: Drive an already-authenticated Claude.ai tab through Chrome CDP.
---

# Claude CDP agent

Target: `https://claude.ai` through an existing Chrome CDP endpoint.

## Required capabilities
- Select project
- Select attachments
- Send prompt
- Receive completed response

## Verified DOM
- Composer: semantic label `Write your prompt to Claude`
- Project controls are exposed as buttons/links with visible project names.
- Attachment control: `Add files, connectors, and more`
- Current chat responses appear as `article` nodes with `Claude responded:` text.

## Interaction rules
Use fresh snapshots after UI changes. Prefer semantic locators over generated refs.
Do not scrape credentials or cookies. The browser must already be authenticated.

## CLI backend
`claude.py` wraps the installed `agent-browser` binary over CDP port 9222.

Example:
`python3 ~/.agents/skills/cdp-agents/claude/claude.py "hello"`

Health check:
`python3 ~/.agents/skills/cdp-agents/claude/claude.py --check`

## Project selection
Inspect the current snapshot for the project control and select by visible project name. Keep the selector isolated in the adapter so Claude UI changes do not affect other providers.

## Attachments
Open `Add files, connectors, and more`, then use the resulting file chooser control. Attachment handling must remain provider-specific.

## Response handling
After send, resnapshot until a new assistant `article` appears and its content stabilizes. Strip UI chrome and return the assistant text only.

## Verified Claude selectors
- Project navigation: `span.min-w-0.truncate` exact text inside an `<a>`; verified `hisual` href `/project/019fbc23-f1ce-73c9-bcb5-9ecadaebf983`.
- Composer: semantic label `Write your prompt to Claude`; verified fill + Enter.
- Attachments control: `Add files, connectors, and more`; file input should be discovered after opening it rather than hardcoded.
- Response: `article` containing `Claude responded:`; ignore `Currently streaming message` until it disappears.

## Project semantics
Do not confuse a conversation title with a project name. A project is selected by clicking the project link after opening Projects.

## Account switching
Use the installed Claude Account Switcher as the session authority. The adapter does not read, print, or manage cookie values. It may use the extension bridge only for `GET_PROFILES` and `SWITCH_PROFILE` so it can rotate to the next saved account. The adapter detects Claude's visible quota message (`You are out of free messages`) and then switches and retries the original prompt once by default. Do not rotate based on an arbitrary response-time threshold.

## Research
`vercel-labs/agent-browser` recommends semantic locators/refs and fresh snapshots after DOM changes. A community Claude.ai adapter also uses fallback chains for prompt, send, stop, response, and file inputs; use it only as a hint, then revalidate selectors against the live DOM.
