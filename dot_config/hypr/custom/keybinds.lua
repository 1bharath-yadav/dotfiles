-- custom/keybinds.lua

-- Meta / edit configs
hl.bind(
	"CTRL + SUPER + Slash",
	hl.dsp.exec_cmd("nvim ~/.config/illogical-impulse/config.json"),
	{ description = "Edit shell config" }
)
hl.bind(
	"CTRL + SUPER + ALT + Slash",
	hl.dsp.exec_cmd("xdg-open ~/.config/hypr/custom/keybinds.lua"),
	{ description = "Edit user keybinds" }
)

-- Hardware
hl.bind("ALT + BracketLeft", hl.dsp.exec_cmd("brightnessctl set 1%-"), { repeating = true })
hl.bind("ALT + BracketRight", hl.dsp.exec_cmd("brightnessctl set +1%"), { repeating = true })

-- Session / toggles
hl.bind("SUPER + ALT + F4", hl.dsp.global("quickshell:sessionToggle"))
hl.bind("SUPER + ALT + N", hl.dsp.exec_cmd("~/.config/hypr/custom/scripts/logseq.sh"))
hl.bind("SUPER + ALT + G", hl.dsp.exec_cmd("~/.config/hypr/custom/scripts/toggle-gdrive.sh"))
hl.bind("SUPER + ALT + B", hl.dsp.exec_cmd("~/.config/hypr/custom/scripts/toggle-syncthing.sh"))
hl.bind("SUPER + ALT + I", hl.dsp.exec_cmd("~/.config/hypr/custom/scripts/send_file.sh"))

-- Screenshots
hl.bind(
	"SUPER + ALT + P",
	hl.dsp.exec_cmd("grim - | wl-copy"),
	{ locked = true, description = "Screenshot >> clipboard" }
)
hl.bind(
	"CTRL + ALT + P",
	hl.dsp.exec_cmd(
		"mkdir -p $(xdg-user-dir PICTURES)/Screenshots && grim $(xdg-user-dir PICTURES)/Screenshots/Screenshot_\"$(date '+%Y-%m-%d_%H.%M.%S')\".png"
	),
	{ locked = true, description = "Screenshot >> clipboard & save" }
)

-- Apps
hl.bind("SUPER + ALT + E", hl.dsp.exec_cmd("zen-browser"))
hl.bind("SUPER + ALT + K", hl.dsp.exec_cmd("koodo-reader"))

hl.bind("SUPER + ALT + O", hl.dsp.workspace.toggle_special("obsidian"), { description = "Toggle Obsidian scratchpad" })
hl.bind("SUPER + Y", hl.dsp.workspace.toggle_special("yazi"), { description = "Toggle Yazi scratchpad" })
hl.bind("SUPER + Z", hl.dsp.workspace.toggle_special("kitty"), { description = "Toggle Kitty scratchpad" })
hl.bind("SUPER + Minus", hl.dsp.workspace.toggle_special("quicknote"), { description = "Toggle Quicknote scratchpad" })
hl.bind("CTRL + SUPER + G", hl.dsp.workspace.toggle_special("calendar"), { description = "Toggle Calendar scratchpad" })
hl.bind("CTRL + SUPER + K", hl.dsp.workspace.toggle_special("keep"), { description = "Toggle Google Keep scratchpad" })
hl.bind(
	"CTRL + SUPER + L",
	hl.dsp.workspace.toggle_special("tasks"),
	{ description = "Toggle Google Tasks scratchpad" }
)
hl.bind("CTRL + SUPER + M", hl.dsp.workspace.toggle_special("gmail"), { description = "Toggle Gmail scratchpad" })
hl.bind("SUPER + Comma", hl.dsp.workspace.toggle_special("hermes"), { description = "Toggle Hermes scratchpad" })

hl.bind("SUPER + Right", hl.dsp.focus({ workspace = "r+1" }), { description = "Move to right workspace" })
hl.bind("SUPER + Left", hl.dsp.focus({ workspace = "r-1" }), { description = "Move to left workspace" })

-- -- Voice Assistant
-- hl.bind(
-- 	"SUPER + ALT + H",
-- 	hl.dsp.exec_cmd("quickshell -c ii ipc call voiceAssistantOverlay toggle"),
-- 	{ description = "Voice assistant: toggle assistant overlay" }
-- )

--- send clipboard content to phone
hl.bind(
	"SUPER + ALT + P",
	hl.dsp.exec_cmd("~/.dotfiles/dot_local/bin/executable_send_file.sh"),
	{ description = "Send clipboard content to phone" }
)
-- Dictation
hl.bind("SUPER + H", hl.dsp.exec_cmd("~/.local/bin/transcribe --mode toggle"), { description = "Dictation toggle" })
