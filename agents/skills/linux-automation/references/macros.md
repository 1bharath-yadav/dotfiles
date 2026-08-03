# Multi-Step Intent Workflow Macros

Specification of multi-step GUI routines executed by `linux-automation`.

---

## Workflow Macro Specifications

### 1. `start_coding`
- **Steps**:
  1. Acquire `LOCK_KEYBOARD`.
  2. Switch to workspace 1: `input.py dispatch 'hl.dsp.focus({ workspace = "1" })'`.
  3. Toggle Kitty scratchpad: `input.py dispatch 'hl.dsp.workspace.toggle_special("kitty")'`.
  4. Toggle Obsidian scratchpad: `input.py dispatch 'hl.dsp.workspace.toggle_special("obsidian")'`.
  5. Release locks & notify.

### 2. `open_research_environment`
- **Steps**:
  1. Acquire `LOCK_MOUSE` & `LOCK_KEYBOARD`.
  2. Launch Zen Browser (or focus `SUPER+ALT+E`).
  3. Bring up Obsidian scratchpad (`SUPER+ALT+O`).
  4. Release locks.

### 3. `presentation_mode`
- **Steps**:
  1. Toggle Do-Not-Disturb on notification daemon (`swaync-client -d -s`).
  2. Fullscreen focus window (`input.py dispatch 'fullscreen 1'`).

### 4. `system_maintenance`
- **Steps**:
  1. Run system upgrade via user zsh alias (`ySyu`).
  2. Clean orphaned packages (`po`).
  3. Clear pacman cache (`pc`).
