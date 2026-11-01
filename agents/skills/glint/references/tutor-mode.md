# Step-by-Step Guidance & Tutor Mode

Use Tutor Mode when guiding a human through a multi-step task, debugging an issue, or running an interactive tutorial on Linux/Wayland.

---

## 1. The 3 Steps of a Tutor Interaction

### Step 1: Render the Stepper Card
Mount the initial stepper using `adapter: "html"`. Pre-mark step 1 with `.active`:

```html
<div class="glint-card" style="width: 360px;">
  <div class="glint-badge glint-badge-sky">Interactive Tutor</div>
  <h3 class="glint-title" style="margin-top: 8px;">Flash ESP32-S3 Firmware</h3>
  <div class="glint-stepper">
    <div class="glint-step active" id="step-1">
      <div class="glint-step-num">1</div>
      <div class="glint-step-content">
        <div class="glint-step-title">Connect Microcontroller</div>
        <div class="glint-step-desc">Plug USB-C cable into the flashing port.</div>
      </div>
    </div>
    <div class="glint-step" id="step-2">
      <div class="glint-step-num">2</div>
      <div class="glint-step-content">
        <div class="glint-step-title">Hold Boot Button</div>
        <div class="glint-step-desc">Hold down GPIO0 while resetting.</div>
      </div>
    </div>
    <div class="glint-step" id="step-3">
      <div class="glint-step-num">3</div>
      <div class="glint-step-content">
        <div class="glint-step-title">Execute esptool.py</div>
        <div class="glint-step-desc">Write bootloader and app binary.</div>
      </div>
    </div>
  </div>
  <button class="glint-btn glint-btn-accent" onclick="glint.nextStep()">Next Step</button>
</div>
```

---

### Step 2: Highlight On-Screen Elements (`glint_point`)
Point a laser dot or highlight box at the actual button or terminal line on the user's screen:

```json
{
  "name": "glint_point",
  "arguments": {
    "app": "Code",
    "target": "Terminal",
    "note": "Hold Boot Button now",
    "ttl_ms": 6000
  }
}
```

---

### Step 3: Advance the Stepper in Real Time (`glint_control`)
When the user finishes a step, advance the stepper without rebuilding the DOM:

```json
{
  "name": "glint_control",
  "arguments": {
    "action": "step",
    "value": 2
  }
}
```
*Effect:* Step 1 automatically marks as `.done` with a green checkmark, Step 2 becomes `.active` with an emerald glow, and the view smoothly scrolls.
