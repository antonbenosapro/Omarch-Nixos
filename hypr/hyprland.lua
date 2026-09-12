-- Learn how to configure Hyprland: https://wiki.hypr.land/Configuring/Start/

-- Omarchy's bootstrap keeps path setup out of this user config.
dofile((os.getenv("OMARCHY_PATH") or "/usr/share/omarchy") .. "/default/hypr/bootstrap.lua")

-- Disable all Omarchy default bindings. Add your own in hypr/bindings.lua.
-- omarchy_default_bindings = false
--
-- Or disable only bindings for Omarchy's preinstalled apps/web apps while
-- keeping core window-manager bindings:
-- omarchy_preinstalled_bindings = false

-- Load Omarchy defaults.
require("default.hypr.omarchy")

-- Put your personal overrides in these files. They're loaded after Omarchy's
-- defaults so package updates can improve the defaults without rewriting your
-- ~/.config/hypr files.
require("hypr.monitors")
require("hypr.input")
require("hypr.bindings")
require("hypr.looknfeel")
require("hypr.autostart")

-- Toggle config flags dynamically.
require("default.hypr.toggles")

-- Add any other personal Hyprland configuration below.
-- o.window("qemu", { workspace = "5" })

-- Interactive Brokers TWS optimizations: full opacity, no mouse hover steal, and float dialogs/popups
o.window("^(.*(install4j|jclient|ib-tws).*)$", { tag = "-default-opacity", opacity = "1.0 1.0", no_follow_mouse = true })
o.window({ class = "^(.*(install4j|jclient|ib-tws).*)$", title = "^(?!.*Trader Workstation).*$" }, { float = true })

-- Terminal window rules: visible border to distinguish terminal windows
o.window({ tag = "terminal" }, { border_size = 2, border_color = "rgba(89b4faee) rgba(45475aaa)" })

