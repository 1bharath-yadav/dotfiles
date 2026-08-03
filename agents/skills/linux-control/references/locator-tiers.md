# 5-Tier Locator Hierarchy & Fallback Logic

This document specifies the fallback order and targeting strategies used by `locator.py`.

---

## Locator Tiers

```
Tier 1: AT-SPI Accessibility Tree
   ↓ (if not exposed or unreadable)
Tier 2: Native Window Metadata (hyprctl activewindow -j)
   ↓ (if window offset insufficient)
Tier 3: Visual OCR Text Bounding Boxes (grim + tesseract)
   ↓ (if text match confidence < 0.80)
Tier 4: Visual Region Fingerprinting (SHA256 Image Hashes)
   ↓ (if relative element unknown)
Tier 5: Physical Coordinates with HiDPI Scale Offset
```

---

## Fallback Rules

1. **AT-SPI (Tier 1)**: Native Wayland/GTK/Qt accessibility nodes. Note: Electron apps (Zen, Chrome, VS Code) require accessibility flags to expose full AT-SPI trees.
2. **Window Metadata (Tier 2)**: Query window origin `[x,y]` and size `[w,h]` via `hyprctl activewindow -j`. Target controls relative to window origin (`x = window_x + dx`, `y = window_y + dy`).
3. **OCR Bounding Boxes (Tier 3)**: Take screenshot using `grim`, extract word coordinates via `tesseract`, and target center of matched word text.
4. **Visual Fingerprinting (Tier 4)**: Calculate hash of screenshot region before and after action to verify UI state change (detect zero-change click misses).
5. **Physical Coordinates (Tier 5)**: Absolute monitor coordinates transformed for display scale factors (`(x * scale) + offset`).
