-- custom/execs.lua
-- Session environment propagation for user services/apps.

hl.on("hyprland.start", function()
	hl.exec_cmd("systemctl --user import-environment --all")
	hl.exec_cmd("dbus-update-activation-environment --systemd --all")
end)
