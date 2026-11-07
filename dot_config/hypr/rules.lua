-- Window rules and special-workspace launchers.
-- Native Hyprland Lua API; property names use snake_case.

-- SUPER + S: general-purpose capture scratchpad.
-- Applies to every window assigned to special:scratchpad.
hl.window_rule({
    match = { workspace = "special:scratchpad" },
    float = true,
    size = { "(monitor_w*0.80)", "(monitor_h*0.80)" },
    center = true,
    rounding = 18,
    border_size = 0,
    opacity = "0.70 override 0.70 override",
})

-- Foot terminal launched while the general scratchpad is active.
hl.window_rule({
    match = { class = "^foot$", workspace = "special:scratchpad" },
    no_blur = false,
    opacity = "0.70 override 0.70 override",
})

-- SUPER + Z: dedicated Kitty/terminal scratchpad.
-- Kitty is launched with app-id kitty-sp; its actual initial class is foot.
hl.window_rule({
    match = { class = "^kitty-sp$" },
    float = true,
    size = { "(monitor_w*0.75)", "(monitor_h*0.75)" },
    center = true,
    workspace = "special:kitty",
    rounding = 14,
    border_size = 0,
    opacity = "1.0 override 1.0 override",
})

-- Remove Omarchy's default-opacity tag and restore normal opacity elsewhere.
hl.window_rule({
    match = { class = ".*" },
    tag = "-default-opacity",
    opacity = "1.0 1.0",
})

-- Obsidian special workspace.
hl.window_rule({
    match = { class = "^([Oo]bsidian)$" },
    float = true,
    size = { "(monitor_w*0.82)", "(monitor_h*0.82)" },
    center = true,
    workspace = "special:obsidian",
})

-- Yazi, quicknote, and Hermes special workspaces.
hl.window_rule({
    match = { class = "^yazi-sp$" },
    float = true,
    size = { "(monitor_w*0.78)", "(monitor_h*0.78)" },
    center = true,
    workspace = "special:yazi",
})
hl.window_rule({
    match = { class = "^quicknote$" },
    float = true,
    size = { "(monitor_w*0.75)", "(monitor_h*0.75)" },
    center = true,
    workspace = "special:quicknote",
})
hl.window_rule({
    match = { class = "^hermes-sp$" },
    float = true,
    size = { "(monitor_w*0.70)", "(monitor_h*0.80)" },
    center = true,
    workspace = "special:hermes",
})

-- ChatGPT and WhatsApp webapps.
hl.window_rule({
    match = { class = "^([Cc]hatgpt|chrome-chatgpt\\.com.*|webapp-chatgpt)$" },
    float = true,
    size = { "(monitor_w*0.68)", "(monitor_h*0.82)" },
    center = true,
    workspace = "special:chatgpt",
})
hl.window_rule({
    match = { class = "^([Ww]hatsapp|chrome-web\\.whatsapp\\.com.*|webapp-whatsapp)$" },
    float = true,
    size = { "(monitor_w*0.72)", "(monitor_h*0.82)" },
    center = true,
    workspace = "special:whatsapp",
})

-- Google Calendar, Keep, Tasks, and Gmail.
hl.window_rule({
    match = { class = "^([Cc]hrome-calendar\\.google\\.com.*|webapp-calendar.*)$" },
    float = true,
    size = { "(monitor_w*0.82)", "(monitor_h*0.82)" },
    center = true,
    workspace = "special:calendar",
})
hl.window_rule({
    match = { class = "^([Cc]hrome-keep\\.google\\.com.*|webapp-keep.*)$" },
    float = true,
    size = { "(monitor_w*0.75)", "(monitor_h*0.80)" },
    center = true,
    workspace = "special:keep",
})
hl.window_rule({
    match = { class = "^([Cc]hrome-tasks\\.google\\.com.*|webapp-tasks.*)$" },
    float = true,
    size = { "(monitor_w*0.42)", "(monitor_h*0.78)" },
    center = true,
    workspace = "special:tasks",
})
hl.window_rule({
    match = { class = "^([Cc]hrome-mail\\.google\\.com.*|webapp-gmail.*)$" },
    float = true,
    size = { "(monitor_w*0.82)", "(monitor_h*0.82)" },
    center = true,
    workspace = "special:gmail",
})

-- Small standalone Chrome window.
hl.window_rule({
    match = {
        class = "^google-chrome$",
        title = "^Untitled - Google Chrome$",
    },
    float = true,
    size = { 520, 680 },
    center = true,
})

-- Satty annotation window.
hl.window_rule({
    match = { class = "^(com\\.gabm\\.satty|satty)$" },
    float = true,
    size = { "(monitor_w*0.80)", "(monitor_h*0.80)" },
    center = true,
})

-- Glint full-screen overlay windows.
hl.window_rule({
    match = {
        class = "^(electron|glint-overlay|glint)$",
        title = "^glint-overlay$",
    },
    float = true,
    pin = true,
    no_anim = true,
    no_blur = true,
    no_shadow = true,
    no_initial_focus = true,
    border_size = 0,
    opacity = "1.0 override 1.0 override",
    size = { "(monitor_w)", "(monitor_h)" },
    move = { "0", "0" },
    render_unfocused = true,
    suppress_event = "activate activatefocus fullscreen maximize",
})
hl.window_rule({
    match = { initial_title = "^glint-overlay$" },
    float = true,
    pin = true,
    no_anim = true,
    no_blur = true,
    no_shadow = true,
    no_initial_focus = true,
    border_size = 0,
    opacity = "1.0 override 1.0 override",
    size = { "(monitor_w)", "(monitor_h)" },
    move = { "0", "0" },
    render_unfocused = true,
    suppress_event = "activate activatefocus fullscreen maximize",
})

-- Glint corner/window overlays.
hl.window_rule({
    match = {
        class = "^(electron|glint-corner|glint)$",
        title = "^(glint-corner.*|glint-window.*)$",
    },
    float = true,
    pin = true,
    no_anim = true,
    no_initial_focus = true,
    border_size = 0,
    size = { 560, 480 },
    move = { "(monitor_w - 580)", "42" },
})
hl.window_rule({
    match = { initial_title = "^(glint-corner.*|glint-window.*)$" },
    float = true,
    pin = true,
    no_anim = true,
    no_initial_focus = true,
    border_size = 0,
    size = { 560, 480 },
    move = { "(monitor_w - 580)", "42" },
})

-- Create each custom special workspace with its first window on demand.
-- Commands use Omarchy's default terminal path (xdg-terminal-exec) for TUIs.
hl.workspace_rule({
    workspace = "special:yazi",
    on_created_empty = "uwsm-app -- xdg-terminal-exec --app-id=yazi-sp -e yazi",
})
hl.workspace_rule({
    workspace = "special:kitty",
    on_created_empty = "uwsm-app -- xdg-terminal-exec --app-id=kitty-sp",
})
hl.workspace_rule({
    workspace = "special:quicknote",
    on_created_empty = "uwsm-app -- xdg-terminal-exec --app-id=quicknote -e yazi /home/archer/til/",
})
hl.workspace_rule({
    workspace = "special:hermes",
    on_created_empty = "uwsm-app -- xdg-terminal-exec --app-id=hermes-sp -e hermes --tui",
})
hl.workspace_rule({ workspace = "special:chatgpt", on_created_empty = "omarchy-launch-webapp https://chatgpt.com" })
hl.workspace_rule({ workspace = "special:whatsapp", on_created_empty = "omarchy-launch-webapp https://web.whatsapp.com/" })
hl.workspace_rule({ workspace = "special:calendar", on_created_empty = "omarchy-launch-webapp https://calendar.google.com" })
hl.workspace_rule({ workspace = "special:keep", on_created_empty = "omarchy-launch-webapp https://keep.google.com" })
hl.workspace_rule({ workspace = "special:tasks", on_created_empty = "omarchy-launch-webapp https://tasks.google.com" })
hl.workspace_rule({ workspace = "special:gmail", on_created_empty = "omarchy-launch-webapp https://mail.google.com" })
hl.workspace_rule({ workspace = "special:xoy-cdp", on_created_empty = "true" })
