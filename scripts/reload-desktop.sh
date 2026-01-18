#!/usr/bin/env bash

CONFIG_PATH="$HOME/personal/git/dotfiles/waybar/niri-config.jsonc"

set -euo pipefail

niri msg action load-config-file
kanshictl reload || pkill -USR1 kanshi
pkill waybar || true
waybar -c "$CONFIG_PATH" & disown

notify-send "Reloaded Niri, waybar and kanshi"
