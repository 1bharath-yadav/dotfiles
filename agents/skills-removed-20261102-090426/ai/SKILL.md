---
name: ai
description: >-
  Unified multi-model CLI router (command 'ai') for querying, consulting, and delegating tasks to 12 frontier AI platforms (Claude 3.5 Sonnet, Gemini 2.0 Flash/Pro, DeepSeek-V3/R1, ChatGPT GPT-4o, Grok, Qwen, Mistral, Meta AI, Kimi, MiniMax, Z.ai, and Copilot). Use whenever you need a second opinion, independent code review, deep mathematical or algorithmic reasoning (DeepSeek R1), live web search verification, image generation (Imagen 3, DALL-E 3, Flux), video generation (Hailuo), or cross-model consensus. Make sure to use this skill whenever the user mentions asking other models, comparing frontier outputs, or running the 'ai' CLI, even if they only mention a single model like 'ask claude', 'ask deepseek', or 'ask gemini'.
metadata:
  version: "2.0"
  cli: "ai"
  providers: "chatgpt, claude, gemini, deepseek, zai, minimax, kimi, grok, qwen, mistral, meta, copilot"
---

# ai — Frontier AI CLI Router

The `ai` CLI is a high-performance, unified command-line router that provides instant access to 12 frontier AI ecosystems directly from your terminal, scripts, and agent workflows.

## Quick Start

```bash
# Query default provider (ChatGPT)
ai "Summarize the key trade-offs between Paxos and Raft"

# Explicit provider overrides
ai --claude "Review this architecture for race conditions"
ai --deepseek --think "Prove that every planar graph is 5-colorable"
ai --gemini "Synthesize current developments in quantum error correction"

# Dedicated executable shims (equivalent to ai --<provider>)
claude-ai "Explain this regex"
deepseek-ai --think "Analyze time complexity"
gemini-ai --imgen "Architectural blueprint of a Mars habitat" -o mars.png
```

---

## Model Selection Matrix

Always choose the provider best suited for the specific task:

| Capability / Task | Recommended Provider | Command Example | Key Strength |
| :--- | :--- | :--- | :--- |
| **Deep Reasoning & Math** | **DeepSeek R1** | `ai --deepseek --think "..."` | Industry-leading chain-of-thought for competitive math, formal logic, and hard algorithms. |
| **Code Architecture & Refactoring** | **Claude 3.5 Sonnet** | `ai --claude "..."` | Superior code structure, clean diffs, and artifact extraction (`--artifacts`). |
| **Large Context & Fast Research** | **Gemini 2.0** | `ai --gemini "..."` | Massive context processing, fast retrieval, and text-to-speech narration (`--tts`). |
| **Image Generation (Photorealistic)** | **Gemini (Imagen 3)** or **Mistral (Flux)** | `ai --gemini --imgen "..." -o out.png`<br>`ai --mistral --imgen "..." -o out.png` | State-of-the-art prompt adherence and visual realism. |
| **Live Web Search & Grounding** | **DeepSeek** or **Kimi** | `ai --deepseek --search "..."`<br>`ai --kimi --search "..."` | Real-time web citations, fact verification, and current event synthesis. |
| **Video Generation** | **MiniMax (Hailuo)** | `ai --minimax --scene video "..."` | Dedicated high-coherence physical video scene generation. |
| **Fast / Open-Weight Inferences** | **Meta AI** or **Mistral** | `ai --meta "..."`<br>`ai --mistral -m fast "..."` | Low latency, Llama 3.3 / Mistral Large reasoning. |
| **Science, Domain Depth & Search** | **Grok** or **Copilot** | `ai --grok "..."`<br>`ai --copilot -m think "..."` | Broad domain retrieval, Think Deeper synthesis. |
| **Multilingual & Specialized Logic** | **Qwen** or **Z.ai** | `ai --qwen --think "..."`<br>`ai --zai --think "..."` | Qwen 2.5-Max and GLM-5.3 deep Chinese/English reasoning. |

For exhaustive provider capabilities, see [`references/providers.md`](references/providers.md).

---

## Universal CLI Flags

The `ai` router standardizes flags across all 12 providers:

| Flag | Description | Examples |
| :--- | :--- | :--- |
| `--<provider>` | Target provider (`--chatgpt`, `--claude`, `--gemini`, `--deepseek`, `--zai`, `--minimax`, `--kimi`, `--grok`, `--qwen`, `--mistral`, `--meta`, `--copilot`) | `ai --claude "..."` |
| `-n`, `--new` | Start a clean, fresh conversation thread (prevents context contamination) | `ai --claude -n "New topic"` |
| `-a`, `--attach <path>` | Attach one or more local files (code, PDFs, images, text) | `ai --claude -a main.py -a test.py "Find bugs"` |
| `--json` | Output machine-readable JSON (with response text, code blocks, or thinking) | `ai --claude --json "..." \| jq -r .text` |
| `--check` | Verify reachability and readiness for a specific provider | `ai --claude --check` |
| `--all-check` | Check connection and readiness across all 12 active providers | `ai --all-check` |

### Stdin Piping

`ai` automatically reads from standard input if piped and no prompt argument is passed (or appends piped input to the prompt):

```bash
# Pipe diffs or file contents directly
git diff | ai --claude "Review this diff for security regressions"

# Pipe logs for root-cause diagnosis
journalctl -u my-service.service -n 50 | ai --deepseek --think "Diagnose root cause"

# Combine file pipe with specific instructions
cat schema.sql | ai --gemini "Convert this PostgreSQL schema to SQLite"
```

---

## Specialized Modalities & Feature Toggles

### 1. Deep Reasoning Mode (`--think` / `--no-think`)
Forces the provider to engage dedicated reasoning / thinking models (e.g., DeepSeek R1, Z.ai Deep Think, Qwen Reasoning, Meta Thinking, Copilot Think Deeper):

```bash
ai --deepseek --think "Optimize this NP-hard scheduling heuristic"
ai --deepseek --think --show-thinking "Derive the Poisson distribution"
ai --qwen --think "Implement an lock-free ring buffer in Rust"
```

### 2. Live Web Search (`--search`)
Enables real-time internet search grounding for live facts, package documentation, and breaking updates:

```bash
ai --deepseek --search "What are the latest breaking changes in PyTorch 2.6?"
ai --kimi --search "Current status of CUDA support on Arch Linux kernel 6.13"
```

### 3. Image Generation (`--imgen ... -o <path>`)
Generates high-resolution images and saves them directly to disk:

```bash
# Gemini (Imagen 3)
ai --gemini --imgen "Cyberpunk hacker workspace in rainy Neo-Tokyo, volumetric lighting, 8k" -o workspace.png

# Mistral (Flux.1)
ai --mistral --imgen "Minimalist vector logo for an AI automation agent" -o logo.png

# Meta AI (Meta Imagine)
ai --meta --imgen "Studio photograph of an ergonomic split mechanical keyboard" -o keyboard.png

# ChatGPT (DALL-E 3)
ai --chatgpt --imgen "Isometric cross-section diagram of an electric hypercar" -o car.png
```

### 4. Text-to-Speech Narration (`--tts`)
Reads aloud the generated response or input text using high-fidelity neural voices:

```bash
ai --gemini --tts "Explain how zero-knowledge proofs work in simple terms"
ai --mistral --tts "Summarize this morning's briefing"
```

### 5. Mode Selectors (`-m <mode>`)
Certain providers offer specialized reasoning modes:
- **Mistral**: `-m fast` (ultra-low latency), `-m think` (deep chain-of-thought), `-m research` (broad research paper analysis)
- **Copilot**: `-m smart` (balanced), `-m think` (deep analytical synthesis), `-m study` (pedagogical explanation), `-m search` (pure web search)

```bash
ai --mistral -m research "Survey of speculative decoding techniques"
ai --copilot -m think "Solve the Navier-Stokes existence and smoothness problem overview"
```

---

## Common Agent Patterns

### Pattern 1: Independent Code Review
Get a second opinion from Claude on a diff or PR:

```bash
git diff main...HEAD | ai --claude -n "Act as a principal engineer. Review this diff for:
1. Subtle race conditions or deadlocks
2. Memory leaks or unbounded queues
3. Missing edge case handling
Be concise and bulleted."
```

### Pattern 2: Mathematical / Algorithm Verification
Use DeepSeek R1 to mathematically verify an algorithm:

```bash
ai --deepseek --think -n "Verify whether the following dynamic programming recurrence is correct:
dp[i][j] = min(dp[i-1][j] + cost(i), dp[i][j-1] + cost(j))
Identify any edge cases where this recurrence violates the optimal substructure property."
```

### Pattern 3: Multi-Model Consensus (Triangulation)
When making high-stakes architectural decisions, query multiple frontier models in parallel:

```bash
PROMPT="What is the safest strategy to migrate a 5TB PostgreSQL database with 0 seconds downtime?"

echo "=== Claude 3.5 Sonnet ==="
ai --claude -n "$PROMPT"

echo "=== DeepSeek R1 ==="
ai --deepseek --think -n "$PROMPT"

echo "=== Gemini 2.0 ==="
ai --gemini -n "$PROMPT"
```

### Pattern 4: Structured Data Extraction via JSON
Use `--json` and `jq` for machine consumption:

```bash
ai --claude --json -n "Extract all function signatures from this snippet and return them in structured text:
$(cat api.py)" | jq -r '.text'
```

For more recipes and automated bash helper functions, see [`references/recipes.md`](references/recipes.md).

---

## Health & Diagnostics

If an agent encounters connection timeouts or needs to verify provider availability:

```bash
# Audit all 12 providers at once
ai --all-check

# Audit a single provider
ai --claude --check
ai --gemini --check
ai --deepseek --check
```

- **Exit Code 0**: Success; the command executed cleanly and returned the model output.
- **Exit Code 1**: An error occurred (e.g. invalid arguments, login required, or network timeout). Check stderr for details.
