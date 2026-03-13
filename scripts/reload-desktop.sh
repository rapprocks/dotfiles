#!/usr/bin/env bash

set -euo pipefail

notify() { notify-send -a "reload-desktop" "$@"; }

# Niri
echo "Reloading Niri config..."
niri msg action load-config-file || true

# Kanshi
echo "Reloading Kanshi..."
kanshictl reload 2>/dev/null || pkill -USR1 kanshi || true

# Waybar — kill any rogue instances not managed by systemd
rogue_pids=$(comm -23 \
  <(pgrep -x waybar | sort) \
  <(systemctl --user show -p MainPID waybar | grep -oP '\d+' | sort) \
)
if [[ -n "$rogue_pids" ]]; then
  echo "Killing rogue waybar instances: $rogue_pids"
  echo "$rogue_pids" | xargs kill
  sleep 0.3
fi

echo "Restarting waybar systemd unit..."
systemctl --user restart waybar

sleep 1

if systemctl --user is-active --quiet waybar; then
  echo "Waybar is running."
  notify "Desktop reloaded" "Niri, Waybar and Kanshi reloaded successfully."
else
  echo "Waybar failed to start. Recent logs:"
  journalctl --user -u waybar -n 20 --no-pager
  notify -u critical "Desktop reload issue" "Waybar failed to start — check journalctl."
  exit 1
fi
