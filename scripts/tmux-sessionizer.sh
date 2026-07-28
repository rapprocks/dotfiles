#!/usr/bin/env bash

# Define the directories where your projects live
if [[ $# -eq 1 ]]; then
    selected=$1
else
    selected=$(find ~/work/git ~/personal/git ~/personal -mindepth 1 -maxdepth 1 -type d | fzf)
fi

if [[ -z $selected ]]; then
    exit 0
fi

# Format the session name (removes dots which tmux hates in session names)
selected_name=$(basename "$selected" | tr . _)
tmux_running=$(pgrep tmux)

# If not in tmux and tmux isn't running, start a new session
if [[ -z $TMUX ]] && [[ -z $tmux_running ]]; then
    tmux new-session -s $selected_name -c $selected
    exit 0
fi

# If the session doesn't exist, create it in the background
if ! tmux has-session -t=$selected_name 2> /dev/null; then
    tmux new-session -ds $selected_name -c $selected
fi

# Switch to the session
if [[ -z $TMUX ]]; then
    tmux attach-session -t $selected_name
else
    tmux switch-client -t $selected_name
fi
