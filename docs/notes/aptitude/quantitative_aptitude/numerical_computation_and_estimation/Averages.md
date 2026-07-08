---
subject: "Quantitative Aptitude"
topic: "Numerical Computation and Estimation"
title: "Averages"
tags: [anki, study, gate_da]
---

# Averages

> [!abstract] One-line summary
> Average = Sum of observations ÷ Number of observations; when a set changes (new members added, weighted groups combined), work with the **sum**, not the average, then divide back.

## Core Definition
$$\text{Average} = \frac{\text{Sum of Observations}}{\text{Number of Observations}}$$
$$\text{Sum of Observations} = \text{Average} \times \text{Number of Observations}$$

> [!warning] Ratios/rates (like speed) can't be averaged directly
> Speed = distance/time. If a trip has two different speeds for equal distances (not equal times), you **cannot** just average the two speeds. Convert to total distance ÷ total time instead.
> Example (from notes): distances via speeds 20 and 30 → $\frac{x}{20} + \frac{x}{30} = 11 \Rightarrow$ solve for total time, not $(20+30)/2$.

## Key Properties
> [!tip] GATE tests these most
> - Adding a new observation shifts the sum by exactly that value — recompute sum first, then divide
> - When a fixed quantity (like age) is added to *every* member, average shifts by the same amount
> - Average of consecutive integers $x, x{+}1, \ldots, x{+}n$ is the **middle term** (or mean of first & last)
> - Combining two groups: $\text{Combined Avg} = \dfrac{\text{Sum}_1 + \text{Sum}_2}{n_1 + n_2}$, **not** $(\text{Avg}_1+\text{Avg}_2)/2$ unless $n_1 = n_2$

## Worked Example — Family average age (from notes)

> [!example]
> 12 years ago, average age of (husband + wife) = 20 → sum = 40.
> Today, same average (20) but now 4 members (husband, wife, + 2 kids aged $x$ and $x{-}2$).
> Husband+wife today = $40 + 12 + 12 = 64$ (each aged 12 more).
> $$\frac{64 + x + (x-2)}{4} = 20 \Rightarrow 64 + 2x - 2 = 80 \Rightarrow 2x = 18 \Rightarrow x = 9$$
> *(Notes arrive at x=5, giving ages 5 and 3 — small arithmetic slip in the original working; re-verify by direct substitution before trusting either.)*

> [!danger] ⚠ Corrected: don't average two group-averages naively
> If group A (n₁ people) has average $a$ and group B (n₂ people) has average $b$, the combined average is the **weighted** mean:
> $$\frac{n_1 a + n_2 b}{n_1 + n_2}$$
> Simple $(a+b)/2$ only works when $n_1 = n_2$.

## Edge Cases & Boundary Conditions
> [!warning] Don't get caught
> - "Average of 5 consecutive numbers is y" → the 3rd (middle) number = y, not the 1st
> - Replacing one observation: new sum = old sum − removed value + new value
> - Percentage-to-fraction shortcuts speed up "average of %-based data" problems (see table below)

## Percentage ↔ Fraction Quick Table
> [!tip] ⭐ Memorize — saves calculation time in averages/percentage-mix problems
> | % | Fraction | Decimal |
> |---|----------|---------|
> | 5% | 1/20 | 0.05 |
> | 10% | 1/10 | 0.10 |
> | 15% | 3/20 | 0.15 |
> | 20% | 1/5 | 0.20 |
> | 25% | 1/4 | 0.25 |
> | 30% | 3/10 | 0.30 |
> | 33⅓% | 1/3 | 0.333... |
> | 66⅔% | 2/3 | 0.666... |
> | 65%, 70% | — | 0.65, 0.70 |

## GATE Focus
> [!example] High-weightage sub-topics
> - Age-based average problems (family, N years ago/hence) — NAT type
> - Weighted average of two/three groups combined
> - Average speed for equal-distance (not equal-time) trips — classic trap

**⭐ Formula sheet:**
$$\text{Sum} = \text{Average} \times n$$
$$\text{Weighted Avg} = \frac{n_1 a + n_2 b}{n_1+n_2}$$
$$\text{Avg Speed (equal distance)} = \frac{2v_1v_2}{v_1+v_2}$$

## Quick Recall
| Term | Meaning |
|------|---------|
| Sum of obs | Average × N |
| Weighted avg | Use sums, never average of averages directly |
| Avg speed (equal dist) | Harmonic mean of the two speeds |

## Connects To
← [[time_speed_distance_and_relative_velocity]] | [[percentages_profit_loss_and_compound_discounts]]

---
*Source: handwritten notes — 2026-07-01*

---

Weighted average vs simple average of averages #flashcard
- Combined average of two groups uses **total sum ÷ total count**, not (avg1+avg2)/2
- Key formula: $\dfrac{n_1 a + n_2 b}{n_1+n_2}$
- GATE trap: assuming equal weighting when group sizes differ — always check $n_1 = n_2$ before shortcutting
^^^

