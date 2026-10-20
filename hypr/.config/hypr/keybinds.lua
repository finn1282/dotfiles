-- ~/.config/hypr/keybinds.lua  (every bind has a description for the Super+/ cheatsheet)

local terminal = "kitty"
local files    = "dolphin"
local yazi     = "kitty --class yazi-float -e yazi"
local menu     = "rofi -show drun"
local browser  = "zen-browser"
local scripts  = "~/.config/hypr/scripts/"

local mod = "SUPER"

-- ===== Apps =====
hl.bind(mod .. " + C", hl.dsp.exec_cmd(terminal), { description = "Open terminal" })
hl.bind(mod .. " + E", hl.dsp.exec_cmd(files),    { description = "Open file manager (Dolphin)" })
hl.bind(mod .. " + W", hl.dsp.exec_cmd(yazi),     { description = "Open Yazi (file manager)" })
hl.bind(mod .. " + R", hl.dsp.exec_cmd(menu),     { description = "Application launcher" })
hl.bind(mod .. " + B", hl.dsp.exec_cmd(browser),  { description = "Open browser" })
hl.bind(mod .. " + N", hl.dsp.exec_cmd("swaync-client -t -sw"), { description = "Notification centre" })
hl.bind(mod .. " + slash", hl.dsp.exec_cmd(scripts .. "keybind-cheatsheet.sh"), { description = "Rofi Cheatsheet" })

-- ===== Windows =====
hl.bind(mod .. " + Q", hl.dsp.window.close(),                      { description = "Close focused window" })
hl.bind(mod .. " + V", hl.dsp.window.float({ action = "toggle" }), { description = "Toggle floating" })
-- hl.bind(mod .. " + F", hl.dsp.fullscreen(), { description = "Toggle fullscreen" })
-- hl.bind(mod .. " + J", hl.dsp.layout("togglesplit"), { description = "Toggle split direction" })

-- ===== Session =====
hl.bind(mod .. " + P", hl.dsp.exec_cmd("loginctl lock-session"), { description = "Lock screen" })
hl.bind(mod .. " + M", hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"), { description = "Exit / shutdown menu" })

-- ===== Screenshots =====
hl.bind(mod .. " + PRINT",   hl.dsp.exec_cmd(scripts .. "screenshot.sh region"), { description = "Screenshot region -> annotate" })
hl.bind("PRINT",             hl.dsp.exec_cmd(scripts .. "screenshot.sh screen"), { description = "Screenshot full screen -> file + clipboard" })
hl.bind("SHIFT + PRINT",     hl.dsp.exec_cmd(scripts .. "screenshot.sh window"), { description = "Screenshot active window -> file + clipboard" })

-- ===== Clipboard history =====
hl.bind(mod .. " + period", hl.dsp.exec_cmd("cliphist list | rofi -dmenu -p ' ' | cliphist decode | wl-copy"), { description = "Clipboard history" })

-- ===== Focus (vim keys) =====
hl.bind(mod .. " + h", hl.dsp.focus({ direction = "left" }),  { description = "Focus left" })
hl.bind(mod .. " + j", hl.dsp.focus({ direction = "down" }),  { description = "Focus down" })
hl.bind(mod .. " + k", hl.dsp.focus({ direction = "up" }),    { description = "Focus up" })
hl.bind(mod .. " + l", hl.dsp.focus({ direction = "right" }), { description = "Focus right" })

-- ===== Workspaces =====
for i = 1, 10 do
    local key = i % 10
    hl.bind(mod .. " + " .. key,         hl.dsp.focus({ workspace = i }),       { description = "Focus workspace " .. i })
    hl.bind(mod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }), { description = "Move window to workspace " .. i })
end

-- ===== Resize =====
hl.bind(mod .. " + right", hl.dsp.window.resize({ x = 40, y = 0, relative = true }),  { repeating = true, description = "Resize window right" })
hl.bind(mod .. " + left",  hl.dsp.window.resize({ x = -40, y = 0, relative = true }),  { repeating = true, description = "Resize window left" })
hl.bind(mod .. " + up",    hl.dsp.window.resize({ x = 0, y = -40, relative = true }), { repeating = true, description = "Resize window up" })
hl.bind(mod .. " + down",  hl.dsp.window.resize({ x = 0, y = 40, relative = true }),  { repeating = true, description = "Resize window down" })

-- ===== Mouse =====
hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true, description = "Move window (drag)" })
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true, description = "Resize window (drag)" })

-- ===== Laptop keys (swayosd popups) =====
hl.bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd("swayosd-client --output-volume +5 --max-volume 100"), { locked = true, repeating = true, description = "Volume up" })
hl.bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd("swayosd-client --output-volume -5"),                  { locked = true, repeating = true, description = "Volume down" })
hl.bind("XF86AudioMute",         hl.dsp.exec_cmd(scripts .. "audio-mute.sh output"), { locked = true, description = "Mute audio" })
hl.bind("XF86AudioMicMute",      hl.dsp.exec_cmd(scripts .. "audio-mute.sh input"),  { locked = true, description = "Mute microphone" })
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("swayosd-client --brightness raise"), { locked = true, repeating = true, description = "Brightness up" })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("swayosd-client --brightness lower"), { locked = true, repeating = true, description = "Brightness down" })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true, description = "Play / pause" })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"),       { locked = true, description = "Next track" })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"),   { locked = true, description = "Previous track" })
hl.bind("XF86Display",   hl.dsp.exec_cmd(scripts .. "toggle-trackpoint.sh"), { description = "Toggle TrackPoint" })
