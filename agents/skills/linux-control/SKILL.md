---
name: linux-control
description: OS-aware desktop input automation and locator skill for Arch Linux + Hyprland + Wayland. Controls mouse coordinates, clicks, typing, hotkey shortcuts, window focus, scratchpads, screenshots, OCR, and 5-tier element locators via CLI tools (`ydotool`, `wtype`, `grim`, `hyprctl`). Trigger whenever the user asks to click a button, focus/move a window, type into a GUI app, take a screenshot, locate UI text, toggle scratchpads, or perform low-level Wayland GUI actions.
---

# Linux Control (Arch Linux + Hyprland + Wayland)

Native GUI input control and 5-tier element locator skill leveraging Wayland CLI utilities (`ydotool`, `wtype`, `grim`, `slurp`, `hyprctl`).

---

## 1. Capability & Capability Probe

Run capability probe to verify installed system tools before executing inputs:
```bash
python3 ~/.dotfiles/agents/skills/linux-control/scripts/locator.py probe
```

---

## 2. Bundled Scripts & CLI Tools

### A. Element Locator & State (`locator.py`)
```bash
# Query active window and monitor layout metadata
python3 ~/.dotfiles/agents/skills/linux-control/scripts/locator.py state

# Search for UI text or button using 5-tier locator hierarchy
python3 ~/.dotfiles/agents/skills/linux-control/scripts/locator.py locate "Login"
```

### B. Hardware Input & Hyprland Dispatches (`input.py`)
```bash
# Move cursor to absolute screen coordinates
python3 ~/.dotfiles/agents/skills/linux-control/scripts/input.py move 500 300

# Click mouse button (left/right/middle) at optional coordinates
python3 ~/.dotfiles/agents/skills/linux-control/scripts/input.py click 500 300 left

# Type string into focused application via wtype
python3 ~/.dotfiles/agents/skills/linux-control/scripts/input.py type "Hello World"

# Write text to Wayland clipboard and trigger Ctrl+V paste
python3 ~/.dotfiles/agents/skills/linux-control/scripts/input.py paste "Clipboard Text"

# Execute Hyprland Lua dispatch expression (scratchpads / focus / workspaces)
python3 ~/.dotfiles/agents/skills/linux-control/scripts/input.py dispatch 'hl.dsp.workspace.toggle_special("obsidian")'
python3 ~/.dotfiles/agents/skills/linux-control/scripts/input.py dispatch 'hl.dsp.workspace.toggle_special("kitty")'
python3 ~/.dotfiles/agents/skills/linux-control/scripts/input.py dispatch 'hl.dsp.workspace.toggle_special("yazi")'
```

### C. Visual Capture & OCR (`capture.py`)
```bash
# Fullscreen capture with SHA256 region hash
python3 ~/.dotfiles/agents/skills/linux-control/scripts/capture.py full /tmp/screen.png

# OCR bounding box text extraction
python3 ~/.dotfiles/agents/skills/linux-control/scripts/capture.py ocr /tmp/screen.png
```

---

## 3. Locator Fallback Tiers & Safety Matrix

- For tier fallback details, read [`references/locator-tiers.md`](./references/locator-tiers.md).
- For action confirmation rules (`READ`, `SAFE`, `CONFIRM`, `DANGEROUS`), read [`references/policy.md`](./references/policy.md).
