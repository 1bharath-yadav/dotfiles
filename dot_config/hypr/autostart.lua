-- Session environment propagation for user services and applications.
hl.on("hyprland.start", function()
  hl.exec_cmd("systemctl --user import-environment --all")
  hl.exec_cmd("dbus-update-activation-environment --systemd --all")
end)
