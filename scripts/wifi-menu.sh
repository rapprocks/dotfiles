#!/usr/bin/env bash


# 1. Identify the Wireless Device
# Find the first device operating in 'station' mode
DEVICE=$(iwctl device list | sed -r 's/\x1B\[[0-9;]*[mK]//g' | grep 'station' | awk '{print $1}' | head -n 1)

if [ -z "$DEVICE" ]; then
    notify-send "Wi-Fi Error" "No wireless device found."
    exit 1
fi

# 2. Initiate Network Scan
iwctl station "$DEVICE" scan
# Allow a brief moment for the scan to populate the network list
sleep 1.5

# 3. Retrieve Available Networks
# Get network list, strip ANSI escape codes, extract SSID column, trim whitespace, and ignore empty lines
NETWORKS=$(iwctl station "$DEVICE" get-networks | tail -n +5 | sed -r 's/\x1B\[[0-9;]*[mK]//g' | cut -c 5-36 | sed 's/ *$//' | grep -v '^$')

if [ -z "$NETWORKS" ]; then
    notify-send "Wi-Fi Error" "No networks found."
    exit 1
fi

# 4. Present Selection Menu
SELECTED_SSID=$(echo "$NETWORKS" | fuzzel --dmenu --prompt="Wi-Fi: ")

if [ -z "$SELECTED_SSID" ]; then
    # User canceled selection
    exit 0
fi

# 5. Handle Connection
# Attempt to connect to the selected SSID
# We run iwctl in a way that allows us to check if a passphrase is required.
# If the network is known, it will connect. If it requires a passphrase, it usually prompts interactively.
# We redirect stdout/stderr to check if it asks for a passphrase or fails.
# Since iwctl might block waiting for input if run normally, we can test it known networks first using 'iwctl known-networks list'

KNOWN_NETWORKS=$(iwctl known-networks list | sed -r 's/\x1B\[[0-9;]*[mK]//g' | tail -n +5 | cut -c 5-36 | sed 's/ *$//')

if echo "$KNOWN_NETWORKS" | grep -Fxq "$SELECTED_SSID"; then
    # Known network, connect directly
    iwctl station "$DEVICE" connect "$SELECTED_SSID"
else
    # Network not known, might need a password.
    # We can prompt for a password immediately to be safe, or check security.
    # To keep it simple, we ask for a password. If it's an open network, user can just hit enter.
    PASSWORD=$(echo "" | fuzzel --dmenu --prompt="Password for $SELECTED_SSID (leave empty if open): " --password)
    
    if [ -n "$PASSWORD" ]; then
        iwctl --passphrase "$PASSWORD" station "$DEVICE" connect "$SELECTED_SSID"
    else
        iwctl station "$DEVICE" connect "$SELECTED_SSID"
    fi
fi

# 6. Notify the User
# Wait a few seconds for the connection to establish
sleep 2

if iwctl station "$DEVICE" show | grep -qi "connected"; then
    notify-send "Wi-Fi" "Successfully connected to $SELECTED_SSID"
else
    notify-send "Wi-Fi Error" "Failed to connect to $SELECTED_SSID"
fi
