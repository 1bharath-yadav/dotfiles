You are a senior Linux desktop UI engineer, Quickshell/QML engineer, and AI systems architect.

Your task is to redesign and rebuild my Linux desktop AI assistant into a polished, production-quality assistant with:

- Letta AI as backend
- Quickshell as frontend
- Kokoro TTS instead of Piper
- best-in-class UI/UX inspired by Perplexity-quality interaction design
- modular, reusable, maintainable code

Main goal:
Build the best possible UI and a fully functional AI assistant. Prioritize elegance, responsiveness, streaming UX, voice UX, and modular architecture over quick hacks.

Important existing paths:

path to edit /home/archer/.local/share/end4dots/dots/.config/quickshell/ii/modules/ii/ 4. Our new assistant implementation must be written under:
/home/archer/.local/share/end4dots/dots/.config/quickshell/ii/modules/ii/assistant

Rules:

- Build a clean, modular assistant implementation in the new assistant folder.
- Keep components reusable and integratable with the rest of ii/quickshell.
- Separate presentation, state, actions, and service integrations clearly.
- Avoid monolithic QML files.

High-level product behavior:

- Press Super + ; to toggle the assistant.
- When invoked, immediately start Whisper voice capture.
- At the same time, show a real listening animation in Quickshell:
  - transparent
  - centered horizontally
  - placed near the bottom center
  - visually refined, subtle, modern, not fake-looking
  - should feel like a live assistant listening state
- Above the animation, show a realtime transcription markdown container.
- The transcription container should start compact.
- After capture ends, support smart send behavior:
  - if transcript has fewer than 10 words, auto-send
  - if transcript has 10 or more words, require explicit confirmation enter
  - also design and propose a better alternative UX if appropriate
- When prompt is submitted, transition into the chat UI.

Chat UI behavior:

- Chat container starts small.
- Then it gradually expands toward the center area as content grows.stat bottom grows up.
- Final maximum size target:
  - about half of center width
  - about 80% of screen height
- Streaming states must feel alive and smooth.
- Show agent thinking stream separately from final answer stream.
- Thinking container should:
  - stream live while backend is thinking
  - auto-collapse once the actual reply starts streaming
- Reply container should stream in progressively.
- All message areas should support markdown wherever appropriate.
- Add useful message container features such as:
  - copy
  - retry/regenerate
  - stop generation
  - collapse/expand thinking
  - timestamp
  - role styling
  - code block actions
  - overflow handling
  - smooth autoscroll with user override
  - selection support
  - rendering safety

Interaction requirements:

- Clicking outside the assistant UI should close/toggle it.
- Pressing Super + ; again should toggle it.
- When assistant opens, cursor must auto-focus the prompt box.
- Keyboard-first operation should be excellent.
- Escape should close overlays or close assistant appropriately.
- Design focus behavior cleanly using proper QML/Qt focus handling.

- Use Kokoro, already installed via uv.
- Models are already available at:
  /home/archer/.local/share/kokoro/models
- Integrate Kokoro effectively for assistant speech output.
- Prefer streaming-friendly speech behavior if practical.
- Design TTS so it does not block UI.
- Support interruption when the user starts a new interaction.
- Keep TTS service modular and replaceable.

Backend requirements:

- Use Letta as the assistant backend already there voice-assistant.py.
- Preserve or improve streaming behavior.
- Support:
  - realtime user prompt send
  - streamed thinking/status events if available
  - streamed final answer tokens
  - conversation/session management
  - cancellation
  - robust error states
- If current Letta integration already exists, refactor it into a clean assistant service layer instead of duplicating logic.

Implementation requirements:

- Produce a phased execution plan before coding.
- Then implement in phases:
  1. reference backup and codebase audit
  2. architecture and state design
  3. backend service integration
  4. frontend shell and interaction model
  5. voice input UX
  6. streaming chat UX
  7. Kokoro TTS integration
  8. polish, animations, and edge cases
- For each phase:
  - explain what files are created/changed
  - explain responsibilities of each module
  - keep code modular
  - avoid regressions

Architecture expectations:

- Create small reusable QML components such as:
  - AssistantRoot
  - AssistantOverlay
  - ListeningOrb or ListeningVisualizer
  - TranscriptPreview
  - PromptInput
  - ChatPanel
  - MessageList
  - MessageBubble
  - ThinkingBubble
  - MarkdownMessage
  - ComposerBar
  - AssistantController
  - AssistantStore
- Create backend/service modules for:
  - LettaService
  - WhisperService
  - KokoroService
  - AssistantSessionManager
  - StreamingCoordinator
- Use clear state machines for:
  - hidden
  - listening
  - transcript-review
  - sending
  - thinking
  - responding
  - speaking
  - error

UX quality bar:

- Must feel premium, minimal, elegant, and alive.
- Motion should communicate state, not decorate randomly.
- Transparency, blur, spacing, sizing, and transitions should feel intentional.
- No ugly copied panel styling.
- No cramped layout.
- No hardcoded one-off hacks unless justified.
- Design for long-term extensibility.

Smart UX suggestion:
If transcript is short (<10 words), auto-send .
If transcript is long, show:

- Send
- Edit
- Cancel
  This is preferred over immediate forced confirmation.

Technical notes:

- Use Quickshell/QML best practices.
- Use keyboard shortcuts via proper QML shortcut handling.
- Use proper Qt Quick focus management for auto-focus behavior.
- Structure code so frontend does not directly own networking/business logic.
- Add comments only where they help maintainability.
- Keep naming consistent.
- Make the code easy to integrate into existing ii modules.

Deliverables:

1. A concise architecture plan.
2. A file/folder tree for the new assistant implementation.
3. Implementation by phases.
4. Final code in the assistant module path.
5. Notes on integration points with existing ii/quickshell config.
6. Notes on replacing Piper with Kokoro.
7. UX rationale for key decisions.

Do not give vague advice. Write concrete production-ready code and explain where each piece goes.
