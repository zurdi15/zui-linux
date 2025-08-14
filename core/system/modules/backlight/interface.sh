#!/usr/bin/env bash

# Find the first available backlight device
BRIGHTNESS_DEVICE=$(ls /sys/class/backlight/ | head -1)
if [[ -z "$BRIGHTNESS_DEVICE" ]]; then
    echo "No backlight device found"
    exit 1
fi

BRIGHTNESS_PATH="/sys/class/backlight/${BRIGHTNESS_DEVICE}/"
MAX_BRIGHTNESS=$(cat ${BRIGHTNESS_PATH}max_brightness)
ACTUAL_BRIGHTNESS=$(cat ${BRIGHTNESS_PATH}brightness)
# Calculate 10% of max brightness as step
BRIGHTNESS_STEP=$((MAX_BRIGHTNESS / 10))
# Ensure minimum step of 1
if [[ $BRIGHTNESS_STEP -lt 1 ]]; then
    BRIGHTNESS_STEP=1
fi
MIN_BRIGHTNESS=$((MAX_BRIGHTNESS / 20))  # 5% minimum
if [[ $MIN_BRIGHTNESS -lt 1 ]]; then
    MIN_BRIGHTNESS=1
fi

if [[ $1 == "up" ]]; then
	bright=$((ACTUAL_BRIGHTNESS + BRIGHTNESS_STEP))
	if [[ $((bright)) -gt $((MAX_BRIGHTNESS)) ]]; then
		bright=$MAX_BRIGHTNESS
	fi
	echo $bright > ${BRIGHTNESS_PATH}brightness

elif [[ $1 == "down" ]]; then
	bright=$((ACTUAL_BRIGHTNESS - BRIGHTNESS_STEP))
	if [[ $((bright)) -lt $MIN_BRIGHTNESS ]]; then
		bright=$MIN_BRIGHTNESS
	fi
	echo "$bright" > ${BRIGHTNESS_PATH}brightness
fi