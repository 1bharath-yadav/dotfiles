# Zero-Boilerplate Semantic UI Components (`theme.css`)

Glint provides pre-styled, GPU-accelerated component classes directly in `theme.css`. Agents do not need to write 50+ lines of inline CSS.

---

## 1. Class Reference Table

| Category | Class | Description |
|---|---|---|
| **Cards** | `.glint-card` | Dark translucent panel with border, blur, and auto click-through |
| | `.glint-card.glint-glass` | Ultra-translucent variant for minimal occlusion |
| **Typography** | `.glint-title` | 15px semi-bold headline |
| | `.glint-subtitle` | 12px muted sub-headline |
| | `.glint-desc` | 13px readable description |
| **Status Chips** | `.glint-badge` | Neutral gray pill chip |
| | `.glint-badge-emerald` | Green active status badge |
| | `.glint-badge-sky` | Sky blue info badge |
| | `.glint-badge-amber` | Amber warning badge |
| | `.glint-badge-rose` | Rose danger / error badge |
| **Stepper** | `.glint-stepper` | Vertical step container |
| | `.glint-step` | Individual step box (supports `.active` and `.done`) |
| | `.glint-step-num` | Step circle badge (contains number or checkmark) |
| | `.glint-step-title` | Step name |
| | `.glint-step-desc` | Step instructions |
| **Metrics** | `.glint-stat-row` | Grid for KPI cards |
| | `.glint-stat` | Metric container box |
| | `.glint-stat-value` | Monospace bold number |
| | `.glint-stat-label` | 11px muted label below value |
| **Layout** | `.glint-grid-2` | 2-column grid |
| | `.glint-grid-3` | 3-column grid |
| **Code** | `.glint-code` | Monospace terminal/code snippet block |
| **Buttons** | `.glint-btn-accent` | Emerald solid button for primary actions |
| | `.glint-btn-outline` | Hairline border button |
| **Animations**| `.glint-pulse` | Infinite gentle emerald glow animation |

---

## 2. High-Speed Copy-Paste Snippets

### A. Live System Metrics HUD
```html
<div class="glint-card" style="width: 320px;">
  <div style="display:flex; justify-content:space-between; align-items:center;">
    <h3 class="glint-title" style="margin:0;">Gemini Worker</h3>
    <span class="glint-badge glint-badge-emerald">Live</span>
  </div>
  <div class="glint-stat-row">
    <div class="glint-stat">
      <div class="glint-stat-value">62ms</div>
      <div class="glint-stat-label">Latency</div>
    </div>
    <div class="glint-stat">
      <div class="glint-stat-value">60 fps</div>
      <div class="glint-stat-label">Overlay</div>
    </div>
  </div>
  <div class="glint-code">$ hyprctl clients -j</div>
</div>
```

### B. Interactive Error Diagnosis Card
```html
<div class="glint-card" style="width: 380px;">
  <div class="glint-badge glint-badge-rose">Build Failure</div>
  <h3 class="glint-title" style="margin-top: 8px;">Rust Borrow Checker Error</h3>
  <p class="glint-desc">Cannot borrow <code>*self</code> as mutable more than once at a time.</p>
  <div class="glint-code">error[E0499]: cannot borrow `*self` as mutable</div>
  <div style="display:flex; gap:8px; margin-top:12px;">
    <button class="glint-btn glint-btn-accent" onclick="glint.setStep(2)">Next Step</button>
    <button class="glint-btn glint-btn-outline" onclick="glint.clear()">Dismiss</button>
  </div>
</div>
```
