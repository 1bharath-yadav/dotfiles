---
subject: "Quantitative Aptitude"
topic: "Numerical Computation and Estimation"
title: "Clocks — Angle and Time Problems"
tags: [anki, study, gate_da]
---

# Clocks — Hour Hand / Minute Hand Angle Problems

> [!abstract] One-line summary
> Clock problems are relative-speed problems: the minute hand gains 5.5°/min on the hour hand, so almost every question reduces to $\text{time} = \text{angle} \div 5.5$.

## Core Definitions
**Hand speeds:**
- Minute hand (MH): $360°/60\text{min} = 6°/\text{min}$
- Hour hand (HH): $360°/(12 \times 60) = 0.5°/\text{min}$
- **Relative speed (MH relative to HH)** = $6 - 0.5 = \boxed{5.5°/\text{min}}$ ⭐

**Two things needed to solve any clock problem:**
1. Relative speed = relative position (angle) ÷ relative time
2. Intuition of *which* hand to "freeze" and rotate the other by 5.5°/min relative to it

## Time → Angle (given a clock time, find angle between hands)
> [!tip] ⭐ GATE PRIORITY — general formula
> $$\theta = \left| 30H - 5.5M \right|$$
> where $H$ = hour (0-11), $M$ = minutes. If result > 180°, use $360° - \theta$ (reflex angle) for the "other side" angle.

> [!example] Worked examples (from notes)
> - 5:00 → $30(5) - 5.5(0) = 150°$
> - 10:15 → $|300 - 82.5| = 217.5°$ → reflex = $360-217.5 = 142.5°$
> - 5:30 → $|150 - 165| = 15°$
> - 3:15 → $|90 - 82.5| = 7.5°$
> - 9:45 → $|270 - 247.5| = 22.5°$ (reflex angle also correct: $360 - 22.5 = 337.5°$)

## Angle → Time (given an angle, find what time(s) it occurs)
> [!tip] ⭐ Core equation — solve for minutes $M$ after hour $H$
> $$\theta = |30H - 5.5M| \implies M = \frac{30H \pm \theta}{5.5}$$
> Both $+\theta$ and $-\theta$ give valid solutions (hands can be on either side).

> [!example] Coincidence / Opposite / Right-angle counts per 12 hours
> | Event | Count per 12 hrs | Count per 24 hrs |
> |-------|------------------|-------------------|
> | Coincide (0°) | 11 times | 22 times |
> | Opposite (180°) | 11 times | 22 times |
> | Right angle (90°) | 22 times | 44 times |
> | Any angle except 0°/180° | 22 times | 44 times |

> [!danger] ⚠ Corrected: right angle is NOT simply "2 times/hour"
> Naively you might think 90° happens twice every hour (22 times in 11 hours → but 12 hours has only 22, not 24).
> Reason: near 12:00 and 6:00 the two 90°-crossings of adjacent hours "miss" — two of the 24 expected occurrences coincide/skip. Always use **22 times per 12 hrs**, not $2 \times 12$.

## Worked Example — "Between 2:00 and 3:00, when do hands form 90°?"
> [!example]
> At 2:00, HH is at $60°$. Need $|60 - 5.5M| = 90$.
> Case 1: $60 - 5.5M = -90 \Rightarrow M = 150/5.5 = 27\tfrac{3}{11}$ min → **2:27³⁄₁₁**
> Case 2: $60 - 5.5M = 90 \Rightarrow M = -30/5.5$ (negative, invalid before 2:00 — use reflex/other side instead)
> General shortcut: $M = \dfrac{30H \pm \theta}{5.5}$

## Gain / Lose (Faulty Watches)
> [!tip] Third pattern — fast/slow watches
> - **Fast watch → GAINS** time (shows ahead of correct time)
> - **Slow watch → LOSES** time (shows behind correct time)
> - These problems reduce to ratio/proportion: if watch gains $g$ minutes per correct hour, use $\dfrac{\text{correct time elapsed}}{\text{watch time elapsed}}$ as the scaling ratio.

> [!warning] Common mistake in relative-hand problems
> When computing minute-hand speed contribution, using $60°/\text{hr}$ instead of the correct $360°/12\text{hr} = 30°/\text{hr}$ for the hour hand is a frequent slip — always double check units (°/min vs °/hr).

## Edge Cases & Boundary Conditions
> [!warning] Don't get caught
> - "It is quarter past three in the watch" type problems mix angle-finding with everyday clock reading — convert to $H, M$ first
> - Reflex angle = $360° - \theta$; GATE sometimes asks for reflex explicitly
> - When first crossing happens *after* the hour hand's position, use $(60 + \text{something})$ adjustment before applying the standard formula

## GATE Focus
> [!example] High-weightage sub-topics
> - Time → Angle direct computation (MCQ, plug into formula)
> - Angle → Time — solving for M, often NAT with fractional minute answers (× ¹¹ denominators are common)
> - Counting coincidences/right-angles per 12 or 24 hours
> - Fast/slow watch ratio problems

**⭐ Formula sheet:**
$$\theta = |30H - 5.5M|$$
$$M = \frac{30H \pm \theta}{5.5}$$
$$\text{Relative speed (MH − HH)} = 5.5°/\text{min}$$

## Quick Recall
| Item | Value |
|------|-------|
| MH speed | 6°/min |
| HH speed | 0.5°/min |
| Relative speed | 5.5°/min |
| Coincidences per 12h | 11 |
| Right angles per 12h | 22 (not 24) |
| Gap between adjacent numbers | 30° |

## Connects To
← [[time_speed_distance_and_relative_velocity]] | [[calender]]

---
*Source: handwritten notes — 2026-07-01*

---

Clock relative speed and the 5.5°/min constant #flashcard
- Minute hand gains on hour hand at 6 − 0.5 = 5.5°/min; every clock problem reduces to angle ÷ 5.5
- Key formula: $\theta = |30H - 5.5M|$; inverse: $M = (30H \pm \theta)/5.5$
- GATE trap: right angles occur only **22** times per 12 hours (not 24) — two expected occurrences coincide near 12:00/6:00
^^^


