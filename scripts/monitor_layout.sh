#!/bin/bash

# Define your layouts
layouts=(
    "Single Monitor - Laptop Only"
    "Dual Monitor - Stacked"
    "Dual Monitor - External Left"
		"External Monitor Only (clamshell)"
)

# Layout configurations
configs=(
    "output eDP-1 enable; output HDMI-A-1 disable"
    "output eDP-1 enable; output HDMI-A-1 enable position 1920,0"
    "output eDP-1 enable; output HDMI-A-1 enable position -1920,0"
    "output eDP-1 disable; output HDMI-A-1 enable"
)

# Use a menu to select a layout
selected=$(printf "%s\n" "${layouts[@]}" | wofi --dmenu --prompt "Choose Monitor Layout")

# Find the index of the selected layout
for i in "${!layouts[@]}"; do
    if [[ "${layouts[$i]}" == "$selected" ]]; then
        index=$i
        break
    fi
done

# Apply the configuration if a selection was made
if [[ -n "$index" ]]; then
    swaymsg "${configs[$index]}"
    swaymsg reload
else
    echo "No layout selected."
    exit 1
fi

