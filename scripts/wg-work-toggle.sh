#!/run/current-system/sw/bin/bash

set -uo pipefail

export PATH="/run/wrappers/bin:/run/current-system/sw/bin:$PATH"
export GPG_TTY="$(tty || true)"

IFACE="wg-work"
CONFIG="$HOME/work/wg-work.conf"

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
	read -rp "Press Enter to close..."
	exit 0
else
	status=$?
	echo
	echo "Connect failed with exit code $status"
	read -rp "Press Enter to close..."
	exit $status
fi
fi
