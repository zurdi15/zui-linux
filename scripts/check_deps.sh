#!/bin/bash
# ZUI System Dependencies Checker
# Checks if all required system dependencies are available

# Configuration
BASE_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_PATH=${TMP_PATH:-/tmp/zui}
LOG_FILE="${TMP_PATH}/check_deps.log"

# Ensure log directory exists
mkdir -p "${TMP_PATH}"

# Imports
source "${BASE_PATH}/scripts/functions/logger.sh"
source "${BASE_PATH}/scripts/functions/colors.sh"

# Check if command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Check if package is installed (Debian/Ubuntu)
package_installed() {
    dpkg -l "$1" &> /dev/null
}

# Check system requirements
check_system() {
    if [[ ! -f /etc/os-release ]]; then
        return 1
    fi
    
    if ! command_exists apt; then
        return 1
    fi

    if [[ ${EUID} -eq 0 ]]; then
        return 1
    fi
    
    return 0
}

# Check build dependencies
check_build() {
    local deps=("build-essential" "cmake" "git" "wget" "curl")
    
    for dep in "${deps[@]}"; do
        if ! package_installed "${dep}" && ! command_exists "${dep}"; then
            return 1
        fi
    done
    return 0
}

# Check X11 dependencies
check_x11() {
    local deps=("libx11-dev" "libxcb1-dev" "libxcb-util0-dev")
    
    for dep in "${deps[@]}"; do
        if ! package_installed "${dep}"; then
            return 1
        fi
    done
    return 0
}

# Check window manager
check_wm() {
    command_exists bspwm && command_exists sxhkd
}

# Check compositor
check_compositor() {
    command_exists picom
}

# Check status bar
check_bar() {
    command_exists polybar
}

# Check applications
check_apps() {
    command_exists rofi && command_exists feh && command_exists dunst && command_exists zsh
}

# Check Python
check_python() {
    command_exists python3 && command_exists pip3
}

# Check snap
check_snap() {
    command_exists snap && systemctl is-active --quiet snapd 2>/dev/null
}

# Check display server
check_display() {
    [[ -n "${DISPLAY:-}" ]] && [[ -z "${WAYLAND_DISPLAY:-}" ]]
}

# Generate report
generate_report() {
    echo -e "${CYAN}╭─────────────────────────────────────────────────────────╮${NC}"
    echo -e "${CYAN}│                  ${GREEN}ZUI Dependency Check${CYAN}                   │${NC}"
    echo -e "${CYAN}╰─────────────────────────────────────────────────────────╯${NC}"
    
    local total_checks=0
    local passed_checks=0
    
    # Define checks
    local -A checks=(
        ["System Requirements"]="check_system"
        ["Build Dependencies"]="check_build"
        ["X11 Dependencies"]="check_x11"
        ["Window Manager"]="check_wm"
        ["Compositor"]="check_compositor"
        ["Status Bar"]="check_bar"
        ["Applications"]="check_apps"
        ["Python Dependencies"]="check_python"
        ["Snap Package Manager"]="check_snap"
        ["Display Server"]="check_display"
    )
    
    # Run checks
    for check_name in "${!checks[@]}"; do
        local func_name="${checks[${check_name}]}"
        ((total_checks++))
        
        printf "%-25s ... " "[${check_name}]"
        
        if ${func_name} >/dev/null 2>&1; then
            echo -e "${GREEN}PASS${NC}"
            ((passed_checks++))
        else
            echo -e "${RED}FAIL${NC}"
        fi
    done
    
    echo ""
    log_info "Results: ${passed_checks}/${total_checks} checks passed"

    if [[ ${passed_checks} -eq ${total_checks} ]]; then
        log_info "${GREEN}System is ready for ZUI installation ✓ ${NC}"
        echo ""
        log_info "${BLUE}Check deps log:${NC} ${LOG_FILE}\n"
        log_info "Next steps:"
        log_info "- Install dependencies: zui.sh install-deps"
        return 0
    elif [[ ${passed_checks} -ge $((total_checks * 3 / 4)) ]]; then
        log_warn "${YELLOW}⚠ System mostly ready. Some optional components missing.${NC}"
        return 1
    else
        log_error "${RED}✗ System not ready. Please install missing dependencies.${NC}"
        return 2
    fi
}

# Only run main if script is executed directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    generate_report
fi
