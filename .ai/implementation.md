# Agent Window Implementation Plan
# Two-mode centered Quickshell agent UI replacing/extending AssistantWindow.qml

---

## 1. Current Architecture Analysis

### Component Tree
```
Assistant.qml              ← IPC entry (voiceAssistant IpcHandler) + legacy overlay IPC
  └─ AssistantRoot.qml     ← Loader wrapper, open/close/toggle/submit surface
       └─ AssistantWindow.qml  ← PanelWindow (fullscreen, anchors all 4 sides)
            ├─ Scrim (MouseArea → close)
            ├─ cardAnchor (Item, bottom-anchored)
            │   └─ card (Rectangle — width/height animated)
            │       ├─ AssistantChatPanel (msgList ListView)
            │       ├─ slashStrip (suggestion chips)
            │       └─ AssistantComposer (input box)
            └─ AssistantController (logic: session + streaming + IPC dispatch)
                 ├─ AssistantSessionManager (state machine, messages[])
                 └─ StreamingCoordinator (append/finalise stream/think)
```

### State Flags
- `GlobalStates.voiceAssistantActive` — window visibility
- `AssistantWindow.wideMode` — local bool toggled by Ctrl+O (80% vs 50/70%)
- Card currently: bottom-anchored, grows upward, no centered mode

### Identified Flicker Causes
1. **Card height binding re-evaluates on every token** — `chatH: chatPanel.desiredHeight` which tracks `msgList.contentHeight` every paint. Causes geometry thrash during streaming.
2. **Behavior on height fights contentHeight** — 200ms `OutQuart` animation on `card.height` fires continuously during streaming; each token triggers a new animation.
3. **Width transition on mode switch** while height is simultaneously animating creates double-animation competition.
4. **`cardAnchor` uses `Translate` + `opacity` simultaneously** — two property animations running on parent container during open/close.
5. **No debounce on card height** — `chatPanel.desiredHeight` has no timer guard, unlike `scrollDebounce` in chat panel.

### Current Ctrl+O Behaviour
`cardAnchor.Keys.onPressed` catches Ctrl+O and sets `root.wideMode`. Works but requires keyboard focus to be on `cardAnchor`, which is fragile.

---

## 2. Target Design

### Mode A — Chat (default, always mounted)
- Centered horizontally and vertically (not bottom-anchored)
- Width: 42% of screen, max 860px
- Height: input-only until first message; grows up to 72% screen height
- Minimal chrome, focus on input

### Mode B — Agent workspace (Ctrl+O)
- Same window grows outward *in place* (no reparent, no remount)
- Width: 88% of screen, max 1500px
- Height: 88% of screen height — fixed, not content-driven
- Chat column stays ~42% width on left; agent pane fills remainder on right
- Agent pane has: tool calls, execution trace, memory, status, future tabs
- Toggle button visible inside card to collapse back to Mode A

### Key Constraints
- Message list (`msgList`) is **never unmounted** during mode transitions
- Card geometry animates with a single coordinated `Behavior` (width + height simultaneously)
- Height binding is **debounced** — not live during streaming
- Ctrl+O registered via existing `GlobalShortcut` mechanism (same as sidebar) — not Keys.onPressed
- `GlobalStates` gets a new `agentModeActive: bool` property (not reusing `wideMode` local)

---

## 3. New Component Tree

```
Assistant.qml                    (unchanged — IPC entry)
  └─ AssistantRoot.qml           (add: agentMode relay)
       └─ AgentWindow.qml        (replaces AssistantWindow.qml)
            ├─ Scrim
            ├─ AgentCard.qml     (centered Item, owns geometry state machine)
            │   ├─ AgentChatColumn.qml   (left column: chat panel + composer + slash)
            │   └─ AgentWorkspacePane.qml (right pane: lazy, Loader-gated)
            │       ├─ AgentToolFeed.qml
            │       ├─ AgentMemoryView.qml
            │       └─ AgentStatusBar.qml
            └─ AssistantController  (unchanged)
                 ├─ AssistantSessionManager  (unchanged)
                 └─ StreamingCoordinator     (unchanged)
```

Files to **keep unchanged**: `AssistantController.qml`, `AssistantSessionManager.qml`, `StreamingCoordinator.qml`, `AssistantComposer.qml`, `AssistantChatPanel.qml`, `AssistantMarkdownMessage.qml`, `AssistantThinkingBubble.qml`, `AssistantMessageBubble.qml`, `AssistantCodeBlock.qml`, `AssistantEventFeed.qml`, `AssistantPromptInput.qml`, `AssistantMessageList.qml`.

Files to **replace**: `AssistantWindow.qml` → `AgentWindow.qml` (new file, stow the old away).

Files to **add**:
- `modules/ii/assistant/AgentWindow.qml`
- `modules/ii/assistant/AgentCard.qml`
- `modules/ii/assistant/AgentChatColumn.qml`
- `modules/ii/assistant/AgentWorkspacePane.qml`
- `modules/ii/assistant/AgentToolFeed.qml`
- `modules/ii/assistant/AgentMemoryView.qml`
- `modules/ii/assistant/AgentStatusBar.qml`

Files to **edit**:
- `AssistantRoot.qml` — swap sourceComponent to `AgentWindow`
- `GlobalStates.qml` — add `agentModeActive: bool`

---

## 4. Geometry State Machine (AgentCard.qml)

```
State IDLE (no messages):
  cardWidth  = screenW * 0.42, max 860
  cardHeight = composerHeight + slashH + 28

State CHAT (messages exist, agentMode=false):
  cardWidth  = screenW * 0.42, max 860
  cardHeight = min(screenH * 0.72, chatContentH + composerH + slashH + 28)

State AGENT (agentMode=true):
  cardWidth  = screenW * 0.88, max 1500
  cardHeight = screenH * 0.88   ← FIXED, not content-driven

Transitions: single NumberAnimation duration=240, easing OutCubic
Height update: Timer { interval: 64 } debounced — only fires when streaming=false or forced
```

Key: card is always centered via `anchors.centerIn: parent` on the `Item` that holds it, relative to the `PanelWindow`.

---

## 5. Flicker Elimination Plan

| Cause | Fix |
|---|---|
| Height thrash during streaming | Debounce timer (64ms); in AGENT mode height is fixed — no binding at all |
| Double animation (width + height) | Single `states`/`transitions` block on card; Behaviors removed from individual properties |
| cardAnchor Translate + opacity simultaneously | Replace with single `opacity` + `scale` (1.0→0.96) on card; no Translate |
| Ctrl+O requires keyboard focus | Move to `GlobalShortcut { name: "agentModeToggle" }` in `AgentWindow.qml` |
| Width change during message streaming | Width only changes on explicit mode toggle, not message count |

---

## 6. AgentWorkspacePane — Lazy + Stable

```qml
Loader {
    id: workspaceLoader
    active: GlobalStates.agentModeActive   // only load once, never unload while active
    // once loaded, keep alive: active stays true until window closes
    asynchronous: true
    sourceComponent: AgentWorkspacePane { ... }
}
```

- Mounted on first Ctrl+O, stays mounted for session lifetime
- Width: `parent.width - chatColumn.width - spacing`
- Contains `TabBar` (Tool calls | Memory | Status | …) for future extensibility
- Backend-agnostic: takes `controller` as required property, reads `controller.messages` filtered by kind

---

## 7. GlobalStates Changes

Add to `GlobalStates.qml`:
```qml
property bool agentModeActive: false
```

Wire in `AgentWindow.qml`:
```qml
GlobalShortcut {
    name: "agentModeToggle"
    description: "Toggle agent workspace mode (Ctrl+O)"
    onPressed: GlobalStates.agentModeActive = !GlobalStates.agentModeActive
}
```

Register keybind in `~/.config/hypr/hyprland.conf` (or the end4dots keybinds file):
```
bind = CTRL, O, exec, quickshell -c ii ipc call agentModeToggle
```
*(Check existing pattern — sidebarLeft uses `GlobalShortcut` not exec — so use the same; the GlobalShortcut fires when Quickshell has focus.)*

---

## 8. Implementation Steps (Ordered)

### Step 1 — GlobalStates
- Edit `GlobalStates.qml`: add `property bool agentModeActive: false`
- No other changes; verify with `quickshell -c ii` reload

### Step 2 — AgentWindow.qml (skeleton, replaces AssistantWindow)
- Create `modules/ii/assistant/AgentWindow.qml`
- Same `PanelWindow` setup as `AssistantWindow.qml` (same namespace, keyboard focus, exclusion)
- Scrim identical
- Replace `cardAnchor` (bottom-anchored) with centered `Item`
- Card: `anchors.centerIn: parent` inside centered item
- Restore `AssistantController` as child (no change)
- Hook `composer` + `chatPanel` + `slashStrip` same as before
- Verify: window opens/closes, chat works — no agent pane yet

### Step 3 — AgentCard geometry state machine
- Extract card into `AgentCard.qml` (or keep inline, extract later)
- Implement the 3-state geometry system (IDLE/CHAT/AGENT) with debounced height
- Add `GlobalShortcut { name: "agentModeToggle" }` in AgentWindow or Assistant.qml
- Verify: Ctrl+O expands/collapses cleanly, no flicker

### Step 4 — AgentChatColumn.qml
- Extract `AssistantChatPanel` + `slashStrip` + `AssistantComposer` into `AgentChatColumn.qml`
- Required properties: `controller`, `messages`
- In CHAT mode: `width = card.width`
- In AGENT mode: `width = card.width * 0.40` (fixed proportion, not screen %)
- Verify: chat still works in both modes

### Step 5 — AgentWorkspacePane.qml (skeleton)
- Create pane: visible only in AGENT mode, Loader-gated
- `TabBar` with tabs: Tool Calls | Memory | Status
- Each tab has a placeholder `StyledText` for now
- Verify: pane appears/disappears without layout jump

### Step 6 — AgentToolFeed.qml
- Reads `controller.messages` filtered by `kind === "tool"` and events with `kind === "tool"`
- ListView of tool call chips (matches existing event chip style in `AssistantChatPanel`)
- Auto-scrolls like chat panel

### Step 7 — AgentStatusBar.qml
- Shows: state, model, agent id (first 12 chars), token count
- Reuse data from `controller.modelName`, `controller.agentId`, `controller.tokenCount`, `controller.state`
- Compact single-row display inside status tab

### Step 8 — AgentMemoryView.qml
- Shows `/mem blocks` output (future: trigger `/mem blocks` on open, parse output)
- For now: `StyledText` placeholder + button to run `/mem blocks`

### Step 9 — Close/dismiss agent mode button
- Small `RippleButton` in workspace pane header: "collapse agent mode" → sets `GlobalStates.agentModeActive = false`
- Also: Escape key closes window (not just agent mode)

### Step 10 — Polish + anti-flicker audit
- Remove any `Behavior` that fires during streaming
- Confirm height debounce timer interval tuning (48–80ms)
- Confirm single animation path for all geometry changes
- Test: open window → send long streamed reply → Ctrl+O mid-stream → no flicker

### Step 11 — AssistantRoot.qml update
- Change `sourceComponent: AssistantWindow { ... }` → `sourceComponent: AgentWindow { ... }`
- Add `agentMode` relay if needed (likely not — GlobalStates handles it)

### Step 12 — Hyprland keybind
- Find end4dots keybind config path (likely `~/.config/hypr/hyprland.conf` or a keybinds.conf)
- Add: `bind = CTRL, O, qs:agentModeToggle` (or whatever pattern end4dots uses for GlobalShortcut triggers)
- Verify: Ctrl+O works from any focused window

---


```
edit here ~/.local/share/end4dots/dots/.config/quickshell/ii/   ← upstream source (do not edit directly)
```


---

## 10. Non-Goals (Explicitly Out of Scope)

- Rewriting AssistantController, SessionManager, StreamingCoordinator
- Changing IPC protocol or daemon interface
- Replacing the existing AiChat.qml in sidebarLeft
- Adding web search or tool execution from UI
- Multi-agent simultaneous view
- Persistent session storage (already handled by Letta backend)

---

## 11. Risk Register

| Risk | Mitigation |
|---|---|
| QML module registration: new files not found | Ensure `qmldir` or implicit module auto-discovery is satisfied; check existing pattern in `modules/ii/assistant/` |
| GlobalShortcut `agentModeToggle` name collision | Check existing shortcut names in shell.qml / panelFamilies before registering |
| Ctrl+O conflict with SidebarLeft `panelWindow.extend` | SidebarLeft Ctrl+O only fires when sidebar has focus — no collision when agent window is open |
| Loader async timing: workspace pane shows after card width animation | Set `asynchronous: false` on workspaceLoader if timing gap is visible |
