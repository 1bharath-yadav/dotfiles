# Safety Matrix & Change Lifecycle

## Risk Levels (R0–R4)

| Level | Classification | Examples | Approval Rule |
| :--- | :--- | :--- | :--- |
| **R0** | Read-Only | Inventory, disk analysis, checking logs, dry-run scans | Autonomous |
| **R1** | Proposal / Draft | Generating plans, proposed configs, audit reports | Autonomous creation; approval before apply |
| **R2** | Safe Mutation | Moving files, renaming directories, changing dotfiles | Explicit user approval |
| **R3** | Deletion / Prune | Pruning caches, removing orphaned packages, emptying trash | Explicit user approval + dry-run preview |
| **R4** | High Impact | Partitioning, formatting, kernel/bootloader edits, systemd mask | Separate explicit authorization + recovery plan |

## Change Lifecycle Protocol

1. **Discover:** Gather factual state via native inspection (`pacman`, `systemctl`, `du`).
2. **Classify:** Determine ownership, impact, and risk tier (R0–R4).
3. **Plan & Dry-Run:** Generate exact commands and calculate reclaimed space or changed lines.
4. **Approve:** Present summary to user. Stop if rejected.
5. **Execute:** Execute constrained, deterministic commands (never unconstrained `rm -rf *`).
6. **Verify:** Confirm expected target state matches actual filesystem state.
7. **Record:** Append operation record to audit log in `~/.local/share/linux-agent/logs/`.
