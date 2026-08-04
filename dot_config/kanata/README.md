# Kanata & Hyprkan Keyboard Remapper Documentation

## Overview
This directory contains the hardware-level remapping configuration (`kanata.kbd`) and application-aware context rules (`apps.json`) for Linux / Hyprland.

- **Engine**: `kanata` (TCP server running on port `10000`)
- **Layer Switcher**: `hyprkan` (dynamically switches layers based on active window)
- **Design Philosophy**: Preserve 100% of standard physical keys (Super key, Number row `1-0`, Arrow keys `◀ ▼ ▲ ▶`, F-keys `F1-F12`, Spacebar) while layering Home-Row Mods and navigation layers on top.

---

## Complete Keymap & Layer Documentation

### 1. Main Layer (`main`) — Default Typing Layer
Every physical key retains its natural location and function. Dual-role tap-hold behavior is added to the home row (`A S D F` / `J K L ;`) and Spacebar.

| Key | Tap Action | Hold Action | Description |
|---|---|---|---|
| `A` | `a` | `Super` (Left Meta) | Home-Row Mod |
| `S` | `s` | `Alt` (Left Alt) | Home-Row Mod |
| `D` | `d` | `Control` (Left Ctrl) | Home-Row Mod |
| `F` | `f` | `Shift` (Left Shift) | Home-Row Mod |
| `J` | `j` | `Shift` (Right Shift) | Home-Row Mod |
| `K` | `k` | `Control` (Right Ctrl) | Home-Row Mod |
| `L` | `l` | `Alt` (Right Alt) | Home-Row Mod |
| `;` | `;` | `Super` (Right Meta) | Home-Row Mod |
| `Caps Lock` | `Escape` | `Control` | Tap = Esc, Hold = Ctrl |
| `Spacebar` | `Space` | `nav` Layer | Tap = Space, Hold = Navigation Layer |
| `Super` (Physical) | `Super` | `Super` | Standard physical Super key preserved |
| `1` – `0`, `-`, `=` | `1` – `0`, `-`, `=` | `1` – `0`, `-`, `=` | Standard physical numbers preserved |
| `◀` `▼` `▲` `▶` | `Left` `Down` `Up` `Right` | `Left` `Down` `Up` `Right` | Standard physical arrow keys preserved |

---

### 2. Navigation Layer (`nav`) — *Hold Spacebar*
Home-row focused arrow and page navigation:

| Key | Action | Function |
|---|---|---|
| `H` | `Left Arrow` | Move cursor left |
| `J` | `Down Arrow` | Move cursor down |
| `K` | `Up Arrow` | Move cursor up |
| `L` | `Right Arrow` | Move cursor right |
| `U` | `Home` | Move to beginning of line |
| `I` | `Page Down` | Page Down |
| `O` | `Page Up` | Page Up |
| `P` | `End` | Move to end of line |
| `Backspace` | `Delete` | Forward delete character |
| `A S D F` | `Super / Alt / Ctrl / Shift` | Home-Row Mods remain active |

---

### 3. Symbol & Number Layer (`symb`) — *Hold `bspc` or chord*
Quick symbol and number entry:

| Row | Keys | Action |
|---|---|---|
| Top Alpha Row | `Q W E R T Y U I O P` | Numbers `1 2 3 4 5 6 7 8 9 0` |
| Number Row | `1 2 3 4 5 6 7 8 9 0` | Symbols `! @ # $ % ^ & * ( )` |
| Bottom Alpha Row | `C V B N M` | Brackets `[ { } ] /` |

---

### 4. System Layer (`syst`) — *Hold `S` or shortcut*
Native hardware and multimedia controls:

| Key | Action | Function |
|---|---|---|
| `I` | `vold` | Volume Down (wpctl) |
| `O` | `volu` | Volume Up (wpctl) |
| `U` | `prev` | Previous Track (playerctl) |
| `P` | `next` | Next Track (playerctl) |
| `[` | `pp` | Play / Pause (playerctl) |
| `C` | `scolor` | Color Picker (hyprpicker) |
| `V` | `brdn` | Brightness Down (brightnessctl) |
| `B` | `brup` | Brightness Up (brightnessctl) |
| `Space` | `lrld` | Live Reload Kanata configuration |

---

### 5. Browser Layer (`browser`) — *Automated via Hyprkan*
Automatically activated when focused on web browsers (Zen, Chrome, Firefox, Brave, Vivaldi, LibreWolf):

| Key | Shortcut | Action |
|---|---|---|
| `H` | `Alt + Left` | Back in browser history |
| `L` | `Alt + Right` | Forward in browser history |
| `J` | `Ctrl + Tab` | Next Tab |
| `K` | `Ctrl + Shift + Tab` | Previous Tab |
| `T` | `Ctrl + T` | Open New Tab |
| `W` | `Ctrl + W` | Close Active Tab |
| `R` | `Ctrl + R` | Reload Page |
| `U` | `Ctrl + Shift + T` | Reopen Closed Tab |
| `I` | `Ctrl + L` | Focus URL Address Bar |
| `O` | `Ctrl + D` | Bookmark Page |

---

### 6. Chords (`defchordsv2`) — Multi-Key Simultaneous Presses

| Chord Combination | Output | Description |
|---|---|---|
| `J + K` | `Escape` | Fast home-row escape |
| `W + E + R` | `Ctrl + =` | Zoom In |
| `S + D + F` | `Ctrl + -` | Zoom Out |
| `Q + W + E` | `Volume Up` | Raise Master Volume |
| `A + S + D` | `Volume Down` | Lower Master Volume |
| `Space + F + G` | `Alt + Tab` | Quick App Switch |
| `Space + S + C` | `Screen Lock` | Lock Session |