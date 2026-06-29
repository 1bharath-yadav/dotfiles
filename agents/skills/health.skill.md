# health.skill.md

# Physical + mental health tracking and optimization

# Stored at: ~/.dotfiles/agents/ (symlinked ~/.agents/)

# Invoke: "Use health skill" or "check my health routine"

## Purpose

Track and optimize Bharath's physical and mental health routines.
Health = capacity creation. Without it, study hours are low-quality.
This skill treats exercise, meditation, yoga, sleep, and nutrition as
first-class priorities — not optional extras.

---

## Trigger

User says any of:

- "check my health routine"
- "run health skill"
- "how's my health tracking"
- "I'm feeling low energy / tired / unfocused"
- "optimize my health routine"

---

## Phase 0 — Orient

1. Read `~/til/optima.md` — daily schedule (exercise/yoga/meditation blocks).
2. Read `~/til/wiki/schema/MEMORY.md` — any noted health patterns.
3. Check `~/til/spaces/habits/` — existing habit tracking data.

---

## Current Routine (baseline from 2026-06-24)

| Block     | Time      | Activity                        | Purpose                                 |
| --------- | --------- | ------------------------------- | --------------------------------------- |
| Morning   | 6:00–8:00 | Skipping + pushups + meditation | Cardio, strength, mental clarity        |
| Afternoon | 4:00–5:00 | Yoga + meditation               | Reset, flexibility, stress relief       |
| Night     | ~10:00 PM | Sleep target                    | 8 hrs minimum for cognitive performance |

### Targets

- **Sleep**: 8 hours. Alarm to go to sleep at 10 PM, not to wake up.
- **Exercise**: 6 days/week minimum. Sunday can be rest or light yoga.
- **Meditation**: 2x daily (morning + afternoon). 15-30 min each.
- **Hydration**: Hot water regularly. Reduces hunger/distraction.
- **Nutrition**: Eat enough. Skipping meals = brain fog = wasted study hours.

---

## Phase 1 — Check-in

When invoked, ask these 5 questions:

1. How many hours did you sleep last night?
2. Did you exercise this morning? What did you do?
3. Did you meditate (morning and/or afternoon)?
4. Energy level right now? (1-5)
5. Any physical issues? (back pain, headache, eye strain, etc.)

---

## Phase 2 — Analyze & Adjust

### Low energy patterns:

| Symptom                 | Likely Cause                   | Fix                                                  |
| ----------------------- | ------------------------------ | ---------------------------------------------------- |
| Tired by 2 PM           | Poor sleep or skipped exercise | Sleep 8 hrs. Don't skip morning block.               |
| Can't focus after lunch | Overeating or heavy food       | Lighter lunch. Hot water.                            |
| Eye strain / headache   | Screen time without breaks     | 20-20-20 rule: every 20 min, look 20ft away, 20 sec. |
| General fatigue         | Dehydration or sedentary       | Walk 5 min every hour. Drink water.                  |
| Irritable / anxious     | Skipped meditation             | Even 5 min meditation resets. Don't skip entirely.   |
| Back/neck pain          | Posture during study           | Stand-up breaks every 45 min. Stretch.               |

### If exercise skipped > 2 days:

- Flag it. Don't let it slide. Capacity degrades fast.
- Suggest: even 15 min of pushups + stretching is better than zero.

### If meditation skipped > 2 days:

- Flag it. Irritability and focus loss follow within 48 hrs.
- Suggest: 5 min breathing exercise as minimum viable meditation.

---

## Phase 3 — Track

### Weekly health score (Sunday review):

```markdown
## Health — Week of YYYY-MM-DD

| Day | Sleep (hrs) | Exercise | Meditation | Energy (1-5) | Notes |
| --- | ----------- | -------- | ---------- | ------------ | ----- |
| Mon |             | ✅/❌    | ✅/❌      |              |       |
| Tue |             | ✅/❌    | ✅/❌      |              |       |
| Wed |             | ✅/❌    | ✅/❌      |              |       |
| Thu |             | ✅/❌    | ✅/❌      |              |       |
| Fri |             | ✅/❌    | ✅/❌      |              |       |
| Sat |             | ✅/❌    | ✅/❌      |              |       |
| Sun |             | ✅/❌    | ✅/❌      |              |       |

**Avg sleep**: X hrs | **Exercise days**: X/7 | **Meditation days**: X/7
```

Log to: `~/til/spaces/habits/YYYY-Www-health.md`

### Monthly pattern check:

- Compare 4 weekly scores. Trend up, down, or flat?
- Correlate with study productivity (mock scores, PYQs solved).
- If health scores drop and study output drops → health is the bottleneck, not study strategy.

---

## Phase 4 — Optimize

### Progressive overload (monthly):

- Month 1: Establish routine. Consistency > intensity.
- Month 2: If consistent, add: 5 more pushups, 5 more min meditation.
- Month 3+: Consider adding: running, cycling, or gym if accessible.

### Study-health integration:

- **Pre-study ritual**: 5 min breathing before Block 1 (9:30 AM). Primes focus.
- **Break movement**: During 1:00-1:20 break, walk outside. Sunlight + movement.
- **Evening wind-down**: After 9:30 PM planning block, no screens. Read or journal.
- **Sleep hygiene**: Screen to grayscale after 10 PM (Hyprland shader or redshift).

---

## Rules

- Never sacrifice sleep for study. 6 hours sleep + 7 hours study < 8 hours sleep + 5 hours study.
- Never treat exercise/meditation as "optional" or "if I have time."
- If user reports skipping health blocks to study more → push back. This is a trap.
- Track trends, not perfection. 5/7 days exercising is sustainable. 7/7 isn't.
- Physical health data is private — log in ~/til/, never in dotfiles.
