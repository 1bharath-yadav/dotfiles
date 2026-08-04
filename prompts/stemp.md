# STEMP — Build Specification & Agent Prompt

**STEMP** = Science, Technology, Engineering, Mathematics, Power/student-eMPowerment.
A local-first, open-source, MIT/Stanford/IIT-grade mastery-learning platform, ADDICTIVE.

Act as a senior software architect, learning scientist, AI education platform designer, and
open-source maintainer. Build the system below. **Do not generate educational content yet** —
first build architecture, schemas, plugin interfaces, and tooling. Content is added gradually,
by the project owner (directly or via reviewed AI content-creation agents) — content can be modified,highlighted,updated live by an end user during a learning session.

---

## 1. Guiding Principles

1. **Deep understanding over coverage** — every concept teaches intuition → fundamentals →
   abstraction → connections → mastery, MIT/Stanford/IIT classroom depth.
2. **Everything is data.** Content, questions, problems, visualizations, and learning paths are
   file-based, schema-validated, and directly editable — never hardcoded in UI.
3. **Maximum decoupling.** Every replaceable part (AI provider, code-execution runtime,
   visualization renderer, search engine, content format) sits behind a small interface so it can
   be swapped, forked, or community-extended without touching core.
4. **Local-first, user-owned.** Runs entirely on the user's machine. No forced telemetry, no
   forced cloud dependency, user controls their own keys/data.
5. **Open source, reuse over rebuild.** Prefer forking/wrapping permissively-licensed projects
   (MIT/Apache) over reimplementing solved problems (sandboxing, SRS math, canvas editors).

---

## 2. Dashboard Hierarchy

```
Dashboard Entry
    └── Subject
          └── Topic
                └── Concept
```

Initial dashboard entries: **Aptitude, Engineering Mathematics, Data Science, Physics.**
Architecture must allow adding new dashboard entries, subjects, topics, and concepts without
code changes — pure content additions.

Example: _Engineering Mathematics → Linear Algebra (subject) → Vector Spaces, Eigenvalues,
Eigenvectors (concepts)_. Do not conflate subjects and topics.

---

## 3. Tech Stack

### Frontend

- **Next.js (App Router) + TypeScript** — MDX rendering, component-driven UI, best fit for
  React Flow / D3 / Three.js visualizations.
- **Velite** for the MDX/content build pipeline (type-safe, schema-validated frontmatter).
- **Tailwind CSS + shadcn/ui** for a restyled, accessible component base.
- **Zustand** for client state.
- **KaTeX** for math rendering.
- **Orama or MeiliSearch** for full-text search across all content (see §9).

### Backend

- **Python + FastAPI** — chosen deliberately, not just "either works," because it's the natural
  host for marimo, Colab-CLI, code-execution orchestration, and future ML-based calibration
  (§8, §11). FastAPI + Pydantic mirrors the frontend's "strict schema" discipline server-side.
- **SQLModel (SQLAlchemy + Pydantic) + Alembic** for the ORM/migrations.
- **SQLite** as the datastore — single file, trivial backup, fits local deployment. (Swap to
  Postgres only if/when multi-user or cloud sync is ever added — keep the ORM layer agnostic.)
- **SSE (Server-Sent Events)** for streaming AI responses and long-running job status (code exec,
  Colab dispatch).

### Frontend ⇄ Backend

Next.js is the **BFF-consuming client**; FastAPI is the **backend of record** for auth, mastery
computation, LLM orchestration, execution-job dispatch, and the marimo/Colab proxy layer. Talk
over REST/JSON + SSE. Keep this boundary strict so either side can be replaced independently.

### Monorepo & Tooling

- **pnpm workspaces** (frontend) + a Python **uv/poetry**-managed backend package, orchestrated
  via a root `Makefile` or `turbo` for shared scripts.
- **Docker Compose** for the full stack: Next.js, FastAPI, Judge0/Piston, marimo, MeiliSearch,
  optional Ollama — `docker compose up` should be the entire onboarding story.

---

## 4. Core Learning Model — Concept Page

Concept pages are **textbook chapters, not FAQs**. `sections` is a flexible, custom-keyed map
(schema requires only `minProperties: 1` — no fixed list). Author 4-7 substantial sections per
concept, each 2-5 paragraphs of continuous prose that builds intuition -> formal definition ->
examples -> edge cases -> connections as one narrative, never twelve short disconnected mini-answers
that each just restate their own heading.

Themes to weave in somewhere (not mandatory separate headings): motivation, intuition, formal
notation, internal mechanisms, properties, real-world applications, common misconceptions, advanced
perspectives. **Connections with other concepts** stay structured data — an explicit knowledge-graph
edge list (§6) — never prose.

---

## 5. Think & Discuss + Problem System

**Think & Discuss** (end of every topic): conceptual questions testing current-topic understanding

- prerequisite recall + cross-domain connections (e.g. math reasoning inside a DSA topic, physics
  inside a math topic). Categories: conceptual, prerequisite recall, advanced thinking, real-world
  scenario, cross-domain, research-style. Formats: MCQ, MSQ, Integer type.
  Difficulty ladder: **Easy → Medium → Hard → Tricky → Mind-bending.**

**Problems** (dropdown by difficulty: Easy/Medium/Hard): statement, learning objective,
constraints, examples, hints, concept connections, expected approach, solution explanation,
complexity analysis, notes.

**Programming problems**: full-screen split interface — left: statement/examples/constraints/
hints; right: code editor, execution, output, test cases. Execution backend is user-selectable
(§8).

**Further Research** (only where meaningful): 10–20 lines — advanced ideas, research
connections, modern applications, open problems.

---

## 6. Knowledge Graph

Concepts are nodes in an explicit prerequisite DAG (`concept_id → [prerequisite_ids]`), stored as
structured data, not inferred from prose. This graph is what powers:

- Cross-domain question generation
- Mastery propagation (weak prerequisite ⇒ flagged even if the current concept quiz passes)
- A visual "skill tree" (React Flow) per subject/dashboard entry

---

## 7. Mastery Model & Progress Circles (new — was undefined in v1)

Define mastery as a computed, not stored, aggregate:

```
mastery(concept) = f(SRS recall strength, problem success rate, recency, attempt count)
mastery(topic)   = weighted avg of mastery(concept) for all concepts in topic
mastery(subject) = weighted avg of mastery(topic)
mastery(dashboard)= weighted avg of mastery(subject)
```

The **progress circle** on every dashboard/subject/topic card renders this same rolled-up number —
one formula, reused at every level, so it's consistent everywhere it appears.

---

## 8. Pluggable Execution Backends (expanded)

Problems/visualizations declare a `runtime` field; the platform ships four, user-selectable
globally or per-problem, all behind one execution interface:

| Runtime                                                        | Use case                                                                     |
| -------------------------------------------------------------- | ---------------------------------------------------------------------------- |
| **Pyodide**                                                    | in-browser Python, zero infra, safe by construction                          |
| **Judge0 / Piston** (self-hosted, MIT/Apache)                  | language-agnostic Easy/Medium/Hard coding problems, sandboxed                |
| **marimo** (embedded local Python service, reactive notebooks) | live, explorable concept demos (e.g. "play with this eigenvector transform") |
| **Colab-CLI** (user's own already-authenticated runtime)       | compute-heavy problems — ML, larger datasets, GPU — with zero hosting burden |

Never execute arbitrary user code directly on the host unsandboxed. This is a local single-user
deploy, but "local" is not a substitute for isolation — container-level sandboxing, timeouts, and
memory caps apply to every runtime except Pyodide (browser-sandboxed already).

---

## 9. Search

Full-text search across all concepts/problems/questions via **MeiliSearch** (self-hosted, in the
Docker Compose stack) or **Orama** (in-browser, if you want zero extra service). Index rebuilds on
content publish (§12).

---

## 10. AI Assistant — Guru (expanded)

Guru's role: clear confusion, hint, guide via Socratic questioning — **never reveals solutions
unless explicitly asked.** Guru is present throughout the platform but only ever _consumes_
content and the knowledge graph; it never writes into the content store.

### Provider modes — all three implemented, user-configurable in Settings, one shared interface:

```
AIProvider.ask(context: StructuredContext) -> Stream[str]
```

1. **API mode** — user supplies their own key (Anthropic/OpenAI/etc.), stored in an **encrypted
   local secrets store** (never plaintext `.env`), streamed via FastAPI SSE.
2. **Paste mode** — builds the same structured Socratic prompt (`concept, question, attempt, code,
error, learning context`) and copies it / opens browser ChatGPT. No infra, no key required.
3. **Local model mode (Ollama)** — for users who want zero cost and zero data leaving the machine.
   Not "future work" — build it alongside the other two from day one; it's the natural default
   for a local-first OSS project.

All three implement the same interface so Guru's UI never needs to know which is active.

---

## 11. Assignments & Mock Tests

Per subject: chapter assignments, topic assignments, subject mock tests.
Per dashboard entry: complete dashboard mock tests.
Also: combined mock tests spanning multiple dashboard entries.

---

## 12. Content Architecture, Ownership & QA Pipeline

All content is file-based and **authored by the project owner** — written directly or produced by
AI content-creation agents that must follow strict Pydantic/Zod schemas and are always reviewed
before publish. State machine per content item: **draft → validated (schema + link + math-render
checks pass) → published (enters search index, visible to learners).**

```
content/
├── aptitude/
├── engineering-mathematics/
│   └── linear-algebra/
│       ├── topics/
│       ├── concepts/
│       ├── questions/
│       ├── problems/
│       ├── visualizations/
│       ├── assignments/
│       ├── mocktests/
│       └── metadata/
├── data-science/
└── physics/
```

Every schema (concept, question, quiz, problem, visualization, animation, metadata, assignment,
mocktest) is documented in `docs/schemas/` and enforced by matching Pydantic (backend) and Zod
(frontend/Velite) definitions generated from a **single source of truth** (e.g. JSON Schema, so
both languages stay in sync automatically rather than hand-duplicated).

---

## 13. Visualization System

Reusable, pluggable renderer registry (`type → component`), supporting: graph visualization, data
structure animation, mathematical visualization, physics visualization, interactive diagrams,
step-by-step execution. Libraries: D3.js, React Flow, Three.js, Manim-generated animations, SVG,
Canvas. Consider **Excalidraw/tldraw** (MIT-licensed) if freehand/whiteboard diagrams are ever
needed — don't build a canvas editor from scratch.
`docs/visualizations.md` defines: when to use each type, data format, rendering rules, performance
considerations.

---

## 14. User Data System

- Export/import full learning history (progress, notes, solved problems, attempts, weak concepts).
- Separately: **DB-level backup/restore** for the SQLite file itself (distinct from the
  human-portable export above).
- Track: progress, notes, solved problems, attempts, weak concepts, learning history.

---

## 15. Memory & Revision System

- **ts-fsrs** (FSRS algorithm — modern successor to SM-2) for spaced repetition scheduling.
- Recall system + memory retrieval exams built on top of the same scheduler.
- Goal: activate deep memory pathways through repeated, spaced retrieval + problem solving.

---

## 16. UI / Theme

**Eye-friendly, not pure black-and-white.**

- Dark mode background: off-black (`#121212`–`#161618`); light mode: warm off-white (`#faf9f6`).
  Never true `#000`/`#fff` (causes glare/halation over long sessions).
- Text: high contrast without max contrast (`#e8e8e6` on dark / `#1c1c1e` on light) — meets WCAG
  AA, not eye-searing.
- One muted accent color only, used sparingly (interactive elements, progress rings).
- Typography: sans for UI (Inter or similar), serif for long-form concept body text
  (Charter/Source Serif — reduces fatigue over long reads). Line length ≈70ch, line-height ≥1.6.
- Respect `prefers-color-scheme`, with manual override in Settings.
- Accessibility (WCAG AA contrast, focus states, keyboard nav) is a hard requirement, not a
  nice-to-have.

---

## 17. `~/projects/tools` Convention (repeatable tools built along the way)

```
tools/
  <tool-name>/
    tool.skill.md     # Purpose / When to use / Usage / Example / Dependencies
    bin/ or script.*   # the executable
    README.md          # optional — tool.skill.md can double as this
```

Known tools to build early (genuinely reusable, not app-internal):

- `setup-doctor` — checks Python/Node versions, port conflicts, Docker availability pre-first-run.
- `new-concept` / `new-problem` / `new-topic` — scaffolds a schema-valid MDX/JSON skeleton from a
  template; likely the highest-leverage tool since content authoring is the ongoing bulk of work.
- `execution-runtime-adapter` — the shared interface behind Pyodide/Judge0/marimo/Colab-CLI (§8),
  factored out so it's independently reusable/forkable.
- `content-linter` — runs the draft→validated schema/link/math checks (§12) as a standalone CLI,
  reusable in CI or pre-commit.

---

## 18. Security & Privacy

- Sandboxed code execution everywhere except Pyodide (browser-sandboxed already) — see §8.
- Encrypted local secrets store for API keys — never plaintext.
- **No telemetry by default.** If usage analytics exist, they are opt-in and anonymous, documented
  explicitly — this matters for OSS trust.

---

## 19. Documentation (`docs/`)

- Architecture & folder structure
- Data schemas (source-of-truth JSON Schema + generated Pydantic/Zod)
- Content creation & QA workflow
- Visualization rules
- AI content-agent guidelines (what they may/may not do, review gate)
- Plugin interfaces (AI provider, execution runtime, visualization type) — how to add a new one
- Development workflow & contribution guidelines
- Written so a future AI agent can understand and safely extend the project unsupervised

---

## 20. Build Order (do not skip ahead)

1. System architecture + monorepo/Docker Compose skeleton
2. Folder structure (`content/`, `docs/`, `tools/`, frontend, backend)
3. Data schemas (JSON Schema source-of-truth → Pydantic + Zod)
4. Plugin interfaces: AI provider, execution runtime, visualization renderer
5. Rendering engine (MDX pipeline, concept page template)
6. Component architecture (Next.js + shadcn/ui, theme tokens per §16)
7. Knowledge graph + mastery model (§6, §7) — foundational, everything else depends on it
8. Content creation workflow + AI agent guidelines + QA pipeline (§12)
9. Core tools (`setup-doctor`, `new-concept`, `content-linter`) (§17)

**Content itself is added gradually, topic by topic, after the above is solid.**

---

---

## 21. AI Agent Prompts for Content Authoring

The canonical Course Planner (Phase 1) and Deep Module Author (Phase 2) prompts live exclusively in `tools/content-adder/tool.skill.md` (§6). All content authoring agents must read `stemp.schema.json` and `tools/content-adder/tool.skill.md` before generating content.
