#!/usr/bin/env bash
# Toggle the TrackPoint. Find the exact device name with: hyprctl devices
DEV="tpps/2-elan-trackpoint"
STATE_FILE="/tmp/trackpoint_state"

if [ -f "$STATE_FILE" ]; then
    hyprctl eval "hl.device({ name = '$DEV', enabled = true })"
    rm "$STATE_FILE"
    notify-send "TrackPoint" "Enabled" -t 1000
else
    hyprctl eval "hl.device({ name = '$DEV', enabled = false })"
    touch "$STATE_FILE"
    notify-send "TrackPoint" "Disabled" -t 1000
fi
