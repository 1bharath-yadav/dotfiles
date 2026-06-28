---
subject: "Database-Warehousing"
topic: "Normalization"
title: "Normalization"
tags: [anki, study]
---

TARGET DECK: Database-Warehousing::Normalization

FILE TAGS: #Database-Warehousing #Normalization

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
