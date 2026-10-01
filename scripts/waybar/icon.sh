#!/run/current-system/sw/bin/bash

MODE="$1"
ID="$2"
ICON="$3"

STATE="$HOME/.cache/waybar-active-icon"

ACTIVE=""

if [[ -f "$STATE" ]]; then
    ACTIVE="$(cat "$STATE")"
fi

if [[ "$MODE" == "drawer" ]]; then

    if [[ "$ACTIVE" == "$ID" ]]; then
        echo '{"text":"","class":"hidden"}'
    else
        echo "{\"text\":\"$ICON\",\"class\":\"active\"}"
    fi

elif [[ "$MODE" == "active" ]]; then

    if [[ "$ACTIVE" == "$ID" ]]; then
        echo "{\"text\":\"$ICON\",\"class\":\"active\"}"
    else
        echo '{"text":"","class":"hidden"}'
    fi

fi
