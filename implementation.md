# Agent Window Implementation Plan

Refactoring the Quickshell Agent UI to match the "Copilot Theme" and finalizing the bootstrap and model selection workflows.

## Goal
Overhaul the Quickshell Letta Assistant UI to match the structural and visual aesthetics of Copilot, enabling a cleaner interface, streamlined key-only bootstrap, and transparent trace visibility per generation step.

## Proposed Changes

### 1. Minimal Bootstrap Workflow
- **Initial Setup**: Remove the multi-step frontend configuration screen. On first use (when API key is missing), prompt solely for the Letta API token. 
- **Auto-Caching**: Once the token is provided and validated, auto-fetch and cache available models and agents immediately.

### 2. Deep Agent Context Sync
- When the user selects a new Agent (or initializes one), make sure Quickshell fetches all associated parameters (description, temperature, model selection, toolset, reasoning modes) directly from the Letta SDK so the settings panel populates correctly without duplicate data entry.

### 3. Header & Prompt Bar Redesign
- **Top Chat Panel Tip Bar**: Move the **Model Status** indicator from the right workspace settings pane into a clean "tip bar" header explicitly at the top of the chat panel. 
- **Prompt Bar Layout**: Redesign `AssistantComposer.qml` to include:
  - Dropdowns for **Model** and **Agent** selection integrated with the top edge of the prompt bar.
  - An **Attach File** icon button directly adjacent to the input.

### 4. Copilot Visual Aesthetic (`AssistantMessageBubble.qml`)
- **User Prompts**: 
  - Display on the right side.
  - Background is a simple, slightly gray background box (no longer bright primary accent colors). 
- **Click-to-Reconstruct**: Allow clicking on a previous user prompt to magically restore its full configuration (text, model, agent settings) back into the input box for editing and re-submission.
- **Agent Responses**:
  - Display as left-aligned plain text/Markdown.
  - Remove outer rounded background layers (no message "bubble" box for system/AI text) for a flat, clean output.
- **Reasoning Blocks ("Thoughts")**: Format streaming "thinking" tokens as discrete collapsible dropdowns (`Understanding the Core Task >`) separating thought output from final answer.

### 5. Detailed Step Diagnostics (Three-Dot Menu)
- Alongside the resend/copy options at the bottom of an agent's completion block, insert a **three-dot menu** element.
- Triggering this menu opens detailed step trace data based on Letta's output:
  - **Input metrics**: Model used, Input tokens, Temperature, Messages count, Tools count.
  - **Output metrics**: Output tokens, Reasoning tokens, Stop reason, Generation Cost.
