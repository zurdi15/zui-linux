#!/bin/bash
# ZUI Post-Installation Script
# Performs final configuration and validation after installation

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
ZUI_PATH=${ZUI_PATH:-${HOME}/.zui}
CONFIG_PATH=${CONFIG_PATH:-${HOME}/.config}
TMP_PATH=${TMP_PATH:-/tmp/zui}
LOG_FILE="${TMP_PATH}/post_install.log"

# Ensure log directory exists
mkdir -p "${TMP_PATH}"

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a "${LOG_FILE}" 2>/dev/null || echo -e "${BLUE}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1" | tee -a "${LOG_FILE}" 2>/dev/null || echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "${LOG_FILE}" 2>/dev/null || echo -e "${RED}[ERROR]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "${LOG_FILE}" 2>/dev/null || echo -e "${GREEN}[SUCCESS]${NC} $1"
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

# Validate installation
validate_installation() {
    log_info "Validating ZUI installation"
    
    local errors=0
    
    # Check ZUI directory structure
    if ! run_with_progress "- Checking ZUI directory structure" test -d "${ZUI_PATH}"; then
        log_error "ZUI directory not found: ${ZUI_PATH}"
        ((errors++))
    fi
    
    # Check current theme link
    if ! run_with_progress "- Validating current theme symlink" test -L "${ZUI_PATH}/current_theme"; then
        log_warn "Current theme link not found: ${ZUI_PATH}/current_theme"
        ((errors++))
    fi
    
    # Check essential configs
    local essential_missing=0
    if [[ ! -L "${CONFIG_PATH}/bspwm" ]]; then
        log_error "Essential config link missing: ${CONFIG_PATH}/bspwm"
        essential_missing=1
    fi
    if [[ ! -L "${CONFIG_PATH}/sxhkd" ]]; then
        log_error "Essential config link missing: ${CONFIG_PATH}/sxhkd"
        essential_missing=1
    fi

    if [[ $essential_missing -eq 0 ]]; then
        if ! run_with_progress "- Validating essential configuration links" true; then
            log_error "Essential configuration links validation failed"
            ((errors++))
        fi
    else
        log_error "Essential configuration links missing"
        ((errors++))
    fi

    if [[ ${errors} -eq 0 ]]; then
        log_success "Installation validation passed"
        echo ""
        return 0
    else
        log_error "Installation validation failed with ${errors} errors"
        echo ""
        return 1
    fi
}

# Update PATH for current session
update_path() {
    log_info "Updating environment settings"
    
    # Add local bin to PATH if not already present
    if [[ ":${PATH}:" != *":${HOME}/.local/bin:"* ]]; then
        if ! run_with_progress "- Adding local bin to PATH" bash -c "export PATH='${HOME}/.local/bin:\${PATH}'"; then
            log_warn "Failed to update PATH"
        fi
    else
        log_info "- Local bin already in PATH"
    fi
    echo ""
}

# Set executable permissions
set_permissions() {
    log_info "Setting executable permissions"
    
    # Make polybar launch script executable
    if [[ -f "${ZUI_PATH}/core/polybar/launch.sh" ]]; then
        if ! run_with_progress "- Setting polybar launch script permissions" chmod +x "${ZUI_PATH}/core/polybar/launch.sh"; then
            log_warn "Failed to set permissions for polybar launch script"
        fi
    fi
    
    # Make system module scripts executable
    if [[ -d "${ZUI_PATH}/core/system/modules" ]]; then
        if ! run_with_progress "- Setting system module permissions" find "${ZUI_PATH}/core/system/modules" -name "*.sh" -exec chmod +x {} \;; then
            log_warn "Failed to set permissions for system modules"
        fi
    fi
    echo ""
}

# Create desktop entry for bspwm
create_desktop_entry() {
    log_info "Creating desktop session entry"
    
    local desktop_entry="/usr/share/xsessions/bspwm.desktop"
    local xsessions_dir="/usr/share/xsessions"
    
    # Create xsessions directory if it doesn't exist
    if [[ ! -d "${xsessions_dir}" ]]; then
        if ! run_with_progress "- Creating xsessions directory" sudo mkdir -p "${xsessions_dir}"; then
            log_warn "Cannot create xsessions directory, skipping desktop entry"
            echo ""
            return 0
        fi
    fi

    if [[ ! -f "${desktop_entry}" ]]; then
        if ! run_with_progress "- Creating bspwm desktop entry" sudo tee "${desktop_entry}" <<EOF; then
[Desktop Entry]
Name=bspwm
Comment=Binary space partitioning window manager
Exec=bspwm
TryExec=bspwm
Type=Application
Icon=preferences-system-windows
X-LightDM-DesktopName=bspwm
DesktopNames=bspwm
Keywords=tiling;wm;windowmanager;window;manager;
EOF
            log_warn "Cannot create desktop entry (permission denied)"
        fi
    else
        log_info "- Desktop entry already exists"
    fi
    echo ""
}

# Generate installation summary
generate_summary() {
    log_info "Installation completed successfully!"
    echo ""
    log_info "Installation Directory: ${ZUI_PATH}"
    log_info "Configuration Directory: ${CONFIG_PATH}"

    if [[ -L "${ZUI_PATH}/current_theme" ]]; then
        local current_theme
        current_theme=$(readlink "${ZUI_PATH}/current_theme" | xargs basename)
        log_info "Current Theme: ${current_theme}"
    fi
    
    echo ""
    log_info "Installation log: ${LOG_FILE}"
    echo ""
    echo "Key Shortcuts:"
    echo "  Super + Return       - Terminal"
    echo "  Super + D            - Application launcher"
    echo "  Super + Shift + D    - Command launcher"
    echo "  Super + X            - Window switcher"
    echo "  Super + Q            - Power menu"
    echo "  Super + L            - Lock screen"
    echo "  Super + N            - Network menu"
    echo "  Super + (num)        - Switch to workspace (num)"
    echo ""
    log_info "Next Steps:"
    log_info "- 1. Log out and log back in"
    log_info "- 2. Select 'bspwm' from your display manager"
    log_info "- 3. Log in to start using ZUI"
    
    # Check for potential issues
    if ! command -v bspwm &> /dev/null; then
        log_warn "⚠️  Warning: bspwm command not found in PATH"
    fi

    if [[ "${SHELL}" != *"zsh" ]]; then
        log_warn "⚠️  Warning: Default shell is not zsh. Run 'chsh -s /usr/bin/zsh' to change it."
    fi
}

# Backup current configuration
create_backup() {
    log_info "Creating configuration backup"

    local backup_dir="${ZUI_PATH}/backups/$(date +%Y%m%d_%H%M%S)"
    
    if ! run_with_progress "- Creating backup directory" mkdir -p "${backup_dir}"; then
        log_warn "Failed to create backup directory"
        echo ""
        return 1
    fi
    
    # Backup configurations
    if ! run_with_progress "- Backing up existing configurations" bash -c "
        configs_to_backup=('.zshrc' '.p10k.zsh' '.vimrc' '.gitconfig' '.config/bspwm' '.config/sxhkd' '.config/polybar' '.config/rofi' '.config/dunst' '.config/picom')
        backed_up=0
        for config in \"\${configs_to_backup[@]}\"; do
            config_path='${HOME}/\${config}'
            if [[ -e \"\${config_path}\" ]] && [[ ! -L \"\${config_path}\" ]]; then
                if cp -r \"\${config_path}\" '${backup_dir}/' 2>/dev/null; then
                    backed_up=1
                fi
            fi
        done
        exit \$backed_up
    "; then
        echo "BACKUP_DIR='${backup_dir}'" > "${ZUI_PATH}/.last_backup"
    else
        rmdir "${backup_dir}" 2>/dev/null || true
        log_info "- No existing configurations found to backup"
    fi
    echo ""
}

# Check system compatibility
check_compatibility() {
    log_info "Checking system compatibility"
    
    local warnings=0
    
    # Check if running in X11
    if [[ -n "${WAYLAND_DISPLAY:-}" ]]; then
        log_warn "- Wayland detected. ZUI is designed for X11 and may not work properly"
        warnings=$((warnings + 1))
    else
        log_info "- X11 environment detected"
    fi
    
    # Check display manager
    if ! run_with_progress "- Checking display manager" bash -c "systemctl is-active --quiet gdm lightdm sddm 2>/dev/null"; then
        log_warn "- No common display manager detected. You may need to configure session manually"
        warnings=$((warnings + 1))
    fi
    
    # Check for conflicting window managers
    if ! run_with_progress "- Checking for conflicting window managers" bash -c "
        wm_processes=('i3' 'awesome' 'dwm' 'xmonad' 'openbox')
        for wm in \"\${wm_processes[@]}\"; do
            if pgrep -x \"\${wm}\" > /dev/null 2>&1; then
                echo \"Another window manager (\${wm}) is running. Please stop it before using ZUI.\" >&2
                exit 1
            fi
        done
    "; then
        log_warn "- Conflicting window manager detected"
        warnings=$((warnings + 1))
    fi

    if [[ ${warnings} -eq 0 ]]; then
        log_success "System compatibility check passed"
    else
        log_warn "System compatibility check completed with ${warnings} warnings"
    fi
    echo ""
}

# Main post-installation function
main() {
    echo ""
    echo "====================="
    echo -e "${BLUE}ZUI Post Installation${NC}"
    echo "====================="
    echo ""
    
    # Run post-installation tasks
    create_backup
    validate_installation || {
        log_error "Installation validation failed. Please check the installation."
        exit 1
    }
    update_path
    set_permissions
    create_desktop_entry
    check_compatibility
    generate_summary
}

# Run main function
main "$@"
