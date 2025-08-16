#!/usr/bin/env bash

theme=${HOME}/.zui/current_theme/rofi/themes/powermenu.rasi
rofi_command="rofi -theme ${theme}"

# Options
lock="󰌾  lock"
logout="󰍃  logout"
suspend="󰒲  suspend"
reboot="󰑐  reboot"
shutdown="⏻  shutdown"

# Variable passed to rofi
options="${lock}\n${logout}\n${suspend}\n${reboot}\n${shutdown}"

chosen="$(echo -e "${options}" | ${rofi_command} -dmenu -selected-row 0)"
case ${chosen} in
    "${shutdown}")
	ans="yes"
	if [[ ${ans} == "yes" || ${ans} == "YES" || ${ans} == "y" || ${ans} == "Y" ]]; then
		systemctl poweroff
	elif [[ ${ans} == "no" || ${ans} == "NO" || ${ans} == "n" || ${ans} == "N" ]]; then
		exit 0
        else
		msg
        fi
        ;;
    "${reboot}")
	ans="yes"
	if [[ ${ans} == "yes" || ${ans} == "YES" || ${ans} == "y" || ${ans} == "Y" ]]; then
		systemctl reboot
	elif [[ ${ans} == "no" || ${ans} == "NO" || ${ans} == "n" || ${ans} == "N" ]]; then
		exit 0
        else
		msg
        fi
        ;;
    "${lock}")
	if [[ -f /usr/bin/betterlockscreen ]]; then
		betterlockscreen -l
	else
		"$(dirname "${0}")/lock.sh"
	fi
        ;;
    "${suspend}")
	ans="yes"
	if [[ ${ans} == "yes" || ${ans} == "YES" || ${ans} == "y" || ${ans} == "Y" ]]; then
		mpc -q pause
		amixer set Master mute
		systemctl suspend
	elif [[ ${ans} == "no" || ${ans} == "NO" || ${ans} == "n" || ${ans} == "N" ]]; then
		exit 0
        else
		msg
        fi
        ;;
    "${logout}")
	ans="yes"
	if [[ ${ans} == "yes" || ${ans} == "YES" || ${ans} == "y" || ${ans} == "Y" ]]; then
		bspc quit
	elif [[ ${ans} == "no" || ${ans} == "NO" || ${ans} == "n" || ${ans} == "N" ]]; then
		exit 0
        else
		msg
        fi
        ;;
	*)
		msg
esac
