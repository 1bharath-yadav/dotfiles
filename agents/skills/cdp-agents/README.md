# CDP Agents

Provider adapters for authenticated AI web apps over Chrome CDP.

## Common contract
- check provider/session reachability.
- select the provider's project-like container.
- attach local files through the real UI.
- send a prompt and wait for completion.
- receive the latest completed response.
- use **@Remote Desktop Commander tool** for local filesystem, terminal, process, and verification work.

## Provider mapping
- Claude → Projects
- ChatGPT → Projects
- Gemini Chat → Notebooks
- Gemini Spark → Spark tasks/tools

## Rules
Use semantic names first and fresh refs only within the current snapshot.
Refresh the snapshot after navigation, menu opens, uploads, or submission.
Keep selectors/workflows inside provider adapters.
Never read cookies, access tokens, or stored credentials.
The browser must already be authenticated by the user.

## Content-pipeline rule
The hisual content pipeline uses **Claude only**. Do not dispatch content tasks to ChatGPT or Gemini.

## Local work
Every CDP agent prompt that needs local files, terminal commands, process control, generated assets, or verification must explicitly use:
`@Remote Desktop Commander tool`

## Architecture: Direct Page-Socket CDP

The provider adapters use direct RFC 6455 WebSocket communication to specific page targets (`cdp_page.py`), bypassing high-level CLI wrapper tools like `agent-browser`.

### Why this technique is superior & deterministic:
1. **Direct V8/DOM Execution vs OS Input Simulation:**
   - Instead of synthesizing accessibility-tree snapshots and simulated keystrokes, direct CDP executes atomic JavaScript within the page's execution context via `Runtime.evaluate(..., {userGesture: true})`.
   - Element lookup, state assertions, and native `.click()` occur in a single round-trip without cross-process latency or race conditions.
2. **Zero Focus Stealing (Hyprland / Wayland safe):**
   - Wrapper CLI tools like `agent-browser tab <id>` issue `Page.bringToFront` or `Target.activateTarget`, which asks the OS window manager to raise and focus the tab. Under Hyprland (especially with `misc:focus_on_activate = true`), this forces workspace switches and steals window focus.
   - Direct page-socket CDP never issues `Page.bringToFront`, `Target.activateTarget`, or OS input events. The browser remains completely quiet in the background without stealing focus.
3. **Programmatic File Uploads:**
   - Files are attached directly via CDP's `DOM.setFileInputFiles` against target `<input type="file">` elements, completely bypassing OS file-picker dialogues.
4. **Fast and Dependency-Free:**
   - Implemented with Python standard library (`socket`, `struct`, `urllib`), requiring no third-party packages or daemon processes.

## Headless & Background Runtime

The XOY Chrome session runs as a user systemd service (`xoy-cdp.service` -> `~/.local/bin/start-xoy-cdp.sh`):
- **Headless Mode (`XOY_HEADLESS=1`):** Launches with `--headless=new`, `--use-fake-ui-for-media-stream`, and custom User-Agent spoofing to bypass Cloudflare Turnstile bot challenges while maintaining authenticated cookies and full WebRTC microphone/audio routing through PipeWire/PulseAudio.
- **Headed Background Mode (`XOY_HEADLESS=0`):** Can be placed silently on a scratchpad or hidden workspace in Hyprland; even in headed mode, direct page CDP never triggers activation or focus jumps.

