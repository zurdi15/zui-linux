#!/bin/bash

# ZUI - Automated BSPWM Desktop Environment
# Shell script for common operations

set -euo pipefail

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
THEME="${THEME:-galaxy}"
BACKUP_DIR="${BACKUP_DIR:-${HOME}/.zui-backup}"
INSTALL_DIR="${INSTALL_DIR:-${HOME}/.zui}"
SCRIPTS_DIR="${SCRIPT_DIR}/scripts"
THEMES_DIR="${SCRIPT_DIR}/themes"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Show help
show_help() {
    cat << EOF
ZUI - Automated BSPWM Desktop Environment

USAGE:
    zui.sh [COMMAND] [OPTIONS]

COMMANDS:
    install              Install ZUI with default theme
    install-ui-only      Install ZUI without shell configuration
    install-deps         Install only dependencies
    install-core         Install only UI core components
    install-shell        Install shell configuration (optional)
    install-theme        Install theme
    set-wallpaper        Set wallpaper (requires path to image file)
    post-install         Run post-installation setup
    uninstall            Remove ZUI installation
    clean                Clean temporary files
    check-deps           Check system dependencies
    backup               Backup existing configurations
    restore              Restore configurations from backup
    list-themes          List available themes
    help                 Show this help message

OPTIONS:
    -t, --theme THEME    Specify theme (default: galaxy)
    -b, --backup-dir DIR Specify backup directory (default: ~/.zui-backup)
    -i, --install-dir DIR Specify install directory (default: ~/.zui)
    -h, --help           Show this help message

ENVIRONMENT VARIABLES:
    THEME                Theme to use (can be overridden with --theme)
    BACKUP_DIR           Backup directory (can be overridden with --backup-dir)
    INSTALL_DIR          Install directory (can be overridden with --install-dir)
EOF
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -t|--theme)
                THEME="$2"
                shift 2
                ;;
            -b|--backup-dir)
                BACKUP_DIR="$2"
                shift 2
                ;;
            -i|--install-dir)
                INSTALL_DIR="$2"
                shift 2
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                if [[ -z "${COMMAND:-}" ]]; then
                    COMMAND="$1"
                else
                    # Store additional arguments for commands that need them
                    COMMAND_ARGS+=("$1")
                fi
                shift
                ;;
        esac
    done
}

# Check if script exists and run it
run_script() {
    local script_name="$1"
    local script_path="${SCRIPTS_DIR}/${script_name}"

    if [[ ! -f "${script_path}" ]]; then
        log_error "Script not found: ${script_path}"
        exit 1
    fi
    
    if [[ ! -x "${script_path}" ]]; then
        log_warning "Making script executable: ${script_path}"
        chmod +x "${script_path}"
    fi

    bash "${script_path}" "${@:2}"
}

# Installation functions
install_full() {
    check_deps_command
    backup_command
    install_deps_command
    install_core_command
    install_shell_command
    install_theme_command
    post_install_command
    log_success "ZUI installation completed!"
    log_info "Please log out and log back in to use ZUI."
}

install_ui_only() {
    check_deps_command
    backup_command
    install_deps_command
    install_core_command
    install_theme_command
    post_install_command
    log_success "ZUI UI-only installation completed!"
    log_warning "Shell configuration was skipped."
    log_info "Run '$0 install-shell' later if you want shell configuration."
}

install_deps_command() {
    run_script "install_deps.sh"
}

install_core_command() {
    run_script "install_core.sh"
}

install_shell_command() {
    run_script "install_shell.sh"
}

install_theme_command() {
    run_script "install_theme.sh" "${THEME}"
}

post_install_command() {
    run_script "post_install.sh"
}

# Uninstallation
uninstall_command() {
    run_script "uninstall.sh"
}

# Maintenance commands
clean_command() {
    rm -rf /tmp/zui
    find . -name "*.log" -delete 2>/dev/null
    find . -name "*.tmp" -delete 2>/dev/null
    log_success "Cleanup completed!"
}

check_deps_command() {
    run_script "check_deps.sh"
}

# Backup and restore
backup_command() {
    run_script "backup.sh" "${BACKUP_DIR}"
}

restore_command() {
    run_script "restore.sh" "${BACKUP_DIR}"
}

# Theme management
list_themes_command() {
    log_info "Available themes:"
    if [[ -d "${THEMES_DIR}" ]]; then
        for theme in "${THEMES_DIR}"/*; do
            theme_name="$(basename "${theme}")"
            [[ "${theme_name}" == .* ]] && continue
            echo "  - ${theme_name}"
        done
    else
        log_error "Themes directory not found: ${THEMES_DIR}"
        exit 1
    fi
}

# Wallpaper management
wallpaper_command() {
    local wallpaper_path="${1:-}"

    if [[ -z "${wallpaper_path}" ]]; then
        log_error "Please provide a path to the wallpaper image file"
        echo "Usage: $0 wallpaper /path/to/image.jpg"
        exit 1
    fi

    if [[ ! -f "${wallpaper_path}" ]]; then
        log_error "${wallpaper_path}: file does not exist"
        exit 1
    fi

    # Check if ZUI is installed
    if [[ ! -d "${INSTALL_DIR}" ]]; then
        log_error "ZUI is not installed. Please run '$0 install' first."
        exit 1
    fi

    # Check if current theme directory exists
    if [[ ! -d "${INSTALL_DIR}/current_theme/wallpapers" ]]; then
        log_error "Current theme wallpapers directory not found. Please reinstall ZUI theme."
        exit 1
    fi

    # Create symbolic link to the new wallpaper
    log_info "Setting wallpaper to: ${wallpaper_path}"
    ln -sfn "$(realpath "${wallpaper_path}")" "${INSTALL_DIR}/current_theme/wallpapers/current_wallpaper"

    # Apply the wallpaper using feh
    if command -v feh >/dev/null 2>&1; then
        feh --bg-fill "${INSTALL_DIR}/current_theme/wallpapers/current_wallpaper"
        log_success "Wallpaper changed successfully!"
    else
        log_warning "feh not found. Please install feh to apply wallpapers automatically."
        log_info "You can manually apply the wallpaper with: feh --bg-fill ${INSTALL_DIR}/current_theme/wallpapers/current_wallpaper"
    fi
}

# Main function
main() {
    local COMMAND=""
    local COMMAND_ARGS=()
    
    # Parse arguments
    parse_args "$@"
    
    # If no command provided, show help
    if [[ -z "${COMMAND:-}" ]]; then
        show_help
        exit 0
    fi
    
    # Execute command
    case "${COMMAND}" in
        check-deps)
            check_deps_command
            ;;
        install)
            install_full
            ;;
        install-ui-only)
            install_ui_only
            ;;
        install-deps)
            install_deps_command
            ;;
        install-core)
            install_core_command
            ;;
        install-shell)
            install_shell_command
            ;;
        install-theme)
            install_theme_command
            ;;
        list-themes)
            list_themes_command
            ;;
        post-install)
            post_install_command
            ;;
        set-wallpaper)
            wallpaper_command "${COMMAND_ARGS[@]}"
            ;;
        uninstall)
            uninstall_command
            ;;
        clean)
            clean_command
            ;;
        backup)
            backup_command
            ;;
        restore)
            restore_command
            ;;
        help)
            show_help
            ;;
        *)
            log_error "Unknown command: ${COMMAND}"
            show_help
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"
