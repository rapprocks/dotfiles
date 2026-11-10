#!/usr/bin/env bash

CONFIG_PATH="$HOME/.dotfiles/waybar/niri-config.jsonc"

if [ -f "$CONFIG_PATH" ]; then
    waybar -c "$CONFIG_PATH"
else
    echo "Error: Configuration file not found at $CONFIG_PATH"
    exit 1
fi
