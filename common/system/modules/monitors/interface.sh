#!/usr/bin/env bash


ZUI_PATH=${HOME}/.zui

# monitor_add() {
# 	desktops=5 # How many desktops to move to the second monitor

# 	for desktop in $(bspc query -D -m $internal_monitor | sed "$desktops"q)
# 	do
# 		bspc desktop $desktop --to-monitor $external_monitor
# 	done

# 	# Remove "Desktop" created by bspwm
# 	bspc desktop Desktop --remove
# }

# monitor_remove() {
# 	bspc monitor $internal_monitor -a tmp # Temp desktop because one desktop required per monitor

# # 	# Move everything to external monitor to reorder desktops
# 	for desktop in $(bspc query -D -m eDP-1)
# 	do
# 		bspc desktop $desktop --to-monitor HDMI-2
# 	done

# 	bspc monitor HDMI-2 -a Desktop # Temp desktop

# 	for desktop in $(bspc query -D -m HDMI-2)
# 	do
# 		bspc desktop $desktop --to-monitor eDP-1
# 	done

# 	bspc desktop tmp --remove # Remove temp desktops
# }

# if [[ $(xrandr -q | grep "$external_monitor connected") ]]; then
#     monitor_add
# else
#     monitor_remove
# fi

python3 $(dirname $0)/core.py

# xrandr --auto
