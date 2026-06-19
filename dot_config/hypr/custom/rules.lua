-- custom/rules.lua

--------------------------------------------------
-- OBSIDIAN SCRATCHPAD
--------------------------------------------------

hl.window_rule({
	match = { class = "^([Oo]bsidian)$" },
	float = true,
})

hl.window_rule({
	match = { class = "^([Oo]bsidian)$" },
	size = { "(monitor_w*0.90)", "(monitor_h*0.90)" },
})

hl.window_rule({
	match = { class = "^([Oo]bsidian)$" },
	center = true,
})

hl.window_rule({
	match = { class = "^([Oo]bsidian)$" },
	workspace = "special:obsidian",
})

--------------------------------------------------
-- YAZI SCRATCHPAD
--------------------------------------------------

hl.window_rule({
	match = { class = "^(yazi-sp)$" },
	float = true,
})

hl.window_rule({
	match = { class = "^(yazi-sp)$" },
	size = { "(monitor_w*0.80)", "(monitor_h*0.80)" },
})

hl.window_rule({
	match = { class = "^(yazi-sp)$" },
	center = true,
})

hl.window_rule({
	match = { class = "^(yazi-sp)$" },
	workspace = "special:yazi",
})

--------------------------------------------------
-- KITTY SCRATCHPAD
--------------------------------------------------

hl.window_rule({
	match = { class = "^(kitty-sp)$" },
	float = true,
})

hl.window_rule({
	match = { class = "^(kitty-sp)$" },
	size = { "(monitor_w*0.85)", "(monitor_h*0.85)" },
})

hl.window_rule({
	match = { class = "^(kitty-sp)$" },
	center = true,
})

hl.window_rule({
	match = { class = "^(kitty-sp)$" },
	workspace = "special:kitty",
})

--------------------------------------------------
-- QUICKNOTE SCRATCHPAD
--------------------------------------------------

hl.window_rule({
	match = { class = "^(quicknote)$" },
	float = true,
})

hl.window_rule({
	match = { class = "^(quicknote)$" },
	size = { "(monitor_w*0.85)", "(monitor_h*0.85)" },
})

hl.window_rule({
	match = { class = "^(quicknote)$" },
	center = true,
})

hl.window_rule({
	match = { class = "^(quicknote)$" },
	workspace = "special:quicknote",
})

--------------------------------------------------
-- HERMES SCRATCHPAD
--------------------------------------------------

hl.window_rule({
	match = { class = "^(hermes-sp)$" },
	float = true,
})

hl.window_rule({
	match = { class = "^(hermes-sp)$" },
	size = { "(monitor_w*0.90)", "(monitor_h*0.90)" },
})

hl.window_rule({
	match = { class = "^(hermes-sp)$" },
	center = true,
})

hl.window_rule({
	match = { class = "^(hermes-sp)$" },
	workspace = "special:hermes",
})

--------------------------------------------------
-- GOOGLE CALENDAR
--------------------------------------------------

hl.window_rule({
	match = { class = "^(gcal)$" },
	float = true,
})

hl.window_rule({
	match = { class = "^(gcal)$" },
	size = { "(monitor_w*0.65)", "(monitor_h*0.85)" },
})

hl.window_rule({
	match = { class = "^(gcal)$" },
	center = true,
})

hl.window_rule({
	match = { class = "^(gcal)$" },
	workspace = "special:calendar",
})

--------------------------------------------------
-- SPECIAL WORKSPACES
--------------------------------------------------

hl.workspace_rule({
	workspace = "special:obsidian",
	on_created_empty = "obsidian",
})

hl.workspace_rule({
	workspace = "special:yazi",
	on_created_empty = "kitty --class yazi-sp -e yazi",
})

hl.workspace_rule({
	workspace = "special:kitty",
	on_created_empty = "kitty --class kitty-sp",
})

hl.workspace_rule({
	workspace = "special:quicknote",
	on_created_empty = "kitty --class quicknote -e yazi '/home/archer/Sync/obsidian_vault/til/'",
})

hl.workspace_rule({
	workspace = "special:calendar",
	on_created_empty = "google-chrome-stable --class=gcal --app=https://calendar.google.com",
})

hl.workspace_rule({
	workspace = "special:hermes",
	on_created_empty = "kitty --class hermes-sp -e hermes --tui",
})
