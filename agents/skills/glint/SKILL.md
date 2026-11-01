---
name: glint
description: "Real-time transparent on-screen visual overlay for Linux/Wayland (Hyprland). Use this skill whenever the user asks to draw on screen, show in 3D, explain in 3D, visualize concepts (photosynthesis, physics, algorithms, circuits, engines), annotate desktop UI, highlight buttons or code lines, display hardware schematics, pipeline flows, or run an interactive step-by-step tutorial over active windows. Always use glint for on-screen companion visuals rather than describing spatial concepts in pure text."
---

# Glint: Real-Time Transparent Visual Overlay (`glint`)

Glint provides a hardware-accelerated, transparent, click-through overlay window on Linux/Wayland (Hyprland). It projects interactive 2D HUD cards, animated hardware schematics, real-time 3D models (Three.js WebGL), and transient laser annotations directly over active workspace windows without disrupting workflow.

---

## 1. Quick Adapter Decision Matrix

| Request / Subject | Adapter | Input Shape | Deep Fallback If Needed |
|---|---|---|---|
| **Custom 2D Card, Math, Widget, or Tutorial** | `html` | `{ html: "..." }` | See [references/ui-components.md](references/ui-components.md) |
| **Physical Machine, Engine, Hardware Anatomy** | `three-cutaway` | `{ primitives: [...], callouts: [...] }` | `~/.agents/skills/3dviz-pro-max/` |
| **Pipeline, DAG, AST, Dataflow Trace** | `xyflow-flow` | `{ nodes: [...], edges: [...] }` | `https://reactflow.dev/llms-medium.txt` |
| **Hardware Circuit, Wiring, Network Topology** | `drawio-diagram` | `{ xml: "<mxGraphModel>..." }` | `~/.agents/skills/drawio-skill/` |
| **Transient Laser Pointer / Screen Highlight** | `glint_point` | `{ x, y, note }` or `{ app, target }` | See [references/tutor-mode.md](references/tutor-mode.md) |

---

## 2. Core Architectural Invariants

1. **Click-Through by Default**:
   Empty and transparent space passes all mouse and pointer clicks straight through to windows beneath (`setIgnoreMouseEvents(true, { forward: true })`). Cards, buttons, and elements tagged `.interactive` or `onclick` automatically capture cursor events.
2. **Docked Window Mode (`glint-corner`)**:
   Interactive 3D scenes and tutorials default to right-docked window mode (`720×600` or `560×480`) so the user's terminal and editor on the left remain 100% unobstructed.
3. **Incremental Mutation Over Redraw**:
   Never tear down and regenerate entire scenes to change a color, focus a camera, or show a progress step. Use `glint_patch` or `glint_control`.

---

## 3. High-Velocity Recipes

### Recipe A: Zero-Boilerplate HTML Stepper (`adapter: "html"`)
Use Glint's pre-styled semantic classes from `theme.css` (`.glint-card`, `.glint-step`, `.glint-badge`, `.glint-btn-accent`):

```json
{
  "name": "glint_draw",
  "arguments": {
    "adapter": "html",
    "title": "ESP32 Flashing Guide",
    "html": "<div class=\"glint-card\" style=\"width:340px;\"><div class=\"glint-badge glint-badge-emerald\">Tutor Mode</div><h3 class=\"glint-title\" style=\"margin-top:6px;\">Flash Firmware</h3><div class=\"glint-stepper\"><div class=\"glint-step active\" id=\"s1\"><div class=\"glint-step-num\">1</div><div class=\"glint-step-content\"><div class=\"glint-step-title\">Connect USB-C</div><div class=\"glint-step-desc\">Plug into /dev/ttyACM0</div></div></div><div class=\"glint-step\" id=\"s2\"><div class=\"glint-step-num\">2</div><div class=\"glint-step-content\"><div class=\"glint-step-title\">Hold Boot</div><div class=\"glint-step-desc\">Hold GPIO0 while resetting</div></div></div></div><button class=\"glint-btn glint-btn-accent\" onclick=\"glint.ask('ESP32 Flashing')\">Ask Voice Assistant</button></div>"
  }
}
```

### Recipe B: Origin-Centered 3D Hardware Cutaway (`adapter: "three-cutaway"`)
All 3D objects center around `[0, 0, 0]` for symmetrical rotation. Callouts use compact hover-to-reveal pills:

```json
{
  "name": "glint_draw",
  "arguments": {
    "adapter": "three-cutaway",
    "title": "Raspberry Pi 4 Model B",
    "payload": {
      "camera": { "position": [4.2, 5.5, 6.2], "target": [0, 0.4, 0], "fov": 42 },
      "primitives": [
        { "id": "pcb", "type": "box", "pos": [0, 0, 0], "size": [5.6, 0.09, 3.6], "color": "#15803d", "roughness": 0.85 },
        { "id": "soc", "type": "box", "label": "Broadcom BCM2711", "pos": [-0.4, 0.11, -0.2], "size": [0.95, 0.15, 0.95], "color": "#cbd5e1", "metalness": 0.9, "roughness": 0.2 },
        { "id": "eth", "type": "box", "label": "Gigabit Ethernet", "pos": [2.2, 0.48, -0.9], "size": [1.15, 0.88, 0.95], "color": "#94a3b8", "metalness": 0.85, "roughness": 0.25 }
      ],
      "callouts": [
        { "id": "c_soc", "label": "BCM2711 SoC", "desc": "Quad-core Cortex-A72 @ 1.5GHz with 4Kp60 HEVC decode.", "tag": "Processor", "part": "soc", "anchor": [-0.4, 0.2, -0.2], "position": [-0.4, 1.8, -1.2] }
      ]
    }
  }
}
```

### Recipe C: Interactive Pipeline Graph (`adapter: "xyflow-flow"`)
Draggable nodes with animated cubic bezier curves. Clicking a node fires `glint.ask(node.title)`:

```json
{
  "name": "glint_draw",
  "arguments": {
    "adapter": "xyflow-flow",
    "title": "Multimodal Pipeline",
    "payload": {
      "nodes": [
        { "id": "ingest", "type": "input", "position": { "x": 80, "y": 140 }, "data": { "label": "Screen Ingest", "desc": "Grim Wayland stream", "status": "active" } },
        { "id": "gemini", "type": "default", "position": { "x": 380, "y": 140 }, "data": { "label": "Gemini 3.8 Core", "desc": "Bidi reasoning", "status": "running" } }
      ],
      "edges": [
        { "from": "ingest", "to": "gemini", "animated": true, "label": "10 fps frames" }
      ]
    }
  }
}
```

### Recipe D: Circuit / Wiring Schematic (`adapter: "drawio-diagram"`)
Clean mxGraph XML rendered to interactive SVG:

```json
{
  "name": "glint_draw",
  "arguments": {
    "adapter": "drawio-diagram",
    "title": "I2C Sensor Bus",
    "payload": {
      "xml": "<mxGraphModel><root><mxCell id=\"0\"/><mxCell id=\"1\" parent=\"0\"/><mxCell id=\"mcu\" value=\"ESP32-S3 SoC\" vertex=\"1\" parent=\"1\" style=\"rounded=1;fillColor=#1e293b;strokeColor=#10b981;fontColor=#f8fafc;strokeWidth=2;\"><mxGeometry x=\"100\" y=\"100\" width=\"160\" height=\"80\" as=\"geometry\"/></mxCell><mxCell id=\"sensor\" value=\"BME280 Sensor\" vertex=\"1\" parent=\"1\" style=\"rounded=1;fillColor=#1e293b;strokeColor=#f59e0b;fontColor=#f8fafc;strokeWidth=1.5;\"><mxGeometry x=\"360\" y=\"100\" width=\"140\" height=\"80\" as=\"geometry\"/></mxCell><mxCell id=\"edge\" value=\"I2C (SDA/SCL)\" edge=\"1\" parent=\"1\" source=\"mcu\" target=\"sensor\" style=\"strokeColor=#f59e0b;strokeWidth=2;fontColor=#94a3b8;\"><mxGeometry relative=\"1\" as=\"geometry\"/></mxCell></root></mxGraphModel>"
    }
  }
}
```

---

## 4. Real-Time Scene Control (`glint_control`)

Drive the active scene without re-sending full payloads:

```json
// Advance stepper to Step 2:
{ "name": "glint_control", "arguments": { "action": "step", "value": 2 } }

// Highlight a 3D part or HTML element:
{ "name": "glint_control", "arguments": { "action": "highlight", "target_part": "soc" } }

// Tween 3D camera to frame a specific part:
{ "name": "glint_control", "arguments": { "action": "focus_camera", "target_part": "soc" } }

// Explode 3D assembly outward:
{ "name": "glint_control", "arguments": { "action": "explode", "value": 0.8 } }

// Resize window bounds:
{ "name": "glint_control", "arguments": { "action": "resize", "width": 720, "height": 600 } }
```

---

## 5. Transient Pointers & Highlights (`glint_point`)

Point laser annotations at on-screen UI buttons or code lines:

```json
// Semantic target via desktop accessibility:
{ "name": "glint_point", "arguments": { "app": "Code", "target": "Terminal", "note": "Type cargo build here", "ttl_ms": 5000 } }

// Raw normalized coordinates [0..1000]:
{ "name": "glint_point", "arguments": { "x": 850, "y": 140, "note": "Click Deploy", "ttl_ms": 4000 } }
```

---

## 6. Deep Skill Fallback Guidelines

- **For Complex 3D Models / Blender Rigs**: If the user needs anatomical human/animal dissection kits, skeletal deformation, or Blender UV/baking pipelines, consult `~/.agents/skills/3dviz-pro-max/`.
- **For Automated Cloud/IaC Schematics**: If the user needs automated Terraform, Kubernetes, SQL, or GraphQL schema parsing, consult `~/.agents/skills/drawio-skill/`.
- **For Standalone React/Svelte Flow Apps**: If building custom React Flow components from scratch, fetch `https://reactflow.dev/llms-medium.txt`.

---

## 7. Reference Guides

- [references/3d-cutaways.md](references/3d-cutaways.md): Origin-centered geometry, PBR calibration, pill callouts.
- [references/schematics.md](references/schematics.md): Hardware wiring mxGraph XML templates.
- [references/flow-pipelines.md](references/flow-pipelines.md): XYFlow DAG nodes, edges, status indicators.
- [references/ui-components.md](references/ui-components.md): Semantic CSS classes (`.glint-card`, `.glint-step`, `.glint-badge`, `.glint-stat`).
- [references/tutor-mode.md](references/tutor-mode.md): Step-by-step guidance workflow and Click-to-Ask loop.
