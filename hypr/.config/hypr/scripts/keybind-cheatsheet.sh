#!/usr/bin/env bash
# Show all current Hyprland keybinds in a searchable rofi cheatsheet.
# Reads the live bind table, so it always matches your real config.
# Needs: hyprctl, jq, rofi.

hyprctl binds -j \
| jq -r '
    # test whether power-of-two bit $b is set in $m
    def hasbit($m; $b): (($m / $b) | floor) % 2 == 1;

    .[]
    # skip binds with no key (mouse/keycode-only) to keep it readable
    | select(.key != null and .key != "")
    | ( [ (if hasbit(.modmask; 64) then "SUPER" else empty end),
          (if hasbit(.modmask; 4)  then "CTRL"  else empty end),
          (if hasbit(.modmask; 8)  then "ALT"   else empty end),
          (if hasbit(.modmask; 1)  then "SHIFT" else empty end),
          .key ]
        | join(" + ") ) as $keys
    | ( if (.description // "") != "" then .description
        else ( .dispatcher + (if (.arg // "") != "" then " " + .arg else "" end) )
        end ) as $label
    | "\($keys)\t\($label)"
  ' \
| sort -u \
| awk -F '\t' '{ printf "%-30s  %s\n", $1, $2 }' \
| rofi -dmenu -i -no-custom -p "Keybinds" \
       -theme ~/.config/rofi/cheatsheet.rasi \
> /dev/null
