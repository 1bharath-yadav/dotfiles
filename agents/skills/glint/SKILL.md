---
name: glint
description: "Real-time transparent on-screen visual overlay for Linux/Wayland. Use this skill whenever the user asks to draw on screen, show in 3D, explain in 3D, visualize concepts (photosynthesis, physics, algorithms, circuits, engines), annotate the desktop, highlight UI buttons, or project diagrams over active windows. Covers glint_draw (HTML/SVG/Canvas/Three.js), glint_patch (real-time DOM/CSS updates without re-generating), glint_control (opacity, camera, highlight), and glint_point (temporary laser pointer)."
---

# Glint: Real-Time Transparent Visual Overlay (`glint`)

Glint provides a hardware-accelerated, transparent, click-through overlay window running on Linux/Wayland (Hyprland). It projects interactive 2D diagrams, animated SVG schematics, real-time 3D models (Three.js WebGL), and transient laser annotations directly over active workspace windows without disrupting desktop workflow.

---

## Architecture & Core Invariants

1. **Click-Through Transparency by Default**:
   - The overlay window is borderless, unmanaged, pinned, and covers the full monitor (`1.0 override` opacity, zero shadow).
   - Empty/transparent space passes all mouse and pointer clicks straight through to underlying applications (`set-ignore-mouse-events: true, { forward: true }`).
   - Cards, badges, buttons, canvas elements, and elements tagged with `.interactive` or `onclick` automatically capture cursor events.

2. **Decoupled Daemon & IPC**:
   - Glint overlay communicates with Passist and local agents over an NDJSON Unix domain socket (`$XDG_RUNTIME_DIR/glint.sock` or `/tmp/glint.sock`).
   - If the overlay is not active when an agent invokes a Glint tool, Passist auto-spawns the Glint daemon and Electron host.

3. **Incremental Evolution Over Re-generation**:
   - **CRITICAL INVARIANT**: Never regenerate 50–100 lines of HTML or reload a 3D scene just to change a badge color, focus a camera, or show an arrow. Always use targeted incremental patches (`action: "style" | "append" | "patch"` or `glint_control`).

---

## The Four Operational Modes

### Mode 1: Fresh Visual Creation (`glint_draw`)

Use when rendering a new scene, diagram, cutaway, or HUD from scratch.

Two authoring paths are supported:

#### A. Freeform Live HTML / SVG / Canvas / Three.js (`adapter: "html"`)
Inject raw HTML markup containing inline SVGs, CSS animations, or CDN-backed Three.js scripts. The overlay executes scripts, binds interactive elements, and enables pan, zoom, and drag automatically:

```json
{
  "name": "glint_draw",
  "arguments": {
    "action": "render",
    "adapter": "html",
    "title": "Chloroplast Light Reactions",
    "html": "<div id=\"stage\" style=\"position: fixed; right: 40px; top: 60px; width: 440px; background: rgba(15,23,42,0.88); backdrop-filter: blur(12px); border-radius: 14px; padding: 18px; border: 1px solid rgba(56,189,248,0.3); color: #f8fafc;\"><h3 style=\"margin: 0 0 8px 0; font-size: 16px; color: #38bdf8;\">Thylakoid Membrane</h3><p style=\"font-size: 13px; color: #cbd5e1; margin: 0 0 12px 0;\">Photons excite chlorophyll pigments, liberating electrons to split H₂O.</p><button class=\"interactive\" onclick=\"glint.ask('ATP Synthase')\" style=\"background: #0284c7; color: white; border: none; border-radius: 8px; padding: 6px 12px; cursor: pointer;\">Inspect ATP Synthase</button></div>"
  }
}
```

#### B. Declarative 3D Cutaway (`adapter: "three-cutaway"`)
For complex physical objects or machines (e.g. jet engines, planetary gears, leaf cross-sections). Passist or Glint normalizes primitives (`box`, `cylinder`, `sphere`, `cone`, `torus`, `lathe`, `tube`, `arrow_vector`) with camera framing, animated photon/fluid streams (`travel`), and 3D callout tracking:

```json
{
  "name": "glint_draw",
  "arguments": {
    "adapter": "three-cutaway",
    "title": "F-35B STOVL Propulsion System",
    "target": "F-35 engine cutaway with lift fan and 3BSD swivel nozzle"
  }
}
```

---

### Mode 2: Incremental DOM Patching (`glint_patch` / `action: "patch"|"style"|"append"|"remove"`)

When a visual is already on screen, modify specific elements in place. Do not re-send the full HTML markup.

| Action | Required Fields | Use Case |
|---|---|---|
| `style` | `selector`, `style` (object) | Update colors, opacity, stroke, transform, or visibility. |
| `append` | `selector`, `html` | Add child cards, progress chips, flow nodes, or arrows. |
| `patch` | `selector`, `html` | Replace inner HTML of an existing container without touching surroundings. |
| `remove` | `selector` | Delete a completed step, dismissed card, or transient alert. |

#### Example: Highlight Step via `style`
```json
{
  "name": "glint_draw",
  "arguments": {
    "action": "style",
    "selector": "#step-2",
    "style": {
      "border-color": "#22c55e",
      "box-shadow": "0 0 16px rgba(34,197,94,0.4)",
      "transform": "scale(1.03)"
    }
  }
}
```

#### Example: Append an Annotation Arrow via `append`
```json
{
  "name": "glint_draw",
  "arguments": {
    "action": "append",
    "selector": "#stage",
    "html": "<div id=\"warning-chip\" class=\"interactive\" style=\"margin-top: 10px; background: rgba(239,68,68,0.2); border: 1px solid #ef4444; color: #fca5a5; padding: 6px 10px; border-radius: 6px; font-size: 12px;\">Peak thermal dissipation reached at nozzle throat.</div>"
  }
}
```

---

### Mode 3: Real-Time Interaction & Click-to-Ask

Glint injects a global `window.glint` JavaScript bridge into every rendered HTML scene:

```javascript
window.glint = {
  // Dispatches HTTP POST to http://127.0.0.1:8765/v1/live/interact
  ask: function(partName, metadata) { ... },

  // Sets global overlay opacity (0.05 - 1.0)
  setOpacity: function(val) { ... },

  // Clears the visual stage
  clear: function() { ... }
};
```

#### Click-to-Ask Pattern:
Tag interactive buttons, SVG nodes, or callouts with `onclick="glint.ask('Item Name')"`:
```html
<div class="interactive node" onclick="glint.ask('Compressor Stage 2', { stage: 2, temp: '420C' })">
  <span>Compressor Core</span>
</div>
```
When the user clicks the element, Passist receives an authentic user interaction event:
> *"The user just clicked on the Compressor Stage 2 component on their screen. Explain its purpose and operation."*

Passist's live voice assistant then speaks directly to that part without the user needing to type.

---

### Mode 4: Spatial Placement in Free Desktop Space

Visuals must never obscure the user's active code editor, terminal prompt, or reading material.

1. **Window-Aware Placement**:
   - Check the focused window geometry via `look_screen` or `hyprctl activewindow -j`.
   - Default card positioning:
     - **Side-by-side**: Anchor to the right edge (`right: 32px; top: 60px; width: 440px;`) or top-right quadrant if the user is working on the left half of the display.
     - **Bottom HUD**: Anchor to `bottom: 40px; left: 50%; transform: translateX(-50%);` for horizontal pipelines or timelines.

2. **Smart Opacity Rules**:
   - **0.95 Opacity**: In empty desktop space or secondary monitor space. High contrast, sharp text.
   - **0.65 Opacity with Backdrop Blur**: When hovering or overlapping existing open windows. Allows text behind the card to remain legible while keeping diagram elements visible:
     ```css
     background: rgba(15, 23, 42, 0.65);
     backdrop-filter: blur(14px);
     -webkit-backdrop-filter: blur(14px);
     ```

---

## Transient Laser Pointer & Screen Highlights (`glint_point`)

To draw immediate user focus to an existing UI button, terminal error line, or graphic without mounting an entire visual stage:

### 1. Laser Pointer (`xy`)
Normalized coordinates `[0..1000]` representing screen X (0 = left, 1000 = right) and Y (0 = top, 1000 = bottom):
```json
{
  "name": "glint_point",
  "arguments": {
    "x": 840,
    "y": 120,
    "note": "Click Deploy here",
    "ttl_ms": 4000
  }
}
```

### 2. Highlight Bounding Box (`rect` with `x, y, width, height`)
```json
{
  "name": "glint_point",
  "arguments": {
    "x": 200,
    "y": 450,
    "width": 320,
    "height": 45,
    "note": "Syntax error occurs on this line",
    "ttl_ms": 6000
  }
}
```
*Note: Ghost annotations automatically fade out via CSS transition after `ttl_ms` (500ms–30000ms, default 5000ms) and never intercept mouse clicks.*

---

## 3D Scene Controls (`glint_control`)

When a 3D cutaway scene is active, control it in real time while continuing the voice conversation:

| Action | Target Part | Value Range | Behavior |
|---|---|---|---|
| `highlight` | Primitive id / label | `0` (indefinite) or seconds (e.g. `4.0`) | Glows target part and dims rest of scene to 35% |
| `focus_camera`| Primitive id / label | Zoom multiplier `0.5`–`4.0` (default `1.0`) | Tweens camera target directly to the part |
| `explode` | *(Optional)* group | `0.0`–`1.0` (`0` = assembled, `1` = exploded) | Slides parts along their procedural explode vectors |
| `opacity` | *(Optional)* part | `0.0`–`1.0` | Adjusts global scene opacity or target group opacity |
| `reset` | None | None | Resets camera, exploded offsets, and highlights |
| `clear` | None | None | Dismisses and unmounts the active visual scene |

---

## Reference Guides

- **Tool Schemas & NDJSON Payloads**: See [references/tools.md](references/tools.md) for parameter types, validation clamps, socket wire formats, and error handling.
- **Production Recipes**: See [references/recipes.md](references/recipes.md) for copy-paste patterns:
  1. 3D Mechanical Cutaway (Three.js + CSS2D callout tracking)
  2. Scientific Biological Process (Photosynthesis with SVG sunbeams & chloroplasts)
  3. Algorithmic Data Structure (Animated search tree & pipeline pulses)
  4. Incremental Styling & Append Patching
