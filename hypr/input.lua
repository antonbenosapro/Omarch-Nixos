-- Keep only your personal input overrides here. Uncommented settings below
-- replace Omarchy's defaults.

-- Keyboard layout and options.
-- See https://wiki.hypr.land/Configuring/Basics/Variables/#input
hl.config({
  input = {
    touchpad = {
      -- Use natural (inverse) scrolling.
      natural_scroll = true,

      -- Use two-finger clicks for right-click instead of lower-right corner.
      clickfinger_behavior = true,

      -- Control the speed of your scrolling.
      scroll_factor = 0.4,

      -- Enable the touchpad while typing.
      disable_while_typing = false,

      -- Enable tap to click.
      tap_to_click = true,
    },
  },
})

-- App-specific touchpad scroll speeds.
-- o.window("(Alacritty|kitty|foot)", { scroll_touchpad = 1.5 })
-- o.window("com.mitchellh.ghostty", { scroll_touchpad = 0.2 })

-- Touchpad Gestures
-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Gestures/

-- 1:1 Workspace switching
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

-- Window state controls (Fullscreen & Floating)
hl.gesture({ fingers = 3, direction = "up", action = "fullscreen" })
hl.gesture({ fingers = 3, direction = "down", action = "float" })

-- 4-Finger Navigation & Menus
hl.gesture({ fingers = 4, direction = "up", action = function() hl.exec_cmd("omarchy-menu toggle") end })
hl.gesture({ fingers = 4, direction = "down", action = "special", workspace_name = "scratchpad" })

-- Live pinch-to-zoom (cursor magnifier)
hl.gesture({ fingers = 2, direction = "pinch", action = "cursorZoom", zoom_level = 1, mode = "live" })

-- Modifier + Gesture Shortcuts
hl.gesture({ fingers = 3, direction = "down", mods = "ALT", action = "close" })
hl.gesture({ fingers = 3, direction = "up", mods = "SUPER", action = "fullscreen", mode = "maximize" })
