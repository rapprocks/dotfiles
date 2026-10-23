#!/run/current-system/sw/bin/bash

IFACE="wg-work"

if /run/current-system/sw/bin/ip link show dev "$IFACE" >/dev/null 2>&1; then
	/run/current-system/sw/bin/ip -s -j addr show dev "$IFACE" 2>/dev/null | /run/current-system/sw/bin/jq -c '
		def netmask($p):
			[0,1,2,3] | map(
				if $p >= ((. + 1) * 8) then 255
				elif $p <= (. * 8) then 0
				else (256 - pow(2; 8 - ($p - (. * 8)))) | floor
				end | tostring
			) | join(".");
		def fmt_bytes($b):
			if $b >= 1073741824 then (((($b / 1073741824) * 100) | round) / 100 | tostring) + " GiB"
			elif $b >= 1048576 then (((($b / 1048576) * 100) | round) / 100 | tostring) + " MiB"
			elif $b >= 1024 then (((($b / 1024) * 100) | round) / 100 | tostring) + " KiB"
			else ($b | tostring) + " B"
			end;
		.[0] |
		(.addr_info | map(select(.family == "inet"))[0]) as $ip |
		{
			text: "󰒃",
			alt: "connected",
			class: "connected",
			tooltip: (
				"Network: <big><b>\(.ifname)</b></big>\n" +
				"State: <b>Connected</b>\n" +
				"Interface: <b>\(.ifname)</b>\n" +
				"IP: <b>\($ip.local // "N/A")/\($ip.prefixlen // "N/A")</b>\n" +
				"Netmask: <b>\(if $ip.prefixlen then netmask($ip.prefixlen) else "N/A" end)</b>\n" +
				"MTU: <b>\(.mtu)</b>\n" +
				"Traffic: <b>⇣ \(fmt_bytes(.stats64.rx.bytes // 0))  ⇡ \(fmt_bytes(.stats64.tx.bytes // 0))</b>"
			)
		}
	'
else
	echo '{"text":"󰒃","alt":"disconnected","class":"disconnected","tooltip":"Network: <big><b>wg-work</b></big>\nState: <b>Disconnected</b>"}'
fi
