#!/usr/bin/env bash

theme=${HOME}/.zui/current_theme/rofi/themes/powermenu.rasi
rofi_command="rofi -theme ${theme}"

uptime=$(uptime -p | sed -e 's/up //g')

# Options
shutdown="襤 shutdown"
reboot="累 reboot"
lock=" lock"
suspend="鈴 suspend"
logout=" logout"

# Variable passed to rofi
options="$shutdown\n$reboot\n$lock\n$suspend\n$logout"

chosen="$(echo -e "$options" | $rofi_command -p "$uptime: " -dmenu -selected-row 2)"
case $chosen in
    $shutdown)
	ans="yes"
	if [[ $ans == "yes" || $ans == "YES" || $ans == "y" || $ans == "Y" ]]; then
		systemctl poweroff
	elif [[ $ans == "no" || $ans == "NO" || $ans == "n" || $ans == "N" ]]; then
		exit 0
        else
		msg
        fi
        ;;
    $reboot)
	ans="yes"
	if [[ $ans == "yes" || $ans == "YES" || $ans == "y" || $ans == "Y" ]]; then
		systemctl reboot
	elif [[ $ans == "no" || $ans == "NO" || $ans == "n" || $ans == "N" ]]; then
		exit 0
        else
		msg
        fi
        ;;
    $lock)
	if [[ -f /usr/bin/betterlockscreen ]]; then
		betterlockscreen -l
	else
		$(dirname $0)/lock.sh
	fi
        ;;
    $suspend)
	ans="yes"
	if [[ $ans == "yes" || $ans == "YES" || $ans == "y" || $ans == "Y" ]]; then
		mpc -q pause
		amixer set Master mute
		systemctl suspend
	elif [[ $ans == "no" || $ans == "NO" || $ans == "n" || $ans == "N" ]]; then
		exit 0
        else
		msg
        fi
        ;;
    $logout)
	ans="yes"
	if [[ $ans == "yes" || $ans == "YES" || $ans == "y" || $ans == "Y" ]]; then
		if [[ "$DESKTOP_SESSION" == "Openbox" ]]; then
			openbox --exit
		elif [[ "$DESKTOP_SESSION" == "bspwm" ]]; then
			bspc quit
		elif [[ "$DESKTOP_SESSION" == "i3" ]]; then
			i3-msg exit
		fi
	elif [[ $ans == "no" || $ans == "NO" || $ans == "n" || $ans == "N" ]]; then
		exit 0
        else
		msg
        fi
        ;;
esac
