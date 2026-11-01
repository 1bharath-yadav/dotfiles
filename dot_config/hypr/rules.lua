-- Window opacity and app-specific placement/workspace rules.
-- Remove Omarchy's translucent default for every app, not only OpenCode.
o.window(".*", { tag = "-default-opacity", opacity = "1.0 1.0" })

o.window("^([Oo]bsidian)$", { float = true, size = { "(monitor_w*0.82)", "(monitor_h*0.82)" }, center = true, workspace = "special:obsidian" })
o.window("^(yazi-sp)$", { float = true, size = { "(monitor_w*0.78)", "(monitor_h*0.78)" }, center = true, workspace = "special:yazi" })
o.window("^(kitty-sp)$", { float = true, size = { "(monitor_w*0.75)", "(monitor_h*0.75)" }, center = true, workspace = "special:kitty" })
o.window("^(quicknote)$", { float = true, size = { "(monitor_w*0.75)", "(monitor_h*0.75)" }, center = true, workspace = "special:quicknote" })
o.window("^(hermes-sp)$", { float = true, size = { "(monitor_w*0.70)", "(monitor_h*0.80)" }, center = true, workspace = "special:hermes" })
o.window("^([Cc]hatgpt|chrome-chatgpt\\.com.*|webapp-chatgpt)$", { float = true, size = { "(monitor_w*0.68)", "(monitor_h*0.82)" }, center = true, workspace = "special:chatgpt" })
o.window("^([Ww]hatsapp|chrome-web\\.whatsapp\\.com.*|webapp-whatsapp)$", { float = true, size = { "(monitor_w*0.72)", "(monitor_h*0.82)" }, center = true, workspace = "special:whatsapp" })
o.window("^(xoy-cdp)$", { workspace = "special:xoy-cdp silent", no_focus = true, no_follow_mouse = true })
o.window("^([Cc]hrome-calendar\\.google\\.com.*|webapp-calendar.*)$", { float = true, size = { "(monitor_w*0.82)", "(monitor_h*0.82)" }, center = true, workspace = "special:calendar" })
o.window("^([Cc]hrome-keep\\.google\\.com.*|webapp-keep.*)$", { float = true, size = { "(monitor_w*0.75)", "(monitor_h*0.80)" }, center = true, workspace = "special:keep" })
o.window("^([Cc]hrome-tasks\\.google\\.com.*|webapp-tasks.*)$", { float = true, size = { "(monitor_w*0.42)", "(monitor_h*0.78)" }, center = true, workspace = "special:tasks" })
o.window("^([Cc]hrome-mail\\.google\\.com.*|webapp-gmail.*)$", { float = true, size = { "(monitor_w*0.82)", "(monitor_h*0.82)" }, center = true, workspace = "special:gmail" })
o.window({ class = "^(google-chrome)$", title = "^(Untitled - Google Chrome)$" }, { float = true, size = { 520, 680 }, center = true })
o.window("^(com\\.gabm\\.satty|satty)$", { float = true, size = { "(monitor_w*0.80)", "(monitor_h*0.80)" }, center = true })
-- Hyprland 0.50+ normalizer for camelCase window rule properties/effects
if not _G.__hypr_window_rule_normalized then
  _G.__hypr_window_rule_normalized = true
  local _orig_hl_window_rule = hl.window_rule
  function hl.window_rule(rules)
    if type(rules) == "table" then
      if type(rules.match) == "table" then
        if rules.match.initialTitle then
          rules.match.initial_title = rules.match.initial_title or rules.match.initialTitle
          rules.match.initialTitle = nil
        end
        if rules.match.initialClass then
          rules.match.initial_class = rules.match.initial_class or rules.match.initialClass
          rules.match.initialClass = nil
        end
      end
      if rules.renderunfocused ~= nil then
        if rules.render_unfocused == nil then
          rules.render_unfocused = rules.renderunfocused
        end
        rules.renderunfocused = nil
      end
    end
    return _orig_hl_window_rule(rules)
  end
end

o.window({ class = "^(electron|glint-overlay|glint)$", title = "^(glint-overlay)$" }, { float = true, pin = true, no_anim = true, no_blur = true, no_shadow = true, no_initial_focus = true, border_size = 0, opacity = "1.0 override 1.0 override", size = { "(monitor_w)", "(monitor_h)" }, move = { "0", "0" }, render_unfocused = true, suppress_event = "activate activatefocus fullscreen maximize" })
o.window({ initialTitle = "^(glint-overlay)$" }, { float = true, pin = true, no_anim = true, no_blur = true, no_shadow = true, no_initial_focus = true, border_size = 0, opacity = "1.0 override 1.0 override", size = { "(monitor_w)", "(monitor_h)" }, move = { "0", "0" }, render_unfocused = true, suppress_event = "activate activatefocus fullscreen maximize" })
o.window("^(glint-overlay)$", { float = true, pin = true, no_anim = true, no_blur = true, no_shadow = true, no_initial_focus = true, border_size = 0, opacity = "1.0 override 1.0 override", size = { "(monitor_w)", "(monitor_h)" }, move = { "0", "0" }, render_unfocused = true, suppress_event = "activate activatefocus fullscreen maximize" })

o.window({ class = "^(electron|glint-corner|glint)$", title = "^(glint-corner.*|glint-window.*)$" }, { float = true, pin = true, no_anim = true, no_initial_focus = true, border_size = 0, size = { 560, 480 }, move = { "(monitor_w - 580)", "42" } })
o.window({ initialTitle = "^(glint-corner.*|glint-window.*)$" }, { float = true, pin = true, no_anim = true, no_initial_focus = true, border_size = 0, size = { 560, 480 }, move = { "(monitor_w - 580)", "42" } })

-- Create each custom special workspace with its first window on demand.
-- Commands use Omarchy's default terminal path (xdg-terminal-exec) for TUIs.
hl.workspace_rule({ workspace = "special:yazi", on_created_empty = "uwsm-app -- xdg-terminal-exec --app-id=yazi-sp -e yazi" })
hl.workspace_rule({ workspace = "special:kitty", on_created_empty = "uwsm-app -- xdg-terminal-exec --app-id=kitty-sp" })
hl.workspace_rule({ workspace = "special:quicknote", on_created_empty = "uwsm-app -- xdg-terminal-exec --app-id=quicknote -e yazi /home/archer/til/" })
hl.workspace_rule({ workspace = "special:hermes", on_created_empty = "uwsm-app -- xdg-terminal-exec --app-id=hermes-sp -e hermes --tui" })
hl.workspace_rule({ workspace = "special:chatgpt", on_created_empty = "omarchy-launch-webapp https://chatgpt.com" })
hl.workspace_rule({ workspace = "special:whatsapp", on_created_empty = "omarchy-launch-webapp https://web.whatsapp.com/" })
hl.workspace_rule({ workspace = "special:calendar", on_created_empty = "omarchy-launch-webapp https://calendar.google.com" })
hl.workspace_rule({ workspace = "special:keep", on_created_empty = "omarchy-launch-webapp https://keep.google.com" })
hl.workspace_rule({ workspace = "special:tasks", on_created_empty = "omarchy-launch-webapp https://tasks.google.com" })
hl.workspace_rule({ workspace = "special:gmail", on_created_empty = "omarchy-launch-webapp https://mail.google.com" })
hl.workspace_rule({ workspace = "special:xoy-cdp", on_created_empty = "true" })
