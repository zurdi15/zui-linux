#!/bin/bash
 
TARGET_FILE="$HOME/.config/polybar/scripts/custom/target_ip"

if [ ! -f $TARGET_FILE ]; then
    echo "%{F#a6493e} %{u-}%{F#ffffff}No target"
else
  ip_address=$(cat "$TARGET_FILE" | awk '{print $1}')
  machine_name=$(cat "$TARGET_FILE" | awk '{print $2}')
  if [ $ip_address ] && [ $machine_name ]; then
      echo "%{F#a6493e} %{F#ffffff}$ip_address%{u-} - $machine_name"
  else
      echo "%{F#a6493e} %{u-}%{F#ffffff}No target"
  fi
fi

