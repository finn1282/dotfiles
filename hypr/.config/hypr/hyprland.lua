-- ~/.config/hypr/hyprland.lua  (Hyprland 0.56, Lua config)
-- Look: Symphony layout + Mac-style motion, colors from the wallpaper (colors.lua)

local c = require("./colors.lua")   -- generated palette (make-palette)

-- ===== Monitor (T490 internal panel) =====
hl.monitor({ output = "eDP-1", mode = "1920x1080", position = "0x0", scale = "1.2" })

-- ===== Environment =====
hl.env("XCURSOR_THEME", "Adwaita")
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("MOZ_ENABLE_WAYLAND", "1")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("GDK_BACKEND", "wayland,x11")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")
hl.env("BROWSER", "zen-browser")
hl.env("_JAVA_AWT_WM_NONREPARENTING", "1")   -- Burp Suite, Ghidra
-- fcitx5 (GTK_IM_MODULE left unset on purpose: GTK uses the Wayland protocol)
hl.env("QT_IM_MODULE", "fcitx")
hl.env("XMODIFIERS", "@im=fcitx")
hl.env("SDL_IM_MODULE", "fcitx")
hl.env("INPUT_METHOD", "fcitx")

-- ===== Look & feel =====
hl.config({
    general = {
        gaps_in = 5,
        gaps_out = 12,
        border_size = 2,
        col = {
            active_border   = c.primary,
            inactive_border = c.outline_variant,
        },
        layout = "dwindle",
        resize_on_border = true,
    },
    decoration = {
        rounding = 12,
        rounding_power = 4.0,          -- squircle corners, like macOS
        active_opacity = 1.0,
        inactive_opacity = 1.0,
        blur = {
            enabled = true,
            size = 7,
            passes = 3,
            new_optimizations = true,
            ignore_opacity = true,
            noise = 0.0117,
            contrast = 0.8916,
            brightness = 0.8172,
            vibrancy = 0.17,
            popups = true,
        },
        shadow = {
            enabled = true,
            range = 30,
            render_power = 3,
            offset = { 0, 4 },
            color = "rgba(00000055)",
            color_inactive = "rgba(00000033)",
        },
    },
    animations = { enabled = true },
    dwindle = { preserve_split = true },
    master = { new_status = "master" },
    misc = {
        force_default_wallpaper = 0,
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
        background_color = c.surface,
        font_family = "Inter",
        focus_on_activate = true,
    },
})

-- ===== Animations (Mac-style easing; speed = tenths of a second) =====
hl.curve("mac",    { type = "bezier", points = { {0.25, 0.1}, {0.25, 1.0} } })
hl.curve("macOut", { type = "bezier", points = { {0.16, 1.0}, {0.3, 1.0} } })

hl.animation({ leaf = "windowsIn",  enabled = true, speed = 4, bezier = "macOut", style = "popin 90%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 3, bezier = "mac",    style = "popin 90%" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 4, bezier = "macOut" })
hl.animation({ leaf = "layers",     enabled = true, speed = 3, bezier = "macOut", style = "fade" })
hl.animation({ leaf = "fade",       enabled = true, speed = 3, bezier = "mac" })
hl.animation({ leaf = "border",     enabled = true, speed = 5, bezier = "mac" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 5, bezier = "macOut", style = "slide" })

-- ===== Input (T490 touchpad + TrackPoint) =====
hl.config({
    input = {
        kb_layout = "us",
        follow_mouse = 1,
        sensitivity = 0.2,
        accel_profile = "flat",
        touchpad = {
            natural_scroll = true,
            tap_to_click = true,
            disable_while_typing = true,
            clickfinger_behavior = true,
        },
    },
    gestures = {
        workspace_swipe_distance = 400,
        workspace_swipe_min_speed_to_force = 15,
        workspace_swipe_cancel_ratio = 0.3,
        workspace_swipe_forever = true,
    },
})
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

-- ===== Blur behind bar, launcher, notifications, OSD =====
for _, ns in ipairs({ "waybar", "rofi", "swayosd" }) do
    hl.layer_rule({ match = { namespace = ns }, blur = true, ignore_alpha = 0 })
end
for _, ns in ipairs({ "swaync-control-center", "swaync-notification-window" }) do
    hl.layer_rule({ match = { namespace = ns }, blur = true, ignore_alpha = 0.5 })
end

-- ===== Window rules =====
hl.window_rule({ match = { class = "yazi-float" },   float = true, size = { 1000, 650 }, center = true })
hl.window_rule({ match = { class = "nmtui-float" },  float = true, size = { 760, 520 },  center = true })
hl.window_rule({ match = { class = "org.pulseaudio.pavucontrol" }, float = true, size = { 760, 520 }, center = true })
hl.window_rule({ match = { class = ".blueman-manager-wrapped" },    float = true, size = { 760, 520 }, center = true })

-- ===== Autostart =====
hl.on("hyprland.start", function()
    hl.exec_cmd("systemctl --user start hyprpolkitagent")
    hl.exec_cmd("hyprpaper")
    hl.exec_cmd("waybar")
    hl.exec_cmd("swaync")
    hl.exec_cmd("swayosd-server")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("udiskie")
    hl.exec_cmd("wl-paste --watch cliphist store")
    hl.exec_cmd("wl-clip-persist --clipboard regular")
    hl.exec_cmd("fcitx5 -d")
end)

require("./keybinds.lua")
