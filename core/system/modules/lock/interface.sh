#!/bin/sh

alpha='dd'
inside='#d8dee9'
separator='#eceff4'
wrong='#bf616a'
keyhl='#4c566a'
bshl='#d08770'
ring='#2e3440'
verif='#a3be8c'

i3lock \
  --inside-color=$inside$alpha \
  --insidever-color=$inside$alpha \
  --insidewrong-color=$inside$alpha \
  --ring-color=$ring$alpha \
  --ringver-color=$verif$alpha \
  --ringwrong-color=$wrong$alpha \
  --line-uses-ring \
  --keyhl-color=$keyhl$alpha \
  --bshl-color=$bshl$alpha \
  --separator-color=$separator$alpha \
  --verif-color=$verif \
  --verifoutline-color=$ring \
  --verifoutline-width=0.8 \
  --wrong-color=$wrong \
  --wrongoutline-color=$ring \
  --wrongoutline-width=0.8 \
  --layout-color=$ring \
  --date-color=$ring \
  --time-color=$ring \
  --screen 1 \
  --blur 1 \
  --clock \
  --indicator \
  --time-str="%H:%M:%S" \
  --date-str="%a %b %e %Y" \
  --verif-text="..." \
  --wrong-text="" \
  --noinput="" \
  --lock-text="..." \
  --lockfailed=" !" \
  --time-font="Iosevka Nerd Font" \
  --time-size=36 \
  --date-font="Iosevka Nerd Font" \
  --date-size=22 \
  --layout-font="Iosevka Nerd Font" \
  --verif-font="Iosevka Nerd Font" \
  --verif-size=65 \
  --wrong-font="Iosevka Nerd Font" \
  --wrong-size=65 \
  --radius=110 \
  --ring-width=10 \
  --pass-media-keys \
  --pass-screen-keys \
  --pass-volume-keys \