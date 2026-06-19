hl.config({
	general = {
		gaps_in = 0,
		gaps_out = 0,
		gaps_workspaces = 0,

		border_size = 1,

		col = {
			active_border = "rgba(ffffffaa)",
			inactive_border = "rgba(00000000)",
		},

		resize_on_border = true,
		no_focus_fallback = true,
		allow_tearing = true,

		snap = {
			enabled = true,
			respect_gaps = true,
		},
	},

	decoration = {
		rounding = 0,
		active_opacity = 1.0,
		inactive_opacity = 1.0,

		blur = {
			enabled = false,
		},

		shadow = {
			enabled = false,
		},
	},

	animations = {
		enabled = false,
	},

	misc = {
		disable_hyprland_logo = true,
		disable_splash_rendering = true,
		mouse_move_enables_dpms = true,
		key_press_enables_dpms = true,
	},

	input = {
		follow_mouse = 1,
		sensitivity = 0,

		touchpad = {
			natural_scroll = true,
		},
	},
})
