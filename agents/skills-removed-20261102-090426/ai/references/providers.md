# Frontier AI Providers Reference

Exhaustive breakdown of all 12 frontier AI providers supported by the `ai` CLI router.

---

## 1. OpenAI (ChatGPT)
- **Flag**: `--chatgpt` (Default when no provider flag is supplied)
- **Standalone Shim**: `chatgpt-ai`
- **Underlying Models**: GPT-4o, DALL-E 3, Advanced Voice Mode
- **Strengths**: General knowledge, broad conversational capability, robust tool calling, text-to-speech.
- **Specialized Flags**:
  - `--imgen <prompt> -o <path>`: Generates images via DALL-E 3 and downloads to disk.
  - `--tts [text]`: Speaks the output using ChatGPT's neural voice synthesis.
  - `--livemode`: Engages interactive continuous voice mode.
  - `--project <name>`: Routes conversation to a named project container.
- **Example**:
  ```bash
  ai "Write a high-performance LRU cache in Go"
  ai --imgen "Isometric cybernetic datagrid" -o datagrid.png
  ```

---

## 2. Anthropic (Claude)
- **Flag**: `--claude`
- **Standalone Shim**: `claude-ai`
- **Underlying Models**: Claude 3.5 Sonnet, Claude 3.5 Haiku, Claude 3 Opus
- **Strengths**: Code architecture, software engineering, long-form technical prose, rigorous adherence to system instructions.
- **Specialized Flags**:
  - `--artifacts`: Extracts code blocks and document artifacts into distinct structured payloads.
  - `--project <name>`: Routes prompt to a specific Claude project context.
  - `-a, --attach <path>`: Uploads local files (codebases, documentation, images).
- **Example**:
  ```bash
  ai --claude -a main.py "Refactor this module to use dependency injection"
  ai --claude --artifacts "Design a single-file interactive SVG chart"
  ```

---

## 3. Google (Gemini)
- **Flag**: `--gemini`
- **Standalone Shim**: `gemini-ai`
- **Underlying Models**: Gemini 2.0 Flash, Gemini 2.0 Pro, Imagen 3
- **Strengths**: 2M token context window, fast multimodal analysis, Imagen 3 photorealism, low latency.
- **Specialized Flags**:
  - `--imgen <prompt> -o <path>`: Generates images via Google Imagen 3.
  - `--tts [text]`: Reads aloud the response using Gemini's native neural speech synthesis.
  - `--gem <name>`: Targets a specific Gemini Gem or Notebook.
- **Example**:
  ```bash
  ai --gemini --imgen "Ultra-detailed macro photo of a water droplet on an emerald leaf" -o leaf.png
  ai --gemini --tts "Provide a quick verbal summary of today's release notes"
  ```

---

## 4. DeepSeek
- **Flag**: `--deepseek`
- **Standalone Shim**: `deepseek-ai`
- **Underlying Models**: DeepSeek-V3, DeepSeek-R1 (Reasoner)
- **Strengths**: Formal mathematical proofs, competitive programming, symbolic logic, complex algorithmic problem solving.
- **Specialized Flags**:
  - `--think` / `--no-think`: Toggles DeepSeek R1 reasoning chain.
  - `--show-thinking`: Streams or displays the full internal thought/scratchpad process before the final answer.
  - `--search`: Enables live web search grounding.
- **Example**:
  ```bash
  ai --deepseek --think "Prove that the sum of the first n cubes equals the square of the sum of the first n integers"
  ai --deepseek --search "Latest benchmarks for DeepSeek-R1 on SWE-bench"
  ```

---

## 5. Z.ai (Zhipu AI)
- **Flag**: `--zai`, `--z-ai`
- **Standalone Shim**: `zai-ai`
- **Underlying Models**: GLM-5.3, GLM-4.7
- **Strengths**: Deep reasoning in bilingual (Chinese/English) tasks, technical documentation, agentic tool workflows.
- **Specialized Flags**:
  - `--think` / `--no-think`: Toggles GLM Deep Think reasoning engine.
  - `--search`: Toggles real-time internet search grounding.
- **Example**:
  ```bash
  ai --zai --think "Analyze the convergence rate of stochastic gradient descent with momentum"
  ```

---

## 6. MiniMax
- **Flag**: `--minimax`
- **Standalone Shim**: `minimax-ai`
- **Underlying Models**: MiniMax M1, Hailuo AI Video-01
- **Strengths**: Video scene generation, multimedia pipelines, physical simulation prompts.
- **Specialized Flags**:
  - `--scene <video|image|ppt|spreadsheet>`: Targets specific workspace generation scenes.
- **Example**:
  ```bash
  ai --minimax --scene video "Cinematic drone shot flying through a misty Scandinavian pine forest at sunrise, 4k"
  ```

---

## 7. Moonshot AI (Kimi)
- **Flag**: `--kimi`
- **Standalone Shim**: `kimi-ai`
- **Underlying Models**: Kimi K3, K2.5 Agent Swarm
- **Strengths**: Agent swarms, long-context document retrieval, dense multi-document synthesis.
- **Specialized Flags**:
  - `--search`: Engages live real-time internet grounding and multi-source verification.
- **Example**:
  ```bash
  ai --kimi --search "Synthesize the latest findings on solid-state battery commercialization in 2026"
  ```

---

## 8. xAI (Grok)
- **Flag**: `--grok`
- **Standalone Shim**: `grok-ai`
- **Underlying Models**: Grok 4.6, Grok 3
- **Strengths**: Real-time knowledge, mathematical analysis, physics modeling, unconstrained technical queries.
- **Specialized Flags**:
  - `-a, --attach <path>`: Local file and image analysis.
- **Example**:
  ```bash
  ai --grok "Calculate the relativistic time dilation for an object traveling at 0.95c for 1 year"
  ```

---

## 9. Alibaba (Qwen)
- **Flag**: `--qwen`
- **Standalone Shim**: `qwen-ai`
- **Underlying Models**: Qwen 2.5-Max, Qwen 2.5-Coder, Qwen3.8
- **Strengths**: Multi-language programming, competitive coding, high-precision structured data manipulation.
- **Specialized Flags**:
  - `--think` / `--no-think`: Toggles deep reasoning mode.
- **Example**:
  ```bash
  ai --qwen --think "Implement a lock-free multi-producer multi-consumer queue in C++20"
  ```

---

## 10. Mistral AI
- **Flag**: `--mistral`
- **Standalone Shim**: `mistral-ai`
- **Underlying Models**: Mistral Large 2, Pixtral Large, Codestral, Flux.1
- **Strengths**: Fast European open-weight frontier model, Flux photorealistic image generation, low latency.
- **Specialized Flags**:
  - `-m <fast|think|research>`: Selects Mistral execution profile.
  - `--imgen <prompt> -o <path>`: Generates images via Flux.1.
  - `--tts [text]`: Read aloud speech synthesis.
  - `--voice`: Real-time audio voice interaction.
- **Example**:
  ```bash
  ai --mistral -m research "Survey recent architectural trends in sparse mixture of experts"
  ai --mistral --imgen "Macro shot of a mechanical watch movement with brass gears and rubies" -o watch.png
  ```

---

## 11. Meta AI
- **Flag**: `--meta`
- **Standalone Shim**: `meta-ai`
- **Underlying Models**: Llama 3.3 70B, Llama 3.1 405B, Meta Imagine
- **Strengths**: Open-weight foundation ecosystem, instant answers, Meta Imagine graphics.
- **Specialized Flags**:
  - `--think` / `--no-think`: Toggles Thinking vs Instant generation.
  - `--imgen <prompt> -o <path>`: Generates images via Meta Imagine.
  - `--dictate`: Speech-to-text dictation.
- **Example**:
  ```bash
  ai --meta --imgen "Synthwave sports car driving towards a retro neon sunset" -o car.png
  ai --meta --think "Explain how Paxos guarantees safety in an asynchronous network with crash failures"
  ```

---

## 12. Microsoft Copilot
- **Flag**: `--copilot`
- **Standalone Shim**: `copilot-ai`
- **Underlying Models**: Copilot GPT-4o, Designer DALL-E 3
- **Strengths**: Deep reasoning with Think Deeper, search integration, academic study explanations.
- **Specialized Flags**:
  - `-m <smart|think|study|search>`: Selects Copilot reasoning mode.
  - `--imgen <prompt> -o <path>`: Generates images via Copilot Designer.
  - `--voice`: Talk to Copilot interactive audio.
- **Example**:
  ```bash
  ai --copilot -m think "Derive Kepler's third law from Newton's law of universal gravitation"
  ai --copilot -m study "Explain the difference between Monads and Functors in Haskell"
  ```
