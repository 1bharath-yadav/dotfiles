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
	match = { class = "^(chrome-calendar.google.com__-Default)$" },
	float = true,
})

hl.window_rule({
	match = { class = "^(chrome-calendar.google.com__-Default)$" },
	size = { "(monitor_w*0.65)", "(monitor_h*0.85)" },
})

hl.window_rule({
	match = { class = "^(chrome-calendar.google.com__-Default)$" },
	center = true,
})

hl.window_rule({
	match = { class = "^(chrome-calendar.google.com__-Default)$" },
	workspace = "special:calendar",
})

--------------------------------------------------
-- GOOGLE CHROME OAUTH POPUP (sign-in, account picker, etc.)
-- Chrome opens these via window.open(), which briefly carries the title
-- "Untitled - Google Chrome" before it navigates. Static rules match on
-- initialTitle, so this catches it; matching the post-navigation title
-- ("Sign in - Google Accounts...") never works, since float/size/center
-- are evaluated once at window creation, before that title exists.
--------------------------------------------------

hl.window_rule({
	match = { class = "^(google-chrome)$", title = "^(Untitled - Google Chrome)$" },
	float = true,
})

hl.window_rule({
	match = { class = "^(google-chrome)$", title = "^(Untitled - Google Chrome)$" },
	size = { 520, 680 },
})

hl.window_rule({
	match = { class = "^(google-chrome)$", title = "^(Untitled - Google Chrome)$" },
	center = true,
})

--------------------------------------------------
-- GOOGLE KEEP
--------------------------------------------------

hl.window_rule({
	match = { class = "^(chrome-keep.google.com__-Default)$" },
	float = true,
})

hl.window_rule({
	match = { class = "^(chrome-keep.google.com__-Default)$" },
	size = { "(monitor_w*0.65)", "(monitor_h*0.85)" },
})

hl.window_rule({
	match = { class = "^(chrome-keep.google.com__-Default)$" },
	center = true,
})

hl.window_rule({
	match = { class = "^(chrome-keep.google.com__-Default)$" },
	workspace = "special:keep",
})

--------------------------------------------------
-- GOOGLE TASKS
--------------------------------------------------

hl.window_rule({
	match = { class = "^(chrome-tasks.google.com__-Default)$" },
	float = true,
})

hl.window_rule({
	match = { class = "^(chrome-tasks.google.com__-Default)$" },
	size = { "(monitor_w*0.45)", "(monitor_h*0.85)" },
})

hl.window_rule({
	match = { class = "^(chrome-tasks.google.com__-Default)$" },
	center = true,
})

hl.window_rule({
	match = { class = "^(chrome-tasks.google.com__-Default)$" },
	workspace = "special:tasks",
})

--------------------------------------------------
-- GMAIL
--------------------------------------------------

hl.window_rule({
	match = { class = "^(chrome-mail.google.com__-Default)$" },
	float = true,
})

hl.window_rule({
	match = { class = "^(chrome-mail.google.com__-Default)$" },
	size = { "(monitor_w*0.75)", "(monitor_h*0.85)" },
})

hl.window_rule({
	match = { class = "^(chrome-mail.google.com__-Default)$" },
	center = true,
})

hl.window_rule({
	match = { class = "^(chrome-mail.google.com__-Default)$" },
	workspace = "special:gmail",
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
	on_created_empty = "kitty --class quicknote -e yazi '/home/archer/til/'",
})

hl.workspace_rule({
	workspace = "special:calendar",
	on_created_empty = "google-chrome-stable --app=https://calendar.google.com",
})

hl.workspace_rule({
	workspace = "special:keep",
	on_created_empty = "google-chrome-stable --app=https://keep.google.com",
})

hl.workspace_rule({
	workspace = "special:tasks",
	on_created_empty = "google-chrome-stable --app=https://tasks.google.com",
})

hl.workspace_rule({
	workspace = "special:gmail",
	on_created_empty = "google-chrome-stable --app=https://mail.google.com",
})

hl.workspace_rule({
	workspace = "special:hermes",
	on_created_empty = "kitty --class hermes-sp -e hermes --tui",
})
