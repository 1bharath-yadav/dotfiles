# Glint Overlay Recipes

Production-ready recipes for interactive visual explanations using HTML5, SVG, Three.js WebGL, and incremental DOM patching.

---

## Recipe 1: 3D Mechanical Cutaway (Three.js WebGL + CSS2D Callout Tracking)

Renders a rotating 3D mechanical assembly with orbiting controls, transparent cutaway casing, and floating HTML callout badges that track 3D coordinates. Clicking any badge triggers `glint.ask(...)`.

### Tool Call: `glint_draw`
```json
{
  "name": "glint_draw",
  "arguments": {
    "action": "render",
    "adapter": "html",
    "title": "Turbojet Engine Core & Afterburner",
    "html": "<div id=\"viewport\" style=\"position: fixed; inset: 0; pointer-events: none;\"><div id=\"hud\" class=\"interactive\" style=\"position: absolute; top: 40px; right: 40px; background: rgba(15,23,42,0.85); backdrop-filter: blur(16px); border: 1px solid rgba(56,189,248,0.3); border-radius: 12px; padding: 14px 18px; color: #f8fafc; font-family: sans-serif; pointer-events: auto; max-width: 320px;\"><h3 style=\"margin: 0 0 6px 0; font-size: 15px; color: #38bdf8;\">Turbofan Cutaway</h3><p style=\"margin: 0 0 10px 0; font-size: 12px; color: #94a3b8;\">Drag to rotate • Scroll to zoom • Click callout to ask</p><button onclick=\"toggleExplode()\" style=\"background: #0284c7; color: white; border: none; padding: 6px 12px; border-radius: 6px; font-size: 12px; cursor: pointer;\">Toggle Exploded View</button></div><div id=\"canvas-container\" class=\"interactive\" style=\"width: 100vw; height: 100vh;\"></div></div><script type=\"module\">import * as THREE from 'https://esm.sh/three@0.160.0';import { OrbitControls } from 'https://esm.sh/three@0.160.0/addons/controls/OrbitControls.js';import { CSS2DRenderer, CSS2DObject } from 'https://esm.sh/three@0.160.0/addons/renderers/CSS2DRenderer.js';const container = document.getElementById('canvas-container');const scene = new THREE.Scene();const camera = new THREE.PerspectiveCamera(45, window.innerWidth / window.innerHeight, 0.1, 1000);camera.position.set(0, 2, 7);const renderer = new THREE.WebGLRenderer({ antialias: true, alpha: true });renderer.setSize(window.innerWidth, window.innerHeight);renderer.setPixelRatio(window.devicePixelRatio);container.appendChild(renderer.domElement);const labelRenderer = new CSS2DRenderer();labelRenderer.setSize(window.innerWidth, window.innerHeight);labelRenderer.domElement.style.position = 'absolute';labelRenderer.domElement.style.top = '0px';labelRenderer.domElement.style.pointerEvents = 'none';container.appendChild(labelRenderer.domElement);const controls = new OrbitControls(camera, renderer.domElement);controls.enableDamping = true;controls.dampingFactor = 0.05;const ambient = new THREE.AmbientLight(0xffffff, 0.8);scene.add(ambient);const dirLight = new THREE.DirectionalLight(0x38bdf8, 2.0);dirLight.position.set(5, 10, 7);scene.add(dirLight);const casingGeo = new THREE.CylinderGeometry(1.4, 1.4, 4.2, 32, 1, true, 0, Math.PI * 1.5);const casingMat = new THREE.MeshPhysicalMaterial({ color: 0x64748b, transparent: true, opacity: 0.35, roughness: 0.2, metalness: 0.8, side: THREE.DoubleSide });const casing = new THREE.Mesh(casingGeo, casingMat);casing.rotation.z = Math.PI / 2;scene.add(casing);const fanGeo = new THREE.CylinderGeometry(1.2, 1.2, 0.3, 24);const fanMat = new THREE.MeshStandardMaterial({ color: 0x38bdf8, metalness: 0.9, roughness: 0.2 });const fan = new THREE.Mesh(fanGeo, fanMat);fan.rotation.z = Math.PI / 2;fan.position.x = -1.5;scene.add(fan);function createBadge(text, sub, pos, partName) { const div = document.createElement('div'); div.className = 'interactive'; div.style.background = 'rgba(15,23,42,0.9)'; div.style.border = '1px solid #38bdf8'; div.style.borderRadius = '8px'; div.style.padding = '6px 10px'; div.style.color = '#fff'; div.style.fontSize = '12px'; div.style.cursor = 'pointer'; div.style.pointerEvents = 'auto'; div.style.boxShadow = '0 4px 14px rgba(0,0,0,0.5)'; div.innerHTML = '<strong>' + text + '</strong><br><span style=\"color:#94a3b8;font-size:10px;\">' + sub + '</span>'; div.onclick = () => window.glint.ask(partName); const obj = new CSS2DObject(div); obj.position.copy(pos); scene.add(obj); }createBadge('Intake Fan', '24 Titanium blades', new THREE.Vector3(-1.5, 1.5, 0), 'Intake Fan');let exploded = false;window.toggleExplode = function() { exploded = !exploded; casing.position.y = exploded ? 1.0 : 0; fan.position.x = exploded ? -2.2 : -1.5; };function animate() { requestAnimationFrame(animate); fan.rotation.x += 0.05; controls.update(); renderer.render(scene, camera); labelRenderer.render(scene, camera); }animate();</script>"
  }
}
```

---

## Recipe 2: Scientific Biological Process (Photosynthesis with Animated Photons)

Visualizes the light reactions of photosynthesis with animated SVG photon rays traveling into the thylakoid membrane, splitting water into oxygen and pumping protons for ATP synthesis.

### Tool Call: `glint_draw`
```json
{
  "name": "glint_draw",
  "arguments": {
    "action": "render",
    "adapter": "html",
    "title": "Photosynthesis: Light-Dependent Reactions",
    "html": "<div id=\"stage\" style=\"position: fixed; right: 40px; top: 60px; width: 480px; background: rgba(15, 23, 42, 0.92); backdrop-filter: blur(14px); border: 1px solid rgba(74, 222, 128, 0.4); border-radius: 16px; padding: 20px; color: #f8fafc; font-family: system-ui, sans-serif; box-shadow: 0 12px 36px rgba(0,0,0,0.6); pointer-events: auto;\"><div style=\"display: flex; justify-content: space-between; align-items: center; margin-bottom: 12px;\"><h2 style=\"margin: 0; font-size: 16px; color: #4ade80; font-weight: 700;\">Photosystem II & Thylakoid Core</h2><span style=\"background: rgba(74, 222, 128, 0.15); color: #4ade80; border: 1px solid rgba(74, 222, 128, 0.3); font-size: 11px; padding: 3px 8px; border-radius: 20px;\">Light Reactions</span></div><svg viewBox=\"0 0 440 220\" style=\"width: 100%; height: auto; background: #020617; border-radius: 10px; border: 1px solid #1e293b;\"><defs><linearGradient id=\"sunlight\" x1=\"0%\" y1=\"0%\" x2=\"100%\" y2=\"100%\"><stop offset=\"0%\" stop-color=\"#fde047\" stop-opacity=\"0.9\"/><stop offset=\"100%\" stop-color=\"#22c55e\" stop-opacity=\"0.2\"/></linearGradient><filter id=\"glow\"><feGaussianBlur stdDeviation=\"2\" result=\"blur\"/><feMerge><feMergeNode in=\"blur\"/><feMergeNode in=\"SourceGraphic\"/></feMerge></filter></defs><path d=\"M 40 20 L 140 120\" stroke=\"url(#sunlight)\" stroke-width=\"4\" stroke-dasharray=\"6,6\"><animate attributeName=\"stroke-dashoffset\" values=\"24;0\" dur=\"1s\" repeatCount=\"indefinite\"/></path><circle cx=\"40\" cy=\"20\" r=\"16\" fill=\"#facc15\" filter=\"url(#glow)\"/><text x=\"32\" y=\"24\" font-size=\"10\" fill=\"#78350f\" font-weight=\"bold\">hν</text><rect x=\"10\" y=\"110\" width=\"420\" height=\"50\" rx=\"8\" fill=\"#064e3b\" opacity=\"0.7\" stroke=\"#10b981\" stroke-width=\"1.5\"/><g class=\"interactive\" onclick=\"glint.ask('Photosystem II')\" style=\"cursor: pointer;\"><circle cx=\"140\" cy=\"135\" r=\"22\" fill=\"#15803d\" stroke=\"#86efac\" stroke-width=\"2\"/><text x=\"122\" y=\"139\" fill=\"#ffffff\" font-size=\"11\" font-weight=\"bold\">PS II</text></g><path d=\"M 140 157 L 140 185\" stroke=\"#38bdf8\" stroke-width=\"2\" stroke-dasharray=\"3,3\"/><text x=\"110\" y=\"200\" fill=\"#38bdf8\" font-size=\"10\">2 H₂O → O₂ + 4 H⁺</text><path d=\"M 162 135 Q 220 90 280 135\" fill=\"none\" stroke=\"#facc15\" stroke-width=\"2\" stroke-dasharray=\"4,4\"><animate attributeName=\"stroke-dashoffset\" values=\"16;0\" dur=\"1.2s\" repeatCount=\"indefinite\"/></path><g class=\"interactive\" onclick=\"glint.ask('Cytochrome b6f')\" style=\"cursor: pointer;\"><rect x=\"260\" y=\"118\" width=\"40\" height=\"34\" rx=\"6\" fill=\"#1e3a8a\" stroke=\"#60a5fa\" stroke-width=\"1.5\"/><text x=\"268\" y=\"139\" fill=\"#ffffff\" font-size=\"10\">Cyt</text></g><g class=\"interactive\" onclick=\"glint.ask('ATP Synthase')\" style=\"cursor: pointer;\"><circle cx=\"380\" cy=\"135\" r=\"20\" fill=\"#a855f7\" stroke=\"#d8b4fe\" stroke-width=\"2\"/><text x=\"368\" y=\"139\" fill=\"#ffffff\" font-size=\"10\">ATP</text></g></svg><div style=\"display: flex; gap: 8px; margin-top: 14px;\"><button class=\"interactive\" onclick=\"glint.ask('Water Splitting Complex')\" style=\"flex: 1; background: #064e3b; border: 1px solid #10b981; color: #86efac; border-radius: 8px; padding: 8px; font-size: 12px; cursor: pointer;\">Inspect H₂O Splitting</button><button class=\"interactive\" onclick=\"glint.ask('Chemiosmosis and Proton Gradient')\" style=\"flex: 1; background: #3b0764; border: 1px solid #a855f7; color: #e9d5ff; border-radius: 8px; padding: 8px; font-size: 12px; cursor: pointer;\">Proton Gradient</button></div></div>"
  }
}
```

---

## Recipe 3: Algorithmic Data Structure (Animated BST & Search Pulse)

Visualizes a Binary Search Tree with animated traversal pulses that highlight search paths dynamically.

### Tool Call: `glint_draw`
```json
{
  "name": "glint_draw",
  "arguments": {
    "action": "render",
    "adapter": "html",
    "title": "Binary Search Tree: Key Traversal",
    "html": "<div id=\"bst-stage\" style=\"position: fixed; right: 40px; top: 60px; width: 420px; background: rgba(15, 23, 42, 0.92); backdrop-filter: blur(16px); border: 1px solid rgba(168, 85, 247, 0.4); border-radius: 16px; padding: 18px; color: #f8fafc; font-family: system-ui, sans-serif; pointer-events: auto;\"><div style=\"display: flex; justify-content: space-between; align-items: center; margin-bottom: 12px;\"><h3 style=\"margin: 0; font-size: 15px; color: #c084fc;\">Binary Search Tree (Find 28)</h3><span id=\"bst-status\" style=\"font-size: 11px; background: #581c87; color: #e9d5ff; padding: 3px 8px; border-radius: 12px;\">O(log n) Path</span></div><svg viewBox=\"0 0 380 200\" style=\"width: 100%; height: auto; background: #020617; border-radius: 8px;\"><line x1=\"190\" y1=\"30\" x2=\"100\" y2=\"80\" stroke=\"#334155\" stroke-width=\"2\" id=\"edge-left\"/><line x1=\"190\" y1=\"30\" x2=\"280\" y2=\"80\" stroke=\"#38bdf8\" stroke-width=\"3\" id=\"edge-right\"/><line x1=\"280\" y1=\"80\" x2=\"230\" y2=\"140\" stroke=\"#38bdf8\" stroke-width=\"3\" id=\"edge-28\"/><line x1=\"280\" y1=\"80\" x2=\"330\" y2=\"140\" stroke=\"#334155\" stroke-width=\"2\"/><g id=\"node-20\" class=\"interactive\" onclick=\"glint.ask('BST Root Node 20')\" style=\"cursor: pointer;\"><circle cx=\"190\" cy=\"30\" r=\"18\" fill=\"#1e293b\" stroke=\"#38bdf8\" stroke-width=\"2\"/><text x=\"182\" y=\"35\" fill=\"#fff\" font-size=\"12\" font-weight=\"bold\">20</text></g><g id=\"node-10\" class=\"interactive\" onclick=\"glint.ask('BST Left Child 10')\" style=\"cursor: pointer;\"><circle cx=\"100\" cy=\"80\" r=\"16\" fill=\"#0f172a\" stroke=\"#475569\" stroke-width=\"2\"/><text x=\"93\" y=\"84\" fill=\"#94a3b8\" font-size=\"11\">10</text></g><g id=\"node-30\" class=\"interactive\" onclick=\"glint.ask('BST Subtree Root 30')\" style=\"cursor: pointer;\"><circle cx=\"280\" cy=\"80\" r=\"18\" fill=\"#0369a1\" stroke=\"#38bdf8\" stroke-width=\"2.5\"/><text x=\"272\" y=\"85\" fill=\"#fff\" font-size=\"12\" font-weight=\"bold\">30</text></g><g id=\"node-28\" class=\"interactive\" onclick=\"glint.ask('BST Target Node 28')\" style=\"cursor: pointer;\"><circle cx=\"230\" cy=\"140\" r=\"18\" fill=\"#15803d\" stroke=\"#4ade80\" stroke-width=\"3\"/><text x=\"222\" y=\"145\" fill=\"#fff\" font-size=\"12\" font-weight=\"bold\">28</text></g><g id=\"node-35\" class=\"interactive\" onclick=\"glint.ask('BST Node 35')\" style=\"cursor: pointer;\"><circle cx=\"330\" cy=\"140\" r=\"16\" fill=\"#0f172a\" stroke=\"#475569\" stroke-width=\"2\"/><text x=\"323\" y=\"144\" fill=\"#94a3b8\" font-size=\"11\">35</text></g></svg><div id=\"explanation\" style=\"margin-top: 10px; font-size: 12px; color: #cbd5e1; line-height: 1.4;\">Comparing target <strong style=\"color: #4ade80;\">28</strong>: 28 &gt; 20 (branch right) → 28 &lt; 30 (branch left) → Found in 2 hops.</div></div>"
  }
}
```

---

## Recipe 4: Incremental Styling & Append Patch Example

Demonstrates modifying the active tree without re-rendering or blinking.

### Step 4A: Highlight Search Node via CSS Style Patch
Target `#node-28` to highlight match confirmation:
```json
{
  "name": "glint_draw",
  "arguments": {
    "action": "style",
    "selector": "#node-28 circle",
    "style": {
      "fill": "#22c55e",
      "stroke": "#ffffff",
      "strokeWidth": "4px",
      "filter": "drop-shadow(0 0 10px #22c55e)"
    }
  }
}
```

### Step 4B: Append Metric Footer via Append Patch
Inject a performance badge into `#bst-stage`:
```json
{
  "name": "glint_draw",
  "arguments": {
    "action": "append",
    "selector": "#bst-stage",
    "html": "<div id=\"metric-chip\" class=\"interactive\" onclick=\"glint.ask('BST Rotations & Height')\" style=\"margin-top: 12px; padding: 8px 12px; background: rgba(34,197,94,0.15); border: 1px solid #22c55e; border-radius: 8px; font-size: 12px; color: #86efac; display: flex; justify-content: space-between;\"><span>Height: 3 • Balanced AVL</span><span style=\"text-decoration: underline; cursor: pointer;\">Verify Balance</span></div>"
  }
}
```

### Step 4C: Dim Non-Relevant Nodes
```json
{
  "name": "glint_draw",
  "arguments": {
    "action": "style",
    "selector": "#node-10, #node-35",
    "style": {
      "opacity": "0.3"
    }
  }
}
```
All changes apply seamlessly on screen in real time with zero layout reload.
