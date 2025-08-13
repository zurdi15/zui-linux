#!/bin/bash
# ZUI Theme Installation Script
# Installs and configures a specific theme

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
LOG_FILE=${LOG_FILE:-/tmp/zui_theme_install.log}

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

# Validate theme
validate_theme() {
    local theme="$1"
    
    if [[ -z "${theme}" ]]; then
        log_error "No theme specified"
        return 1
    fi
    
    if [[ ! -d "${BASE_PATH}/themes/${theme}" ]]; then
        log_error "Theme '${theme}' not found in ${BASE_PATH}/themes/"
        log_info "Available themes:"
        for entry in "${BASE_PATH}/themes"/*; do
            [[ -d "${entry}" || -f "${entry}" ]] && [[ "$(basename "${entry}")" != .* ]] && echo "  - $(basename "${entry}")"
        done
        return 1
    fi
    
    log_info "Theme '${theme}' validated"
    return 0
}

# Copy theme files
copy_theme_files() {
    local theme="$1"
    
    log_info "Copying theme files for '${theme}'..."
    
    # Create theme directory
    mkdir -p "${ZUI_PATH}/themes/${theme}"
    
    # Copy theme files
    rsync -am "${BASE_PATH}/themes/${theme}/" "${ZUI_PATH}/themes/${theme}/" || {
        log_error "Failed to copy theme files"
        return 1
    }
    
    log_success "Theme files copied"
}

# Create theme symlinks
create_theme_symlinks() {
    local theme="$1"
    
    log_info "Creating theme symlinks..."
    
    # Link current theme
    ln -sfn "${ZUI_PATH}/themes/${theme}" "${ZUI_PATH}/current_theme"
    
    # Link current wallpaper
    if [[ -f "${ZUI_PATH}/current_theme/wallpapers/default" ]]; then
        ln -sfn "${ZUI_PATH}/current_theme/wallpapers/default" \
                "${ZUI_PATH}/current_theme/wallpapers/current_wallpaper"
    elif [[ -d "${ZUI_PATH}/current_theme/wallpapers" ]]; then
        # Find first wallpaper file if default doesn't exist
        local wallpaper
        wallpaper=$(find "${ZUI_PATH}/current_theme/wallpapers" -type f \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" \) | head -n1)
        if [[ -n "${wallpaper}" ]]; then
            ln -sfn "${wallpaper}" "${ZUI_PATH}/current_theme/wallpapers/current_wallpaper"
        fi
    fi
    
    log_success "Theme symlinks created"
}

# Configure application symlinks
configure_app_symlinks() {
    local theme="$1"
    
    log_info "Configuring application symlinks..."
    
    # Remove existing config links
    local configs=(
        "bspwm" "rofi" "dunst" "gtk-3.0" "gtk-4.0"
        "lsd" "nvim" "picom" "polybar" "sublime-text" "sxhkd"
    )
    
    for config in "${configs[@]}"; do
        if [[ -L "${CONFIG_PATH}/${config}" ]] || [[ -d "${CONFIG_PATH}/${config}" ]]; then
            rm -rf "${CONFIG_PATH:?}/${config}"
        fi
    done
    
    # Create new symlinks
    # bspwm
    ln -sfn "${ZUI_PATH}/common/bspwm" "${CONFIG_PATH}/bspwm"

    # rofi - need to link themes first
    ln -sfn "${ZUI_PATH}/current_theme/rofi" "${CONFIG_PATH}/rofi"
    
    # dunst
    if [[ -d "${ZUI_PATH}/current_theme/dunst" ]]; then
        ln -sfn "${ZUI_PATH}/current_theme/dunst" "${CONFIG_PATH}/dunst"
    fi
    
    # GTK
    if [[ -d "${ZUI_PATH}/current_theme/gtk-3.0" ]]; then
        ln -sfn "${ZUI_PATH}/current_theme/gtk-3.0" "${CONFIG_PATH}/gtk-3.0"
    fi
    if [[ -d "${ZUI_PATH}/current_theme/gtk-4.0" ]]; then
        ln -sfn "${ZUI_PATH}/current_theme/gtk-4.0" "${CONFIG_PATH}/gtk-4.0"
    fi
    
    # lsd
    if [[ -d "${ZUI_PATH}/current_theme/lsd" ]]; then
        ln -sfn "${ZUI_PATH}/current_theme/lsd" "${CONFIG_PATH}/lsd"
    fi
    
    # nvim
    if [[ -d "${ZUI_PATH}/current_theme/nvim" ]]; then
        ln -sfn "${ZUI_PATH}/current_theme/nvim" "${CONFIG_PATH}/nvim"
    fi
    
    # picom
    if [[ -d "${ZUI_PATH}/current_theme/picom" ]]; then
        ln -sfn "${ZUI_PATH}/current_theme/picom" "${CONFIG_PATH}/picom"
    fi
    
    # polybar - link individual files for flexibility
    if [[ -d "${ZUI_PATH}/current_theme/polybar" ]]; then
        local polybar_files=("launch.sh" "colors.ini" "main_bar.ini" "top_bars.ini" "bottom_bars.ini")
        for file in "${polybar_files[@]}"; do
            if [[ -f "${ZUI_PATH}/current_theme/polybar/${file}" ]]; then
                ln -sfn "${ZUI_PATH}/current_theme/polybar/${file}" "${ZUI_PATH}/common/polybar/${file}"
            fi
        done
    fi
    ln -sfn "${ZUI_PATH}/common/polybar" "${CONFIG_PATH}/polybar"
    
    # sublime-text
    if [[ -d "${ZUI_PATH}/current_theme/sublime-text" ]]; then
        ln -sfn "${ZUI_PATH}/current_theme/sublime-text" "${CONFIG_PATH}/sublime-text"
    fi
    
    # sxhkd
    ln -sfn "${ZUI_PATH}/common/sxhkd" "${CONFIG_PATH}/sxhkd"
    
    log_success "Application symlinks configured"
}

# Configure home directory files
configure_home_files() {
    local theme="$1"
    
    log_info "Configuring home directory files..."
    
    # zshrc configuration (only if terminal is not configured separately)
    if [[ -f "${ZUI_PATH}/current_theme/.zshrc" && ! -f "${ZUI_PATH}/shell/.zshrc" ]]; then
        ln -sfn "${ZUI_PATH}/current_theme/.zshrc" "${HOME}/.zshrc"
        # Also link for root
        sudo ln -sfn "/home/${USER}/.zshrc" /root/.zshrc || \
            log_warn "Failed to link zshrc for root"
    fi
    
    log_success "Home directory files configured"
}

# Install theme resources
install_theme_resources() {
    local theme="$1"
    
    log_info "Installing theme resources..."
    
    # Install fonts
    if command -v fc-cache &> /dev/null; then
        fc-cache -v > /dev/null 2>&1 || log_warn "Failed to refresh font cache"
    fi
    
    # Install themes
    if [[ -d "${ZUI_PATH}/current_theme/.themes" ]]; then
        rsync -am "${ZUI_PATH}/current_theme/.themes/" "${HOME}/.themes/" || \
            log_warn "Failed to install GTK themes"
    fi
    
    # Install local resources
    if [[ -d "${ZUI_PATH}/current_theme/.local" ]]; then
        rsync -am "${ZUI_PATH}/current_theme/.local/" "${HOME}/.local/" || \
            log_warn "Failed to install local resources"
    fi
    
    # Install icons
    if [[ -d "${ZUI_PATH}/common/.icons" ]]; then
        sudo rsync -am "${ZUI_PATH}/common/.icons/" "${HOME}/.icons/" || \
            log_warn "Failed to install icons"
    fi
    
    log_success "Theme resources installed"
}

# Configure hardware-specific settings
configure_hardware_specific() {
    local theme="$1"
    
    log_info "Configuring hardware-specific settings..."
    
    # Configure backlight for polybar based on GPU
    if [[ -f "${ZUI_PATH}/current_theme/polybar/bottom_bars.ini" ]]; then
        if lspci | grep -qi 'amd'; then
            sed -i 's/intel_backlight/amdgpu_bl0/g' "${ZUI_PATH}/current_theme/polybar/bottom_bars.ini" || \
                log_warn "Failed to configure AMD backlight in polybar"
        fi
    fi
    
    log_success "Hardware-specific settings configured"
}

# Run theme-specific installation
run_theme_install() {
    local theme="$1"
    
    log_info "Running theme-specific installation..."
    
    if [[ -f "${BASE_PATH}/themes/${theme}/install" ]]; then
        log_info "Executing theme install script..."
        bash "${BASE_PATH}/themes/${theme}/install" || \
            log_warn "Theme install script failed"
    else
        log_info "No theme-specific install script found"
    fi
    
    log_success "Theme-specific installation completed"
}

# Install neovim plugins
install_neovim_plugins() {
    log_info "Installing neovim plugins..."
    
    if command -v nvim &> /dev/null; then
        nvim +PlugInstall +qall || log_warn "Failed to install neovim plugins"
    else
        log_warn "Neovim not found, skipping plugin installation"
    fi
    
    log_success "Neovim plugins installation completed"
}

reload_bspwm() {
    if [[ -f "${HOME}/.config/bspwm/bspwmrc" ]]; then
        bash "${HOME}/.config/bspwm/bspwmrc" >> "${LOG_FILE}" 2>&1
    fi
}

# Main installation function
main() {
    local theme="${1:-}"
    
    echo ""
    echo "======================"
    echo -e "${BLUE}ZUI Theme Installation${NC}"
    echo "======================"
    echo ""

    # Validate theme
    validate_theme "${theme}"
    
    # Install theme
    copy_theme_files "${theme}"
    create_theme_symlinks "${theme}"
    configure_app_symlinks "${theme}"
    configure_home_files "${theme}"
    install_theme_resources "${theme}"
    configure_hardware_specific "${theme}"
    run_theme_install "${theme}"
    install_neovim_plugins

    # Reload bspwm to apply theme
    reload_bspwm

    log_success "Theme '${theme}' installed successfully!"
    log_info "Current theme: ${theme}"
    log_info "You may need to reload your shell or log out/in for all changes to take effect."
    echo ""
    log_info "Next steps:"
    log_info "- Post Install: zui.sh post-install"
}

# Show usage if no arguments
if [[ $# -eq 0 ]]; then
    echo "Usage: $0 <theme_name>"
    echo ""
    echo "Available themes:"
    if [[ -d "${BASE_PATH}/themes" ]]; then
        for entry in "${BASE_PATH}/themes"/*; do
            [[ -d "${entry}" || -f "${entry}" ]] && [[ "$(basename "${entry}")" != .* ]] && echo "  - $(basename "${entry}")"
        done
    else
        echo "  No themes found"
    fi
    exit 1
fi

# Run main function
main "$@"
