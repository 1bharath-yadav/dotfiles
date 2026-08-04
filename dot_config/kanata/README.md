# Kanata & Hyprkan Power-User Configuration

## Architecture
- **Engine**: `kanata` (hardware-level remapping with TCP server on port `10000`)
- **App Switcher**: `hyprkan` (dynamically switches layers based on active Hyprland window class)

## Layer Design
1. `base`: Home-Row Mods (`A S D F` / `J K L ;` mapped to `Super`, `Alt`, `Ctrl`, `Shift`), `Space` tap = space / hold = `nav` layer, `Caps` tap = `Escape` / hold = `Ctrl`, `J+K` chord = `Escape`.
2. `nav`: Directional movement (`H` = Left, `J` = Down, `K` = Up, `L` = Right), Navigation (`U` = Home, `I` = PageDown, `O` = PageUp, `P` = End), Delete (`Backspace` / `Del`).
3. `browser`: Context-aware web navigation (`H` = Back, `L` = Forward, `J` = Next Tab, `K` = Prev Tab, `T` = New Tab, `W` = Close Tab, `R` = Reload, `U` = Reopen Tab, `I` = Address Bar, `O` = Bookmark).

## Services
- `kanata.service` (user unit)
- `hyprkan.service` (user unit)