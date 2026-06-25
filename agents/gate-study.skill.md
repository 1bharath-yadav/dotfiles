# gate-study.skill.md
# GATE DA preparation workflow and study plan optimizer
# Stored at: ~/.dotfiles/agents/ (symlinked ~/.agents/)
# Invoke: "Use gate-study skill" or "optimize my GATE plan"

## Purpose
Manage, optimize, and evolve Bharath's GATE Data Science & AI preparation.
Reads current study state, tracks progress, adjusts sprint priorities based on
performance data, and ensures the study plan stays aligned with reality.

---

## Trigger
User says any of:
- "optimize my GATE plan"
- "update gate study"
- "run gate-study skill"
- "what should I study today/this week"
- "analyze my mock test results"

---

## Phase 0 — Orient

1. Read `~/til/study.md` — current strategy, phase, sprint schedule.
2. Read `~/til/optima.md` — summary block for current priorities.
3. Read `~/til/wiki/schema/MEMORY.md` — last session context, decisions.
4. Read `~/til/schedule.json` — calendar structure, sprint metadata.
5. Check `~/til/vault/notes/` — which subjects have actual Anki content.
6. If in Phase 3: check mock test results (user provides or in notelab).

---

## Phase 1 — Diagnose Current State

### If diagnostic not yet done:
- Remind: "Take the GATE DA 2025 paper cold. 3 hours. Score after."
- Provide paper link if needed.
- After scoring, help build heatmap.

### If diagnostic done:
- Read heatmap from `~/til/study.md` or user input.
- Calculate: `priority_score = GATE_weightage × weakness_level` per subject.
- Reorder sprint schedule if needed.

### If mid-sprint:
- Ask: "What did you cover this week? What felt weak?"
- Cross-reference with sprint target in study.md.
- Identify: ahead/behind/on-track per subject.

---

## Phase 2 — Optimize Plan

### Weekly optimization (Sunday evening or on-demand):
1. Score the week: which subjects got time, which didn't.
2. Check Anki card count per subject — proxy for mistake-based learning.
3. If a sprint is behind → extend by 2-3 days, compress next sprint.
4. If IITM quiz approaching (< 7 days) → shift primary to PDSA/DBMS.
5. Update `~/til/study.md` sprint table with actual dates.
6. Update `~/til/schedule.json` if calendar blocks need adjustment.

### Monthly optimization:
1. Review monthly milestone in study.md — hit or missed?
2. Recalculate subject weightage × weakness from latest mock/PYQ data.
3. Adjust Phase 3 start date if Phase 2 needs more time.
4. Update optima.md status log.

---

## Phase 3 — Mock Test Analysis

When user provides mock test results:
1. Parse score breakdown by subject.
2. Compare to previous mock (if exists) — show delta.
3. Categorise errors: conceptual gap / silly mistake / time pressure / blank.
4. For conceptual gaps → identify specific subtopic → add to next week's revision.
5. For time pressure → suggest practice strategy (timed mini-sets).
6. Create summary card in Anki for each conceptual error.
7. Update MEMORY.md with mock score and trend.

### Mock analysis template:
```markdown
## Mock Test — YYYY-MM-DD
| Subject | Attempted | Correct | Wrong | Marks | Notes |
|---------|-----------|---------|-------|-------|-------|
| Prob & Stats | /X | | | | |
| ML | /X | | | | |
| Prog & DSA | /X | | | | |
| Linear Algebra | /X | | | | |
| DBMS | /X | | | | |
| AI | /X | | | | |
| Calculus & Opt | /X | | | | |
| GA | /X | | | | |
| **Total** | **/65** | | | **/100** | |
```

---

## Phase 4 — Generate Study Targets

Output format for "what should I study today/this week":
```
TODAY (Tue, Jul 8 — Week 2: Linear Algebra)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
09:30–11:30  Eigenvalues & eigenvectors — watch lecture for weak spots only
11:30–13:00  Gate Overflow PYQs: Linear Algebra → eigenvalue problems
14:00–16:00  IITM PDSA: Week 3 content
17:00–19:00  Mixed PYQs: Prob & Stats + Linear Algebra
20:00–21:30  Anki review + plan tomorrow

RULE: 30 min max per problem. Read solution if stuck.
```

---

## Rules
- Never suggest re-listening to full lectures. Only weak subtopics.
- Always tie recommendations to GATE weightage data.
- Track progress in study.md, not in separate files.
- When IITM exam < 7 days away, IITM takes primary slot.
- Be honest about whether the plan is working. If 3 weeks pass with no PYQs solved, flag it.
- Sprint reordering requires showing the reasoning (weightage × weakness).
