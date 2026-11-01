# Interactive Pipeline Flows & DAGs (`xyflow-flow`)

Distilled from `xyflow` and React Flow / Svelte Flow best practices.

> **Full Framework Fallback:** If you are building standalone web applications in React Flow / Svelte Flow with custom DOM node handles, fetch `https://reactflow.dev/llms-medium.txt` or `https://reactflow.dev/llms.txt`.

---

## 1. Flow Schema Specification

Glint's `xyflow-flow` adapter renders an ultra-fast, zero-bundle interactive canvas with draggable nodes, animated cubic bezier edges, and click-to-ask integration:

```json
{
  "adapter": "xyflow-flow",
  "title": "LLM Multimodal Reasoning Pipeline",
  "payload": {
    "nodes": [
      {
        "id": "ingest",
        "type": "input",
        "position": { "x": 80, "y": 140 },
        "data": {
          "label": "Wayland Screen Ingest",
          "desc": "Grim capture stream (10 fps @ 1280x720)",
          "tag": "Producer",
          "status": "active",
          "metrics": "10 fps • 640 KB/s"
        }
      },
      {
        "id": "model",
        "type": "default",
        "position": { "x": 400, "y": 140 },
        "data": {
          "label": "Gemini 3.8 Flash Core",
          "desc": "Bidi WebSocket multimodal reasoning",
          "tag": "AI Engine",
          "status": "running",
          "metrics": "24kHz PCM • 1.2s TTFT"
        }
      },
      {
        "id": "overlay",
        "type": "output",
        "position": { "x": 720, "y": 140 },
        "data": {
          "label": "Glint Overlay Stage",
          "desc": "Hardware-accelerated Wayland transparent view",
          "tag": "Renderer",
          "status": "ready",
          "metrics": "Electron 44 • 60 fps"
        }
      }
    ],
    "edges": [
      {
        "from": "ingest",
        "to": "model",
        "animated": true,
        "label": "JPEG Frames"
      },
      {
        "from": "model",
        "to": "overlay",
        "animated": true,
        "label": "Control Ops"
      }
    ]
  }
}
```

---

## 2. Node Status Styling Tiers

The `data.status` field controls glowing badge indicators on each node:
- `"active"`: Emerald glowing pulse (`#10a37f`)
- `"running"`: Sky blue flowing glow (`#38bdf8`)
- `"ready"`: Muted slate indicator (`#94a3b8`)
- `"error"`: Red warning border and indicator (`#e5484d`)

---

## 3. Interactive Click-to-Ask Loop

When the user clicks any node in the flow, Glint fires `glint.ask(node.title, node.data)` and dispatches `POST http://127.0.0.1:8765/v1/live/interact`. The connected voice agent instantly explains that node's real-time metrics and purpose.
