# ideas.skill.md
# Daily idea generation and incubation system
# Stored at: ~/.dotfiles/agents/ (symlinked ~/.agents/)
# Invoke: "Run ideas skill" or "idea generation" or "what should I think about"

## Purpose
Bharath's best work comes from detective-style deep thinking. This skill
ensures he generates, captures, evaluates, and incubates ideas daily —
not just during study but as a meta-cognitive practice that compounds.

Ideas are the raw material for: projects, businesses, research directions,
tools, career pivots, interview stories, and personal growth.

---

## Trigger
User says any of:
- "idea time"
- "run ideas skill"
- "what should I think about"
- "rate my idea"
- "review my ideas"
- "I have an idea"

---

## Philosophy

> You don't need more information. You need more thinking time applied to
> the information you already have.

- Quantity first. Quality emerges from volume.
- Write ideas down immediately. Unwritten ideas die.
- Revisit old ideas regularly. Time transforms bad ideas into good ones.
- Cross-pollinate. The best ideas come from connecting two unrelated domains.
- Protect idea time. It's not "wasting time" — it's the highest-leverage activity.

---

## Daily Practice (5-10 min, during 8:00-9:30 PM planning block)

### The 3-Idea Rule
Every evening, write down 3 ideas. Any domain. No quality filter.

Format in `~/til/notelab/ideas.md`:
```markdown
## YYYY-MM-DD

1. **[Category]** Idea title — one-line description
2. **[Category]** Idea title — one-line description
3. **[Category]** Idea title — one-line description
```

### Categories:
- `[Tool]` — something to build (script, app, automation)
- `[Study]` — a better way to learn/practice/remember something
- `[Career]` — job opportunity, portfolio piece, interview angle
- `[Research]` — paper idea, experiment, deeper investigation
- `[Life]` — personal optimization, habit, routine change
- `[Biz]` — product/service/startup concept
- `[Connect]` — connecting two domains in a novel way

### Prompt Starters (when stuck):
- "What frustrated me today that could be automated?"
- "What did I learn today that connects to something I already know?"
- "If I had to build one thing this weekend, what would be most useful?"
- "What question am I avoiding because it's too hard?"
- "What would a 10x version of my current study process look like?"
- "What tool do I wish existed for GATE prep?"
- "What's the most counterintuitive thing I learned recently?"

---

## Weekly Review (Sunday, part of weekly review)

### Rate existing ideas:
Go through unrated ideas in `notelab/ideas.md` and score:

| Score | Meaning | Action |
|-------|---------|--------|
| ★★★ | Exciting + feasible + high impact | Move to `spaces/ideas.md` with full writeup |
| ★★ | Interesting but needs more thought | Keep in notelab, revisit next week |
| ★ | Meh or already exists | Archive or delete |

### Cross-pollination check:
- Look at ideas from different categories side by side
- Ask: "Can idea X from [Tool] solve a problem in [Study]?"
- The best innovations come from this step

### Promote to action:
- Any ★★★ idea that takes < 2 hours → schedule in 10% time window
- Any ★★★ idea that takes > 2 hours → add to `notelab/pending.md` with scope estimate
- Never execute during study blocks — ideas go to the queue

---

## Monthly Incubation Review

Every month, re-read ALL ideas from the past 30 days:
1. Pattern check: what themes keep recurring? That's your subconscious priority.
2. Kill stale ideas: anything unrated for 30 days → archive or delete
3. Idea count: track total ideas generated per month (target: 90+, i.e., 3/day)
4. Best idea of the month: pick one, write a 1-paragraph expansion in `spaces/ideas.md`

---

## Integration with Other Skills

### → gate-study
- Study ideas often emerge during problem-solving. "What if I visualized eigenvalues as X?"
- These go into `[Study]` category and can improve study methodology.

### → health
- Ideas about routine optimization. "What if I meditated while walking?"
- `[Life]` category.

### → career (future)
- Project ideas become portfolio pieces. "Build a GATE DA question generator."
- `[Career]` or `[Tool]` category → add to portfolio backlog.

---

## File Locations

| File | Purpose |
|------|---------|
| `~/til/notelab/ideas.md` | Daily capture (raw, unrated) |
| `~/til/spaces/ideas.md` | Promoted ideas (★★★, with full writeup) |
| `~/til/notelab/capture.md` | Quick sparks mid-task (move to ideas.md in evening) |

---

## Rules
- Never skip idea generation. Even "bad" ideas exercise the muscle.
- 3/day minimum. No maximum.
- Don't execute ideas during study blocks. Capture → queue → 10% window.
- Ideas are private — all files in ~/til/, never in dotfiles.
- Don't overthink the rating. Gut feeling is fine. The point is volume.
- Revisiting old ideas is MORE valuable than generating new ones. Don't just write and forget.
- When an idea keeps coming back after being dismissed, that's signal. Promote it.
