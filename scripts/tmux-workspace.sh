#!/usr/bin/env bash

SESSION="rapprocks"

DOTCONFIG_DIR="${1:-$HOME/.dotfiles}"

# If session already exists, just attach
tmux has-session -t "$SESSION" 2>/dev/null && {
  tmux attach -t "$SESSION"
  exit 0
}

# Create session in $HOME, with first window in dotfiles
tmux new-session -d -s "$SESSION" -n dotfiles -c "$DOTCONFIG_DIR"

# Second window (nixconf if present, otherwise $HOME)
if [[ -d "$HOME/nixconf" ]]; then
  tmux new-window -t "$SESSION" -n nixconf -c "$HOME/nixconf"
fi

# Third window
tmux new-window -t "$SESSION" -n rando -c "$HOME"

# Start in first window
tmux select-window -t "$SESSION:1"

tmux attach -t "$SESSION"
