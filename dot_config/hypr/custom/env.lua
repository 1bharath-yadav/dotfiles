-- custom/env.lua — archer's additions on top of hyprland/env.lua

-- Nix visibility for launcher/systemd-started apps
hl.env(
	"XDG_DATA_DIRS",
	"$HOME/.local/share/flatpak/exports/share:/var/lib/flatpak/exports/share:/usr/local/share:/usr/share"
)

-- Editor
hl.env("EDITOR", "nvim")

-- Input method (fcitx5) example
-- hl.env("QT_IM_MODULE", "fcitx")
-- hl.env("XMODIFIERS", "@im=fcitx")
