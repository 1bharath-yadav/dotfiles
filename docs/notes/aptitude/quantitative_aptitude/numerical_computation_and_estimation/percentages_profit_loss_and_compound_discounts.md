---
subject: "Quantitative Aptitude"
topic: "Numerical Computation and Estimation"
title: "Percentages Profit Loss and Compound Discounts"
tags: [anki, study, gate_da]
---

# Percentages, Profit/Loss, Compound Discounts

> [!abstract] One-line summary
> Percentage problems are comparison problems in disguise — converting the % to its fraction equivalent almost always solves faster than decimal arithmetic.

## Core Formulas & Properties
> [!tip] GATE tests these most
> - $x\% \text{ of } N = \dfrac{x}{100} \times N$
> - Percentage increase from $x$ to $x + \frac{1}{5}x$ = **20%** (i.e. $x + 0.2x = 1.2x$)
> - Successive % changes are **not additive** — apply multiplicatively: $(1+p_1)(1+p_2) \neq 1 + p_1 + p_2$
> - See [[Averages]] for the full %→fraction quick-reference table (5%, 10%, ..., 30%, 33⅓%, 66⅔%)

> [!warning] Don't get caught
> - $x + 0.1x - (x + 0.2x) = -0.1x$, i.e. going from +20% back to +10% is a **decrease of 0.1x from the +20% figure**, not from original $x$ — always track the reference base
> - "Increased by 1/5" = +20%, not +1/5 of the new value

## Common GATE Question Patterns
> [!example] High-weightage sub-topics
> - Successive percentage change chains (price hikes/discounts stacked)
> - Fraction-form percentage arithmetic for speed (avoid decimals under time pressure)
> - Percentage-of-percentage word problems (population growth, exam pass rates)

## Quick Recall
| Change | Multiplier |
|--------|-----------|
| +x% | $(1 + x/100)$ |
| −x% | $(1 − x/100)$ |
| Two successive +x%, +y% | $(1+x/100)(1+y/100)$ — expand, don't add |

## Connects To
← [[Averages]] | [[ratios_proportions_and_direct_inverse_variations]]

---
*Source: handwritten notes — 2026-07-01*

---

Successive percentage changes are multiplicative, not additive #flashcard
- Two changes of +x% and +y% combine to $(1+x/100)(1+y/100) - 1$, not simply $x+y$ percent
- Key formula: Final value $= P(1+x/100)(1+y/100)$
- GATE trap: for a +20% then −20% sequence, net is **−4%**, not 0% — students assume they cancel
^^^
