---
name: claude-desktop-connect
description: Automate sending prompts to Claude Desktop across multiple accounts (ds, bat, iitm, etc.) on Wayland/Hyprland using AT-SPI accessibility, and extract markdown responses to terminal or session.jsonl. Use when interacting with Claude Desktop, delegating queries to Claude Desktop, or scraping Claude Desktop responses.
---

# Claude Desktop Connect (`claude-desktop-connect`)

Automates desktop GUI interactions with **Claude Desktop** on Arch Linux (Wayland / Hyprland). Queries the active window and prompt elements via AT-SPI accessibility, sends prompts with automatic workspace preservation, monitors completion, extracts markdown responses via native message actions, and logs all turns to `session.jsonl`.

## 1. CLI Entry Point

The CLI is globally available in PATH:

```bash
claude-desktop-connect [OPTIONS]
```

Or invoke directly via Python:
```bash
python /home/archer/projects/workflows/claude-desktop/claude-desktop-connect.py [OPTIONS]
```

---

## 2. Supported Accounts

Claude Desktop profiles can be chosen with `--account` (`-a`):

| Profile Flag | Profile Window Title | Launcher Command |
|---|---|---|
| `-a ds` (default) | `Claude (ds)` | `claude-desktop-ds` |
| `-a bat` | `Claude (bat)` | `claude-desktop-bat` |
| `-a bharath9014` | `Claude (bharath9014)` | `claude-desktop-bharath9014` |
| `-a bharathy723` | `Claude (bharathy723)` | `claude-desktop-bharathy723` |
| `-a bharathy798` | `Claude (bharathy798)` | `claude-desktop-bharathy798` |
| `-a byadhav` | `Claude (byadhav)` | `claude-desktop-byadhav` |
| `-a iitm` | `Claude (iitm)` | `claude-desktop-iitm` |
| `-a default` | `Claude` | `claude-desktop` |

---

## 3. Core Usage Patterns

### A. One-Shot Prompt
Send a query and print the formatted response to stderr/stdout:
```bash
claude-desktop-connect -a ds -p "Summarize the difference between TCP and UDP in 3 bullet points."
```

### B. Auto-Launch if Not Running (`--launch`, `-l`)
If the profile window is not currently open on any workspace, launch it in background `nohup` with `--force-renderer-accessibility` and wait for it to be ready:
```bash
claude-desktop-connect -a iitm -p "Explain merge sort" --launch
```

### C. Raw Output for Piping (`--raw`, `-r`)
Print **only** the response markdown to stdout (ideal for shell pipes, `jq`, or saving to file):
```bash
claude-desktop-connect -a ds -p "Generate a valid JSON object with keys foo and bar" --raw | jq .
claude-desktop-connect -a ds -p "Write an Arch PKGBUILD for ripgrep" --raw > PKGBUILD
```

### D. Reading Prompt from Stdin
Pipe input directly into Claude:
```bash
cat error.log | claude-desktop-connect -a ds -p -
# Or simply omit -p when piping:
git diff | claude-desktop-connect -a ds --raw
```

### E. Custom Timeout (`--timeout`, `-t`)
For long generations or complex queries, extend the wait deadline (default: 120s):
```bash
claude-desktop-connect -a ds -p "Draft an exhaustive 2000-word essay" -t 300
```

---

## 4. Session Logs (`session.jsonl`)

Every turn automatically appends a structured record to `session.jsonl` (defaults to `/home/archer/projects/workflows/claude-desktop/session.jsonl` or override with `--session-file` / `-s`):

```json
{
  "id": "af620f16-f2d4-42d7-b276-dd1cf98dcb71",
  "timestamp": "2026-11-02T06:03:55.362843+00:00",
  "account": "ds",
  "prompt": "Reply with only the word: PING_PONG_CONFIRMED",
  "response": "PING_PONG_CONFIRMED",
  "duration_seconds": 8.43,
  "status": "completed"
}
```

### Querying the Log
```bash
# View recent turns
tail -n 5 /home/archer/projects/workflows/claude-desktop/session.jsonl | jq '{account, prompt, duration: .duration_seconds}'

# Search past responses by account
jq 'select(.account=="ds") | {timestamp, prompt, response}' /home/archer/projects/workflows/claude-desktop/session.jsonl
```

---

## 5. Architectural & Operating Guarantees

1. **Workspace & Focus Preservation**:
   - The CLI queries Hyprland's `activewindow` before input.
   - It briefly focuses Claude to paste/submit the prompt, and then immediately restores your previous active window so terminal work is never interrupted.
2. **Generation State Polling**:
   - Polling uses AT-SPI button states (`Stop response` vs `Copy`) instead of fixed sleeps.
3. **Exact Markdown Quality**:
   - Response capture clicks Claude's native `Copy` action, preserving exact indentation, math, and code formatting, with an automatic AT-SPI static text fallback.
