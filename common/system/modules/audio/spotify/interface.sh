#!/bin/bash

# see man zscroll for documentation of the following parameters
zscroll -l 33 \
        --delay 0.1 \
        --scroll-padding " - " \
        --match-command "$(dirname $0)/core.sh --status" \
        --match-text "Playing" "--scroll 1" \
        --match-text "Paused" "--scroll 0" \
        --match-text "Paused" "--scroll 1" \
        --update-check true "$(dirname $0)/core.sh" &
wait

