#!/bin/bash
# ZUI Core Installation Script
# Sets up the core ZUI directory structure and common configurations

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

# Create ZUI directory structure
create_zui_structure() {
    log_info "Creating ZUI directory structure..."
    
    mkdir -p "${ZUI_PATH}"
    mkdir -p "${ZUI_PATH}/themes"
    mkdir -p "${ZUI_PATH}/common"
    mkdir -p "${ZUI_PATH}/shell"
    mkdir -p "${ZUI_PATH}/backups"
    mkdir -p "${CONFIG_PATH}"
    
    log_success "ZUI directory structure created"
}

# Copy common configurations
install_common_configs() {
    log_info "Installing common configurations..."
    
    # Check if config exists to preserve user settings
    if [[ -f "${ZUI_PATH}/common/system/config.yml" ]]; then
        log_info "Preserving existing system configuration"
        rsync -am --exclude='*config.yml' "${BASE_PATH}/common/" "${ZUI_PATH}/common/"
    else
        rsync -am "${BASE_PATH}/common/" "${ZUI_PATH}/common/"
    fi
    
    log_success "Common configurations installed"
}

# Configure system permissions
configure_permissions() {
    log_info "Configuring system permissions..."
    
    # Add user to video group for backlight control
    sudo usermod -a -G video "${USER}" || log_warn "Failed to add user to video group"
    
    # Configure backlight rules based on hardware
    if lspci | grep -qi 'amd'; then
        log_info "Detected AMD graphics, configuring AMD backlight rules"
        sudo cp "${BASE_PATH}/redist/root/amd-backlight.rules" /etc/udev/rules.d/70-backlight.rules || \
            log_warn "Failed to configure AMD backlight rules"
    elif lspci | grep -qi 'intel'; then
        log_info "Detected Intel graphics, configuring Intel backlight rules"
        sudo cp "${BASE_PATH}/redist/root/intel-backlight.rules" /etc/udev/rules.d/70-backlight.rules || \
            log_warn "Failed to configure Intel backlight rules"
    fi
    
    # Configure StreamDeck rules if present
    if [[ -f "${BASE_PATH}/redist/root/10-streamdeck.rules" ]]; then
        sudo cp "${BASE_PATH}/redist/root/10-streamdeck.rules" /etc/udev/rules.d/ || \
            log_warn "Failed to configure StreamDeck rules"
        sudo udevadm control --reload-rules || log_warn "Failed to reload udev rules"
    fi
    
    log_success "System permissions configured"
}

# Configure network triggers
configure_network_triggers() {
    log_info "Configuring network interface triggers..."
    
    # Create temporary trigger file with user substitution
    cp "${BASE_PATH}/redist/root/trigger-check-network" "${TMP_PATH}/trigger-check-network"
    sed -i "s/<user>/${USER}/g" "${TMP_PATH}/trigger-check-network"
    
    # Install network triggers
    sudo cp "${TMP_PATH}/trigger-check-network" /etc/network/if-up.d/ || \
        log_warn "Failed to install network up trigger"
    sudo cp "${TMP_PATH}/trigger-check-network" /etc/network/if-down.d/ || \
        log_warn "Failed to install network down trigger"
    sudo cp "${TMP_PATH}/trigger-check-network" /etc/network/if-post-down.d/ || \
        log_warn "Failed to install network post-down trigger"
    sudo cp "${TMP_PATH}/trigger-check-network" /etc/network/if-pre-up.d/ || \
        log_warn "Failed to install network pre-up trigger"
    
    log_success "Network triggers configured"
}

# Main installation function
main() {
    echo ""
    echo "====================="
    echo -e "${BLUE}ZUI Core Installation${NC}"
    echo "====================="
    echo ""

    mkdir -p "${TMP_PATH}"

    create_zui_structure
    install_common_configs
    # install_zui_utilities
    configure_permissions
    configure_network_triggers
    
    log_success "ZUI core installation completed!"
    log_info "ZUI installed to: ${ZUI_PATH}"
    log_info "Configuration directory: ${CONFIG_PATH}"
    echo ""
    log_info "Next steps:"
    log_info "- Install terminal configuration (optional): zui.sh install-terminal"
    log_info "- Install theme: zui.sh install-theme --theme <theme_name>"
}

# Run main function
main "$@"
