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
BASE_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ZUI_PATH=${ZUI_PATH:-${HOME}/.zui}
CONFIG_PATH=${CONFIG_PATH:-${HOME}/.config}

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

# Validate installation
validate_installation() {
    log_info "Validating ZUI installation..."
    
    local errors=0
    
    # Check ZUI directory structure
    if [[ ! -d "$ZUI_PATH" ]]; then
        log_error "ZUI directory not found: $ZUI_PATH"
        ((errors++))
    fi
    
    # Check current theme link
    if [[ ! -L "$ZUI_PATH/current_theme" ]]; then
        log_error "Current theme link not found: $ZUI_PATH/current_theme"
        ((errors++))
    fi
    
    # Check essential configs
    local essential_configs=("bspwm" "sxhkd")
    for config in "${essential_configs[@]}"; do
        if [[ ! -L "$CONFIG_PATH/$config" ]]; then
            log_error "Essential config link missing: $CONFIG_PATH/$config"
            ((errors++))
        fi
    done
    
    # Check utilities
    if [[ ! -x "$HOME/.local/bin/zui-theme" ]]; then
        log_warn "ZUI theme utility not found or not executable"
    fi
    
    if [[ $errors -eq 0 ]]; then
        log_success "Installation validation passed"
        return 0
    else
        log_error "Installation validation failed with $errors errors"
        return 1
    fi
}

# Update PATH for current session
update_path() {
    log_info "Updating PATH for current session..."
    
    # Add local bin to PATH if not already present
    if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
        export PATH="$HOME/.local/bin:$PATH"
        log_success "Added $HOME/.local/bin to PATH"
    fi
}

# Set executable permissions
set_permissions() {
    log_info "Setting executable permissions..."
    
    # Make ZUI utilities executable
    if [[ -d "$HOME/.local/bin" ]]; then
        find "$HOME/.local/bin" -name "zui-*" -exec chmod +x {} \; || \
            log_warn "Failed to set permissions for ZUI utilities"
    fi
    
    # Make polybar launch script executable
    if [[ -f "$ZUI_PATH/common/polybar/launch.sh" ]]; then
        chmod +x "$ZUI_PATH/common/polybar/launch.sh" || \
            log_warn "Failed to set permissions for polybar launch script"
    fi
    
    # Make system module scripts executable
    if [[ -d "$ZUI_PATH/common/system/modules" ]]; then
        find "$ZUI_PATH/common/system/modules" -name "*.sh" -exec chmod +x {} \; || \
            log_warn "Failed to set permissions for system modules"
    fi
    
    log_success "Executable permissions set"
}

# Create desktop entry for bspwm
create_desktop_entry() {
    log_info "Creating desktop entry for BSPWM..."
    
    local desktop_entry="/usr/share/xsessions/bspwm.desktop"
    local xsessions_dir="/usr/share/xsessions"
    
    # Create xsessions directory if it doesn't exist
    if [[ ! -d "$xsessions_dir" ]]; then
        if sudo mkdir -p "$xsessions_dir" 2>/dev/null; then
            log_info "Created xsessions directory"
        else
            log_warn "Cannot create xsessions directory, skipping desktop entry"
            return 0
        fi
    fi
    

#     window-manager
# preferences-desktop-display
# applications-system
# preferences-system


    if [[ ! -f "$desktop_entry" ]]; then
        if sudo tee "$desktop_entry" > /dev/null 2>&1 <<EOF; then
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
            log_success "Desktop entry created"
        else
            log_warn "Cannot create desktop entry (permission denied)"
        fi
    else
        log_info "Desktop entry already exists"
    fi
}

# Generate installation summary
generate_summary() {
    echo ""
    log_info "Installation Directory: $ZUI_PATH"
    log_info "Configuration Directory: $CONFIG_PATH"
    
    if [[ -L "$ZUI_PATH/current_theme" ]]; then
        local current_theme
        current_theme=$(readlink "$ZUI_PATH/current_theme" | xargs basename)
        log_info "Current Theme: $current_theme"
    fi
    
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
    echo "Utilities:"
    echo "  zui-theme           - Theme management"
    echo "  zui-wallpaper       - Wallpaper management"
    echo "  zui-reload          - Reload configuration"
    echo ""
    log_info "Next Steps:"
    log_info "- 1. Log out and log back in"
    log_info "- 2. Select 'bspwm' from your display manager"
    log_info "- 3. Log in to start using ZUI"
    
    # Check for potential issues
    if ! command -v bspwm &> /dev/null; then
        log_warn "⚠️  Warning: bspwm command not found in PATH"
    fi
    
    if [[ "$SHELL" != *"zsh" ]]; then
        log_warn "⚠️  Warning: Default shell is not zsh. Run 'chsh -s /usr/bin/zsh' to change it."
    fi
}

# Backup current configuration
create_backup() {
    log_info "Creating configuration backup..."
    
    local backup_dir="$ZUI_PATH/backups/$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"
    
    # List of configs to backup
    local configs_to_backup=(
        ".zshrc" ".p10k.zsh" ".vimrc" ".gitconfig"
        ".config/bspwm" ".config/sxhkd" ".config/polybar"
        ".config/rofi" ".config/dunst" ".config/picom"
    )
    
    for config in "${configs_to_backup[@]}"; do
        local config_path="$HOME/$config"
        if [[ -e "$config_path" ]] && [[ ! -L "$config_path" ]]; then
            cp -r "$config_path" "$backup_dir/" 2>/dev/null || \
                log_warn "Failed to backup $config"
        fi
    done
    
    if [[ -n "$(ls -A "$backup_dir" 2>/dev/null)" ]]; then
        log_success "Configuration backup created: $backup_dir"
        echo "BACKUP_DIR='$backup_dir'" > "$ZUI_PATH/.last_backup"
    else
        rmdir "$backup_dir" 2>/dev/null
        log_info "No existing configurations found to backup"
    fi
}

# Check system compatibility
check_compatibility() {
    log_info "Checking system compatibility..."
    
    local warnings=0
    
    # Check if running in X11
    if [[ -n "${WAYLAND_DISPLAY:-}" ]]; then
        log_warn "Wayland detected. ZUI is designed for X11 and may not work properly."
        warnings=$((warnings + 1))
    fi
    
    # Check display manager (allow command to fail)
    if ! systemctl is-active --quiet gdm lightdm sddm 2>/dev/null; then
        log_warn "No common display manager detected. You may need to configure session manually."
        warnings=$((warnings + 1))
    fi
    
    # Check for conflicting window managers
    local wm_processes=("i3" "awesome" "dwm" "xmonad" "openbox")
    for wm in "${wm_processes[@]}"; do
        if pgrep -x "$wm" > /dev/null 2>&1; then
            log_warn "Another window manager ($wm) is running. Please stop it before using ZUI."
            warnings=$((warnings + 1))
        fi
    done
    
    if [[ $warnings -eq 0 ]]; then
        log_success "System compatibility check passed"
    else
        log_warn "System compatibility check completed with $warnings warnings"
    fi
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
