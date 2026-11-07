# Practical CLI Recipes & Automation Patterns

Bash scripting patterns for AI agents utilizing the `ai` router.

---

## 1. Automated PR / Diff Review Script

Pipe git changes directly to Claude 3.5 Sonnet to obtain an automated senior engineer review before committing or pushing:

```bash
#!/usr/bin/env bash
set -euo pipefail

# Check if there are uncommitted changes
if git diff --quiet && git diff --cached --quiet; then
  echo "No local changes to review."
  exit 0
fi

echo "Requesting code review from Claude 3.5 Sonnet..."
git diff HEAD | ai --claude -n "Act as a staff software engineer conducting a code review.
Review this git diff and provide:
1. Critical correctness issues, potential panics, or memory safety bugs.
2. Performance bottlenecks or suboptimal algorithmic complexity.
3. Edge case considerations not covered in tests.
Keep feedback concise, actionable, and formatted in markdown."
```

---

## 2. Multi-Model Consensus (Triangulation)

When evaluating high-stakes architectural decisions or complex algorithms, query multiple frontier models and compare their assessments:

```bash
#!/usr/bin/env bash
set -euo pipefail

PROMPT="$1"
OUTPUT_DIR="consensus_$(date +%s)"
mkdir -p "$OUTPUT_DIR"

echo "Querying Claude 3.5 Sonnet..."
ai --claude -n "$PROMPT" > "$OUTPUT_DIR/claude.md" &
PID_CLAUDE=$!

echo "Querying DeepSeek R1..."
ai --deepseek --think -n "$PROMPT" > "$OUTPUT_DIR/deepseek.md" &
PID_DEEPSEEK=$!

echo "Querying Gemini 2.0..."
ai --gemini -n "$PROMPT" > "$OUTPUT_DIR/gemini.md" &
PID_GEMINI=$!

wait $PID_CLAUDE $PID_DEEPSEEK $PID_GEMINI

echo "Synthesizing consensus..."
cat <<EOF | ai --claude -n "Synthesize these three independent model assessments into a consolidated decision matrix highlighting points of consensus and disagreement:

### Claude Assessment:
$(cat "$OUTPUT_DIR/claude.md")

### DeepSeek Assessment:
$(cat "$OUTPUT_DIR/deepseek.md")

### Gemini Assessment:
$(cat "$OUTPUT_DIR/gemini.md")
EOF
```

---

## 3. Extracting Structured Code Blocks

When generating code files or artifacts, use `--json` combined with `jq` to parse clean code blocks without surrounding conversational filler:

```bash
#!/usr/bin/env bash
set -euo pipefail

TARGET_FILE="cache.py"
PROMPT="Implement an async thread-safe TTL cache in Python with eviction callbacks."

# Extract raw text from JSON response
RESPONSE_JSON=$(ai --claude --json -n "$PROMPT")
CODE=$(echo "$RESPONSE_JSON" | jq -r '.code_blocks[0] // .text')

echo "$CODE" > "$TARGET_FILE"
echo "Saved generated implementation to $TARGET_FILE"
```

---

## 4. Visual Asset Generation Pipeline

Generate images using photorealistic engines (Imagen 3 or Flux.1) and verify file creation:

```bash
#!/usr/bin/env bash
set -euo pipefail

OUTPUT="assets/hero_banner.png"
mkdir -p "$(dirname "$OUTPUT")"

PROMPT="Futuristic minimalist cloud computing network diagram, clean typography, dark neon aesthetic"

echo "Generating asset via Gemini Imagen 3..."
ai --gemini --imgen "$PROMPT" -o "$OUTPUT"

if [[ -f "$OUTPUT" ]]; then
  echo "Image successfully created at $OUTPUT ($(du -h "$OUTPUT" | cut -f1))"
else
  echo "Failed to generate image." >&2
  exit 1
fi
```

---

## 5. Diagnostic Health Check in Scripts

Before launching a batch workflow, verify provider connectivity:

```bash
#!/usr/bin/env bash
set -euo pipefail

echo "Checking required providers..."
for provider in claude deepseek gemini; do
  if ! ai "--$provider" --check >/dev/null 2>&1; then
    echo "Provider $provider is not ready or requires authentication." >&2
    exit 1
  fi
  echo "Provider $provider: READY"
done
```
