-- Appearance, touchpad gestures, and animation curves.
hl.gesture({ fingers = 3, direction = "swipe", action = "move" })
hl.gesture({ fingers = 3, direction = "pinch", action = "fullscreen" })
hl.gesture({ fingers = 4, direction = "horizontal", action = "workspace" })
hl.gesture({
    fingers = 4,
    direction = "up",
    action = function()
        hl.dispatch(hl.dsp.global("quickshell:overviewWorkspacesToggle"))
    end,
})
hl.gesture({
    fingers = 4,
    direction = "down",
    action = function()
        hl.dispatch(hl.dsp.global("quickshell:overviewWorkspacesToggle"))
    end,
})

hl.config({
    general = {
        gaps_in = 4,
        gaps_out = 5,
        gaps_workspaces = 50,
        border_size = 1,
        col = {
            active_border = "rgba(44464f77)",
            inactive_border = "rgba(1a1b2033)",
        },
        resize_on_border = true,
        no_focus_fallback = true,
        allow_tearing = true,
        snap = {
            enabled = true,
            window_gap = 4,
            monitor_gap = 5,
            respect_gaps = true,
        },
    },
    decoration = {
        rounding_power = 2.5,
        rounding = 18,
        blur = {
            enabled = false,
            popups = false,
            input_methods = false,
            special = false,
        },
        shadow = {
            enabled = true,
            range = 20,
            offset = { 0, 2 },
            render_power = 10,
            color = "rgba(00000020)",
        },
        dim_inactive = true,
        dim_strength = 0.05,
        dim_special = 0.2,
    },
    animations = { enabled = false },
    dwindle = {
        preserve_split = true,
        smart_split = false,
        smart_resizing = false,
    },
    misc = {
        background_color = "rgba(121318FF)",
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
        vrr = 0,
        mouse_move_enables_dpms = true,
        key_press_enables_dpms = true,
        animate_manual_resizes = false,
        animate_mouse_windowdragging = false,
        enable_swallow = false,
        swallow_regex = "(foot|kitty|allacritty|Alacritty)",
        on_focus_under_fullscreen = 2,
        allow_session_lock_restore = true,
        session_lock_xray = true,
        initial_workspace_tracking = false,
        focus_on_activate = true,
    },
    binds = {
        scroll_event_delay = 0,
        hide_special_on_workspace_change = true,
    },
    cursor = {
        zoom_factor = 1,
        zoom_rigid = false,
        zoom_disable_aa = true,
        hotspot_padding = 1,
    },
    xwayland = { force_zero_scaling = true },
})

-- Make the global active border consistent with the theme-neutral palette.
hl.window_rule({
    match = { pin = 1 },
    border_color = "rgba(afc6ffAA) rgba(afc6ff77)",
})

local curves = {
    expressiveFastSpatial = { 0.42, 1.67, 0.21, 0.90 },
    expressiveSlowSpatial = { 0.39, 1.29, 0.35, 0.98 },
    expressiveDefaultSpatial = { 0.38, 1.21, 0.22, 1.00 },
    emphasizedDecel = { 0.05, 0.70, 0.10, 1.00 },
    emphasizedAccel = { 0.30, 0.00, 0.80, 0.15 },
    standardDecel = { 0.00, 0.00, 0.00, 1.00 },
    menu_decel = { 0.10, 1.00, 0.00, 1.00 },
    menu_accel = { 0.52, 0.03, 0.72, 0.08 },
    stall = { 1.00, -0.10, 0.70, 0.85 },
}

for name, p in pairs(curves) do
    hl.curve(name, {
        type = "bezier",
        points = { { p[1], p[2] }, { p[3], p[4] } },
    })
end

local animations = {
    { "windowsIn", true, 3, "emphasizedDecel", "popin 80%" },
    { "fadeIn", true, 3, "emphasizedDecel" },
    { "windowsOut", true, 2, "emphasizedDecel", "popin 90%" },
    { "fadeOut", true, 2, "emphasizedDecel" },
    { "windowsMove", true, 3, "emphasizedDecel", "slide" },
    { "border", true, 10, "emphasizedDecel" },
    { "layersIn", true, 2.7, "emphasizedDecel", "popin 93%" },
    { "layersOut", true, 2.4, "menu_accel", "popin 94%" },
    { "fadeLayersIn", true, 0.5, "menu_decel" },
    { "fadeLayersOut", true, 2.7, "stall" },
    { "workspaces", true, 7, "menu_decel", "slide" },
    { "specialWorkspaceIn", true, 2.8, "emphasizedDecel", "slidevert" },
    { "specialWorkspaceOut", true, 1.2, "emphasizedAccel", "slidevert" },
    { "zoomFactor", true, 3, "standardDecel" },
}

for _, a in ipairs(animations) do
    local rule = {
        leaf = a[1],
        enabled = a[2],
        speed = a[3],
        bezier = a[4],
    }
    if a[5] then rule.style = a[5] end
    hl.animation(rule)
end
