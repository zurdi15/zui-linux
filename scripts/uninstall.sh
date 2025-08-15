#!/bin/bash
# ZUI Uninstallation Script
# Safely removes ZUI installation and restores backups

set -euo pipefail

# Configuration
BASE_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ZUI_PATH=${ZUI_PATH:-${HOME}/.zui}
CONFIG_PATH=${CONFIG_PATH:-${HOME}/.config}
TMP_PATH=${TMP_PATH:-/tmp/zui}
LOG_FILE="${TMP_PATH}/install_deps.log"

# Ensure log directory exists
mkdir -p "${TMP_PATH}"

# Imports
source "${BASE_PATH}/scripts/functions/logger.sh"
source "${BASE_PATH}/scripts/functions/colors.sh"

# ZUI UI-related packages (window manager and desktop environment components)
readonly ZUI_UI_PACKAGES=(
    # Window Manager Core
    "bspwm"
    "sxhkd"
    
    # Desktop Environment Components
    "polybar"
    "rofi"
    "dunst"
    "picom" 
    "feh"
    "playerctl"
    "pavucontrol"
    
    # Development libraries for UI components
    "libxcb-ewmh-dev"
    "libxcb-icccm4-dev" 
    "libxcb-keysyms1-dev"
    "libxcb-xtest0-dev"
    "libxcb-util0-dev"
    "libxcb-randr0-dev"
    "libxcb-composite0-dev"
    "libxcb-image0-dev"
    "libxcb-xkb-dev"
    "libxcb-damage0-dev"
    "libxcb-xfixes0-dev"
    "libxcb-render-util0-dev"
    "libxcb-render0-dev"
    "libxcb-present-dev"
    "libxcb-xinerama0-dev"
    "libxcb-glx0-dev"
    "libxcb-cursor-dev"
    "libxcb-xrm0"
    "libxcb-xrm-dev"
    "libxcb-shape0"
    "libxcb-shape0-dev"
    "libxkbcommon-dev"
    "libxkbcommon-x11-dev"
    "libstartup-notification0-dev"
    "xcb-proto"
    "xcb"
    "libxcb1-dev"
    "libx11-xcb-dev"
    "libx11-dev"
    "libxinerama-dev"
    "libxrandr-dev"
    "libxext-dev"
    "libxft-dev"
    
    # Audio/Video for desktop integration
    "libasound2-dev"
    "libpulse-dev"
    
    # Graphics and rendering
    "libcairo2-dev"
    "libfreetype6-dev"
    "libimlib2-dev"
    "libpixman-1-dev"
    "libgl1-mesa-dev"
    "libpango1.0-dev"
    
    # Desktop integration
    "libdbus-1-dev"
    "libnotify-dev"
    "libgtk-3-dev"
    "libglib2.0-dev"
    "libxdg-basedir-dev"
    "libxss-dev"
)

# Core ZUI UI components (main desktop environment packages)
readonly ZUI_CORE_UI_PACKAGES=(
    "bspwm"
    "sxhkd" 
    "polybar"
    "rofi"
    "dunst"
    "picom"
    "feh"
    "playerctl"
    "pavucontrol"
)

# Confirmation prompt
confirm_uninstall() {
    echo -e "${YELLOW}WARNING: This will remove ZUI and its UI configurations.${NC}\n"
    echo "The following will be removed:"
    echo "  - ZUI directory: ${ZUI_PATH}"
    echo "  - UI configuration symlinks in: ${CONFIG_PATH} (bspwm, polybar, etc.)"
    echo ""
    echo "The following will be preserved:"
    echo "  - Shell configurations (.zshrc, .p10k.zsh)"
    echo "  - Shell applications (zsh, lsd, bat, ranger, neovim)"
    echo "  - User-installed zsh themes and plugins"
    echo ""
    echo "Available backups will be preserved."
    echo ""
    
    read -p "Are you sure you want to proceed? [y/N]: " -n 1 -r
    echo

    if [[ ! ${REPLY} =~ ^[Yy]$ ]]; then
        log_info "Uninstallation cancelled."
        exit 0
    fi
}

# Check for backups
check_backups() {
    log_info "Checking for available backups..."

    if [[ -f "${ZUI_PATH}/.last_backup" ]]; then
        local backup_dir
        backup_dir=$(grep 'BACKUP_DIR=' "${ZUI_PATH}/.last_backup" | cut -d'=' -f2 | tr -d "'\"")

        if [[ -d "${backup_dir}" ]]; then
            log_info "Found backup: ${backup_dir}"
            echo ""
            read -p "Do you want to restore configurations from backup? [y/N]: " -n 1 -r
            echo

            if [[ ${REPLY} =~ ^[Yy]$ ]]; then
                restore_backup "${backup_dir}"
            fi
        else
            log_warn "Backup directory not found: ${backup_dir}"
        fi
    else
        log_info "No backup information found"
    fi
}

# Restore backup
restore_backup() {
    local backup_dir="$1"

    log_info "Restoring backup from: ${backup_dir}"

    # Restore files from backup
    if [[ -d "${backup_dir}" ]]; then
        cp -r "${backup_dir}"/* "$HOME"/ 2>/dev/null || {
            log_warn "Some files could not be restored from backup"
        }
        log_success "Backup restored"
    else
        log_error "Backup directory not found: ${backup_dir}"
        return 1
    fi
}

# Remove configuration symlinks
remove_config_symlinks() {
    log_info "Removing configuration symlinks..."
    
    local configs=(
        "bspwm" "sxhkd" "polybar" "rofi" "dunst"
        "picom" "gtk-3.0" "gtk-4.0" "lsd" "nvim" "sublime-text"
    )
    
    for config in "${configs[@]}"; do
        local config_path="${CONFIG_PATH}/${config}"
        if [[ -L "${config_path}" ]]; then
            rm "${config_path}" && log_info "Removed: ${config_path}" || \
                log_warn "Failed to remove: ${config_path}"
        elif [[ -d "${config_path}" ]] && [[ ! -L "${config_path}" ]]; then
            log_warn "Directory exists but is not a symlink: ${config_path} (skipping)"
        fi
    done
    
    log_success "Configuration symlinks removed"
}

# Remove home directory symlinks (UI-related only)
remove_home_symlinks() {
    log_info "Checking home directory symlinks..."
    
    # We now preserve shell configurations (.zshrc, .p10k.zsh)
    # Only remove if they point specifically to ZUI locations

    local zshrc_path="${HOME}/.zshrc"
    local p10k_path="${HOME}/.p10k.zsh"

    # Check if .zshrc points to ZUI - if so, we can remove it
    # but only if it's a ZUI-created symlink, not user's original config
    if [[ -L "${zshrc_path}" ]]; then
        local target
        target=$(readlink "${zshrc_path}")
        if [[ "$target" == *"/.zui/"* ]]; then
            log_info "Removing ZUI .zshrc symlink (points to ZUI): ${zshrc_path}"
            rm "${zshrc_path}" || log_warn "Failed to remove: ${zshrc_path}"
        else
            log_info "Preserving .zshrc (not a ZUI symlink): ${zshrc_path}"
        fi
    else
        log_info "No .zshrc symlink found (preserved)"
    fi
    
    # Check if .p10k.zsh points to ZUI
    if [[ -L "${p10k_path}" ]]; then
        local target
        target=$(readlink "${p10k_path}")
        if [[ "$target" == *"/.zui/"* ]]; then
            log_info "Removing ZUI .p10k.zsh symlink (points to ZUI): ${p10k_path}"
            rm "${p10k_path}" || log_warn "Failed to remove: ${p10k_path}"
        else
            log_info "Preserving .p10k.zsh (not a ZUI symlink): ${p10k_path}"
        fi
    else
        log_info "No .p10k.zsh symlink found (preserved)"
    fi
    
    # Also check root symlinks, but same logic
    for file in ".zshrc" ".p10k.zsh"; do
        if [[ -L "/root/${file}" ]]; then
            local target
            target=$(readlink "/root/${file}")
            if [[ "$target" == *"/.zui/"* ]]; then
                log_info "Removing ZUI root symlink: /root/${file}"
                sudo rm "/root/${file}" || log_warn "Failed to remove: /root/${file}"
            else
                log_info "Preserving root ${file} (not a ZUI symlink)"
            fi
        fi
    done
    
    log_success "Home directory symlinks processed (shell config preserved)"
}

# Remove system rules and triggers
remove_system_rules() {
    log_info "Removing system rules and triggers..."
    
    # Remove udev rules
    local rules=(
        "/etc/udev/rules.d/70-backlight.rules"
        "/etc/udev/rules.d/10-streamdeck.rules"
    )
    
    for rule in "${rules[@]}"; do
        if [[ -f "${rule}" ]]; then
            sudo rm "${rule}" && log_info "Removed: ${rule}" || \
                log_warn "Failed to remove: ${rule}"
        fi
    done
    
    # Reload udev rules
    sudo udevadm control --reload-rules 2>/dev/null || \
        log_warn "Failed to reload udev rules"
    
    # Remove network triggers
    local triggers=(
        "/etc/network/if-up.d/trigger-check-network"
        "/etc/network/if-down.d/trigger-check-network"
        "/etc/network/if-post-down.d/trigger-check-network"
        "/etc/network/if-pre-up.d/trigger-check-network"
    )
    
    for trigger in "${triggers[@]}"; do
        if [[ -f "${trigger}" ]]; then
            sudo rm "${trigger}" && log_info "Removed: ${trigger}" || \
                log_warn "Failed to remove: ${trigger}"
        fi
    done
    
    log_success "System rules and triggers removed"
}

# Remove ZSH plugins (only ZUI-installed ones)
remove_zsh_plugins() {
    log_info "Checking ZSH plugins installed by ZUI..."
    
    # Only remove ZUI-specific plugins that we know we installed
    # Preserve user's existing zsh setup
    local zui_specific_plugins=(
        "/usr/share/zsh/zsh-plugins/zsh-sudo"  # This one we install from our redist
    )
    
    local removed_any=false
    
    for plugin in "${zui_specific_plugins[@]}"; do
        if [[ -d "${plugin}" ]]; then
            log_info "  Removing ZUI-installed plugin: ${plugin}"
            sudo rm -rf "${plugin}" || log_warn "Could not remove ${plugin}"
            removed_any=true
        fi
    done
    
    # Only remove parent directory if it's empty and we're sure we created it
    if [[ -d "/usr/share/zsh/zsh-plugins" ]] && [[ "${removed_any}" == "true" ]]; then
        if [[ -z "$(ls -A /usr/share/zsh/zsh-plugins 2>/dev/null)" ]]; then
            log_info "  Removing empty ZSH plugins directory"
            sudo rmdir "/usr/share/zsh/zsh-plugins" 2>/dev/null || log_warn "Could not remove ZSH plugins directory"
        else
            log_info "  Preserving ZSH plugins directory (contains other plugins)"
        fi
    fi
    
    if [[ "${removed_any}" == "true" ]]; then
        log_success "ZUI ZSH plugins removed"
    else
        log_info "No ZUI-specific ZSH plugins found to remove"
    fi
}

# Remove packages
remove_packages() {
    log_info "Package removal options:"
    echo "  1) Remove UI/Window Manager packages only (bspwm, polybar, etc.)"
    echo "  2) Remove all UI-related packages (including UI development libraries)"
    echo "  3) Skip package removal"
    echo ""
    echo "Note: Shell tools (zsh, lsd, bat, ranger, neovim) are preserved"
    
    read -p "Choose option [1-3]: " -n 1 -r
    echo

    case ${REPLY} in
        1)
            remove_ui_core_packages
            ;;
        2)
            remove_all_ui_packages
            ;;
        3)
            log_info "Skipping package removal"
            ;;
        *)
            log_warn "Invalid option. Skipping package removal"
            ;;
    esac
}

# Remove core UI packages only
remove_ui_core_packages() {
    log_info "Removing core UI/Window Manager packages..."
    
    local packages_to_remove=()
    local packages_found=()
    
    # Check which packages are actually installed
    for package in "${ZUI_CORE_UI_PACKAGES[@]}"; do
        if dpkg -l | grep -q "^ii.*${package}"; then
            packages_to_remove+=("${package}")
            packages_found+=("${package}")
        fi
    done
    
    if [[ ${#packages_found[@]} -eq 0 ]]; then
        log_info "No core UI packages found to remove"
        return
    fi
    
    log_info "Found ${#packages_found[@]} core UI packages to remove:"
    printf "  - %s\n" "${packages_found[@]}"
    
    log_info ""
    log_info "Shell tools (zsh, lsd, bat, ranger, neovim) will be preserved"
    
    read -p "Proceed with UI package removal? [y/N]: " -n 1 -r
    echo
    
    if [[ ${REPLY} =~ ^[Yy]$ ]]; then
        log_info "Removing UI packages..."
        sudo apt remove --purge -y "${packages_to_remove[@]}" || \
            log_warn "Some packages could not be removed"
        
        log_info "Running autoremove to clean up UI dependencies..."
        sudo apt autoremove -y || log_warn "Autoremove failed"
        
        log_success "Core UI packages removed"
    else
        log_info "Package removal cancelled"
    fi
}

# Remove all UI packages
remove_all_ui_packages() {
    log_info "Removing all UI-related packages..."
    
    local packages_to_remove=()
    local packages_found=()
    
    # Check which packages are actually installed
    for package in "${ZUI_UI_PACKAGES[@]}"; do
        if dpkg -l | grep -q "^ii.*${package}"; then
            packages_to_remove+=("${package}")
            packages_found+=("${package}")
        fi
    done
    
    if [[ ${#packages_found[@]} -eq 0 ]]; then
        log_info "No UI packages found to remove"
        return
    fi
    
    log_info "Found ${#packages_found[@]} UI packages to remove:"
    printf "  - %s\n" "${packages_found[@]}"
    
    echo
    log_info "Shell tools (zsh, lsd, bat, ranger, neovim) will be preserved"
    log_warn "WARNING: This will remove UI development libraries that may be used by other applications!"
    read -p "Are you sure you want to proceed? [y/N]: " -n 1 -r
    echo

    if [[ ${REPLY} =~ ^[Yy]$ ]]; then
        log_info "Removing UI packages..."
        sudo apt remove --purge -y "${packages_to_remove[@]}" || \
            log_warn "Some packages could not be removed"
        
        log_info "Running autoremove to clean up UI dependencies..."
        sudo apt autoremove -y || log_warn "Autoremove failed"
        
        log_success "All UI packages removed"
    else
        log_info "Package removal cancelled"
    fi
}

# Remove manually installed packages and tools (UI-related only)
remove_manual_installations() {
    log_info "Removing manually installed UI tools..."
    
    # Remove i3lock-color (if installed from source)
    if command -v i3lock &> /dev/null && [[ -f "/usr/local/bin/i3lock" ]]; then
        log_info "  Removing i3lock-color"
        sudo rm -f /usr/local/bin/i3lock /usr/local/bin/i3lock-color || \
            log_warn "Could not remove i3lock-color"
    fi
    
    # Note: Preserving Powerlevel10k and user's zsh configuration
    # Users might have their own shell setup that we shouldn't touch
    
    log_success "Manual UI installations removed"
    log_info "Shell configuration (Powerlevel10k, etc.) preserved"
}

# Remove desktop entry
remove_desktop_entry() {
    log_info "Removing desktop entry..."
    
    local desktop_entry="/usr/share/xsessions/bspwm.desktop"

    if [[ -f "${desktop_entry}" ]]; then
        sudo rm "${desktop_entry}" && log_success "Desktop entry removed" || \
            log_warn "Failed to remove desktop entry"
    else
        log_info "Desktop entry not found"
    fi
}

# Remove ZUI directory
remove_zui_directory() {
    log_info "Removing ZUI directory..."

    if [[ -d "${ZUI_PATH}" ]]; then
        # Ask user if they want to keep backups
        if [[ -d "${ZUI_PATH}/backups" ]] && [[ -n "$(ls -A "${ZUI_PATH}/backups" 2>/dev/null)" ]]; then
            echo ""
            read -p "Do you want to keep backup directory? [Y/n]: " -n 1 -r
            echo

            if [[ ! ${REPLY} =~ ^[Nn]$ ]]; then
                local backup_preserve
                backup_preserve="${HOME}/.zui-backups-$(date +%Y%m%d_%H%M%S)"
                mv "${ZUI_PATH}/backups" "${backup_preserve}" && \
                    log_info "Backups preserved in: ${backup_preserve}" || \
                    log_warn "Failed to preserve backups"
            fi
        fi

        rm -rf "${ZUI_PATH}" && log_success "ZUI directory removed" || \
            log_error "Failed to remove ZUI directory"
    else
        log_info "ZUI directory not found"
    fi
}

# Generate uninstallation summary
generate_summary() {
    echo "Removed:"
    echo "  ✓ ZUI directory: ${ZUI_PATH}"
    echo "  ✓ Configuration symlinks"
    echo "  ✓ System rules and triggers"
    echo "  ✓ ZUI-specific plugins"
    echo "  ✓ Manual UI installations (i3lock-color)"
    echo "  ✓ UI packages (if selected)"
    echo ""
    echo "Preserved:"
    echo "  ✓ Shell tools (zsh, lsd, bat, ranger, neovim)"
    echo "  ✓ User shell configuration (themes, plugins)"
    echo "  ✓ Build tools and general development libraries"
    echo ""
    echo "UI package removal was optional and based on user selection."
    echo ""
    echo "Next steps:"
    echo "• If you removed UI packages, log out and log back in"
    echo "• Select a different desktop environment if needed"
    echo "• Your shell configuration and tools remain intact"
    echo ""
    echo "=============================="
}

# Main uninstallation function
main() {
    echo -e "${CYAN}╭─────────────────────────────────────────────────────────╮${NC}"
    echo -e "${CYAN}│                  ${GREEN}ZUI Uninstallation ${CYAN}                    │${NC}"
    echo -e "${CYAN}╰─────────────────────────────────────────────────────────╯${NC}"
    
    # Check if ZUI is installed
    if [[ ! -d "${ZUI_PATH}" ]]; then
        log_warn "ZUI does not appear to be installed at: ${ZUI_PATH}"
        read -p "Continue with cleanup anyway? [y/N]: " -n 1 -r
        echo

        if [[ ! ${REPLY} =~ ^[Yy]$ ]]; then
            log_info "Uninstallation cancelled."
            exit 0
        fi
    fi
    
    # Run uninstallation
    confirm_uninstall
    check_backups
    remove_config_symlinks
    remove_home_symlinks
    remove_system_rules
    remove_zsh_plugins
    remove_desktop_entry
    remove_zui_directory
    remove_manual_installations
    remove_packages
    generate_summary
    
    log_success "ZUI uninstallation completed!"
}

# Run main function
main "$@"
