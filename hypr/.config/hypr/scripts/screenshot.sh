#!/usr/bin/env bash
# screenshot.sh region|screen|window
dir="$HOME/Pictures/Screenshots"; mkdir -p "$dir"
file="$dir/$(date +%Y-%m-%d_%H-%M-%S).png"
case "$1" in
    region) grim -g "$(slurp)" - | swappy -f - ; exit ;;
    screen) grim "$file" ;;
    window) grim -g "$(hyprctl activewindow -j | jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"')" "$file" ;;
    *) echo "usage: $0 region|screen|window" >&2; exit 1 ;;
esac
wl-copy < "$file" && notify-send -i "$file" "Screenshot saved" "$(basename "$file")"
