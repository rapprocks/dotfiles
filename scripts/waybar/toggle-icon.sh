#!/run/current-system/sw/bin/bash

STATE="$HOME/.cache/waybar-active-icon"

ID="$1"

if [[ -z "$ID" ]]; then
    exit 1
fi

# If the clicked icon is already active, deactivate it.
if [[ -f "$STATE" ]] && [[ "$(cat "$STATE")" == "$ID" ]]; then
    rm -f "$STATE"
else
    # Otherwise make this the active icon.
    printf '%s\n' "$ID" > "$STATE"
fi

# Get Waybar's PID without requiring pgrep/pkill.
WAYBAR_PID=$(
    /run/current-system/sw/bin/systemctl \
        --user show \
        --property=MainPID \
        --value \
        waybar.service
)

if [[ "$WAYBAR_PID" =~ ^[1-9][0-9]*$ ]]; then
    kill -s RTMIN+8 "$WAYBAR_PID"
fi
