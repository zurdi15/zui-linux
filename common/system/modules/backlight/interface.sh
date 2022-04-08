#!/usr/bin/env bash

BRIGHTNESS_PATH=/sys/class/backlight/*/
MAX_BRIGHTNESS=$(cat ${BRIGHTNESS_PATH}max_brightness)
ACTUAL_BRIGHTNESS=$(cat ${BRIGHTNESS_PATH}brightness)
BRIGHTNESS_STEP=2424

if [[ $1 == "up" ]]; then
	bright=$((ACTUAL_BRIGHTNESS + BRIGHTNESS_STEP))
	if [[ $((bright)) -gt $((MAX_BRIGHTNESS)) ]]; then
		bright=$MAX_BRIGHTNESS
	fi
	echo $bright > ${BRIGHTNESS_PATH}brightness

elif [[ $1 == "down" ]]; then
	bright=$((ACTUAL_BRIGHTNESS - BRIGHTNESS_STEP))
	if [[ $((bright)) -lt 1212 ]]; then
		bright="1212"
	fi
	echo "$bright" > ${BRIGHTNESS_PATH}brightness
fi