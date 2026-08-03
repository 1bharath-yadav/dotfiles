---
name: linux-automation
description: High-level intent macros, multi-step GUI workflow orchestration, resource lock scheduling, and event-driven automation for Arch Linux + Hyprland. Orchestrates complex routines like `start_coding`, `open_research_environment`, `presentation_mode`, and `system_maintenance` using hardware mutex locks (`scheduler.py`) and watchdog monitoring (`watchdog.py`). Trigger whenever the user requests high-level workspace setup, multi-step app automation, desktop workflow macros, or background routine execution.
---

# Linux Automation (Arch Linux + Hyprland + Wayland)

High-level workflow macro engine and resource-locking scheduler for Arch Linux + Hyprland.

---

## 1. Hardware Mutex Locking & Scheduling (`scheduler.py`)

Prevent concurrent input collisions by acquiring flock-based hardware locks:

```bash
# Acquire lock before multi-step mouse or keyboard automation
python3 ~/.dotfiles/agents/skills/linux-automation/scripts/scheduler.py acquire mouse 5.0
python3 ~/.dotfiles/agents/skills/linux-automation/scripts/scheduler.py acquire keyboard 5.0

# Release lock when workflow completes
python3 ~/.dotfiles/agents/skills/linux-automation/scripts/scheduler.py release mouse
python3 ~/.dotfiles/agents/skills/linux-automation/scripts/scheduler.py release keyboard
```

---

## 2. Watchdog Monitoring & Recovery (`watchdog.py`)

Check process state or recover hung GUI applications:

```bash
# Check if process PID is active
python3 ~/.dotfiles/agents/skills/linux-automation/scripts/watchdog.py check_pid 1234

# Attempt recovery for modal popup or hung window
python3 ~/.dotfiles/agents/skills/linux-automation/scripts/watchdog.py recover_app "zen-browser"
```

---

## 3. High-Level Macro Routines

| Macro Intent | Action Sequence |
|---|---|
| **`start_coding`** | Acquire lock → Workspace 1 → Toggle Kitty & Obsidian scratchpads → Release lock |
| **`open_research_environment`** | Acquire lock → Launch Zen Browser → Toggle Obsidian scratchpad (`SUPER+ALT+O`) |
| **`presentation_mode`** | Enable Do-Not-Disturb (`swaync-client -d -s`) → Fullscreen focused window |
| **`system_maintenance`** | Upgrade repos/AUR (`ySyu`) → Clean orphans (`po`) → Clear package cache (`pc`) |

For complete workflow step definitions, read [`references/macros.md`](./references/macros.md).

---

## 4. Test Cases & Evals

Test prompts and assertion rules are maintained in [`evals/evals.json`](./evals/evals.json).
