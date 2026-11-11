#!/usr/bin/env bash


IFACE="wg-work"
if ip link show dev "$IFACE" >/dev/null 2>&1; then
    echo '{"text":"\u00a0","class":"connected","tooltip":"WireGuard: connected"}'
else
    echo '{"text":"\u00a0","class":"disconnected","tooltip":"WireGuard: disconnected"}'
fi
