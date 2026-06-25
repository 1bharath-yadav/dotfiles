# skill.md — Master Agent Skill File
# Stored at: ~/.dotfiles/agents/skill.md (public repo)
# When a section outgrows this file, split into <name>.skill.md and reference here.

## Purpose
Central skill registry for AI agents working with this dotfiles environment.
Agents read this to understand available skills, delegation patterns, and operating rules.

---

## Available Skills

### config-refresh
- **File**: [config-refresh.skill.md](./config-refresh.skill.md)
- **Trigger**: "refresh config for <pkg>" / "deep update <pkg>"
- **Purpose**: Deep-research and apply optimized config updates for any CLI/TUI/desktop package
- **Cadence**: Every ~4 months per package
- **Output**: Updated config + `docs/packages/<pkg>/usage.md`

### gate-study
- **File**: [gate-study.skill.md](./gate-study.skill.md)
- **Trigger**: "optimize my GATE plan" / "what should I study today"
- **Purpose**: Manage, optimize, and evolve GATE DA preparation — sprint scheduling, mock analysis, daily targets
- **Reads**: `~/til/study.md`, `~/til/schedule.json`, `~/til/optima.md`
- **Output**: Updated study plan, mock analysis, daily/weekly study targets

### health
- **File**: [health.skill.md](./health.skill.md)
- **Trigger**: "check my health routine" / "I'm feeling low energy"
- **Purpose**: Track exercise, meditation, sleep, nutrition as capacity-creation activities
- **Output**: Weekly health scores in `~/til/spaces/habits/`

### news-digest
- **File**: [news-digest.skill.md](./news-digest.skill.md)
- **Trigger**: "what happened this week" / "run news digest"
- **Purpose**: 3 hrs/week curated news — AI/ML, job market, open source, science
- **Output**: Weekly digest in `~/til/wiki/social/digest-YYYY-Www.md`

### ideas
- **File**: [ideas.skill.md](./ideas.skill.md)
- **Trigger**: "idea time" / "rate my idea" / "review my ideas"
- **Purpose**: Daily 3-idea generation practice, weekly rating, monthly incubation review
- **Output**: Ideas in `~/til/notelab/ideas.md`, promoted to `~/til/spaces/ideas.md`
---

## Delegation Patterns

### How Bharath delegates to agents
1. Batches questions/thoughts during study blocks (writes them down)
2. Processes batch in 10% time window
3. Expects: quick summary of what was done, no manual reading required
4. Prefers: discuss → plan → confirm → implement (for anything non-trivial)

### What agents should auto-handle (no confirmation needed)
- Reading files for context
- Searching documentation
- Generating summaries
- Updating MEMORY.md session log
- Updating optima.md status log

### What requires confirmation
- Any file write outside agents/, docs/
- Git commits and pushes
- Config changes to live dotfiles
- Any external write (email, calendar, API calls)
- Structural changes to the system (new files, new patterns)

---

## Operating Rules

### File Locations
| File | Path | Visibility | Purpose |
|------|------|-----------|---------|
| This file | `~/.dotfiles/agents/skill.md` | Public (GitHub) | Skill registry |
| Sub-skills | `~/.dotfiles/agents/*.skill.md` | Public | Individual skill definitions |
| USER.md | `~/til/wiki/schema/USER.md` | Private | Personal details, schedule, context |
| MEMORY.md | `~/til/wiki/schema/MEMORY.md` | Private | Cross-agent shared memory |
| SOUL.md | `~/til/wiki/schema/SOUL.md` | Private | Agent persona + routing rules |
| optima.md | `~/til/optima.md` | Private | Long-term goals + current status |
| study.md | `~/til/study.md` | Private | GATE study plan + schedule |
| Anki cards | `~/til/vault/notes/` | Private | Study flashcards synced to Anki |
| Agent docs | `~/.dotfiles/docs/skills/` | Public | Usage guides for future self |

### Session Start Reads (for any agent)
1. `~/.dotfiles/agents/skill.md` (this file) — what skills exist
2. `~/til/wiki/schema/USER.md` — who is Bharath, current state
3. `~/til/wiki/schema/MEMORY.md` — what happened recently
4. `~/til/optima.md` — summary block (first 10 lines) for current priorities

### Chezmoi Rules
- Dotfiles source is `~/.dotfiles/`, never edit live `~/.config/` directly
- Branch: `chizmoi`
- New root files not prefixed `dot_`/`private_` must be added to `.chezmoiignore`
- `agents/` and `docs/` are already in `.chezmoiignore`

### Commit Convention
```
git status --short
git add <specific-files>
git commit -m "<type>: <why>"
git push origin chizmoi
```

### Privacy Rules
- `~/.dotfiles` is public on GitHub — NO private data in agents/ or docs/
- Private data goes in `~/til/` (not pushed to GitHub)
- Never commit plaintext secrets or private keys
- Encrypt repo secrets as `*.age` (native age first, ssh fallback)

---

## Tracking (planned)

- **Anki stats**: via AnkiConnect (port 8765) — script to build
- **Git commits**: `git log --oneline --since` on dotfiles and til repos
- **Study time**: manual log in `~/til/notelab/capture.md`
- **Config refresh**: logged in `~/.dotfiles/docs/refresh-log.md`

---

## Future Skills (split when needed)

When any section below exceeds ~30 lines, extract to `<name>.skill.md`:

- **weekly-review**: Sunday review ritual, what to check, where to log
