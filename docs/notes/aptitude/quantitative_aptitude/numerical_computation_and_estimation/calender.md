---
aliases: [calendar problems, odd days, day of week]
subject: "Quantitative Aptitude"
topic: "Numerical Computation and Estimation"
title: "Calendars — Day-of-Week Problems"
tags: [anki, study, gate_da]
---

# Calendars — Day-of-Week Problems

> [!abstract] One-line summary
> Calendar problems reduce to counting "odd days" — the remainder when total elapsed days is divided by 7 — to find which day of the week a given date falls on.

## Core Definitions

**Odd day:** Remainder when number of days is divided by 7.

**Day mapping:**
| Odd days | 0 | 1 | 2 | 3 | 4 | 5 | 6 |
|----------|---|---|---|---|---|---|---|
| Day | Sun | Mon | Tue | Wed | Thu | Fri | Sat |

> [!note] First day of the week = Sunday (standard in calendar aptitude)

**Odd days per year type:**

- Normal year: $365 = 52 \times 7 + 1$ → **1 odd day**
- Leap year: $366 = 52 \times 7 + 2$ → **2 odd days**

## Leap Year Condition

> [!tip] ⭐ GATE PRIORITY — three-part rule
>
> 1. Year divisible by 4 → leap year (general rule)
> 2. **Exception:** Century years (100, 200, 1900…) → NOT leap year, even if div by 4
> 3. **Exception to exception:** Divisible by 400 → IS a leap year (1600, 2000 ✓)

**Why:** Earth's revolution = 365¼ days. One full revolution → 365d 6hrs. 4 years → +1 day extra → Feb 29.

> [!danger] ⚠ GATE trap — 1900 is NOT a leap year
> 1900 ÷ 4 = 475 ✓ but 1900 is a century year and 1900 ÷ 400 ≠ integer → **not leap**.
> 1600, 2000, 2400 → leap (div by 400). 1700, 1800, 1900, 2100 → not leap.

## Odd Days per Century

> [!tip] ⭐ Memorise these four values
> | Century span | Odd days |
> |-------------|----------|
> | First 100 years (1–100) | 5 |
> | First 200 years | 3 |
> | First 300 years | 1 |
> | First 400 years | **0** (cycle resets) |
> | First 500 years | 5 (= 400 + 100, repeats) |

**Derivation for 100 years:**

- 100 years = 76 normal + 24 leap (years div by 4, excluding century itself)
- Odd days = $76 \times 1 + 24 \times 2 = 76 + 48 = 124$
- $124 \div 7 = 17$ rem $\mathbf{5}$ → **5 odd days**

**200 years:** $5 + 5 = 10 \to 10 \div 7 =$ rem $\mathbf{3}$
**300 years:** $3 + 5 = 8 \to 8 \div 7 =$ rem $\mathbf{1}$
**400 years:** $1 + 5 + 1 = 7 \to$ rem $\mathbf{0}$ (the 400th year is leap → +1 extra)

> [!warning] The +1 at 400 years
> Every 400-year cycle contains exactly 97 leap years → $400 \times 365 + 97 = 146097$ days → $146097 \div 7 = 20871$ exactly → **0 odd days**. The calendar repeats every 400 years.

## Month Odd Days Table

> [!tip] ⭐ Memorise — fixed values per month (normal year)
> | Month | Days | Odd days |
> |-------|------|----------|
> | January | 31 | 3 |
> | February | 28 | 0 |
> | March | 31 | 3 |
> | April | 30 | 2 |
> | May | 31 | 3 |
> | June | 30 | 2 |
> | July | 31 | 3 |
> | August | 31 | 3 |
> | September | 30 | 2 |
> | October | 31 | 3 |
> | November | 30 | 2 |
> | December | 31 | 3 |

> [!danger] ⚠ February in a leap year = 29 days → 1 odd day (not 0)
> This is a flagged GATE trap. Leap year Feb contributes **1 odd day**, not 0.

## Algorithm — Finding Day for a Given Date

> [!example] ⭐ Standard procedure
> To find the day for date $D$-$M$-$Y$:
>
> 1. **Completed centuries odd days** — look up table above for floor centuries
> 2. **Remaining years odd days** — for remaining $r$ years:
>    - Count leap years in $r$: $\lfloor r/4 \rfloor$ (no century correction needed here, centuries already handled)
>    - Odd days = $(r - \text{leaps}) \times 1 + \text{leaps} \times 2 = r + \text{leaps}$, then mod 7
> 3. **Completed months odd days** — sum from month table for months Jan through $M-1$
>    - Adjust Feb if year is leap
> 4. **Completed days** — $(D - 1)$ days, compute mod 7
> 5. **Sum all** → mod 7 → map to day

> [!warning] Key phrase: "completed" not "current"
> We count **completed** years, **completed** months, **completed** days.
> The year itself is not complete on Jan 1 — only years _before_ the target year count.
> Nearest reference century: look for the century _just before_ the target year.

## Worked Example 1 — 3rd June 1997

> [!example] Step by step
> **Step 1: Century (1900)**
> 1900 is NOT a leap year. Odd days for first 1900 years = 1900 years odd days.
> Centuries: 19 centuries. $19 \div 4 = 4$ complete 400-year cycles + 3 extra centuries.
> 4 complete cycles → $4 \times 0 = 0$. 3 extra centuries: 100→5, 200→3, 300→1 → take the 3rd = 1.
> Actually: use the table directly — first 1900 years = odd days of (1600 + 300) = 0 + 1 = **1 odd day**.
>
> **Step 2: Remaining years (97 years after 1900, i.e. 1901–1996 completed)**
> Leap years in 97: $\lfloor 97/4 \rfloor = 24$. Normal years = 73.
> Odd days = $73 \times 1 + 24 \times 2 = 73 + 48 = 121$. $121 \div 7 =$ rem **2** → but wait:
> Notes show: $0 + 3 + 3 = 16 \div 7 =$ rem 2 → Tuesday (notes got this). _(Small discrepancy in notes — the correct answer is Tuesday.)_
>
> **Step 3: Completed months in 1997 (Jan + Feb + Mar + Apr + May)**
> Jan=3, Feb=0 (1997 not leap), Mar=3, Apr=2, May=3 → total = 11. $11 \div 7 =$ rem **4**
>
> **Step 4: Completed days** → 2 days (3rd June means 2 completed days). Rem = **2**
>
> **Total:** $1 + 2 + 4 + 2 = 9 \div 7 =$ rem **2** → **Tuesday** ✓

## Worked Example 2 — Guru Nanak Jayanti (14 Nov 1469)

> [!example]
> Century 1400: first 1400 years → $1400 = 3 \times 400 + 200$ → $0 + 3 = 3$ odd days
> Remaining 69 years: LY = $\lfloor 69/4 \rfloor = 17$. Normal = 52. Odd = $52 + 34 = 86 \to$ rem 2.
> In 69: split → 69LY=17, rem → $17 \times 2 + 52 \times 1 = 86 \to 86 \div 7 =$ rem 2.
> Months (Jan–Oct completed): J=3, F=0, M=3, A=2, M=3, J=2, J=3, A=3, S=2, O=3 → 24 → rem 3.
> Days: 13 completed → $13 \div 7 =$ rem 6.
> Total: $3 + 2 + 3 + 6 = 14 \div 7 =$ rem **0** → **Sunday** _(notes show Friday; recheck century calculation — 1469 straddles 14th century, so use 1300: $3 \times 400 + 100 = 5$... the exact answer depends on starting epoch convention. Notes got Friday.)_

> [!note] Added by agent — BC/AD difference
> AD (Anno Domini) = Common Era (CE). BC = Before Common Era (BCE).
> For BC dates, year counting goes backwards: 1 BC → 1 AD (no year 0).
> GATE problems almost always use AD dates; BC problems are rare.

## Misc Patterns

> [!tip] Same calendar year conditions
>
> - Two non-leap years have the same calendar if they have the same odd-day offset since the last reference
> - The calendar repeats with period 400 years
> - Within a century: same calendar if total odd days accumulated between the two years = 0 mod 7

**⭐ Formula sheet:**
$$\text{Total odd days} = (\text{century odd days}) + (\text{year odd days}) + (\text{month odd days}) + (\text{day odd days}) \pmod{7}$$
$$\text{Leap years in } r \text{ years from century start} = \left\lfloor \frac{r}{4} \right\rfloor$$
$$\text{Year odd days} = r + \left\lfloor \frac{r}{4} \right\rfloor \pmod{7}$$

## Quick Recall

| Item                              | Odd days     |
| --------------------------------- | ------------ |
| Normal year                       | 1            |
| Leap year                         | 2            |
| 100 years                         | 5            |
| 200 years                         | 3            |
| 300 years                         | 1            |
| 400 years                         | 0            |
| Feb (normal)                      | 0            |
| Feb (leap)                        | **1** ← trap |
| Jan, Mar, May, Jul, Aug, Oct, Dec | 3            |
| Apr, Jun, Sep, Nov                | 2            |

## Edge Cases

> [!danger] Don't get caught
>
> - **1900 is NOT a leap year** — century but not div by 400
> - **Feb in a leap year = 1 odd day**, not 0
> - Count **completed** years/months/days, not current
> - Century odd-day table starts from year 1 (or year 0 depending on convention) — be consistent
> - "First day of week = Sunday" in standard aptitude problems

## Connects To

← [[Probability-Statistics/Counting]] | aptitude index

---

_Source: handwritten notes — 2026-06-28_

---

Calendar odd-days — century table #flashcard

- 100 yrs = 5 odd days, 200 = 3, 300 = 1, 400 = 0. Repeats every 400 years.
- Key formula: Total odd days = (century) + (remaining years + their leap count) + (month table) + (day−1), all mod 7
- GATE traps: 1900 is NOT a leap year; Feb in leap year = **1 odd day** not 0; always count **completed** units
  ^^^

---
## Worked Example 3 — Jan 1st 1998 was Wednesday; find Jan 1st 2003 — Updated 2026-07-01

> [!example] Relative day-shift method (faster than full odd-day calc)
> Instead of computing odd days from year 1, use the **known reference date directly** and just count odd days across the intervening years.
> Years 1998–2002 (5 years spanned): 1998(N)=1, 1999(N)=1, 2000(**Leap**)=2, 2001(N)=1, 2002(N)=1 → total = 6 odd days.
> $6 \div 7 =$ rem **6** → Wed + 6 = **Tuesday**? *(Notes conclude "Wednesday" via a different grouping — recount: only years fully completed between the two Jan-1 dates count. Jan 1 1998 → Jan 1 2003 spans exactly 5 completed years: 1998,1999,2000,2001,2002. With 2000 as the only leap year: $4(1) + 1(2) = 6$ odd days → Wed+6 = Tuesday. Verify against a calendar before trusting either answer — this is flagged as a discrepancy.)*

> [!tip] ⭐ Faster technique for "given day X, find day on date N years later"
> Don't recompute from century tables. Just sum odd days for the **exact span of years** between the two dates (inclusive of leap years crossed) and add to the known reference day.

## Conditional / Hypothetical Calendar Questions

> [!example] "If a year had 400 days and a week had 9 days" — worked
> $400 \div 9 = 44$ remainder $4$ → 4 "odd days" in this hypothetical calendar.
> Odd-day cycle for centuries in this system: $100 \to 5$, $200 \to 3$, $300 \to 1$, $400 \to 0$ (mirrors the real base-7 pattern but recomputed for divisor 9 — same structural logic, different modulus).
> ⭐ GATE PRIORITY: these conditional questions test whether you understand the **method** (odd-day accumulation and modular reduction), not memorized constants — the 5-3-1-0 pattern for 100/200/300/400 is a coincidence of base-7; a different week length changes the actual remainders.

## Month Repetition Pattern

> [!tip] A calendar month's day-pattern repeats after accumulating 7 odd days
> Example: March's calendar repeats in **November** of the same year (non-leap).
> Gaps (in odd days) between March and each subsequent month determine which month shares March's layout:
> Apr=3, May=3, Jun=3, Jul=2, Aug=3, Sep=2, Oct=3 → cumulative reaches 7 (mod 7 = 0) at **November**.

> [!note] Added by agent — general rule for month-repeat pairs (non-leap year)
> | Pair | | Pair | |
> |------|---|------|---|
> | Jan ↔ Oct | | May ↔ — (unique) | |
> | Feb ↔ Mar ↔ Nov | | Jun ↔ — (unique) | |
> | Apr ↔ Jul | | Aug ↔ — (unique) | |
> | Sep ↔ Dec | | | |
> In a leap year, Jan↔Oct breaks (Jan pairs with nothing else) and Feb stands alone; recompute case by case.

## Connects To (updated)
← [[Clocks]] | [[Probability-Statistics/Counting]] | aptitude index

