---
name: cdp-browser
description: Fast browser automation CLI connecting exclusively to the dedicated xoy-cdp Chrome service via CDP on port 9222. Never uses Playwright. Use when navigating websites, scraping data, downloading assets (Lottie, SVGs, images), interacting with authenticated web apps, or taking screenshots.
---

# CDP Browser Automation (`cdp-browser`)

Fast browser automation connecting exclusively to the dedicated `xoy-cdp` Google Chrome instance via the Chrome DevTools Protocol (CDP) on **port 9222**.

## 1. Strict Invariants

- **NEVER use Playwright or Puppeteer**: The entire toolchain relies exclusively on the native `agent-browser` CLI communicating directly over CDP port 9222.
- **Dedicated Profile**: Connects to the single persistent profile at `~/.config/xoy` managed by `xoy-cdp.service`. This preserves authenticated logins (LottieFiles, GitHub, Figma, Claude, AI platforms) across sessions without ephemeral state resets.
- **Binary Path**: `/home/archer/.local/share/mise/installs/npm-agent-browser/latest/node_modules/.bin/agent-browser` (or via the packaged wrapper script `.agents/skills/cdp-browser/scripts/cdp-browser`).

---

## 2. Service Lifecycle & Auto-Healing

The browser runs as a systemd user service (`xoy-cdp.service`) or via `~/.local/bin/start-xoy-cdp.sh`.

### Check Service Status:
```bash
curl -fsS --max-time 1 "http://127.0.0.1:9222/json/version"
```

### Start Service if Inactive:
```bash
systemctl --user start xoy-cdp
```

### Automated Execution via Helper Script:
The packaged helper script automatically checks health, starts `xoy-cdp` if it is offline, and forwards all arguments to `agent-browser --cdp 9222`:

```bash
.agents/skills/cdp-browser/scripts/cdp-browser <command> [options]
```

---

## 3. Core Command Reference

### Navigation & Snapshots
```bash
# Navigate to a URL
.agents/skills/cdp-browser/scripts/cdp-browser open "https://example.com"

# Capture interactive accessibility snapshot (returns @e1, @e2, @e3 refs)
.agents/skills/cdp-browser/scripts/cdp-browser snapshot -i

# Inspect current URL and title
.agents/skills/cdp-browser/scripts/cdp-browser get url
.agents/skills/cdp-browser/scripts/cdp-browser get title
```

### Element Interaction
```bash
# Click an element by its snapshot reference
.agents/skills/cdp-browser/scripts/cdp-browser click @e2

# Fill an input field
.agents/skills/cdp-browser/scripts/cdp-browser fill @e3 "search query"

# Press keys (e.g. Enter, Escape, Tab)
.agents/skills/cdp-browser/scripts/cdp-browser press Enter

# Extract text content from an element
.agents/skills/cdp-browser/scripts/cdp-browser get text @e1
```

### Visual Inspection & Screenshots
```bash
# Capture clean screenshot
.agents/skills/cdp-browser/scripts/cdp-browser screenshot /path/to/output.png

# Capture annotated screenshot (with numbered bounding boxes matching refs)
.agents/skills/cdp-browser/scripts/cdp-browser screenshot --annotate

# Full page screenshot
.agents/skills/cdp-browser/scripts/cdp-browser screenshot --full /path/to/output.png
```

### Tab & Session Management
```bash
# List all active browser tabs
.agents/skills/cdp-browser/scripts/cdp-browser tab list

# Open a new tab
.agents/skills/cdp-browser/scripts/cdp-browser tab new "https://lottiefiles.com"

# Switch to a tab by index/id
.agents/skills/cdp-browser/scripts/cdp-browser tab switch 1

# Close a tab
.agents/skills/cdp-browser/scripts/cdp-browser tab close 1
```

### JavaScript Evaluation
```bash
# Execute JavaScript expression in the page context
.agents/skills/cdp-browser/scripts/cdp-browser eval "window.location.href"
```

---

## 4. Asset Acquisition Workflow (Video Maker Integration)

When sourcing Lottie JSON animations, SVG icons, or dataset diagrams for educational videos:

1. **Check or Launch Browser**:
   ```bash
   .agents/skills/cdp-browser/scripts/cdp-browser open "https://lottiefiles.com/featured"
   ```
2. **Find & Inspect Asset**:
   ```bash
   .agents/skills/cdp-browser/scripts/cdp-browser snapshot -i
   .agents/skills/cdp-browser/scripts/cdp-browser fill @e1 "percentage growth"
   .agents/skills/cdp-browser/scripts/cdp-browser press Enter
   ```
3. **Download Asset Directly to Repository Assets**:
   ```bash
   # Download directly into subject or video assets folder
   curl -s "https://assets.../animation.json" -o content/subjects/<subject>/videos/<video-id>/assets/growth.json
   ```
4. **Validate Asset**:
   - Verify valid JSON structure: `jq . content/subjects/<subject>/videos/<video-id>/assets/growth.json`
   - Pass the captured Lottie JSON to the active HyperFrames Lottie integration; do not introduce a retired renderer dependency.
