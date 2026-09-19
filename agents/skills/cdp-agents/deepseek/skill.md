---
name: cdp-deepseek
description: Drive an already-authenticated DeepSeek Web (chat.deepseek.com) tab through Chrome CDP.
---

# DeepSeek CDP Agent

Direct page-socket CDP adapter for `https://chat.deepseek.com` without `agent-browser` and zero window-focus stealing.

## Capabilities
- Send text prompts and stream responses to completion
- DeepThink (R1 Reasoner) mode toggle (`--think` / `--r1` or `--no-think`)
- Web Search mode toggle (`--search` or `--no-search`)
- Chain-of-thought extraction (`--show-thinking`)
- Clean final markdown answer extraction (separated from internal thinking blocks)
- Attach local files via CDP `DOM.setFileInputFiles` (`--attach <path>`)
- Start fresh conversation (`--new`)
- Health check and authentication verification (`--check`)
- Note: DeepSeek does **not** generate images or support live voice mode.

## Verified DOM Selectors
- **Composer:** `textarea#chat-input, textarea[placeholder*='DeepSeek'], textarea`
- **Send Button:** `[role='button'].ds-button._52c986b, button[aria-label="Send"], div.ds-icon-button`
- **Stop Button:** Button transforms in-place into stop icon (`rect` / stop SVG)
- **DeepThink (R1) Button:** `.ds-toggle-button:has-text('DeepThink'), [role='button']:has-text('深度思考')`
- **Search Button:** `.ds-toggle-button:has-text('Search'), [role='button']:has-text('联网搜索')`
- **Selected State Class:** `.ds-toggle-button--selected`
- **File Input:** `input[type="file"]`
- **Message Item:** `div.ds-message, [data-virtual-list-item-key]`
- **Reasoning / Thinking Content:** `.ds-think-content`
- **Final Answer Content:** `.ds-markdown:not(.ds-think-content *)`
- **New Chat:** `div._5a8ac7a.a084f19e, button:has-text("New chat")` or navigate to `https://chat.deepseek.com/`

## Usage
```bash
# Check connectivity and login state
ai --deepseek --check
# or
python3 ~/.agents/skills/cdp-agents/deepseek/deepseek.py --check

# Standard chat prompt
ai --deepseek "Explain Paxos consensus in simple terms"

# Enable DeepThink (R1 Reasoner) with reasoning process shown
ai --deepseek --think --show-thinking "Prove that the square root of 2 is irrational"

# Enable Web Search
ai --deepseek --search "What are the latest AI hardware announcements today?"

# Attach local files
ai --deepseek --attach ./main.rs "Review this Rust code for concurrency bugs"

# Start fresh conversation
ai --deepseek --new "New topic prompt"
```

## Architecture & Safety
- Direct page-level WebSocket CDP via `cdp_page.py`.
- No `agent-browser`, zero focus stealing, works in headed or headless (`XOY_HEADLESS=1`).
- Robust reasoning separation: Filters out `.ds-think-content` so final answers are never polluted by internal reasoning chains unless `--show-thinking` is explicitly requested.
