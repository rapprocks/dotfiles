#!/usr/bin/env bash

SESSION="rapprocks"

DOTFILES_DIR="$HOME/.dotfiles"
DOTCONFIG_DIR="$HOME/personal/git/dotfiles"  # optional arg, fallback to $HOME

# If session already exists, just attach
tmux has-session -t "$SESSION" 2>/dev/null && {
  tmux attach -t "$SESSION"
  exit 0
}

# Create session with HOME as default (affects all future windows/panes)
tmux new-session -d -s "$SESSION" -n dotfiles -c "$HOME"
tmux send-keys -t "$SESSION:dotfiles" "cd $DOTFILES_DIR && clear" C-m
#tmux new-session -d -s "$SESSION" -n dotfiles -c "$DOTFILES_DIR"

# Second window
tmux new-window -t "$SESSION" -n dotconfig -c "$DOTCONFIG_DIR"

# Third window
tmux new-window -t "$SESSION" -n rando

# Start in first window
tmux select-window -t "$SESSION:1"

tmux attach -t "$SESSION"
