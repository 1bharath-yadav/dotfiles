-- Personal bindings loaded after Omarchy's defaults.
--
-- Reserved Omarchy bindings are intentionally avoided. See:
-- /usr/share/omarchy/default/hypr/bindings/*.lua

-- Utilities and personal actions.
o.bind("CTRL + SUPER + Slash", "Open default editor", "omarchy-default-editor")
o.bind("CTRL + SUPER + ALT + Slash", "Edit Hyprland bindings", "omarchy-launch-editor ~/.config/hypr/bindings.lua")
-- End4 Brightness.qml behavior hosted as an Omarchy shell service.
-- Alt+[ / Alt+] (no Super modifier).
hl.unbind("SUPER + BracketLeft")
hl.unbind("SUPER + BracketRight")
o.bind("ALT + BracketLeft", "Decrease brightness (hardware then gamma)", "omarchy-shell brightness decrement")
o.bind("ALT + BracketRight", "Increase brightness (gamma then hardware)", "omarchy-shell brightness increment")
o.bind("SUPER + ALT + SHIFT + G", "Toggle Google Drive", "~/.local/bin/toggle-gdrive.sh")
o.bind("SUPER + ALT + I", "Send file", "~/.local/bin/send_file.sh")
-- Override Omarchy's Google Maps binding on this key.
hl.unbind("SUPER + SHIFT + S")

-- Hyprshot screenshot workflow.
-- Region capture goes to clipboard; window/output captures are saved by Hyprshot.
o.bind("SUPER + SHIFT + S", "Screenshot region to clipboard", "hyprshot -m region --freeze --clipboard-only --silent")
o.bind("SUPER + SHIFT + P", "Screenshot active window to clipboard", "hyprshot -m window --clipboard-only --silent")
o.bind("SUPER + ALT + P", "Screenshot monitor to clipboard", "hyprshot -m output --clipboard-only --silent")
o.bind("SUPER + ALT + Semicolon", "Screenshot region and annotate", "hyprshot -m region --freeze --raw | satty --filename -")
o.bind("SUPER + ALT + E", "Zen Browser", "zen-browser")
o.bind("SUPER + ALT + SHIFT + K", "Koodo Reader", "koodo-reader")
-- Super+Alt+H remains available for ChatGPT dictation; click the bar robot for AI.
o.bind("SUPER + ALT + H", "ChatGPT dictation", "python3 ~/projects/cdp-agents/chatgpt/chatgpt.py --stt toggle")

-- Custom special workspaces.
o.bind("SUPER + Y", "Toggle Yazi scratchpad", hl.dsp.workspace.toggle_special("yazi"))
o.bind("SUPER + Z", "Toggle Kitty scratchpad", hl.dsp.workspace.toggle_special("kitty"))
o.bind("SUPER + MINUS", "Toggle Quicknote scratchpad", hl.dsp.workspace.toggle_special("quicknote"))
hl.unbind("SUPER + ALT + C")
o.bind("SUPER + ALT + C", "Toggle Calendar scratchpad", hl.dsp.workspace.toggle_special("calendar"))
hl.unbind("SUPER + SHIFT + K")
o.bind("SUPER + SHIFT + K", "Toggle Keep scratchpad", hl.dsp.workspace.toggle_special("keep"))
o.bind("CTRL + SUPER + L", "Toggle Tasks scratchpad", hl.dsp.workspace.toggle_special("tasks"))
o.bind("CTRL + SUPER + M", "Toggle Gmail scratchpad", hl.dsp.workspace.toggle_special("gmail"))
o.bind("SUPER + COMMA", "Toggle Hermes scratchpad", hl.dsp.workspace.toggle_special("hermes"))
o.bind("SUPER + ALT + Y", "Toggle XOY CDP scratchpad", hl.dsp.workspace.toggle_special("xoy-cdp"))

-- OSTT dictation: `ostt launch` is toggle-based (press once to record,
-- press again to stop and transcribe). Never run it on key release.
hl.unbind("F9")
o.bind("F9", "OSTT dictation (toggle)", "/home/archer/.local/bin/ostt launch --paste")

-- Passist voice: open/close the microphone for the always-running voice session.
hl.unbind("SUPER + H")
o.bind("SUPER + H", "Passist live voice (toggle)", "/home/archer/.local/bin/passist-ctl toggle-voice")


