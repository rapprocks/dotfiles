#!/usr/bin/env bash

OUTPUT_DIR="$HOME/Videos/screenrecordings"

if [[ ! -d "$OUTPUT_DIR" ]]; then
  notify-send "Screen recording directory does not exist: $OUTPUT_DIR" -u critical -t 3000
  exit 1
fi

filename="$OUTPUT_DIR/screenrecording-$(date +'%Y-%m-%d_%H-%M-%S').mp4"

toggle_indicator() {
  pkill -RTMIN+8 waybar
}

stop_screenrecording() {
  pkill -x wf-recorder
  notify-send "Screen recording saved to $OUTPUT_DIR" -t 2000
  sleep 0.2
  toggle_indicator
}

screenrecording_active() {
  pgrep -x wf-recorder >/dev/null
}

start_screenrecording() {
  region=$(slurp) || exit 1
  wf-recorder -g "$region" -f "$filename" -c libx264 -p crf=23 -p preset=medium -p movflags=+faststart &
  toggle_indicator
}

if screenrecording_active; then
  stop_screenrecording
else
  start_screenrecording
fi

