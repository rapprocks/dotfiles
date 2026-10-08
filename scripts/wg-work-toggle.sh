#!/run/current-system/sw/bin/bash

set -uo pipefail

export PATH="/run/wrappers/bin:/run/current-system/sw/bin:$PATH"
export GPG_TTY="$(tty || true)"

IFACE="wg-work"
CONFIG="$HOME/workspace/work/scripts/wg-work.conf"

# Check if triggered by the python script
AUTO_SWITCH=0
if [[ "${1:-}" == "--auto-switch" ]]; then
    AUTO_SWITCH=1
fi

echo "WireGuard toggle: $IFACE"
echo

if /run/current-system/sw/bin/ip link show dev "$IFACE" >/dev/null 2>&1; then
    echo "Disconnecting..."
    if /run/wrappers/bin/sudo /run/current-system/sw/bin/wg-quick down "$CONFIG"; then
        echo
        echo "Disconnected."
        /run/current-system/sw/bin/pkill -RTMIN+8 waybar || true
        read -rp "Press Enter to close..."
        exit 0
    else
        status=$?
        echo
        echo "Disconnect failed with exit code $status"
        read -rp "Press Enter to close..."
        exit $status
    fi
else
    echo "Connecting..."
    echo "You may be prompted for your sudo password and YubiKey PIN."
    echo
    if /run/wrappers/bin/sudo /run/current-system/sw/bin/wg-quick up "$CONFIG"; then
        echo
        echo "Connected."
        /run/current-system/sw/bin/pkill -RTMIN+8 waybar || true
        
		if [[ $AUTO_SWITCH -eq 1 ]]; then
        echo "Launching LibreNMS search..."
        
        # Launch the script detached to keep it in the graphical session
        setsid -f /home/earn/workspace/work/scripts/libre_switch_ssh.sh
        
        # No sleep needed, terminal can close instantly
        exit 0
    else
        read -rp "Press Enter to close..."
        exit 0
    fi
    else
        status=$?
        echo
        echo "Connect failed with exit code $status"
        read -rp "Press Enter to close..."
        exit $status
    fi
fi
