# Letta Assistant

A modular, production-focused Letta-backed desktop assistant for Quickshell/QML.

## Installation

Install into the Quickshell venv to share dependencies with the QML frontend:

```bash
~/.local/state/quickshell/.venv/bin/pip install -e /home/archer/.dotfiles/libs/letta_assistant
```

This keeps the letta-assistant package isolated from other venvs while ensuring the PySide6 bridge and services are available to the Quickshell assistant module.

## Package Structure

- `app/` — Application bootstrap and container lifecycle
- `config/` — Configuration, settings, state files, and credential management
- `domain/` — Domain models, enums, and events
- `services/` — Business logic services (Letta, Whisper, Kokoro, session management)
- `ui_bridge/` — PySide6 QObject bridge for QML integration
- `cli/` — Command-line interface and REPL
- `utils/` — Logging, text processing, subprocess utilities

## Phase Plan

1. **Phase 1**: Extract backend code (config, services, CLI) ✅
2. **Phase 2**: Add PySide6 bridge (store, controller, models) ✅
3. **Phase 3**: Build Quickshell QML frontend
4. **Phase 4**: Kokoro lifecycle integration and polish

## CLI REPL (Quick Start)

Start interactive REPL:

```bash
letta-assistant
```

### Core Commands

**Agents**:
```
/agents              List all agents
/new [name]          Create new agent
/resume <id>         Switch to agent
```

**Messages**:
```
/ask <text>          Send message (non-streaming)
/stream <text>       Send with streaming & thinking
/history [n]         Show last n messages
```

**Memory**:
```
/memory              View agent memory blocks
/blocks              Edit core memory
/passages [q]        Search archival memory
/remember <text>     Save to memory
```

**Voice** (requires ffmpeg + whisper):
```
/voice [duration]    Record → Transcribe → Agent → Speak
/listen [duration]   Record & transcribe only
/speak <text>        Text-to-speech
/voice-status        Check dependencies
```

**Settings**:
```
/model [new]         Show/switch model
/rename <name>       Rename agent
/description <text>  Update description
```

**Tools & Development**:
```
/tools list          Available tools
/attached            Tools on current agent
/export              Export agent as .af file
/clone [name]        Clone agent
/ade                 Open Agent Editor
/help                Show all commands
/exit                Exit REPL
```

### Architecture

**Pure Functional** (30+ focused functions):
- `services/letta_service.py` — Letta SDK wrapper
- `commands/*.py` — Command handlers (one per domain)
- `commands/voice.py` — STT + TTS + voice mode

**No Classes**: Everything is functions, easier to test and maintain.

**Concise Code**:
- Total codebase: ~1500 lines
- Each command: 10-25 lines
- Each module: 50-150 lines

See `FUNCTIONAL_ARCHITECTURE.md` for full design details.
