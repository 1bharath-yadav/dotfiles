# Agent Usage Guide

> How to operate AI agents effectively without re-reading manuals.
> Written so future-Bharath can pick this up cold.

---

## Quick Reference

### Starting a Session (any agent)

Tell the agent:
```
Read ~/.dotfiles/agents/skill.md, then ~/til/wiki/schema/USER.md, 
then ~/til/wiki/schema/MEMORY.md, then first 10 lines of ~/til/optima.md.
```

Or shorter: "Read my skill.md and context files, then help me with X."

The agent now knows: who you are, what you're working on, what happened last session, what skills exist.

---

## Agent Roster

| Agent | Best For | Access |
|-------|----------|--------|
| **Antigravity (Gemini)** | IDE-integrated coding, file edits, system builds, browser tasks | VS Code sidebar |
| **Claude** | Deep reasoning, planning, writing, research | claude.ai or API |
| **Codex** | Code generation, debugging, quick scripts | CLI or IDE |
| **Ollama** | Local/offline queries, privacy-sensitive tasks | Local API |

### Which agent for what?

- **Config refresh**: Any agent — invoke with "use config-refresh skill for <pkg>"
- **Study planning**: Claude or Antigravity — needs reasoning about priorities
- **Quick script**: Codex — fastest for one-off code
- **File system ops**: Antigravity — has direct file access in IDE
- **Private questions**: Ollama — stays local

---

## Delegation Protocol

### The 10% Rule
You have ~1.5 hrs/day for non-study tasks. Use agents efficiently:

1. **During study**: Write questions/tasks in `notelab/capture.md` (don't context-switch)
2. **In 10% window**: Open agent, paste batch, get answers
3. **For async tasks**: Tell agent to do it, confirm result later

### What to delegate
- Config updates and research → config-refresh skill
- Summarising articles/docs → any agent
- Formatting/structuring notes → any agent
- Script writing → Codex or Antigravity
- System maintenance → Antigravity (has file access)

### What NOT to delegate
- Understanding GATE concepts (you need to learn, not the agent)
- Anki card content decisions (only you know what you got wrong)
- Schedule adherence (no agent can make you sit down)

---

## System Files Map

```
~/.dotfiles/agents/
  skill.md              ← master skill registry (START HERE)
  config-refresh.skill.md ← config refresh workflow
  (future: gate-study.skill.md, anki-cards.skill.md, etc.)

~/.dotfiles/docs/
  skills/agent-usage.md ← this file
  packages/<pkg>/usage.md ← per-package config docs
  refresh-log.md        ← config refresh history

~/til/
  optima.md             ← goals + status (10-line summary at top)
  wiki/schema/
    USER.md             ← identity, schedule, context
    MEMORY.md           ← cross-agent shared memory
    SOUL.md             ← agent persona (for llmwiki/Hermes)
  notelab/
    capture.md          ← batch questions here during study
    pending.md          ← backlog tasks
    plan.md             ← subject-wise study plan
  vault/notes/          ← Anki flashcards by subject
```

---

## Maintenance

- **MEMORY.md**: Agents auto-update session log. You review weekly.
- **optima.md**: Agents append to status log. You review/edit the summary when priorities shift.
- **skill.md**: You update when adding new skills or changing rules.
- **This file**: Update when you discover better agent workflows.
