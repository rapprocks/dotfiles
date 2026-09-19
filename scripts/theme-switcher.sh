#!/usr/bin/env bash
set -euo pipefail

export PATH="/run/current-system/sw/bin:$PATH"

# Read-only status query
if [[ "${1:-}" == "--status" ]]; then
  if [[ "$(dconf read /org/gnome/desktop/interface/color-scheme 2>/dev/null || echo "prefer-light")" == "'prefer-dark'" ]]; then
    echo '{"text": "󰖔", "class": "dark"}'
  else
    echo '{"text": "󰖨", "class": "light"}'
  fi
  exit 0
fi

# Require explicit mode argument
MODE="${1:-}"
if [[ "$MODE" != "dark" && "$MODE" != "light" ]]; then
  echo "Usage: theme-switcher.sh [dark|light|--status]" >&2
  exit 1
fi

# Determine colors for the requested mode
case "$MODE" in
  dark)
    COLOR_SCHEME="prefer-dark"
    KDE_SCHEME="BreezeDark"
    GTK_THEME="Adwaita-dark"
    ;;
  light)
    COLOR_SCHEME="prefer-light"
    KDE_SCHEME="BreezeLight"
    GTK_THEME="Adwaita"
    ;;
esac

echo "Applying $MODE mode desktop settings..."

# Validate required commands are available
if ! command -v dconf &>/dev/null; then
  echo "Error: dconf not found in PATH" >&2
  exit 1
fi

if ! command -v plasma-apply-colorscheme &>/dev/null; then
  echo "Error: plasma-apply-colorscheme not found in PATH" >&2
  exit 1
fi

# Set GNOME/GTK color preference (required)
if ! dconf write /org/gnome/desktop/interface/color-scheme "'$COLOR_SCHEME'"; then
  echo "Error: Failed to write color-scheme to dconf" >&2
  exit 1
fi

# Set GTK theme name (for any remaining GTK apps not using color-scheme)
if ! dconf write /org/gnome/desktop/interface/gtk-theme "'$GTK_THEME'"; then
  echo "Error: Failed to write gtk-theme to dconf" >&2
  exit 1
fi

# Apply KDE application color scheme (required)
if ! plasma-apply-colorscheme "$KDE_SCHEME"; then
  echo "Error: Failed to apply KDE color scheme" >&2
  exit 1
fi

# Reload SwayNC CSS (optional - respects color theme changes)
if command -v swaync-client &>/dev/null; then
  if swaync-client --skip-wait --reload-css 2>/dev/null; then
    echo "SwayNC CSS reloaded"
  else
    echo "Warning: Failed to reload SwayNC CSS" >&2
  fi
fi

# Trigger Alacritty reload by touching the main config file (optional)
ALACRITTY_CONFIG="$HOME/.config/alacritty/alacritty.toml"
if [[ -f "$ALACRITTY_CONFIG" ]]; then
  if touch -c "$ALACRITTY_CONFIG"; then
    echo "Alacritty config reload triggered"
  else
    echo "Warning: Failed to trigger Alacritty reload" >&2
  fi
fi

# Reload tmux if running (optional)
if command -v tmux &>/dev/null && tmux list-sessions &>/dev/null 2>&1; then
  if tmux source-file ~/.config/tmux/tmux.conf 2>/dev/null; then
    echo "tmux reloaded"
  else
    echo "Warning: Failed to reload tmux" >&2
  fi
fi

# Send notification (optional)
if command -v notify-send &>/dev/null; then
  notify-send "Switched to $MODE mode" || true
fi

exit 0
