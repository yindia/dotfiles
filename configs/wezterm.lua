local wezterm = require 'wezterm'

local config = {}

if wezterm.config_builder then
  config = wezterm.config_builder()
end

config.initial_cols = 120
config.initial_rows = 28
config.automatically_reload_config = true
config.audible_bell = "Disabled"
config.visual_bell = {
  fade_in_function = "EaseIn",
  fade_in_duration_ms = 80,
  fade_out_function = "EaseOut",
  fade_out_duration_ms = 120,
}

config.adjust_window_size_when_changing_font_size = false
config.harfbuzz_features = { "calt=1", "clig=1", "liga=1" }
config.enable_tab_bar = true
config.window_background_opacity = 1.0
config.use_fancy_tab_bar = false
config.hide_tab_bar_if_only_one_tab = false
config.tab_max_width = 28
config.window_decorations = "RESIZE"
config.window_padding = {
  left = 10,
  right = 10,
  top = 8,
  bottom = 8,
}
config.default_cwd = wezterm.home_dir
config.default_workspace = "~"

config.scrollback_lines = 100000

config.color_scheme = "Atelierdune (light) (terminal.sexy)"
config.colors = {
  foreground = "#26231f",
  background = "#fefbec",
  selection_fg = "#17140f",
  selection_bg = "#d0b183",
  cursor_bg = "#8f6f4f",
  cursor_fg = "#fefbec",
  cursor_border = "#8f6f4f",
  split = "#d6c7aa",
  scrollbar_thumb = "#c5b18f",

  tab_bar = {
    background = "#e9ddc5",
    active_tab = {
      bg_color = "#fefbec",
      fg_color = "#17140f",
      intensity = "Bold",
    },
    inactive_tab = {
      bg_color = "#ded1b8",
      fg_color = "#5f5648",
    },
    inactive_tab_hover = {
      bg_color = "#d0b183",
      fg_color = "#17140f",
    },
    new_tab = {
      bg_color = "#e9ddc5",
      fg_color = "#5f5648",
    },
    new_tab_hover = {
      bg_color = "#d0b183",
      fg_color = "#17140f",
    },
  },
}

config.window_frame = {
  font_size = 14.0,
  active_titlebar_bg = "#e9ddc5",
  inactive_titlebar_bg = "#ded1b8",
  active_titlebar_fg = "#17140f",
  inactive_titlebar_fg = "#5f5648",
  button_fg = "#5f5648",
  button_bg = "#e9ddc5",
  button_hover_fg = "#17140f",
  button_hover_bg = "#d0b183",
}

config.inactive_pane_hsb = {
  saturation = 0.85,
  brightness = 0.92,
}

local function basename(path)
  return path:gsub("\\", "/"):match("([^/]+)$") or path
end

local function add_status_segment(cells, text, color)
  if text == nil or text == "" then
    return
  end

  if #cells > 0 then
    table.insert(cells, { Foreground = { Color = "#a07f5f" } })
    table.insert(cells, { Text = " | " })
  end

  table.insert(cells, { Foreground = { Color = color or "#5f5648" } })
  table.insert(cells, { Text = text })
end

wezterm.on("update-right-status", function(window, pane)
  local workspace = window:active_workspace()
  local leader = window:leader_is_active() and "LEADER" or ""
  local cwd = pane:get_current_working_dir()
  local cwd_label = nil

  if cwd then
    local path = cwd.file_path or tostring(cwd)
    cwd_label = path:gsub("^" .. wezterm.home_dir, "~")
  end

  local process = pane:get_foreground_process_name()
  if process then
    process = basename(process)
  end

  local domain = pane:get_domain_name()
  local battery = nil
  local ok, battery_info = pcall(wezterm.battery_info)
  if ok and battery_info and battery_info[1] then
    battery = string.format("%.0f%%", battery_info[1].state_of_charge * 100)
  end

  local cells = {}
  add_status_segment(cells, leader, "#8f6f4f")
  add_status_segment(cells, "ws:" .. workspace)
  add_status_segment(cells, cwd_label)
  add_status_segment(cells, process)
  add_status_segment(cells, domain)
  add_status_segment(cells, battery)
  add_status_segment(cells, wezterm.strftime("%a %b %d %H:%M"))
  table.insert(cells, { Text = " " })

  window:set_right_status(wezterm.format(cells))
end)

config.leader = {
  key = "a",
  mods = "CTRL",
  timeout_milliseconds = 1000,
}

config.keys = {
  { key = "Enter", mods = "SHIFT", action = wezterm.action.SendString "\x1b\r" },
  { key = "t", mods = "SUPER", action = wezterm.action.SpawnTab "CurrentPaneDomain" },
  { key = "w", mods = "SUPER", action = wezterm.action.CloseCurrentTab { confirm = true } },
  { key = "d", mods = "SUPER", action = wezterm.action.SplitHorizontal { domain = "CurrentPaneDomain" } },
  { key = "d", mods = "SUPER|SHIFT", action = wezterm.action.SplitVertical { domain = "CurrentPaneDomain" } },
  { key = "Enter", mods = "SUPER|SHIFT", action = wezterm.action.TogglePaneZoomState },
  { key = "w", mods = "SUPER|SHIFT", action = wezterm.action.CloseCurrentPane { confirm = true } },
  { key = "x", mods = "SUPER|SHIFT", action = wezterm.action.ActivateCopyMode },
  { key = "p", mods = "SUPER|SHIFT", action = wezterm.action.ActivateCommandPalette },
  { key = "l", mods = "SUPER|SHIFT", action = wezterm.action.ShowLauncher },
  { key = "s", mods = "SUPER|SHIFT", action = wezterm.action.ShowLauncherArgs { flags = "FUZZY|WORKSPACES" } },
  { key = "[", mods = "SUPER|ALT", action = wezterm.action.ActivateTabRelative(-1) },
  { key = "]", mods = "SUPER|ALT", action = wezterm.action.ActivateTabRelative(1) },
  { key = "[", mods = "SUPER|SHIFT", action = wezterm.action.MoveTabRelative(-1) },
  { key = "]", mods = "SUPER|SHIFT", action = wezterm.action.MoveTabRelative(1) },
  { key = "k", mods = "SUPER|SHIFT", action = wezterm.action.ClearScrollback "ScrollbackAndViewport" },
  { key = "f", mods = "SUPER|SHIFT", action = wezterm.action.Search "CurrentSelectionOrEmptyString" },
  { key = "u", mods = "SUPER|SHIFT", action = wezterm.action.QuickSelect },
  { key = "i", mods = "SUPER|SHIFT", action = wezterm.action.ShowDebugOverlay },
  {
    key = "r",
    mods = "SUPER|SHIFT",
    action = wezterm.action.PromptInputLine {
      description = "Rename tab",
      action = wezterm.action_callback(function(window, pane, line)
        if line then
          window:active_tab():set_title(line)
        end
      end),
    },
  },

  { key = "LeftArrow", mods = "SUPER|ALT", action = wezterm.action.ActivatePaneDirection("Left") },
  { key = "RightArrow", mods = "SUPER|ALT", action = wezterm.action.ActivatePaneDirection("Right") },
  { key = "UpArrow", mods = "SUPER|ALT", action = wezterm.action.ActivatePaneDirection("Up") },
  { key = "DownArrow", mods = "SUPER|ALT", action = wezterm.action.ActivatePaneDirection("Down") },

  { key = "LeftArrow", mods = "SUPER|SHIFT", action = wezterm.action.AdjustPaneSize { "Left", 5 } },
  { key = "RightArrow", mods = "SUPER|SHIFT", action = wezterm.action.AdjustPaneSize { "Right", 5 } },
  { key = "UpArrow", mods = "SUPER|SHIFT", action = wezterm.action.AdjustPaneSize { "Up", 3 } },
  { key = "DownArrow", mods = "SUPER|SHIFT", action = wezterm.action.AdjustPaneSize { "Down", 3 } },
  {
    key = "n",
    mods = "SUPER|SHIFT",
    action = wezterm.action.PromptInputLine {
      description = "Enter workspace name",
      action = wezterm.action_callback(function(window, pane, line)
        if line then
          window:perform_action(
            wezterm.action.SwitchToWorkspace {
              name = line,
            },
            pane
          )
        end
      end),
    },
  },

  { key = "|", mods = "LEADER", action = wezterm.action.SplitHorizontal { domain = "CurrentPaneDomain" } },
  { key = "-", mods = "LEADER", action = wezterm.action.SplitVertical { domain = "CurrentPaneDomain" } },
  { key = "x", mods = "LEADER", action = wezterm.action.CloseCurrentPane { confirm = true } },

  { key = "LeftArrow", mods = "LEADER", action = wezterm.action.ActivatePaneDirection("Left") },
  { key = "RightArrow", mods = "LEADER", action = wezterm.action.ActivatePaneDirection("Right") },
  { key = "UpArrow", mods = "LEADER", action = wezterm.action.ActivatePaneDirection("Up") },
  { key = "DownArrow", mods = "LEADER", action = wezterm.action.ActivatePaneDirection("Down") },

  { key = "h", mods = "LEADER", action = wezterm.action.AdjustPaneSize { "Left", 5 } },
  { key = "l", mods = "LEADER", action = wezterm.action.AdjustPaneSize { "Right", 5 } },
  { key = "k", mods = "LEADER", action = wezterm.action.AdjustPaneSize { "Up", 2 } },
  { key = "j", mods = "LEADER", action = wezterm.action.AdjustPaneSize { "Down", 4 } },
  { key = "s", mods = "LEADER", action = wezterm.action.ActivateTabRelative(1) },
  { key = "w", mods = "LEADER", action = wezterm.action.CloseCurrentTab { confirm = true } },
  { key = "p", mods = "LEADER", action = wezterm.action.ShowLauncher },
  { key = "/", mods = "LEADER", action = wezterm.action.Search("CurrentSelectionOrEmptyString") },
  { key = "t", mods = "LEADER", action = wezterm.action.ShowTabNavigator },
  { key = "z", mods = "LEADER", action = wezterm.action.TogglePaneZoomState },
  {
    key = "n",
    mods = "LEADER",
    action = wezterm.action.PromptInputLine {
      description = "Enter workspace name",
      action = wezterm.action_callback(function(window, pane, line)
        if line then
          window:perform_action(
            wezterm.action.SwitchToWorkspace {
              name = line,
            },
            pane
          )
        end
      end),
    },
  },
  { key = "o", mods = "LEADER", action = wezterm.action.SwitchToWorkspace { name = "default" } },
}

return config
