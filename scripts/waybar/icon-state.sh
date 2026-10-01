#!/usr/bin/env bash

STATE="$HOME/.cache/waybar-icon-state"

if [[ -f "$STATE" ]]; then
    echo '{"text":"","class":"hidden"}'
else
    echo '{"text":"󰅶","class":"active"}'
fi
