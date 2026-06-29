# news-digest.skill.md
# Weekly curated news digest — 3 hrs/week budget
# Stored at: ~/.dotfiles/agents/ (symlinked ~/.agents/)
# Invoke: "Run news digest" or "what happened this week"

## Purpose
Deliver a personalized, high-signal weekly news digest in ≤30 min reading time.
Bharath allocates 3 hrs/week for world awareness — this skill ensures that time
produces maximum signal with zero doomscrolling.

---

## Trigger
User says any of:
- "what happened this week"
- "run news digest"
- "weekly news"
- "catch me up on the world"

---

## Time Budget
- **3 hrs/week total**: ~25 min/day or one 3-hr Sunday block
- Agent work: search + summarise = save Bharath's reading time
- Output: one digest file per week, ≤ 500 words per section

---

## Phase 0 — Personalization Profile

### Topics (ranked by relevance to Bharath):

| Priority | Topic | Why |
|----------|-------|-----|
| 🔴 Must | AI/ML breakthroughs, LLM developments | Core career domain |
| 🔴 Must | Data Science industry & job market | Active job hunting |
| 🟡 High | GATE / Indian education policy | Directly affects goals |
| 🟡 High | Open source / Linux ecosystem | Professional identity |
| 🟡 High | India tech + startup ecosystem | Career context |
| 🟢 Read if time | Science breakthroughs (physics, quantum) | Personal interest |
| 🟢 Read if time | Philosophy, consciousness, meditation research | Spiritual seeker |
| ⚫ Skip | Celebrity news, sports, politics drama, crypto hype | Zero signal |

---

## Phase 1 — Source & Search

Weekly search queries (run in order):
1. `AI ML breakthroughs this week {YYYY}` — what's new in AI
2. `LLM agent developments this week` — agent ecosystem updates
3. `data science job market India {YYYY}` — career landscape
4. `GATE 2027 updates notifications` — exam-related news
5. `open source releases this week` — Linux, tooling, languages
6. `India technology startups this week` — ecosystem context
7. `physics breakthroughs this week` — if time permits
8. `meditation consciousness research` — if time permits

### Sources to prioritize:
- Hacker News top stories
- arXiv highlights (cs.AI, cs.LG, stat.ML)
- The Batch (Andrew Ng's newsletter)
- Indian tech media (Inc42, YourStory — headlines only)
- r/MachineLearning, r/LocalLLaMA highlights
- GATE official notifications

### Sources to skip:
- Mainstream news (noise:signal too high)
- Twitter/X threads (addictive, low density)
- YouTube (time sink — summarise if critical)

---

## Phase 2 — Curate & Summarise

For each item:
1. One-line summary (what happened)
2. Why it matters to Bharath (1 sentence)
3. Action needed? (read paper / update resume / note for interview / none)
4. Link to source

### Scoring:
- 🔴 Must read = directly affects goals or career
- 🟡 Good to know = context, trends
- 🟢 Optional = interesting but not urgent
- ⚫ Skip = noise

---

## Phase 3 — Output

### Digest file
Path: `~/til/wiki/social/digest-YYYY-Www.md`

```markdown
---
title: "Weekly Digest — Week W{XX}, {YYYY}"
type: digest
week: YYYY-Www
generated: YYYY-MM-DD
---

# Weekly Digest — W{XX}

## 🔴 Must Know
1. **[Title]** — One-line summary. *Why it matters*. [Source](url)
2. ...

## 🟡 Good to Know
1. **[Title]** — One-line summary. [Source](url)
2. ...

## 🟢 Optional Reads
1. **[Title]** — One-line summary. [Source](url)

## Action Items
- [ ] Read: [specific paper/article]
- [ ] Update resume with: [specific skill/project]
- [ ] Note for interviews: [specific talking point]
```

### Delivery
- Generate digest on Sunday during weekly review block (or on demand)
- Keep in `wiki/social/` for searchability
- Max 10 items in Must Know, 5 in Good to Know, 5 in Optional

---

## Rules
- Never include clickbait or engagement-optimized content
- If nothing important happened in a category, say "quiet week" — don't pad
- Time-box research to 1 hour max per digest
- Don't chase every arXiv paper — only ones with practical impact or paradigm shifts
- Job market section: focus on what companies are hiring for, not layoff doom
- Everything stays in ~/til/ (private), never in dotfiles
