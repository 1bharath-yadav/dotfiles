# Security Policy & Permission Matrix

This document defines security boundaries, local keystroke-injection risks (`ydotoold`), and confirmation rules for `linux-control`.

---

## 1. Local Keystroke-Injection Security (`ydotoold`)
- `ydotool` communicates with `ydotoold` daemon over `/run/user/$UID/.ydotool_socket` or `/dev/uinput`.
- Access is restricted to users in the `input` group (`archer`).
- **Security Boundary**: `ydotool` has full passwordless keystroke injection privileges. All automated typing and shortcut execution must be logged to local journal.
- **Privacy Rule**: Execution logs containing sensitive data (passwords, tokens) must be saved to private storage (`~/til/wiki/schema/`), NEVER to the public `~/.dotfiles` repository.

---

## 2. Action Confirmation Policy

Reuses the established dotfiles delegation patterns:

| Level | Actions | Confirmation Requirement |
|---|---|---|
| **READ** | `capture.py`, `locator.py probe`, `locator.py state`, reading state | Auto-execute (No confirmation needed) |
| **SAFE** | Focus window, switch workspace, toggle scratchpad, move cursor | Auto-execute (No confirmation needed) |
| **CONFIRM** | Form submission, file edits outside `agents/`, git commits, app launch | Requires User Confirmation |
| **DANGEROUS** | System poweroff/reboot, file deletions (`rm -rf`), config rewrites | Requires Confirmation + Explicit Warning |

---

## 3. Scope of Reversible Actions (Rollback)
Only the following operations support automated rollback/undo:
- Restoring Wayland clipboard (`wl-copy` previous content).
- Closing GUI windows spawned directly by the current task sequence.
- Invoking application `Ctrl+Z` undo keystrokes where supported by active input field.
