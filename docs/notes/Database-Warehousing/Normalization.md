---
subject: "Database-Warehousing"
topic: "Normalization"
title: "Normalization"
tags: [anki, study]
---

<!--SR:!2026-06-30,1,230-->


| Case                           | Condition                          | Formula                                                |
| ------------------------------ | ---------------------------------- | ------------------------------------------------------ |
| **All single-attribute keys**  | n attributes, each is a CK         | 2ⁿ − 1                                                 |
| **One composite key**          | 1 CK with k attrs, m non-key attrs | 2^m                                                    |
| **Disjoint composite keys**    | CK₁, CK₂ with no common attrs      | 2^(N−a) + 2^(N−b) − 2^(N−a−b)                          |
| **Nested keys**                | CK₁ ⊂ CK₂ (rare, usually invalid)  | Use CK₂ only                                           |
| **Non-key attributes present** | m attrs not in any CK              | Multiply final answer by 2^m (if included in counting) |

Start
│
▼
How many candidate keys?
│
├── 1 key with k attributes
│ └── Superkeys = 2^(N−k)
│
├── 2 keys?
│ ├── Disjoint? → 2^(N−a) + 2^(N−b) − 2^(N−a−b)
│ └── Overlapping? → Inclusion-Exclusion
│
└── 3+ keys?
└── Always use Inclusion-Exclusion Principle

# Superkeys — Counting via Inclusion-Exclusion

> [!abstract] One-line summary
> A superkey is any attribute set that functionally determines all attributes; counting them requires Inclusion-Exclusion over candidate key unions.

## Core Definitions

**Superkey:** A set $S \subseteq R$ such that $S \to R$ (determines every attribute).

**Candidate Key (CK):** A _minimal_ superkey — no proper subset is also a superkey.

**Key rule:** Every superkey _must contain_ at least one candidate key as a subset.

$$\text{\# Superkeys} = \text{Total subsets} - \text{subsets containing NO candidate key}$$

**Equivalent via Inclusion-Exclusion over candidate key "hit" sets:**

$$|\text{Superkeys}| = \sum_i |S_i| - \sum_{i<j}|S_i \cap S_j| + \sum_{i<j<k}|S_i \cap S_j \cap S_k| - \cdots$$

where $S_i$ = set of all subsets of $R$ that **contain** $CK_i$.

**Key variables:**

- $n$ = total attributes in relation $R$
- $k$ = size (length) of a candidate key $CK$
- $|S_i|$ = $2^{n-k_i}$ (fix $CK_i$'s attributes, free to pick any subset of remaining $n - k_i$ attrs)
- $k_{ij} = |CK_i \cup CK_j|$ (union size for pair intersection term)

## Case Counting Principle

> [!tip] ⭐ GATE PRIORITY — use this for every superkey count
> **# superkeys containing $CK$** = $2^{N-K}$
> where $N$ = total attributes, $K$ = $|CK|$
> Logic: $CK$'s $K$ attrs are fixed (must be present); remaining $N-K$ attrs are free (include or not).

**Constraint:** No candidate key can be a subset of another (minimality). If $CK_i \subset CK_j$, then $CK_j$ is not minimal — contradiction. So all CKs are incomparable.

## Inclusion-Exclusion Procedure

> [!example] Step-by-step algorithm
>
> 1. List all candidate keys $CK_1, CK_2, \ldots, CK_m$
> 2. **Singles:** $|S_i| = 2^{n - |CK_i|}$
> 3. **Pairs:** $|S_i \cap S_j| = 2^{n - |CK_i \cup CK_j|}$ — union size matters, not sum
> 4. **Triples:** $|S_i \cap S_j \cap S_k| = 2^{n - |CK_i \cup CK_j \cup CK_k|}$
> 5. **Quadruple** (all 4 CKs): $2^{n - |CK_1 \cup CK_2 \cup CK_3 \cup CK_4|}$
> 6. Apply alternating $+, -, +, -$ signs

> [!warning] Critical trap — union size, not sum of sizes
> $|S_i \cap S_j| = 2^{n - |CK_i \cup CK_j|}$, NOT $2^{n - (|CK_i| + |CK_j|)}$
> Overlapping attributes between two CKs are counted **once** in the union.

## Worked Example (from notes)

**Schema:** $R(A, B, C, D, E, F, G)$ → $n = 7$

**Candidate keys:** $CK_1 = \{A,B\}$, $CK_2 = \{B,D\}$, $CK_3 = \{E,F\}$, $CK_4 = \{C,E,F\}$

> [!note] Overlap analysis
> | Pair | Intersection | Union | Union size |
> |------|-------------|-------|------------|
> | $CK_1, CK_2$ | $\{B\}$ | $\{A,B,D\}$ | 3 |
> | $CK_1, CK_3$ | $\emptyset$ | $\{A,B,E,F\}$ | 4 |
> | $CK_1, CK_4$ | $\emptyset$ | $\{A,B,C,E,F\}$ | 5 — wait, $CK_4 \supset CK_3$, not a valid CK |
> | $CK_3, CK_4$ | $\{E,F\}$ | $\{C,E,F\}$ | 3 |
> | All others | $\emptyset$ | size 4 | 4 |

**Singles** ($\sum |S_i|$): $2^{7-2} + 2^{7-2} + 2^{7-2} + 2^{7-2} = 4 \times 32 = 128$

**Pairs** ($\sum |S_i \cap S_j|$): $16 + 16 + 32 + 16 + 32 + 16 = 64$ — see notes table with union sizes 3,4,4,3,4,4

**Triples** ($\sum |S_i \cap S_j \cap S_k|$): all triple unions have size 5 → $4 \times 2^{7-5} = 4 \times 4 = 16$

**Quadruple:** $1 \times 2^{7-6} = 2$

$$\text{\# Superkeys} = 128 - 64 + 16 - 2 = \boxed{78}$$

## Maximum Superkeys Formula

> [!tip] ⭐ Two-candidate-key upper bound
> With 2 CKs of sizes $k_1$, $k_2$ with overlap $k_{12} = |CK_1 \cup CK_2|$:
> $$\text{Max superkeys} = 2^{n-k_1} + 2^{n-k_2} - 2^{n-k_{12}}$$

**General:** For $m$ CKs, standard I-E formula above.

**Non-key attributes** are always "free" — they can appear in any superkey independently.

> [!warning] Superkey ≠ Candidate Key
> Every CK is a superkey. Not every superkey is a CK.
> The question "is $\{A, B, C\}$ a superkey?" requires only checking $\{A,B,C\} \to R$.
> The question "is it a CK?" additionally requires no proper subset determines $R$.

## Key Properties

| Property                       | Detail                                                      |
| ------------------------------ | ----------------------------------------------------------- |
| Every relation has ≥1 superkey | The full attribute set $R$ is always a superkey             |
| CKs are minimal superkeys      | Remove any attr → no longer determines $R$                  |
| Superkeys counted with I-E     | Avoid double-counting sets containing multiple CKs          |
| Non-key attrs are free         | They contribute $2^{\text{free count}}$ factor per CK       |
| Overlapping CKs reduce count   | Shared attrs shrink the union → larger $2^{n-\text{union}}$ |

## Edge Cases

> [!danger] Don't get caught
>
> - If two CKs share all attributes → they're the same CK (not two separate ones)
> - If $CK_i \subset CK_j$ → $CK_j$ is not a candidate key (not minimal); re-examine the problem
> - Counting "subsets containing NO CK" = Total subsets − Superkeys (complement approach)
> - $2^{n - |CK_i \cup CK_j|}$: when $CK_i \cap CK_j = \emptyset$, union size = $|CK_i| + |CK_j|$

> [!note] Added by agent — Complement approach (alternative method)
> $$\text{\# Superkeys} = 2^n - \text{(subsets containing no candidate key)}$$
> The complement is harder to compute directly but useful as a sanity check.
> Standard I-E over "containing at least one CK" is almost always faster for GATE.

## GATE Focus

> [!example] High-weightage patterns
>
> - Given FDs, find all CKs → count superkeys (NAT type, 1–2 marks)
> - Given CKs directly, apply $2^{n-k}$ per key + I-E (MCQ or NAT)
> - "How many superkeys contain attribute $X$?" — condition on $X$ being free or in a CK
> - Maximum possible superkeys given $n$ attrs and one CK of size $k$

**⭐ Formula sheet:**
$$|S_i| = 2^{n - |CK_i|}$$
$$|S_i \cap S_j| = 2^{n - |CK_i \cup CK_j|}$$
$$\text{\# Superkeys} = \sum|S_i| - \sum|S_i \cap S_j| + \sum|S_i \cap S_j \cap S_k| - \cdots$$

## Quick Recall

| Term          | Meaning                                             |
| ------------- | --------------------------------------------------- |
| Superkey      | Attr set $\to$ all attrs                            |
| Candidate key | Minimal superkey                                    |
| $2^{n-k}$     | Superkeys containing one CK of size $k$             |
| I-E principle | Alternating sum to avoid double-counting overlaps   |
| Union size    | Use $\|CK_i \cup CK_j\|$, not $\|CK_i\| + \|CK_j\|$ |

## Connects To

← [[Normalization]] | [[Relational-Model]] | [[Integrity-Constraints]] | [[BCNF]]

---

_Source: handwritten notes — 2026-06-28_

---

Superkey counting via inclusion-exclusion #flashcard

- A superkey contains at least one CK. Count by summing over CKs, subtracting pairwise overlaps, adding triples, etc.
- Key formula: $|S_i| = 2^{n - |CK_i|}$; pair intersection: $2^{n - |CK_i \cup CK_j|}$
- GATE trap: use **union size** for pair/triple terms, not sum of individual sizes; shared attributes count once
  ^^^
