#!/usr/bin/env bash

# Simple theme switcher with light/dark support
# Usage: theme-switch <dark|light> or theme-switch (toggles)

CONFIG_DIR="$HOME/.config/mytheme"
THEMES_DIR="$CONFIG_DIR/themes"
CURRENT_DIR="$CONFIG_DIR/current"
CURRENT_NAME_FILE="$CONFIG_DIR/current.name"

# Get current theme name
get_current_theme() {
  [[ -f "$CURRENT_NAME_FILE" ]] && cat "$CURRENT_NAME_FILE" || echo ""
}

# Toggle between light and dark if no argument given
if [[ -z "$1" ]]; then
  current=$(get_current_theme)
  if [[ "$current" == "light" ]]; then
    THEME_NAME="dark"
  else
    THEME_NAME="light"
  fi
else
  THEME_NAME="$1"
fi

THEME_PATH="$THEMES_DIR/$THEME_NAME"

if [[ ! -d "$THEME_PATH" ]]; then
  echo "Theme '$THEME_NAME' not found in $THEMES_DIR"
  exit 1
fi

# Copy theme to current
rm -rf "$CURRENT_DIR"
mkdir -p "$CURRENT_DIR"
cp -r "$THEME_PATH/"* "$CURRENT_DIR/"
echo "$THEME_NAME" > "$CURRENT_NAME_FILE"

echo "Switched to theme: $THEME_NAME"

# Detect if light or dark mode
is_light_mode() {
  [[ -f "$CURRENT_DIR/light.mode" ]]
}

# ============================================
# RELOAD SERVICES/APPS - customize as needed
# ============================================

# GTK/GNOME apps (file managers, etc.)
if command -v gsettings &>/dev/null; then
  if is_light_mode; then
    gsettings set org.gnome.desktop.interface color-scheme "prefer-light"
    gsettings set org.gnome.desktop.interface gtk-theme "Adwaita"
  else
    gsettings set org.gnome.desktop.interface color-scheme "prefer-dark"
    gsettings set org.gnome.desktop.interface gtk-theme "Adwaita-dark"
  fi
  echo "  → GTK theme updated"
fi

# Terminal emulators
# Alacritty - just touch the config file to trigger reload
if [[ -f ~/.config/alacritty/alacritty.toml ]]; then
  touch ~/.config/alacritty/alacritty.toml
  echo "  → Alacritty reloaded"
fi

# Kitty
if pgrep -x kitty &>/dev/null; then
  killall -SIGUSR1 kitty
  echo "  → Kitty reloaded"
fi

# Ghostty
if pgrep -x ghostty &>/dev/null; then
  killall -SIGUSR2 ghostty
  echo "  → Ghostty reloaded"
fi

# Hyprland (if using)
if command -v hyprctl &>/dev/null && [[ "$XDG_CURRENT_DESKTOP" == "Hyprland" ]]; then
  hyprctl reload &>/dev/null
  echo "  → Hyprland reloaded"
fi

# Waybar (if using)
if pgrep -x waybar &>/dev/null; then
  killall -SIGUSR2 waybar  # or: pkill waybar && waybar &
  echo "  → Waybar reloaded"
fi

# Mako notifications (if using)
if command -v makoctl &>/dev/null && pgrep -x mako &>/dev/null; then
  makoctl reload
  echo "  → Mako reloaded"
fi

# Sway (if using)
if command -v swaymsg &>/dev/null && [[ "$XDG_CURRENT_DESKTOP" == "sway" ]]; then
  swaymsg reload
  echo "  → Sway reloaded"
fi

echo "Done!"
