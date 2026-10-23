#!/usr/bin/env bash

set -uo pipefail

# 1. Check connected audio devices via wpctl and filter for headphones/headsets
HEADSET_IDS=()
HEADSET_NAMES=()

while IFS=$'\t' read -r id name _; do
    [[ -z "${id:-}" ]] && continue
    info=$(wpctl inspect "$id" 2>/dev/null)

    # Match bluetooth, headphone, or headset devices
    if echo "$info" | grep -Eqi 'device\.form-factor = "(headphone|headset)"|icon-name = ".*head(phone|set).*"|device\.api = "bluez5"'; then
        desc=$(echo "$info" | sed -n 's/.*device\.description = "\(.*\)"/\1/p' | head -n1)
        [[ -z "$desc" ]] && desc="$name"
        HEADSET_IDS+=("$id")
        HEADSET_NAMES+=("$desc")
    fi
done < <(wpctl list audio devices)

if [[ ${#HEADSET_IDS[@]} -eq 0 ]]; then
    notify-send "Audio Profile" "No headphones or headsets connected."
    exit 0
fi

# 2. Choose among available headsets via rofi -dmenu (returns 0-based index)
HEADSET_IDX=$(printf "%s\n" "${HEADSET_NAMES[@]}" | rofi -dmenu -i -format i -p "Headset:")
[[ -z "${HEADSET_IDX:-}" || "$HEADSET_IDX" -lt 0 ]] && exit 0

DEVICE_ID="${HEADSET_IDS[$HEADSET_IDX]}"
DEVICE_NAME="${HEADSET_NAMES[$HEADSET_IDX]}"

# 3. List available profiles for the selected headset and choose one
PROFILE_IDS=()
PROFILE_LABELS=()

while IFS=$'\t' read -r p_idx p_label; do
    [[ -z "${p_idx:-}" ]] && continue
    PROFILE_IDS+=("$p_idx")
    PROFILE_LABELS+=("$p_label")
done < <(pw-dump "$DEVICE_ID" | jq -r '
    .[] |
    (.info.params.Profile[0].index // -1) as $current |
    .info.params.EnumProfile[]? |
    select(.available != "no") |
    "\(.index)\t\(.description)\(if .index == $current then " [active]" else "" end)"
')

if [[ ${#PROFILE_IDS[@]} -eq 0 ]]; then
    notify-send "Audio Profile" "No profiles found for $DEVICE_NAME."
    exit 1
fi

PROFILE_IDX=$(printf "%s\n" "${PROFILE_LABELS[@]}" | rofi -dmenu -i -format i -p "Profile ($DEVICE_NAME):")
[[ -z "${PROFILE_IDX:-}" || "$PROFILE_IDX" -lt 0 ]] && exit 0

PROFILE_INDEX="${PROFILE_IDS[$PROFILE_IDX]}"
PROFILE_DESC="${PROFILE_LABELS[$PROFILE_IDX]% \[active\]}"

# 4. Apply the selected profile with wpctl
if wpctl set-profile "$DEVICE_ID" "$PROFILE_INDEX"; then
    notify-send "Audio Profile" "Set $DEVICE_NAME to:\n$PROFILE_DESC"
else
    notify-send "Audio Profile Error" "Failed to set profile on $DEVICE_NAME."
    exit 1
fi
