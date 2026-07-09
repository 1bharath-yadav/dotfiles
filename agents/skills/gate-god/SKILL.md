---
name: gate-god
description: |
  3-stage deep mastery system for GATE Data Science & AI preparation.
  Stage 1: Subject-wise study session prompts. Stage 2: Comprehensive concept
  hierarchies (all variations, angles, perspectives). Stage 3: Deep-dive per
  concept with subject-specific study methods. Integrates with gate-god.html
  tracker and ai-office vision-notes for PDF generation. Target: MIT/Stanford
  research-ready depth.
---

# GATE God — Deep Mastery Skill

## Trigger

User says any of:

- "gate god" / "gate-god"
- "study session: \<subject\>"
- "deep dive: \<concept\>"
- "generate concept tree: \<subject\>"
- "update gate-god"
- "what should I study deeply"

---

## Context Files — Read These First

1. `~/til/wiki/schema/USER.md` — Bharath's profile, schedule, learning style
2. `~/zen_spaces/AI_DS_PH/Gate-Datascience-syllabus.md` — official GATE DA syllabus
3. `~/zen_spaces/AI_DS_PH/GATE-DA/gate-god.html` — concept tracker (source of truth for all concepts)
4. `~/.dotfiles/agents/skills/gate-god/prompts/` — subject-specific prompt templates

---

## Subject IDs & Colors

| ID               | Subject                  | Study Method                                         |
| ---------------- | ------------------------ | ---------------------------------------------------- |
| `prob-stats`     | Probability & Statistics | Derivation + intuition + GATE patterns               |
| `linear-algebra` | Linear Algebra           | Geometric intuition + matrix computation + proofs    |
| `calculus-opt`   | Calculus & Optimization  | Rough work + graphical + Taylor                      |
| `prog-dsa`       | Programming, DSA         | Implement first → analyze → pattern recognize        |
| `database`       | Database & Warehousing   | Schema design + query writing + normalization drills |
| `ml`             | Machine Learning         | Intuition → math → code → edge cases → GATE traps    |
| `ai`             | Artificial Intelligence  | Algorithm trace + tree drawing + logic proofs        |
| `ga`             | General Aptitude         | Timed practice + pattern banks                       |

---

## Stage 1 — Generate Study Session Prompt

When user requests a study session for a subject:

1. Read the corresponding prompt template from `prompts/<subject-id>.md`
2. Customize it based on:
   - Which concepts the user has already completed (check gate-god.html state or ask)
   - User's current energy/time (morning = hard concepts, evening = review)
   - Any specific weak areas mentioned
3. Output the prompt — either run it directly or format it for copy-paste

---

## Stage 2 — Concept Hierarchy Session

When user requests a concept hierarchy for a subject or topic:

### Output Format

```
SUBJECT: <name>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
TOPIC: <name>
  ├── Concept 1
  │   ├── What it IS (definition, formal + informal)
  │   ├── WHY it exists (motivation, what problem it solves)
  │   ├── HOW it works (mechanism, algorithm, proof sketch)
  │   ├── Variations (types, special cases)
  │   ├── Perspectives (geometric, algebraic, probabilistic, computational)
  │   ├── Connections (to other concepts in this subject and others)
  │   ├── Edge cases & traps (common GATE mistakes)
  │   └── Patterns (recurring problem types, solution templates)
  ├── Concept 2
  │   └── ...
```

### Depth Guidelines

- **Naive level**: Start with the simplest correct explanation. Use analogy.
- **Intermediate**: Add formal definition, key properties, first proof/derivation.
- **Advanced**: All variations, edge cases, connections to other fields.
- **MIT/Stanford**: Research perspective — why this concept matters beyond exams.

### Concept Coverage Mandate

The hierarchy stored in `gate-god.html` is the minimum. If the agent discovers
sub-concepts, variations, or perspectives NOT in the HTML, add them to the
session AND flag them for addition to the tracker.

---

## Stage 3 — Deep Concept Study

When user requests a deep dive on a specific concept:

### Step 1: Identify Concept Type

| Type                  | Method                                              | Output Style                                    |
| --------------------- | --------------------------------------------------- | ----------------------------------------------- |
| **Math/Formula**      | Derivation walkthrough + rough work exercises       | Step-by-step, boxed formulas, practice problems |
| **Algorithm**         | Trace through example → implement → analyze         | Code + trace table + complexity analysis        |
| **Theory/Definition** | Definition → why → when → comparison                | Structured notes with comparison tables         |
| **Model/Technique**   | Intuition → math → code → evaluate                  | Mixed: diagrams + equations + code              |
| **Proof**             | Statement → intuition → formal proof → implications | Proof structure with commentary                 |

### Step 2: Generate Content

Structure for handwritten notes (A4 paper):

```
┌─────────────────────────────────────────┐
│ CONCEPT: <name>                    p. X │
│─────────────────────────────────────────│
│ ⚡ ONE-LINE: <what it is, 1 sentence>   │
│                                         │
│ 📐 FORMAL DEFINITION:                   │
│   <mathematical/formal definition>      │
│   <define each symbol>                  │
│                                         │
│ 💡 INTUITION:                           │
│   <analogy, geometric picture, or ELI5> │
│                                         │
│ 🔑 KEY PROPERTIES:                      │
│   1. ...                                │
│   2. ... ← ⚠ GATE TRAP                 │
│   3. ...                                │
│                                         │
│ 🔗 CONNECTIONS:                         │
│   → <related concept 1>                │
│   → <related concept 2>                │
│                                         │
│ ⭐ FORMULA SHEET:                       │
│   ┌─────────────────────────────┐       │
│   │ <key formula, boxed>        │       │
│   └─────────────────────────────┘       │
│                                         │
│ 📝 PRACTICE:                            │
│   Q1: <GATE-style question>             │
│   Q2: <variation>                       │
│                                         │
│ ⚠ COMMON MISTAKES:                     │
│   • <mistake 1>                         │
│   • <mistake 2>                         │
└─────────────────────────────────────────┘
```

### Step 3: Image Generation

Generate images when the concept involves:

- **Geometric intuition** (vector projections, hyperplanes, decision boundaries)
- **Algorithm visualization** (tree traversals, sorting steps, graph search)
- **Data flow diagrams** (neural network architecture, pipeline flows)
- **Plots/graphs** (distributions, loss curves, bias-variance)
- **Comparison diagrams** (side-by-side visual of two approaches)

Use the `generate_image` tool. The image should be:

- Clean, labeled, no clutter
- Dark background if possible (matches note aesthetic)
- Large enough to be readable when printed

### Step 4: PDF Generation (Optional)

When handwritten notes aren't practical (large tables, complex diagrams):

1. Generate content as JSON matching ai-office vision-notes schema
2. Save to `~/projects/ai-office/vision-notes/content_json/`
3. Run: `cd ~/projects/ai-office && npm run notes:build`
4. Output PDF saved to `~/projects/ai-office/vision-notes/output_pdfs/`
5. Copy PDF to `~/zen_spaces/AI_DS_PH/GATE-DA/<subject>/pdfs/`

---

## Study Flow — Per Session

```
1. USER: "study session: probability"
2. AGENT reads prompt template + checks progress in gate-god.html
3. AGENT identifies next uncompleted concepts in priority order
4. For each concept:
   a. Start with naive-level introduction (assume zero knowledge)
   b. Build to intermediate (formal definitions, key results)
   c. Dig to Stanford depth (proofs, connections, research context)
   d. Provide handwritten-note-ready content
   e. Generate images where visual explanation > text
   f. Give 2-3 GATE-style practice problems
   g. Highlight common traps
5. After concept is understood:
   - USER marks "completed" in gate-god.html
   - USER takes handwritten notes for retention
   - Later: USER attempts GATE PYQs, marks "tested" when confident
```

---

## Rules

1. **Start small, go deep**: Every concept begins with a simple introduction.
   Like MIT OpenCourseWare — accessible start, rigorous depth.
2. **Subject-specific methods**: Don't teach math like you teach programming.
   Each subject has its own optimal learning method (see table above).
3. **No surface-level**: Every explanation must answer WHY, not just WHAT.
   If you can't explain why a concept exists, you don't understand it.
4. **Handwritten notes priority**: Content should be structured for A4 paper.
   Claude generates images when text can't explain it linearly.
5. **GATE alignment**: Every concept connects back to GATE exam patterns.
   But depth goes beyond GATE — aim for research-ready understanding.
6. **Honest assessment**: If Bharath's understanding has gaps, say so.
   Don't move forward if foundations are weak.
7. **Track progress**: After each session, remind to update gate-god.html.
8. **IITM overlap**: PDSA and DBMS concepts that overlap with IITM should
   be prioritized — study once, cover both exams.
