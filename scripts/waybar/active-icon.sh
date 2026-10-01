#!/run/current-system/sw/bin/bash

STATE="$HOME/.cache/waybar-active-icon"

if [[ ! -f "$STATE" ]]; then
    echo '{"text":"","class":"hidden"}'
    exit 0
fi

case "$(cat "$STATE")" in
    idle_inhibitor)
        echo '{"text":"󰅶","class":"active"}'
        ;;
    *)
        echo '{"text":"","class":"hidden"}'
        ;;
esac
