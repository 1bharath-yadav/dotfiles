# 3D Cutaways & Spatial Reasoning (`three-cutaway`)

Distilled from `3dviz-pro-max` for real-time desktop overlays on Linux/Wayland.

> **Deep Kit Fallback:** If the user requires full procedural biological anatomy kits, skeletal rigging, or Blender asset baking, load `~/.agents/skills/3dviz-pro-max/`.

---

## 1. Core Geometric Invariants

1. **Origin-Centered Rotational Symmetry `(0, 0, 0)`**:
   - The primary object's center of mass must align with `[0, 0, 0]`.
   - Never apply camera x/y offsets to shift the model visually; instead, place the docked window using `mode: "window"` and bounds `{ width: 720, height: 600 }`.
   - OrbitControls will rotate smoothly around `(0, 0, 0)` without eccentric edge-wobble.

2. **Primitive Geometry Hierarchy**:
   - `box`: Dimensions `[width, height, depth]`. PCBs, IC chips, battery cells, structural frames.
   - `cylinder`: Dimensions `[radiusTop, radiusBottom, height]`. Shafts, capacitors, pipes, mounting holes.
   - `sphere`: Dimensions `[radius]`. Joints, balls, bearings, sensors.
   - `cone`: Dimensions `[radius, height]`. Nozzles, injectors, indicators.
   - `torus`: Dimensions `[radius, tubeRadius]`. O-rings, gaskets, coiling coils.

3. **PBR Physical Material Calibration**:
   - Metallic components (copper traces, aluminum heatsinks, RJ45 shields):
     `{ metalness: 0.85..0.95, roughness: 0.15..0.3, color: "#94a3b8" }`
   - Matte silicon / FR4 fiberglass (PCBs, microcontrollers, plastic caps):
     `{ metalness: 0.1..0.2, roughness: 0.75..0.9, color: "#15803d" }`
   - Emissive indicator LEDs / laser targets:
     `{ color: "#10a37f", emissive: "#10a37f", emissive_intensity: 1.2 }`

---

## 2. Compact Pill Callouts (Zero Chatbot Residue)

Callouts track 3D parts in screen-space via CSS2D. They must use compact label pills that expand description only on cursor hover:

```json
{
  "id": "c_soc",
  "label": "Broadcom BCM2711 SoC",
  "desc": "Quad-core Cortex-A72 64-bit CPU @ 1.5GHz with 4Kp60 decode.",
  "tag": "Processor",
  "hot": false,
  "part": "bcm_soc",
  "anchor": [-0.4, 0.2, -0.2],
  "position": [-0.4, 1.8, -1.2]
}
```

- **`anchor`**: Exact 3D point on the part where the pointer line attaches.
- **`position`**: 3D coordinate where the floating pill badge rests.
- **`hot: true`**: Adds an emerald pulsing highlight for tutor focus.

---

## 3. Complete Minimal Working Recipe

```json
{
  "adapter": "three-cutaway",
  "title": "ESP32-S3 Microcontroller",
  "payload": {
    "camera": {
      "position": [4.0, 4.5, 5.0],
      "target": [0, 0, 0],
      "fov": 42
    },
    "primitives": [
      {
        "id": "board",
        "type": "box",
        "pos": [0, 0, 0],
        "size": [4.8, 0.08, 2.6],
        "color": "#1e293b",
        "roughness": 0.85
      },
      {
        "id": "rf_shield",
        "type": "box",
        "label": "ESP32-S3 SoC & RF Shield",
        "pos": [-0.8, 0.12, 0],
        "size": [1.8, 0.18, 1.8],
        "color": "#cbd5e1",
        "metalness": 0.9,
        "roughness": 0.2
      },
      {
        "id": "antenna",
        "type": "box",
        "label": "2.4GHz PCB Antenna",
        "pos": [1.8, 0.05, 0],
        "size": [0.8, 0.04, 2.2],
        "color": "#eab308",
        "metalness": 0.95,
        "roughness": 0.2
      }
    ],
    "callouts": [
      {
        "id": "c_shield",
        "label": "ESP32-S3 SoC",
        "desc": "Dual-core Xtensa LX7 @ 240MHz with integrated 2.4GHz Wi-Fi & BLE 5.0.",
        "tag": "Processor",
        "part": "rf_shield",
        "anchor": [-0.8, 0.2, 0],
        "position": [-0.8, 1.8, 0]
      }
    ]
  }
}
```
