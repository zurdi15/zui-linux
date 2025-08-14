#!/bin/bash
# ZUI Core Installation Script
# Sets up the ZUI directory structure and core components

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
BASE_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ZUI_PATH=${ZUI_PATH:-${HOME}/.zui}
CONFIG_PATH=${CONFIG_PATH:-${HOME}/.config}
TMP_PATH=${TMP_PATH:-/tmp/zui}
LOG_FILE="${TMP_PATH}/install_core.log"

# Ensure log directory exists
mkdir -p "${TMP_PATH}"

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Progress indicator
show_progress() {
    local pid=$1
    local message="$2"
    local spinner='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    local i=0

    echo -ne "${BLUE}[INFO]${NC} ${message} "
    while kill -0 "${pid}" 2>/dev/null; do
        printf "${spinner:$i:1}"
        sleep 0.1
        printf "\b"
        i=$(( (i+1) % ${#spinner} ))
    done
    echo -e "${GREEN}✓${NC}"
}

# Silent command execution with progress
run_with_progress() {
    local message="$1"
    shift

    # For sudo commands, ensure credentials are fresh
    if [[ "$1" == "sudo" ]]; then
        sudo -v 2>/dev/null || true
    fi

    # Run command in background and capture output
    "$@" >> "${LOG_FILE}" 2>&1 &
    local pid=$!

    show_progress "${pid}" "${message}"

    # Wait for completion and check exit code
    wait "${pid}"
    return $?
}

# Ensure sudo credentials are cached
authenticate_sudo() {
    # Test sudo access and cache credentials
    if ! sudo -v; then
        log_error "Failed to authenticate sudo access"
        exit 1
    fi
}

create_zui_structure() {
    log_info "Creating ZUI folder structure"

    if ! run_with_progress "- Creating themes directory" mkdir -p "${ZUI_PATH}/themes"; then
        log_error "Failed to create ZUI directory structure"
        exit 1
    fi
    if ! run_with_progress "- Creating core directory" mkdir -p "${ZUI_PATH}/core"; then
        log_error "Failed to create ZUI directory structure"
        exit 1
    fi
    if ! run_with_progress "- Creating shell directory" mkdir -p "${ZUI_PATH}/shell"; then
        log_error "Failed to create ZUI directory structure"
        exit 1
    fi
    if ! run_with_progress "- Creating backups directory" mkdir -p "${ZUI_PATH}/backups"; then
        log_error "Failed to create ZUI directory structure"
        exit 1
    fi
    if ! run_with_progress "- Creating config directory" mkdir -p "${CONFIG_PATH}"; then
        log_error "Failed to create ZUI directory structure"
        exit 1
    fi
    echo ""
}

install_core_components() {
    log_info "Installing ZUI core components"
    # Check if config exists to preserve user settings
    if [[ -f "${ZUI_PATH}/core/system/config.yml" ]]; then
        if ! run_with_progress "- Installing core components preserving existing configuration" rsync -am --exclude='*config.yml' "${BASE_PATH}/core/" "${ZUI_PATH}/core/"; then
            log_error "Failed to install core components"
            exit 1
        fi
    else
        if ! run_with_progress "- Installing core components" rsync -am "${BASE_PATH}/core/" "${ZUI_PATH}/core/"; then
            log_error "Failed to install core components"
            exit 1
        fi
    fi

    # Add user to video group for backlight control
    if ! run_with_progress "- Adding user to video group for backlight control" sudo usermod -a -G video "${USER}"; then
        log_warn "Failed to add user to video group"
    fi
    
    # Configure backlight rules based on hardware
    if lspci | grep -qi 'amd'; then
        if ! run_with_progress "- Configuring AMD backlight rules" sudo cp "${BASE_PATH}/core/system/modules/backlight/amd-backlight.rules" /etc/udev/rules.d/70-backlight.rules; then
            log_warn "Failed to configure AMD backlight rules"
        fi
    elif lspci | grep -qi 'intel'; then
        if ! run_with_progress "- Configuring Intel backlight rules" sudo cp "${BASE_PATH}/core/system/modules/backlight/intel-backlight.rules" /etc/udev/rules.d/70-backlight.rules; then
            log_warn "Failed to configure Intel backlight rules"
        fi
    fi
    echo ""
}

# Configure network triggers
configure_network_triggers() {
    log_info "Configuring network triggers"
    # Create temporary trigger file with user substitution
    if ! run_with_progress "- Creating network trigger configuration" sh -c "cp '${BASE_PATH}/core/system/modules/network/trigger-check-network' '${TMP_PATH}/trigger-check-network' && sed -i 's/<user>/${USER}/g' '${TMP_PATH}/trigger-check-network'"; then
        log_error "Failed to create network trigger configuration"
        return 1
    fi
    
    # Install network triggers
    if ! run_with_progress "- Installing network up trigger" sudo ln -snf "${TMP_PATH}/trigger-check-network" /etc/network/if-up.d/trigger-check-network; then
        log_warn "Failed to install network up trigger"
    fi

    if ! run_with_progress "- Installing network down trigger" sudo ln -snf "${TMP_PATH}/trigger-check-network" /etc/network/if-down.d/trigger-check-network; then
        log_warn "Failed to install network down trigger"
    fi

    if ! run_with_progress "- Installing network post-down trigger" sudo ln -snf "${TMP_PATH}/trigger-check-network" /etc/network/if-post-down.d/trigger-check-network; then
        log_warn "Failed to install network post-down trigger"
    fi

    if ! run_with_progress "- Installing network pre-up trigger" sudo ln -snf "${TMP_PATH}/trigger-check-network" /etc/network/if-pre-up.d/trigger-check-network; then
        log_warn "Failed to install network pre-up trigger"
    fi
    echo ""
}

# Main installation function
main() {
    echo ""
    echo "====================="
    echo -e "${BLUE}ZUI Core Installation${NC}"
    echo "====================="
    echo ""

    authenticate_sudo

    create_zui_structure
    install_core_components
    configure_network_triggers

    echo ""
    log_info "ZUI installed to: ${ZUI_PATH}"
    log_info "Configuration directory: ${CONFIG_PATH}"
    echo ""
    log_info "Next steps:"
    log_info "- Install terminal configuration (optional): zui.sh install-terminal"
    log_info "- Install theme: zui.sh install-theme --theme <theme_name>"
}

# Run main function
main "$@"
