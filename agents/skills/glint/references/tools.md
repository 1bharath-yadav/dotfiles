# Glint Tool Declarations & Socket Wire Protocol

This reference documents the parameter schemas, validation rules, NDJSON socket messages, and response contracts for all Glint-related tools.

---

## 1. `glint_draw`

Renders interactive visuals (HTML5, SVG, Canvas, Three.js) or incrementally patches existing on-screen elements.

### Parameter Schema

| Parameter | Type | Required | Default | Description |
|---|---|---|---|---|
| `action` | string | No | `"render"` | Mode: `"render"` (full scene), `"patch"` (replace element content), `"style"` (update CSS styles/opacity), `"append"` (add child elements), `"remove"` (delete element). |
| `selector` | string | For patch/style/append/remove | None | CSS selector targeting element (e.g. `"#engine"`, `".callout"`, `"#stage"`). |
| `html` | string | For render/patch/append | None | HTML/SVG/Canvas markup to render or insert. Aliased from `code` or `content`. |
| `style` | object | For style action | None | Key-value dictionary of CSS properties (e.g. `{"opacity": "0.5", "borderColor": "#22c55e"}`). |
| `adapter` | string | No | `"html"` or `"three-cutaway"` | Visual adapter: `"html"` (default for live HTML/SVG/Canvas), `"three-cutaway"` (3D procedural models), `"drawio-diagram"`, `"xyflow-flow"`. |
| `target` | string | For auto-synthesis | None | Plain-English topic for dynamic 3D synthesis (e.g. `"F-35 engine"`, `"Photosynthesis"`). |
| `title` | string | No | `"Interactive Stage"` | HUD title displayed in the visual header. |

### Tool Call Example: Full HTML Scene
```json
{
  "name": "glint_draw",
  "arguments": {
    "action": "render",
    "adapter": "html",
    "title": "Quantum Wavefunction Collapse",
    "html": "<div id=\"stage\" style=\"position: fixed; top: 80px; right: 40px; width: 420px; background: rgba(15,23,42,0.92); border: 1px solid #38bdf8; border-radius: 12px; padding: 16px; color: #f8fafc;\"><h3 style=\"margin: 0 0 8px 0; color: #38bdf8;\">Superposition State</h3><canvas id=\"wave-canvas\" width=\"388\" height=\"180\" style=\"background: #020617; border-radius: 8px;\"></canvas><div style=\"margin-top: 10px; display: flex; gap: 8px;\"><button class=\"interactive\" onclick=\"glint.ask('Measure Wavefunction')\" style=\"background: #0284c7; color: #fff; border: none; border-radius: 6px; padding: 6px 12px; cursor: pointer;\">Measure</button></div></div><script>(function(){const c=document.getElementById('wave-canvas');const ctx=c.getContext('2d');let t=0;function loop(){ctx.clearRect(0,0,c.width,c.height);ctx.strokeStyle='#38bdf8';ctx.lineWidth=2;ctx.beginPath();for(let x=0;x<c.width;x++){const y=c.height/2+Math.sin(x*0.04+t)*40*Math.exp(-Math.pow((x-c.width/2)/80,2));if(x===0)ctx.moveTo(x,y);else ctx.lineTo(x,y);}ctx.stroke();t+=0.08;requestAnimationFrame(loop);}loop();})();</script>"
  }
}
```

### Response
```json
{
  "status": "draw_dispatched",
  "adapter": "html",
  "action": "render",
  "title": "Quantum Wavefunction Collapse",
  "delivered": true
}
```

### NDJSON Socket Op Emitted to Glint
```json
{"op":"draw","adapter":"html","title":"Quantum Wavefunction Collapse","payload":{"action":"render","html":"..."}}
```

---

## 2. Incremental DOM Patching (`action: "patch"|"style"|"append"|"remove"`)

Used to update existing elements without regenerating or re-rendering the whole page.

### A. Style Patch (`action: "style"`)
Modifies element style via `Object.assign(target.style, styles)`.
```json
{
  "name": "glint_draw",
  "arguments": {
    "action": "style",
    "selector": "#stage",
    "style": {
      "opacity": "0.7",
      "transform": "scale(1.02)",
      "border-color": "#22c55e"
    }
  }
}
```

### B. Append Patch (`action: "append"`)
Appends new child elements to `selector` and automatically binds interactive click listeners and script tags:
```json
{
  "name": "glint_draw",
  "arguments": {
    "action": "append",
    "selector": "#stage",
    "html": "<div id=\"status-badge\" class=\"interactive\" onclick=\"glint.ask('Status Badge')\" style=\"margin-top: 8px; font-size: 12px; color: #22c55e;\">✓ Coherence maintained at 99.4%</div>"
  }
}
```

### C. Inner HTML Patch (`action: "patch"`)
Replaces `target.innerHTML` of the selected container:
```json
{
  "name": "glint_draw",
  "arguments": {
    "action": "patch",
    "selector": "#measurement-result",
    "html": "<span style=\"color: #f59e0b; font-weight: bold;\">Collapsed to Eigenstate |1⟩</span>"
  }
}
```

### D. Element Removal (`action: "remove"`)
Calls `target.remove()` on the matching DOM node:
```json
{
  "name": "glint_draw",
  "arguments": {
    "action": "remove",
    "selector": "#status-badge"
  }
}
```

---

## 3. `glint_control`

Controls the 3D scene that is currently active on screen in real time.

### Parameter Schema

| Parameter | Type | Required | Validation Range | Description |
|---|---|---|---|---|
| `action` | string | Yes | Enum: `"highlight"`, `"opacity"`, `"explode"`, `"focus_camera"`, `"reset"`, `"clear"` | Control operation. |
| `target_part` | string | Required for `highlight` and `focus_camera` | Any matching primitive ID, group name, or callout label | Target component. Aliased from `part`, `target`, `id`. |
| `value` | number | Optional | Per-action range | `highlight`: duration in seconds (0 = indefinite, default 4.0, max 60.0).<br>`opacity`: 0.0–1.0.<br>`explode`: 0.0–1.0 (0 reassembles).<br>`focus_camera`: zoom factor 0.5–4.0 (default 1.0). |

### Examples

#### Highlight Part
```json
{
  "name": "glint_control",
  "arguments": {
    "action": "highlight",
    "target_part": "lift_fan",
    "value": 5.0
  }
}
```

#### Explode 3D Model
```json
{
  "name": "glint_control",
  "arguments": {
    "action": "explode",
    "value": 0.8
  }
}
```

#### Move Camera to Part
```json
{
  "name": "glint_control",
  "arguments": {
    "action": "focus_camera",
    "target_part": "swivel_nozzle",
    "value": 2.5
  }
}
```

### NDJSON Socket Op Emitted
```json
{"op":"control","action":"highlight","target_part":"lift_fan","value":5.0}
```

### Response
```json
{
  "status": "control_dispatched",
  "action": "highlight",
  "target_part": "lift_fan",
  "delivered": true
}
```
*If overlay is offline:*
```json
{
  "status": "error",
  "error": "overlay not running; call glint_draw first"
}
```

---

## 4. `glint_point`

Draws temporary screen-space laser pointers or bounding-box highlights over real desktop windows.

### Parameter Schema

| Parameter | Type | Required | Range | Description |
|---|---|---|---|---|
| `x` | number | Yes | 0.0–1000.0 | Normalized screen X coordinate (0 = left edge, 1000 = right edge). |
| `y` | number | Yes | 0.0–1000.0 | Normalized screen Y coordinate (0 = top edge, 1000 = bottom edge). |
| `width` | number | No | 1.0–1000.0 | If provided along with `height`, draws a highlighted box. |
| `height` | number | No | 1.0–1000.0 | If provided along with `width`, draws a highlighted box. |
| `note` | string | No | Max 80 characters | Label or instruction note displayed alongside the annotation. |
| `ttl_ms` | integer | No | 500–30000 (default 5000) | Lifetime before fading out in milliseconds. |

### Example A: Single Laser Point
```json
{
  "name": "glint_point",
  "arguments": {
    "x": 485,
    "y": 210,
    "note": "Look at line 42",
    "ttl_ms": 4000
  }
}
```
**Socket Op:**
```json
{"op":"point","frame":"screen","xy":[485,210],"note":"Look at line 42","ttl_ms":4000}
```

### Example B: Bounding Box Highlight
```json
{
  "name": "glint_point",
  "arguments": {
    "x": 100,
    "y": 80,
    "width": 250,
    "height": 60,
    "note": "Save button",
    "ttl_ms": 5000
  }
}
```
**Socket Op:**
```json
{"op":"highlight","frame":"screen","rect":[100,80,250,60],"note":"Save button","ttl_ms":5000}
```

### Response
```json
{
  "status": "annotation_dispatched",
  "kind": "highlight",
  "delivered": true
}
```

---

## 5. Live Interaction Bridge (`POST /v1/live/interact`)

When a user clicks any `.interactive` element, 3D mesh part, or callout card, the overlay executes:
```javascript
window.glint.ask(label, metadata);
```

This triggers an HTTP POST to the local assistant daemon:
- **URL**: `http://127.0.0.1:8765/v1/live/interact`
- **Headers**: `Content-Type: application/json`
- **Payload**:
  ```json
  {
    "label": "Lift Fan",
    "metadata": { "tag": "Cold Thrust", "rpm": 12000 },
    "timestamp": 1730372400000
  }
  ```

Passist handles this turn by injecting a synthesized prompt into Gemini Live or the agent context:
> *"The user just clicked on the Lift Fan component on their screen. Explain what this part does and how it connects to the rest of the system."*

The voice assistant will immediately speak about the requested component without requiring keyboard input.
