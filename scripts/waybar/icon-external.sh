#!/usr/bin/env bash

STATE="$HOME/.cache/waybar-icon-state"

if [[ -f "$STATE" ]]; then
    echo '{"text":"󰅶","class":"active"}'

else
    echo '{"text":"","class":"hidden"}'
fi
