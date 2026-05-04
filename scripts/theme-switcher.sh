#!/usr/bin/env bash
set -euo pipefail

export PATH="/run/current-system/sw/bin:$PATH"

DOTFILES="$HOME/personal/git/dotfiles"
CONFIG="$HOME/.config"
DCONF_KEY="/org/gnome/desktop/interface/color-scheme"

if [[ "${1:-}" == "--status" ]]; then
  if [[ "$(dconf read $DCONF_KEY)" == "'prefer-dark'" ]]; then
    echo '{"text": "󰖔", "class": "dark"}'
  else
    echo '{"text": "󰖨", "class": "light"}'
  fi
  exit 0
fi

# Detect current mode from system theme (set by nwg-look)
if [[ "$(dconf read $DCONF_KEY)" == "'prefer-dark'" ]]; then
  mode=light
  color_scheme="prefer-light"
else
  mode=dark
  color_scheme="prefer-dark"
fi

# 1. Update all config files first
# Sync GTK settings.ini files
gtk_theme="Adwaita"
[[ "$mode" == "dark" ]] && gtk_theme="Adwaita-dark"

for v in gtk-3.0 gtk-4.0; do
  # HARDCODE prefer-dark to 0 so it never conflicts with Adwaita-dark
  sed -i "s/gtk-application-prefer-dark-theme=.*/gtk-application-prefer-dark-theme=0/" \
    "$CONFIG/$v/settings.ini" 2>/dev/null || true
    
  # Set explicit GTK theme name
  sed -i "s/gtk-theme-name=.*/gtk-theme-name=$gtk_theme/" \
    "$CONFIG/$v/settings.ini" 2>/dev/null || true
done

# app:symlink_name:dark_file:light_file
apps=(
  "alacritty:colors.toml:rose-pine.toml:rose-pine-dawn.toml"
  "fuzzel:colors.ini:rose-pine.ini:rose-pine-dawn.ini"
	"tmux:colors.conf:rose-pine.conf:rose-pine-dawn.conf"
	"waybar:colors.css:rose-pine.css:rose-pine-dawn.css"
  "mako:colors:rose-pine:rose-pine-dawn"
)

for entry in "${apps[@]}"; do
  IFS=: read -r app symlink dark light <<< "$entry"
  [[ "$mode" == "dark" ]] && theme="$dark" || theme="$light"
  ln -sf "$DOTFILES/$app/$theme" "$CONFIG/$app/$symlink"
done

# 2. Trigger reloads and broadcast changes
# Toggle system theme (source of truth & triggers D-Bus for Waybar/Ghostty)
dconf write $DCONF_KEY "'$color_scheme'"

# Force GTK apps (Thunar) to hot-reload their settings
gsettings set org.gnome.desktop.interface gtk-theme "'$gtk_theme'"

# Force xdg-desktop-portal-gtk to restart and apply new theme for the file chooser
systemctl --user restart xdg-desktop-portal-gtk 2>/dev/null || true

# Reload tmux
tmux source-file ~/.config/tmux/tmux.conf 2>/dev/null || true

# Reload mako
makoctl reload

#echo "Switched to $mode mode"
notify-send "Switched to $mode mode"
