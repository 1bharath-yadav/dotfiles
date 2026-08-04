-- custom/execs.lua
-- Session environment propagation so launcher-started apps see Hyprland env

hl.on("hyprland.start", function()
	hl.exec_cmd("systemctl --user import-environment --all")
	hl.exec_cmd("dbus-update-activation-environment --systemd --all")
end)
