#!/usr/bin/env bash

# Terminate already running bar instances
killall -q polybar

## Wait until the processes have been shut down
while pgrep -u "${UID}" -x polybar >/dev/null; do sleep 1; done

TOP_BARS="${HOME}/.config/polybar/top_bars.ini"
BOTTOM_BARS="${HOME}/.config/polybar/bottom_bars.ini"

## Top Right bars
polybar cpu -c "${TOP_BARS}" &
polybar memory -c "${TOP_BARS}" &
polybar disk -c "${TOP_BARS}" &

## Top Center bars
polybar date -c "${TOP_BARS}" &

## Bottom Left bars
polybar spotify -c "${BOTTOM_BARS}" &

## Bottom Center bars

## Bottom Right bars
if [[ -L /sys/class/power_supply/BAT0 ]]; then
	BATTERY='-battery'
else
	BATTERY=''
fi
if [[ -z $(find /sys/class/backlight -type d -empty) ]]; then
	BACKLIGHT='-backlight'
else
	BACKLIGHT=''
fi
polybar notifications"${BATTERY}""${BACKLIGHT}" -c "${BOTTOM_BARS}" &
polybar indicators"${BATTERY}""${BACKLIGHT}" -c "${BOTTOM_BARS}" &
polybar network"${BATTERY}""${BACKLIGHT}" -c "${BOTTOM_BARS}" &
polybar battery"${BACKLIGHT}" -c "${BOTTOM_BARS}" &
polybar audio"${BACKLIGHT}" -c "${BOTTOM_BARS}" &
polybar backlight -c "${BOTTOM_BARS}" &

## Top Left bars
if [[ -z ${SECONDARY_MONITOR} ]]; then
	polybar workspaces-single-monitor -c "${TOP_BARS}" &
else
	polybar workspaces -c "${TOP_BARS}" &
	export MAIN_MONITOR=${SECONDARY_MONITOR}
	polybar workspaces -c "${TOP_BARS}" &
fi