#!/usr/bin/env bash
# Mute via PipeWire (so Waybar and swayosd see it), then mirror it onto the
# ALSA switch on the PCH card, which drives the F1/F4 LEDs on the T490.
case "$1" in
    output) node=@DEFAULT_AUDIO_SINK@;   osd=--output-volume; ctl=Master;  on=unmute; off=mute  ;;
    input)  node=@DEFAULT_AUDIO_SOURCE@; osd=--input-volume;  ctl=Capture; on=cap;    off=nocap ;;
    *) echo "usage: $0 output|input" >&2; exit 1 ;;
esac
swayosd-client "$osd" mute-toggle
if wpctl get-volume "$node" | grep -q MUTED; then
    amixer -c PCH -q set "$ctl" "$off"
else
    amixer -c PCH -q set "$ctl" "$on"
fi
