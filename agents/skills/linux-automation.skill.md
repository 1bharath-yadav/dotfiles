# linux-automation.skill.md
# Stored at: ~/.dotfiles/agents/skills/linux-automation.skill.md (public repo)
# Primary implementation: ~/.dotfiles/agents/skills/linux-automation/SKILL.md

---
name: linux-automation
description: Intent-based desktop automation, high-level workflow macros, event-driven orchestration, and composite desktop routines for Arch Linux + Hyprland. Handles macros like `start_coding`, `clean_desktop`, `open_research_environment`, `presentation_mode`, `system_maintenance`, `daily_startup`, `daily_shutdown`, `record_session`, and `dictation_note`. Reads semantic state resources (`desktop://`) and orchestrates multi-step desktop workflows deterministically using Hyprland compositor primitives and Linux subsystem integrations. Trigger whenever the user asks for desktop routines, workflow automation, workspace setup, macro actions, or multi-step Arch Linux system routines.
---

# Linux Automation (Arch Linux + Hyprland + Wayland)

High-level intent macros, workflow orchestration, and event-driven automation for Arch Linux + Hyprland.

See full skill implementation reference at [`agents/skills/linux-automation/SKILL.md`](./linux-automation/SKILL.md).

## Quick Macro Reference
- **`start_coding`**: Workspace 1 setup + Kitty + Obsidian scratchpad.
- **`clean_desktop`**: Unfloat active floating windows & close scratchpads.
- **`open_research_environment`**: Zen Browser + Workspace 2 + Obsidian scratchpad.
- **`presentation_mode`**: Toggle Do-Not-Disturb + Fullscreen active window.
- **`system_maintenance`**: `yay -Syu` (`ySyu`), clean orphans (`po`), clear cache (`pc`), inspect `journalctl`.
- **`dictation_note`**: Dictation toggle (`SUPER+H`) + Paste into note.

## State Resources
- `desktop://focused-window` (`hyprctl activewindow -j`)
- `desktop://windows` (`hyprctl clients -j`)
- `desktop://workspaces` (`hyprctl workspaces -j`)
- `desktop://clipboard` (`wl-paste`)
