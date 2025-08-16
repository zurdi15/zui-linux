#!/bin/bash
# ZUI Theme Installation Script
# Installs and configures a specific theme

set -euo pipefail

# Configuration
BASE_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ZUI_PATH=${ZUI_PATH:-${HOME}/.zui}
CONFIG_PATH=${CONFIG_PATH:-${HOME}/.config}
TMP_PATH=${TMP_PATH:-/tmp/zui}
LOG_FILE="${TMP_PATH}/install_theme.log"

# Ensure log directory exists
mkdir -p "${TMP_PATH}"

# Imports
source "${BASE_PATH}/scripts/functions/logger.sh"
source "${BASE_PATH}/scripts/functions/colors.sh"
source "${BASE_PATH}/scripts/functions/command_utils.sh"

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
}

# Copy theme files
copy_theme_files() {
    local theme="$1"
    
    log_info "Setting up theme files"
    
    # Create theme directory and copy files
    if ! run_with_progress "- Creating theme directory and copying files" bash -c "mkdir -p '${ZUI_PATH}/themes/${theme}' && rsync -am '${BASE_PATH}/themes/${theme}/' '${ZUI_PATH}/themes/${theme}/'"; then
        log_error "Failed to copy theme files"
        return 1
    fi
    echo ""
}

# Create theme symlinks
create_theme_symlinks() {
    local theme="$1"
    
    log_info "Creating theme symlinks"
    
    # Link current theme
    if ! run_with_progress "- Creating current theme symlink" ln -sfn "${ZUI_PATH}/themes/${theme}" "${ZUI_PATH}/current_theme"; then
        log_warn "Failed to create current theme symlink"
    fi
    
    # Link current wallpaper
    if [[ -f "${ZUI_PATH}/current_theme/wallpapers/default" ]]; then
        if ! run_with_progress "- Creating wallpaper symlink" ln -sfn "${ZUI_PATH}/current_theme/wallpapers/default" "${ZUI_PATH}/current_theme/wallpapers/current_wallpaper"; then
            log_warn "Failed to create wallpaper symlink"
        fi
    elif [[ -d "${ZUI_PATH}/current_theme/wallpapers" ]]; then
        # Find first wallpaper file if default doesn't exist
        local wallpaper
        wallpaper=$(find "${ZUI_PATH}/current_theme/wallpapers" -type f \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" \) | head -n1)
        if [[ -n "${wallpaper}" ]]; then
            if ! run_with_progress "- Creating fallback wallpaper symlink" ln -sfn "${wallpaper}" "${ZUI_PATH}/current_theme/wallpapers/current_wallpaper"; then
                log_warn "Failed to create fallback wallpaper symlink"
            fi
        fi
    fi
    echo ""
}

# Configure application symlinks
configure_app_symlinks() {
    local theme="$1"
    
    log_info "Configuring application symlinks"
    
    # Remove existing config links
    if ! run_with_progress "- Removing existing configuration links" bash -c "
        configs=('bspwm' 'rofi' 'dunst' 'gtk-3.0' 'gtk-4.0' 'lsd' 'nvim' 'picom' 'polybar' 'sublime-text' 'sxhkd')
        for config in \"\${configs[@]}\"; do
            if [[ -L '${CONFIG_PATH}/\${config}' ]] || [[ -d '${CONFIG_PATH}/\${config}' ]]; then
                rm -rf '${CONFIG_PATH}/\${config}'
            fi
        done
    "; then
        log_warn "Failed to remove some existing configuration links"
    fi
    
    # Create new symlinks
    if ! run_with_progress "- Creating core application symlinks" bash -c "
        # bspwm and sxhkd (core components)
        ln -sfn '${ZUI_PATH}/core/bspwm' '${CONFIG_PATH}/bspwm'
        ln -sfn '${ZUI_PATH}/core/sxhkd' '${CONFIG_PATH}/sxhkd'
        
        # rofi
        ln -sfn '${ZUI_PATH}/current_theme/rofi' '${CONFIG_PATH}/rofi'
    "; then
        log_warn "Failed to create some core application symlinks"
    fi
    
    # Theme-specific symlinks
    if [[ -d "${ZUI_PATH}/current_theme/dunst" ]]; then
        if ! run_with_progress "- Creating dunst symlink" ln -sfn "${ZUI_PATH}/current_theme/dunst" "${CONFIG_PATH}/dunst"; then
            log_warn "Failed to create dunst symlink"
        fi
    fi
    
    if [[ -d "${ZUI_PATH}/current_theme/gtk-3.0" ]]; then
        if ! run_with_progress "- Creating GTK 3.0 symlink" ln -sfn "${ZUI_PATH}/current_theme/gtk-3.0" "${CONFIG_PATH}/gtk-3.0"; then
            log_warn "Failed to create GTK 3.0 symlink"
        fi
    fi
    
    if [[ -d "${ZUI_PATH}/current_theme/gtk-4.0" ]]; then
        if ! run_with_progress "- Creating GTK 4.0 symlink" ln -sfn "${ZUI_PATH}/current_theme/gtk-4.0" "${CONFIG_PATH}/gtk-4.0"; then
            log_warn "Failed to create GTK 4.0 symlink"
        fi
    fi
    
    if [[ -d "${ZUI_PATH}/current_theme/lsd" ]]; then
        if ! run_with_progress "- Creating lsd symlink" ln -sfn "${ZUI_PATH}/current_theme/lsd" "${CONFIG_PATH}/lsd"; then
            log_warn "Failed to create lsd symlink"
        fi
    fi
    
    if [[ -d "${ZUI_PATH}/current_theme/nvim" ]]; then
        if ! run_with_progress "- Creating neovim symlink" ln -sfn "${ZUI_PATH}/current_theme/nvim" "${CONFIG_PATH}/nvim"; then
            log_warn "Failed to create neovim symlink"
        fi
    fi
    
    if [[ -d "${ZUI_PATH}/current_theme/picom" ]]; then
        if ! run_with_progress "- Creating picom symlink" ln -sfn "${ZUI_PATH}/current_theme/picom" "${CONFIG_PATH}/picom"; then
            log_warn "Failed to create picom symlink"
        fi
    fi
    
    if [[ -d "${ZUI_PATH}/current_theme/sublime-text" ]]; then
        if ! run_with_progress "- Creating sublime-text symlink" ln -sfn "${ZUI_PATH}/current_theme/sublime-text" "${CONFIG_PATH}/sublime-text"; then
            log_warn "Failed to create sublime-text symlink"
        fi
    fi
    
    # polybar (special handling)
    if [[ -d "${ZUI_PATH}/current_theme/polybar" ]]; then
        local polybar_files=("launch.sh" "colors.ini" "main_bar.ini" "top_bars.ini" "bottom_bars.ini")
        for file in "${polybar_files[@]}"; do
            if [[ -f "${ZUI_PATH}/current_theme/polybar/${file}" ]]; then
                if ! run_with_progress "- Creating polybar ${file} symlink" ln -sfn "${ZUI_PATH}/current_theme/polybar/${file}" "${ZUI_PATH}/core/polybar/${file}"; then
                    log_warn "Failed to create polybar ${file} symlink"
                fi
            fi
        done
    fi
    
    if ! run_with_progress "- Creating polybar config symlink" ln -sfn "${ZUI_PATH}/core/polybar" "${CONFIG_PATH}/polybar"; then
        log_warn "Failed to create polybar config symlink"
    fi
    echo ""
}

# Configure home directory files
configure_home_files() {
    local theme="$1"
    
    log_info "Configuring home directory files"
    
    # zshrc configuration (only if shell is not configured separately)
    if [[ -f "${ZUI_PATH}/current_theme/.zshrc" && ! -f "${ZUI_PATH}/shell/.zshrc" ]]; then
        if ! run_with_progress "- Creating zshrc symlinks" bash -c "ln -sfn '${ZUI_PATH}/current_theme/.zshrc' '${HOME}/.zshrc' && sudo ln -sfn '/home/${USER}/.zshrc' /root/.zshrc"; then
            log_warn "Failed to create zshrc symlinks"
        fi
    fi
    echo ""
}

# Install theme resources
install_theme_resources() {
    local theme="$1"
    
    log_info "Installing theme resources"
    
    # Install fonts and refresh cache
    if command -v fc-cache &> /dev/null; then
        if ! run_with_progress "- Refreshing font cache" fc-cache -v; then
            log_warn "Failed to refresh font cache"
        fi
    fi
    
    # Install GTK themes
    if [[ -d "${ZUI_PATH}/core/.themes" ]]; then
        if ! run_with_progress "- Installing GTK themes" rsync -am "${ZUI_PATH}/core/.themes/" "${HOME}/.themes/"; then
            log_warn "Failed to install GTK themes"
        fi
    fi
    
    # Install local resources
    if [[ -d "${ZUI_PATH}/core/.local" ]]; then
        if ! run_with_progress "- Installing local resources" rsync -am "${ZUI_PATH}/core/.local/" "${HOME}/.local/"; then
            log_warn "Failed to install local resources"
        fi
    fi
    
    # Install icons
    if [[ -d "${ZUI_PATH}/core/.icons" ]]; then
        if ! run_with_progress "- Installing icons" sudo rsync -am "${ZUI_PATH}/core/.icons/" "${HOME}/.icons/"; then
            log_warn "Failed to install icons"
        fi
    fi
    echo ""
}

# Configure hardware-specific settings
configure_hardware_specific() {
    local theme="$1"
    
    log_info "Configuring hardware-specific settings"
    
    # Configure backlight for polybar based on GPU
    if [[ -f "${ZUI_PATH}/current_theme/polybar/bottom_bars.ini" ]]; then
        if lspci | grep -qi 'amd'; then
            if ! run_with_progress "- Configuring AMD backlight settings" sed -i 's/intel_backlight/amdgpu_bl0/g' "${ZUI_PATH}/current_theme/polybar/bottom_bars.ini"; then
                log_warn "Failed to configure AMD backlight in polybar"
            fi
        fi
    fi
    echo ""
}

# Run theme-specific installation
run_theme_install() {
    local theme="$1"
    
    log_info "Running theme-specific installation"
    
    if [[ -f "${BASE_PATH}/themes/${theme}/install" ]]; then
        if ! run_with_progress "- Executing theme install script" bash "${BASE_PATH}/themes/${theme}/install"; then
            log_warn "Theme install script failed"
        fi
    else
        log_info "- No theme-specific install script found"
    fi
    echo ""
}

# Reload window manager
reload() {
    log_info "Applying theme configuration"
    
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
    echo -e "${CYAN}│                 ${GREEN}ZUI Theme Installation${CYAN}                  │${NC}"
    echo -e "${CYAN}╰─────────────────────────────────────────────────────────╯${NC}"
    
    local theme="${1:-}"

    authenticate_sudo

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

    # Reload bspwm to apply theme
    reload

    log_info "Theme '${theme}' installed successfully!"
    log_info "You may need to reload your shell or log out/in for all changes to take effect."
    echo ""
    log_info "${BLUE}Installation log:${NC} ${LOG_FILE}\n"
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
