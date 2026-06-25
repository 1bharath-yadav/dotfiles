# config-refresh.skill.md
# Generalized dotfile/package config refresh skill
# Stored at: ~/.dotfiles/agents/ (symlinked from ~/.agents/)
# Invoke: "Use config-refresh skill for <package>"

## Purpose
Deep-research and apply optimized config updates for any CLI/TUI/desktop package.
Runs every ~4 months per package. Produces a human-readable usage.md so the user
understands every config decision, not just the outcome.

---

## Trigger
User says any of:
- "refresh config for <pkg>"
- "update my <pkg> setup"
- "deep update <pkg>"
- "run config-refresh for <pkg>"

---

## Phase 0 — Orient (always first)
1. Read AGENTS.md → understand env (arch, chezmoi, package-manager layers).
2. Read `~/.dotfiles/docs/packages/<pkg>/usage.md` if it exists (prior state).
3. Read `~/.dotfiles/docs/refresh-log.md` → check last-refreshed date for pkg.
4. Locate current config in dotfiles: `find ~/.dotfiles -name '*<pkg>*' -type f`.
5. Read the actual live config from `~/.config/<pkg>/` via Desktop Commander.

---

## Phase 1 — Research (web search)
Search in this order, most specific first:
1. `<pkg> changelog <current_year>` — what actually changed upstream
2. `<pkg> config best practices <current_year>` — community consensus
3. `<pkg> arch linux tips` — distro-specific wins
4. `<pkg> deprecated options` — find dead config lines
5. `<pkg> performance optimization` — only if relevant (editors, shells, WMs)

Collect findings as a short bullet list (max 15 items). Discard noise.

---

## Phase 2 — Diff & Decide
For each finding:
- KEEP   → already configured, good
- ADD    → missing but valuable
- REMOVE → deprecated / dead / conflicting
- CHANGE → better default or newer syntax

Present the diff table to the user before touching any files:

| Option/Setting | Action | Reason |
|---|---|---|
| `option_name` | ADD/REMOVE/CHANGE/KEEP | one-line reason |

Wait for user confirmation (y/edit/skip) before Phase 3.

---

## Phase 3 — Apply
- Edit dotfiles source only (never live `~/.config` directly).
- Use Desktop Commander edit_block for surgical edits; write_file only for full rewrites.
- chezmoi apply after all edits: `chezmoi apply --verbose`.
- Verify no broken symlinks: `chezmoi verify`.

---

## Phase 4 — Document
Write/overwrite `~/.dotfiles/docs/packages/<pkg>/usage.md` using the schema below.
Then append one line to `~/.dotfiles/docs/refresh-log.md`.

---

## Phase 5 — Commit
```
git -C ~/.dotfiles add docs/packages/<pkg>/usage.md <changed-config-files>
git -C ~/.dotfiles commit -m "chore(<pkg>): config refresh $(date +%Y-%m)"
git -C ~/.dotfiles push origin chizmoi
```

---

## usage.md Schema
Path: `~/.dotfiles/docs/packages/<pkg>/usage.md`

```markdown
# <pkg>
> One-sentence description of what this tool does for me.

## Last Refreshed
YYYY-MM-DD

## Why I Use It
One paragraph — the job it does that nothing else handles as well.

## Config Choices
Each non-default setting, one line each:
- `setting = value` — why (source: upstream docs / community / personal)

## 20% That Matters (daily usage)
The keybinds, commands, or flags used 80% of the time:
| What | How |
|---|---|
| action | key/command |

## Known Quirks
Edge cases, workarounds, or gotchas discovered.

## Skipped / Rejected Options
Things researched but deliberately not enabled, and why.

## Sources
- upstream changelog URL
- any blog/wiki referenced
```

---

## refresh-log.md Schema
Path: `~/.dotfiles/docs/refresh-log.md`

Append one line per run:
```
YYYY-MM-DD | <pkg> | <version-at-refresh> | agent: <model/session-id>
```

Warn if any package line is >120 days old.

---

## Rules
- Never rewrite a working config completely. Surgical edits only.
- If upstream changed a default you relied on, always flag it explicitly.
- usage.md is the source of truth for "why". Keep it under 80 lines.
- Config files live in chezmoi source (`~/.dotfiles/`), not live paths.
- Skill is package-agnostic: works for zsh, nvim, hyprland, tmux, git, starship, etc.
- Always confirm diff table with user before applying.
