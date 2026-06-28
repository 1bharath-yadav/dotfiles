# notes-to-obsidian.skill.md
# Convert handwritten / raw doc notes → polished Obsidian markdown
# Stored at: ~/.dotfiles/agents/skills/
# Invoke: "convert my notes" / "clean up this note" / "obsidianify"

## Purpose
Transform messy input (handwritten OCR image, raw typed docs, bullet dumps)
into structured, visually rich Obsidian notes with highlights, callouts,
quick-reference sections, and GATE-optimised layout.

---

## Trigger
User says any of:
- "convert my notes" / "obsidianify this"
- "clean up this handwritten note"
- "turn this into an Obsidian note"
- "format my notes for Obsidian"
- Uploads an image of handwritten notes

---

## Phase 0 — Ingest

### Input types handled:
| Type | How to get text |
|------|-----------------|
| Handwritten image (jpg/png) | Ask Claude Vision to extract raw text first |
| Raw typed doc / `.txt` | Read directly |
| `.md` file (messy) | Read, identify structure problems |
| Pasted dump in chat | Use as-is |

### Step 1 — Extract if image:
Prompt Claude Vision:
```
Extract all text from this handwritten note exactly as written.
Preserve structure: headings, bullet points, equations, tables.
Flag illegible words with [?].
Output: raw text only, no commentary.
```

### Step 2 — Context (hardcoded, no file reads needed):
- User is preparing for **GATE DA** (Data Science & AI). This is the fixed context.
- Ask user for subject/topic if not obvious from the note content itself.
- Do NOT read `optima.md` or `study.md` — unnecessary overhead.

---

## Phase 1 — Analyse Structure

Before formatting, identify:
1. **Subject** — which GATE DA topic (ML, Stats, LA, DSA, DBMS, AI, Calc, GA)?
2. **Content type** — concept intro / derivation / formula sheet / PYQ solution?
3. **Missing pieces** — incomplete proofs, undefined terms, gaps in logic?
4. **Key items** — formulas, definitions, theorems, traps, edge cases?

Flag to user if subject is ambiguous before proceeding.

### Auto-enrichment (always apply, no user prompt needed):
After extracting what the user wrote, the agent must:
- **Fill gaps**: if a definition is incomplete, complete it correctly using standard GATE DA material.
- **Add what's missing**: if a key property, edge case, or common trap is absent from the notes, add it under a `> [!note] Added by agent` callout — so the user knows it wasn't in their original notes.
- **Flag mistakes**: if the user's note contains an error (wrong formula, incorrect claim), correct it inline and mark with `> [!danger] ⚠ Corrected: <original mistake>`.
- **Surface the most important thing**: identify the single highest-weightage / most-tested fact in the topic and mark it with `⭐ GATE PRIORITY` — even if the user didn't emphasise it.
- Do NOT silently ignore errors. Corrections must be visible.

---

## Phase 2 — Build Obsidian Note

### File naming convention:
```
<SUBJECT>-<topic-slug>.md
e.g.  ML-bias-variance-tradeoff.md
      STATS-bayes-theorem.md
      LA-eigenvalues.md
```

### Save path:
```
~/til/vault/notes/<SUBJECT>/<filename>.md
```

### Note template:

```markdown
---
tags: [gate-da, <subject>, <topic>]
aliases: [<short topic name>]
created: <YYYY-MM-DD>
source: handwritten | doc | typed
---

# <Topic Name>

> [!abstract] One-line summary
> What this concept IS, in one sentence.

## Core Definition
$$<key formula or definition>$$

**Key variables:** define each symbol inline.

## Key Properties
> [!tip] GATE tests these most
> - Property 1
> - Property 2
> - Property 3 ← **common trap**

## Important Results / Theorems
| Result | Condition | Formula |
|--------|-----------|---------|
| | | |

## Edge Cases & Boundary Conditions
> [!warning] Don't get caught
> - Edge case 1
> - Edge case 2

## GATE Focus
> [!example] High-weightage sub-topics
> - Sub-topic A — appears as MCQ type
> - Sub-topic B — appears as NAT type

**⭐ Formula sheet:**
$$<formula 1>$$
$$<formula 2>$$

## Quick Recall
| Term | Meaning |
|------|---------|
| | |

## Connects To
← [[<related-topic-1>]] | [[<related-topic-2>]]

---
*Source: handwritten notes — <date>*
```

---

## Phase 3 — Enrich

After filling the template, apply these passes in order:

### Pass 1: Callout audit
Every section must have at least one callout. Use:
- `[!abstract]` — summary / definition
- `[!tip]` — properties GATE tests
- `[!warning]` — traps, common errors, edge cases
- `[!example]` — question patterns, worked examples
- `[!note]` — extra context, derivations, memory tricks
- `[!danger]` — guaranteed wrong answer if missed

### Pass 2: Formula check
- Every formula in LaTeX, properly typeset
- Inline: `$f(x)$` — for variables mid-sentence
- Block: `$$\sum_{i=1}^n x_i$$` — for standalone equations
- Star `⭐` any formula that appears in GATE papers more than twice

### Pass 3: Table injection
If the note has ≥3 comparable items (e.g. distributions, algorithms, metrics),
force them into a comparison table. Tables > bullets for GATE quick revision.

### Pass 4: Link injection
Check `~/til/vault/notes/` — find any related existing notes.
Add `[[wiki-links]]` in the "Connects To" section.
Never create orphan notes.

### Pass 5: Flashcard block
Append a flashcard at the bottom for the most-likely-tested concept:
```markdown
<Most-testable concept or misconception> #flashcard
- <Definition / intuition in 2-3 lines>
- Key formula: $<formula>$
- GATE trap: <what trips people up>
^^^
```

---

## Phase 4 — Quality Check

Before writing the file, verify:
- [ ] File name follows `<SUBJECT>-<slug>.md` convention
- [ ] Tags include `gate-da` and subject tag
- [ ] Every major section has a callout
- [ ] All formulas render correctly in LaTeX
- [ ] At least one `[!warning]` for traps
- [ ] At least one `⭐` formula
- [ ] Flashcard block at the end
- [ ] `[[wiki-links]]` to ≥1 related note
- [ ] No prose dumps — bullets and tables only in properties sections

---

## Phase 5 — Write File

### Pre-write: check for existing file
1. `Desktop Commander: list_directory ~/til/vault/notes/<SUBJECT>/`
2. Look for any file whose name matches the topic (fuzzy — same concept, different slug).
3. **If match found → `mode: append`**, add a `---` separator and a dated section header:
   ```markdown
   ---
   ## <Topic> — Updated <YYYY-MM-DD>
   <new content here>
   ```
4. **If no match → `mode: rewrite`** with full template.

```
Desktop Commander: write_file
  path: ~/til/vault/notes/<SUBJECT>/<filename>.md
  mode: rewrite | append  (decided above)
```

Confirm path with user only if subject is ambiguous.

---

## Rules
- Never write a wall of prose. Dense structure wins.
- If handwriting is ambiguous, show the [?] extraction to user and ask before formatting.
- If converting multiple pages, do one topic per file — never merge different concepts.
- Derivations go in a collapsed `<details>` block or a linked separate note, not inline.
- Don't invent content. Mark gaps as `<!-- TODO: verify -->`.
- After writing, output the file path and a 2-line summary of what was created.

---

## Output to User (after write)

```
✅ Note written: ~/til/vault/notes/<SUBJECT>/<filename>.md
   Topic: <topic name> | <N> callouts | <N> formulas | <N> links
   Flashcard added: <concept tested>
```
