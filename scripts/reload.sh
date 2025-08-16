#!/bin/bash
# ZUI reload
# Reloads the current configuration

set -euo pipefail

# Configuration
BASE_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_PATH=${TMP_PATH:-/tmp/zui}
LOG_FILE="${TMP_PATH}/install_theme.log"

# Ensure log directory exists
mkdir -p "${TMP_PATH}"

# Imports
source "${BASE_PATH}/scripts/functions/logger.sh"
source "${BASE_PATH}/scripts/functions/colors.sh"
source "${BASE_PATH}/scripts/functions/command_utils.sh"

reload() {
    log_info "Reloading ZUI configuration"
    
    if [[ -f "${HOME}/.config/bspwm/bspwmrc" ]]; then
        if ! run_with_progress "- Reloading bspwm configuration" bash "${HOME}/.config/bspwm/bspwmrc"; then
            log_warn "Failed to reload bspwm configuration"
        fi
    fi
    if pgrep -x "dunst" > /dev/null; then
        if ! run_with_progress "- Restarting dunst daemon" bash -c "pkill -x dunst && sleep 0.5 && dunst &"; then
            log_warn "Failed to restart dunst daemon"
        fi
    else
        # Start dunst if not running
        if ! run_with_progress "- Starting dunst daemon" bash -c "dunst &"; then
            log_warn "Failed to start dunst daemon"
        fi
    fi
    echo ""
}

# Main installation function
main() {
    echo -e "${CYAN}╭─────────────────────────────────────────────────────────╮${NC}"
    echo -e "${CYAN}│                ${GREEN}ZUI reload configuration${CYAN}                 │${NC}"
    echo -e "${CYAN}╰─────────────────────────────────────────────────────────╯${NC}"

    reload
}

# Run main function
main "$@"
