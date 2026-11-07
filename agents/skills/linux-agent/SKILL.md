---
name: linux-agent
description: >-
  System governance, maintenance, diagnostics, and cleanup specialist for Arch Linux +
  Omarchy (Hyprland Wayland). Use whenever inspecting system health, diagnosing failed
  systemd services, checking package status/orphans, auditing caches, performing safe
  interactive or dry-run cleanups, checking Omarchy desktop configuration, or generating
  clean structured OS summaries for other AI agents.
---

# Linux Agent (`linux-agent`)

The system governance, inspection, and safe maintenance skill for this **Arch Linux + Omarchy** workstation.

## Core Directives

1. **Clean Summaries for AI Agents:** When called by another agent (Pi, Codex, OpenCode, Claude Code, Antigravity), do NOT dump hundreds of lines of raw `journalctl`, `pacman`, or `systemctl` output into chat context. Use `linux-agent <cmd> --summary` to retrieve concise, token-efficient Markdown summaries.
2. **Approval-Gated Safety (R0–R4):**
   - **R0 (Autonomous):** Read-only inspection, dry-run cache scans, health diagnostics.
   - **R1–R4 (Approval-gated):** Package removals, file deletions, system changes. Never execute destructive operations without a dry-run preview and explicit user approval.
3. **Arch + Omarchy Architecture:**
   - **Never run partial upgrades:** No `pacman -Sy <pkg>`. System upgrades use `omarchy update` or `pacman -Syu`.
   - **Never edit `/usr/share/omarchy/`:** That directory is packaged/read-only. User configurations live in `~/.config/` and themes in `~/.config/omarchy/themes/`.
   - **Dual-source chezmoi:** Public dotfiles in `~/.dotfiles`, private agents/configs in `~/.private-dotfiles`.

---

## Command Reference (`linux-agent`)

The front CLI `linux-agent` (located in `~/.local/bin/linux-agent`) is the single canonical entrypoint for deterministic system operations:

```bash
# 1. System Health & Quick Status
linux-agent status --summary         # Fast Markdown status (Uptime, Load, RAM, GPU, Disk, Failed Units)
linux-agent status --json            # Structured JSON for scripts

# 2. Storage & Cache Governance
linux-agent clean --dry-run          # Scan all caches, calculate sizes, show total reclaimable space (R0)
linux-agent clean --summary          # Compact Markdown table of cleanup candidates
linux-agent clean --interactive      # Interactive prompt per category (TUI mode)
linux-agent clean --target <cat>     # Target specific cache: pacman, aur, dev, desktop, docker, journals, trash

# 3. Toolchain & System Diagnostics
linux-agent doctor                   # Comprehensive check: pacman, mise, uv, pnpm, cargo, Omarchy status
linux-agent sync                     # Canonical system sync: omarchy update + mise install/upgrade/prune

# 4. Package & Service Audits
linux-agent packages --orphans       # List dependency orphans (pacman -Qtdq)
linux-agent packages --foreign       # List foreign / AUR packages (pacman -Qmq)
linux-agent services --failed        # Check failed system and user units (systemctl --failed)
```

---

## Detailed References

For deeper policies and architectural specifications, consult:

- [`references/architecture.md`](references/architecture.md) — M01–M10 governance modules & directory ownership.
- [`references/omarchy-rules.md`](references/omarchy-rules.md) — Omarchy distribution rules, themes, hooks, and desktop integration.
- [`references/cleanup-rules.md`](references/cleanup-rules.md) — Canonical cache classifications (regenerable vs. protected).
- [`references/safety-matrix.md`](references/safety-matrix.md) — R0–R4 risk classifications and dry-run execution protocols.
