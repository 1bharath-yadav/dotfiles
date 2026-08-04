# Browser automation (tier 1)

For anything inside a browser tab, **CDP (Chrome DevTools Protocol)** beats
AT-SPI. It exposes the DOM, CSS/XPath selectors, JavaScript execution, network
interception, downloads/uploads, and PDF generation — strictly more capable than
the accessibility tree for web content.

This skill's `browser` subcommand delegates to the standalone
[`agent-browser`](https://github.com/agent-browser) CLI (a Node tool already
installed on this machine at `~/.openagents/nodejs/bin/agent-browser`), which
speaks CDP over a WebSocket.

## Launching Chrome with CDP

Nothing on this machine exposes a debugging port by default, so the first
`browser open` triggers a Chrome launch with CDP enabled. The standard recipe:

```bash
google-chrome-stable \
  --remote-debugging-port=9222 \
  --user-data-dir=/tmp/chrome-cdp-profile \
  --no-first-run --no-default-browser-check \
  "about:blank"
```

- `--remote-debugging-port=9222` (or `=0` for an ephemeral port printed to
  stdout) is what makes CDP reachable.
- `--user-data-dir` isolates the automation profile from your daily browsing.
- agent-browser discovers and connects to that port automatically; you usually
  don't have to pass it.

Verify it's up:

```bash
curl -s http://localhost:9222/json/version   # CDP endpoint
linux-automation browser status               # via agent-browser
```

## Subcommands

| Action | Maps to | Notes |
|--------|---------|------|
| `status` | agent-browser connection check | First thing to run if something's off. |
| `open --url U` | `goto U` | Navigates the active tab. |
| `click --selector S` | `click S` | CSS or XPath. |
| `type --selector S --text T` | `type S T` | Clears first if the field has content. |
| `scroll [down\|up]` | `scroll <dir> 500` | Default 500px. |
| `extract [--selector S]` | `get-dom` (+optional selector) | Page or element text. |
| `screenshot` | `screenshot` | PNG to agent-browser's default path. |
| `pdf` | `pdf` | Print current page to PDF. |

For richer flows (multi-step forms, waiting for selectors, network stubs),
call `agent-browser` directly or via `api.browser_*` — the wrapper here covers
the common cases.

## When to fall back from CDP

- **Native file dialogs** (the OS "Open File" picker) are not part of the DOM —
  CDP can't drive them. Use AT-SPI (`a11y`) on the dialog, or `ydotool` to type
  the path and hit Enter.
- **Chrome's own chrome** (the URL bar, menus, devtools) is sometimes exposed
  via AT-SPI but rarely needed — prefer keyboard shortcuts (`Ctrl+L` for the
  address bar, `Ctrl+T` for a new tab) via `keyboard hotkey`.
- **PDFs / canvas / WebGL content** inside a page has no DOM — OCR it.

## CDP vs. AT-SPI for browser content

Both work on Chrome. Prefer CDP because:

- It gives you the live DOM (selectors, text, attributes) — no tree walking.
- You can run arbitrary JS (`document.querySelector`, event dispatch, etc.).
- Downloads/uploads go through `Page.setDownloadBehavior` / file inputs.
- It survives layout/visibility quirks that confuse the a11y tree.

Reach for AT-SPI on Chrome only for the OS-level chrome and native dialogs.
