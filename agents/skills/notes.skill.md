# notes.skill.md

# Convert, correct, and curate GATE DA/PH notes across the Obsidian vault.

# Two modes: CONVERT (raw input → new note) and CURATE (fix/deepen/reorganize existing vault).

# Stored at: ~/.dotfiles/agents/skills/

# Invoke: "convert my notes" / "obsidianify" / "organize my vault" / "audit <folder>" /

# "fix mistakes in <file>" / "reorganize <subject>" / "deepen this note"

## Purpose

Depth and correctness for GATE exam prep are non-negotiable. Structure (callouts,
tables, terseness) is the vehicle for that depth, never a substitute for it. This
skill has full read/write/delete authority over `/home/archer/til/vault/notes/` —
it can rewrite, correct, deepen, split, merge, rename, delete, and reorganize any
note or folder, with two hard exceptions: never touch spaced-repetition metadata,
and never silently make destructive changes without logging them.

---

## ⚠ INVIOLABLE RULE — Spaced Repetition Metadata

Lines matching `<!--SR:!fsrs,...-->` are NOT content. They are the SR plugin's live
scheduling state (interval, ease, due date) for the flashcard directly above them.

- **NEVER** delete, edit, reorder, or regenerate these lines. Ever. This overrides
  every other instruction in this skill, including "full authority to reorganize."
- They travel WITH their flashcard, atomically: `<Question> ?\n...\n^^^\n<!--SR:...-->`.
  If a flashcard block moves (file split, reorder, merge), its SR line moves with
  it — verbatim, byte-for-byte, same line.
- Before ANY `mode: rewrite` on a file that might contain SR lines: `view` the file
  first, locate every SR line, note which flashcard it's paired with, and manually
  re-insert each one attached to its flashcard in the new version.
- A flashcard can only be deleted if truly obsolete/wrong, and only with the SR line
  deleted alongside it (never leave an orphaned SR line with no flashcard above it,
  and never leave a flashcard with its SR line stripped). Log any such deletion.
- Treat this like deleting exam-prep history — because that's what it is.

---

## Vault Conventions (learned from existing structure — match locally, don't invent)

The vault has **two coexisting directory styles**. Detect which applies before writing:

**Style A — GATE DA core + Physics subjects** (flat, no topic subfolder):

```
notes/<Subject-PascalCase>/<Concept-PascalCase>.md
e.g.  notes/Programming-DSA/Merge-Sort.md
      notes/Database-Warehousing/BCNF.md
```

**Style B — Aptitude tracks** (nested, snake*case, scaffolded by `create*\*.sh`):

```
notes/aptitude/<subject_snake_case>/<topic_snake_case>/<concept_snake_case>.md
e.g.  notes/aptitude/quantitative_aptitude/numerical_computation_and_estimation/Averages.md
```

Rule: if the target directory already has files, match their existing naming case
and nesting depth exactly. If creating a brand-new subject folder, default to Style A
(flat, PascalCase) unless the topic is clearly an Aptitude-track concept.

**Frontmatter (both styles, always):**

```yaml
---
subject: "<Subject Name, human-readable>"
topic: "<Topic Name, human-readable>"
title: "<Full Note Title>"
tags: [study, gate_da]
---
```

---

## Mode Detection

- **CONVERT MODE** — input is new: a handwritten image, raw doc, or chat dump →
  Phase 0–6 below.
- **CURATE MODE** — request targets existing vault content: "fix", "organize",
  "improve", "reorganize", "audit", "delete", "merge", "split", "deepen",
  "clean up the vault" → Phase C1–C4 below.
- Either mode can trigger the other mid-task (e.g. converting new notes surfaces
  an error in an old related note → fix it too, note it in the session log).

---

# CONVERT MODE

## Phase 0 — Ingest

| Input                  | How to get text                                                             |
| ---------------------- | --------------------------------------------------------------------------- |
| Handwritten image      | Extract raw text via vision; preserve structure; flag illegible words `[?]` |
| Raw typed doc / `.txt` | Read directly                                                               |
| Messy `.md`            | Read, identify structure problems                                           |
| Pasted chat dump       | Use as-is                                                                   |

Context is fixed: user is preparing for **GATE DA** (default) or **GATE PH** (only
if user says "Physics"). Don't ask — infer subject from content; ask only if truly
ambiguous.

## Phase 1 — Analyse & Auto-Enrich

Identify: subject, topic, content type (concept/derivation/formula-sheet/PYQ),
missing pieces, key formulas/theorems/traps.

Always apply, no prompting needed:

- **Fill gaps** — complete incomplete definitions correctly using standard GATE material.
- **Add what's missing** — properties/edge-cases/traps absent from the raw note go
  under `> [!note] Added by agent`.
- **Flag mistakes** — wrong formula/claim gets corrected inline, marked
  `> [!danger] ⚠ Corrected: <original mistake>`. Never silently fix errors.
- **Surface priority** — the single most-tested fact gets `⭐ GATE PRIORITY`.
- **Depth mandate** (see Curate Phase C3) — apply the same GATE-exam-ready bar to
  every new note, not just a bullet-point stub.

## Phase 2 — Note Template

```markdown
---
subject: "<Subject Name>"
topic: "<Topic Name>"
title: "<Full Note Title>"
tags: [study, gate_da]
---

# <Topic Name>

> [!abstract] One-line summary
> What this concept IS, in one sentence.

> [!note] Intuition
> One plain-language analogy, zero jargon, 1-2 lines — makes the formal definition stick.

## Core Definition

$$<key formula or definition>$$
**Key variables:** define each symbol inline.

## Key Properties

> [!tip] GATE tests these most
>
> - Property 1
> - Property 2 ← **common trap**

## Important Results / Theorems

| Result | Condition | Formula |
| ------ | --------- | ------- |

## Edge Cases & Boundary Conditions

> [!warning] Don't get caught
>
> - Edge case 1

## GATE Focus

> [!example] High-weightage sub-topics
>
> - Sub-topic A — MCQ type
> - Sub-topic B — NAT type

**⭐ Formula sheet:**
$$<formula>$$

## Quick Recall

| Term | Meaning |
| ---- | ------- |

## Connects To

← [[<related-topic-1>]] | [[<related-topic-2>]]

---

_Source: handwritten notes — <date>_
```

## Phase 3 — Enrich (apply in order)

1. **Callout audit** — every section has ≥1 callout: `[!abstract]` summary,
   `[!tip]` properties, `[!warning]` traps, `[!example]` patterns, `[!note]` extra
   context, `[!danger]` guaranteed-wrong-if-missed.
2. **Formula check** — LaTeX only; inline `$f(x)$`, block `$$\sum$$`; star `⭐` any
   formula appearing in GATE papers more than twice.
3. **Table injection** — ≥3 comparable items (distributions, algorithms, metrics)
   force into a table. Tables beat bullets for revision speed.
4. **Link injection** — check the target directory (and siblings) for related notes;
   add `[[wiki-links]]` in "Connects To". Never create orphan notes.
5. **Flashcard block** — append for the most-testable concept:

```markdown
<Most-testable concept or misconception> #flashcard

- definition, intuition, explanation
- formulas in KaTeX: inline $f(x)$ or block $$\sum$$
- use tables, bullet trees, bold for GATE traps
  ^^^
```

(New flashcards get NO SR line — the SR plugin generates one on first review. Only
pre-existing flashcards being edited/moved carry their SR line forward.)

## Phase 4 — Quality Check

- [ ] Filename matches the local vault convention (Style A or B, detected above)
- [ ] Tags include `gate_da` + subject
- [ ] Every major section has a callout
- [ ] Intuition/ELI5 note present
- [ ] ≥1 `[!warning]` trap, ≥1 `⭐` formula
- [ ] Flashcard block present
- [ ] `[[wiki-links]]` to ≥1 related note
- [ ] No prose walls — bullets/tables in properties sections

## Phase 5 — Write File

1. `list_directory` the target folder at `depth: 2`. Scan for a fuzzy topic match
   (same concept, different slug counts as a match).
   - **Match found → `mode: append`.** Read the existing file FIRST (SR-line rule
     above). Add a `---` separator + dated header:

     ```markdown
     ---

     ## <Topic> — Updated <YYYY-MM-DD>

     <new content>
     ```

   - **No match → `mode: rewrite`** with the full template.

2. Folder doesn't exist? Create it, matching the local convention (Style A/B).
3. **Always absolute paths.** Desktop Commander resolves `~/` against its own
   working directory, NOT `/home/archer` — use `/home/archer/til/vault/notes/...`
   explicitly, every time, no exceptions.
4. **Update the directory's `index.md`** — see the mandatory section below. This
   is not optional and not deferred; do it in the same operation as the note write.

---

# CURATE MODE

## Phase C1 — Survey

1. `list_directory` the target scope (file, folder, or whole `notes/`) at depth 2–3.
2. `view` every candidate file's full content before touching it — never edit blind.
3. Per file, assess: factual correctness, depth (GATE-exam-ready or a stub?),
   callout quality, orphan status (any `[[links]]` in/out?), overlap with siblings.

## Phase C2 — Decide Action Per File

| Signal                                                | Action                                               |
| ----------------------------------------------------- | ---------------------------------------------------- |
| Factual error                                         | Correct inline, `[!danger] ⚠ Corrected: <mistake>`   |
| Shallow/stub content                                  | Deepen per Phase C3 — don't wait to be asked         |
| Weak/missing callouts                                 | Re-apply the Callout audit (Convert Phase 3, pass 1) |
| One file covers 2+ distinct concepts                  | **Split** into atomic files, one concept             |
| each, cross-link both ways                            |
| Two files are near-100% duplicate of the same concept | **Merge** into the more                              |

complete one; turn the other into a one-line redirect stub `See [[Surviving-Note]]`
(don't hard-delete it — Obsidian backlinks may point at it) |
| Related-but-distinct concepts in separate files | **Do NOT merge** — cross-link
via "Connects To" instead. Atomic files stay atomic; only true duplicates merge. |
| File renamed or moved | Grep sibling/related notes for `[[old-name]]` and update
every reference to the new name/path |
| Dead file: no incoming links, no content value, superseded | **Delete** — but only
after confirming no backlinks exist; log the reason in the session summary |

> [!warning] Merging is the exception, not the default
> Bharath's own stated principle for this vault is atomic files — never merge
> distinct concepts just because they're adjacent. "Full authority to reorganize"
> means the freedom to fix, deepen, split, and re-link aggressively — it does not
> override atomicity. Only collapse two files when they are genuinely the same
> concept duplicated, and always leave a redirect stub, never a silent 404.
