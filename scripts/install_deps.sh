#!/bin/bash
# ZUI Dependencies Installation Script
# Installs all required system dependencies for ZUI

set -euo pipefail

# Configuration
BASE_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_PATH=${TMP_PATH:-/tmp/zui}
LOG_FILE="${TMP_PATH}/install_deps.log"

# Ensure log directory exists
mkdir -p "${TMP_PATH}"

# Imports
source "${BASE_PATH}/scripts/functions/logger.sh"
source "${BASE_PATH}/scripts/functions/colors.sh"
source "${BASE_PATH}/scripts/functions/command_utils.sh"

# Global tracking for installed software
declare -a INSTALLED_SOFTWARE=()

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

# Add software to tracking list
track_software() {
    INSTALLED_SOFTWARE+=("$1")
}

# Check if running as root
check_not_root() {
    if [[ ${EUID} -eq 0 ]]; then
        log_error "This script should not be run as root"
        exit 1
    fi
}

# Check distribution
check_distro() {
    if ! command -v apt &> /dev/null; then
        log_error "This installer currently only supports Debian/Ubuntu-based systems"
        exit 1
    fi
}

# Check if snap is available
check_snap() {
    if ! command -v snap &> /dev/null; then
        log_warn "Snap is not available on this system. Some packages may not be installed."
        return 1
    fi
    return 0
}

# Install system packages
install_system_packages() {
    log_info "Preparing system for ZUI installation"
    
    if ! run_with_progress "- Updating package repositories" sudo apt update; then
        log_error "Failed to update repositories"
        exit 1
    fi
    
    if ! run_with_progress "- Upgrading system packages" sudo apt dist-upgrade -y; then
        log_error "Failed to upgrade system"
        exit 1
    fi

    if ! run_with_progress "- Installing build dependencies and core packages" sudo apt install -y \
        snap build-essential libxcb-ewmh-dev libxcb-icccm4-dev libxcb-keysyms1-dev \
        libxcb-xtest0-dev cmake cmake-data pkg-config python3-sphinx libcairo2-dev \
        libxcb-util0-dev libxcb-randr0-dev libxcb-composite0-dev python3-xcbgen xcb-proto \
        libxcb-image0-dev libxcb-xkb-dev libasound2-dev libpulse-dev libjsoncpp-dev \
        libmpdclient-dev libcurl4-openssl-dev libnl-genl-3-dev libuv1-dev libpam0g-dev \
        libxrandr-dev libfreetype6-dev libimlib2-dev libxft-dev libxext-dev libxcb-damage0-dev \
        libxcb-xfixes0-dev libxcb-render-util0-dev libxcb-render0-dev libxcb-present-dev \
        libxcb-xinerama0-dev libpixman-1-dev libdbus-1-dev libconfig-dev libgl1-mesa-dev \
        libpcre2-dev libpcre3-dev libevdev-dev uthash-dev libev-dev libx11-xcb-dev libxcb-glx0-dev \
        meson dh-autoreconf libpango1.0-dev xcb libxcb1-dev libyajl-dev libxcb-cursor-dev \
        libxkbcommon-dev libxkbcommon-x11-dev libstartup-notification0-dev libxcb-xrm0 \
        libxcb-xrm-dev libxcb-shape0 libxcb-shape0-dev pavucontrol python3-pip \
        libhidapi-libusb0 libx11-dev libxinerama-dev libxss-dev libglib2.0-dev \
        libgtk-3-dev libxdg-basedir-dev libnotify-dev libnotify-bin python3-pulsectl \
        curl git wget rsync zsh; then
        log_error "Failed to install system packages"
        exit 1
    fi
    
    track_software "System packages (build tools, development libraries)"
    echo ""
}

# Install window manager components
install_window_manager() {
    log_info "Installing window manager components"
    
    # Try package manager first, fallback to source
    if run_with_progress "- Installing bspwm and sxhkd from package manager" sudo apt install -y bspwm sxhkd; then
        track_software "bspwm (Binary Space Partitioning Window Manager)"
        track_software "sxhkd (Simple X HotKey Daemon)"
    else
        log_warning "Package manager installation failed, building from source..."
        
        if [[ ! -d "${TMP_PATH}/bspwm" ]]; then
            if ! run_with_progress "- Installing bspwm" bash -c "git clone https://github.com/baskerville/bspwm.git '${TMP_PATH}/bspwm' >> '${LOG_FILE}' 2>&1 && cd '${TMP_PATH}/bspwm' && make >> '${LOG_FILE}' 2>&1 && sudo make install >> '${LOG_FILE}' 2>&1"; then
                log_error "Failed to clone, build or install bspwm"
                exit 1
            fi
        else
            if ! run_with_progress "- Installing bspwm" bash -c "cd '${TMP_PATH}/bspwm' && make >> '${LOG_FILE}' 2>&1 && sudo make install >> '${LOG_FILE}' 2>&1"; then
                log_error "Failed to build bspwm"
                exit 1
            fi
        fi
        track_software "bspwm (Binary Space Partitioning Window Manager) [from source]"
        
        if [[ ! -d "${TMP_PATH}/sxhkd" ]]; then
            if ! run_with_progress "- Installing sxhkd" bash -c "git clone https://github.com/baskerville/sxhkd.git '${TMP_PATH}/sxhkd' >> '${LOG_FILE}' 2>&1 && cd '${TMP_PATH}/sxhkd' && make >> '${LOG_FILE}' 2>&1 && sudo make install >> '${LOG_FILE}' 2>&1"; then
                log_error "Failed to clone, build or install sxhkd"
                exit 1
            fi
        else
            if ! run_with_progress "- Installing sxhkd" bash -c "cd '${TMP_PATH}/sxhkd' && make >> '${LOG_FILE}' 2>&1 && sudo make install >> '${LOG_FILE}' 2>&1"; then
                log_error "Failed to build sxhkd"
                exit 1
            fi
        fi
        track_software "sxhkd (Simple X HotKey Daemon) [from source]"
    fi
    echo ""
}

# Install compositor
install_picom() {
    if command -v picom &> /dev/null; then
        log_info "Picom already installed, skipping..."
        track_software "picom (Compositor) [already installed]"
        echo ""
        return 0
    fi

    log_info "Installing picom compositor"
    
    if [[ ! -d "${TMP_PATH}/picom" ]]; then
        if ! run_with_progress "- Preparing picom submodules" bash -c "git clone https://github.com/ibhagwan/picom.git '${TMP_PATH}/picom' >> '${LOG_FILE}' 2>&1 && cd '${TMP_PATH}/picom' && git submodule update --init --recursive >> '${LOG_FILE}' 2>&1"; then
            log_error "Failed to clone picom or initialize submodules"
            exit 1
        fi
    else
        if ! run_with_progress "- Preparing picom submodules" bash -c "cd '${TMP_PATH}/picom' && git submodule update --init --recursive >> '${LOG_FILE}' 2>&1"; then
            log_error "Failed to initialize picom submodules"
            exit 1
        fi
    fi
    
    if ! run_with_progress "- Installing picom" bash -c "cd '${TMP_PATH}/picom' && meson --buildtype=release . build >> '${LOG_FILE}' 2>&1 && ninja -C build >> '${LOG_FILE}' 2>&1 && sudo ninja -C build install >> '${LOG_FILE}' 2>&1"; then
        log_error "Failed to build or install picom"
        exit 1
    fi
    
    track_software "picom (X11 Compositor)"
    echo ""
}

# Install polybar
install_polybar() {
    if command -v polybar &> /dev/null; then
        log_info "Polybar already installed, skipping..."
        track_software "polybar (Status Bar) [already installed]"
        echo ""
        return 0
    fi

    log_info "Installing polybar"
    
    if [[ ! -d "${TMP_PATH}/polybar" ]]; then
        if ! run_with_progress "- Preparing polybar" bash -c "git clone --recursive https://github.com/polybar/polybar '${TMP_PATH}/polybar' >> '${LOG_FILE}' 2>&1 && cd '${TMP_PATH}/polybar' && mkdir -p build && cd build && cmake .. >> '${LOG_FILE}' 2>&1 && make -j\$(nproc) >> '${LOG_FILE}' 2>&1"; then
            log_error "Failed to clone, configure or compile polybar"
            exit 1
        fi
    else
        if ! run_with_progress "- Preparing polybar" bash -c "cd '${TMP_PATH}/polybar' && mkdir -p build && cd build && cmake .. >> '${LOG_FILE}' 2>&1 && make -j\$(nproc) >> '${LOG_FILE}' 2>&1"; then
            log_error "Failed to configure or compile polybar"
            exit 1
        fi
    fi
    
    if ! run_with_progress "- Installing polybar" bash -c "cd '${TMP_PATH}/polybar/build' && sudo make install >> '${LOG_FILE}' 2>&1"; then
        log_error "Failed to install polybar"
        exit 1
    fi
    
    track_software "polybar (Status Bar)"
    echo ""
}

# Install audio components
install_audio_tools() {
    log_info "Installing audio and media tools"

    if [[ ! -d "${TMP_PATH}/zscroll" ]]; then
        if run_with_progress "- Installing zscroll" bash -c "git clone https://github.com/noctuid/zscroll '${TMP_PATH}/zscroll' >> '${LOG_FILE}' 2>&1 && cd '${TMP_PATH}/zscroll' && sudo python3 setup.py install >> '${LOG_FILE}' 2>&1 && sudo chown -R ${USER}:${USER} '${TMP_PATH}/zscroll' >> '${LOG_FILE}' 2>&1"; then
            track_software "zscroll (Text Scrolling Tool)"
        else
            log_warn "Failed to clone or install zscroll"
        fi
    fi
    
    if run_with_progress "- Installing playerctl" sudo apt install -y playerctl; then
        track_software "playerctl (Media Player Controller)"
    else
        log_warn "Failed to install playerctl"
    fi
    
    if check_snap; then
        if run_with_progress "- Installing Spotify via snap" sudo snap install spotify; then
            track_software "Spotify (Music Streaming)"
        else
            log_warn "Failed to install Spotify via snap"
        fi
    fi
    echo ""
}

# Install application launcher and utilities
install_utilities() {
    log_info "Installing essential utilities"
    
    # Rofi
    if run_with_progress "- Installing rofi (Application Launcher)" sudo apt install -y rofi; then
        track_software "rofi (Application Launcher)"
    else
        log_error "Failed to install rofi"
        exit 1
    fi
    
    # Feh for wallpapers
    if run_with_progress "- Installing feh (Image Viewer/Wallpaper Manager)" sudo apt install -y feh; then
        track_software "feh (Image Viewer & Wallpaper Manager)"
    else
        log_error "Failed to install feh"
        exit 1
    fi
    
    # Install i3lock-color
    if [[ ! -d "${TMP_PATH}/i3lock-color" ]]; then
        if run_with_progress "- Installing i3lock-color (Enhanced Screen Locker)" bash -c "git clone https://github.com/Raymo111/i3lock-color.git '${TMP_PATH}/i3lock-color' >> '${LOG_FILE}' 2>&1 && cd '${TMP_PATH}/i3lock-color' && ./install-i3lock-color.sh >> '${LOG_FILE}' 2>&1"; then
            track_software "i3lock-color (Enhanced Screen Locker)"
        else
            log_warn "Failed to clone or install i3lock-color"
        fi
    fi
    echo ""
}

# Install notification daemon
install_dunst() {
    if command -v dunst &> /dev/null; then
        log_info "Dunst already installed, skipping..."
        track_software "dunst (Notification Daemon) [already installed]"
        echo ""
        return 0
    fi

    log_info "Installing dunst"
    
    if [[ ! -d "${TMP_PATH}/dunst" ]]; then
        if ! run_with_progress "- Installing dunst (Notification Daemon)" bash -c "git clone https://github.com/dunst-project/dunst.git '${TMP_PATH}/dunst' >> '${LOG_FILE}' 2>&1 && cd '${TMP_PATH}/dunst' && make >> '${LOG_FILE}' 2>&1 && sudo make install >> '${LOG_FILE}' 2>&1"; then
            log_error "Failed to clone, build or install dunst"
            exit 1
        fi
    else
        if ! run_with_progress "- Installing dunst (Notification Daemon)" bash -c "cd '${TMP_PATH}/dunst' && make >> '${LOG_FILE}' 2>&1 && sudo make install >> '${LOG_FILE}' 2>&1"; then
            log_error "Failed to build or install dunst"
            exit 1
        fi
    fi
    
    track_software "dunst (Notification Daemon)"
    echo ""
}

# Install StreamDeck support (optional)
install_streamdeck() {
    log_info "Installing StreamDeck support..."
    
    if run_with_progress "Installing StreamDeck UI" pip3 install streamdeck_ui; then
        track_software "StreamDeck UI (Hardware Controller)"
    else
        log_warn "Failed to install StreamDeck UI"
    fi
}

# Cleanup
cleanup() {
    if run_with_progress "Cleaning up package cache" sudo apt autoremove -y; then
        :
    else
        log_warn "Failed to autoremove packages"
    fi
    echo ""
}

# Generate installation summary
generate_summary() {
    if [[ ${#INSTALLED_SOFTWARE[@]} -eq 0 ]]; then
        echo "No new software was installed (all components were already present)"
    else
        echo -e "${BLUE}\nNewly Installed Software:${NC}"
        for software in "${INSTALLED_SOFTWARE[@]}"; do
            echo -e "  ${GREEN}✓${NC} ${software}"
        done
    fi
}

# Main installation function
main() {
    echo -e "${CYAN}╭─────────────────────────────────────────────────────────╮${NC}"
    echo -e "${CYAN}│              ${GREEN}ZUI Dependencies Installation${CYAN}              │${NC}"
    echo -e "${CYAN}╰─────────────────────────────────────────────────────────╯${NC}"
    
    # Pre-flight checks
    check_not_root
    check_distro
    authenticate_sudo

    install_system_packages
    install_window_manager
    install_picom
    install_polybar
    install_audio_tools
    install_utilities
    install_dunst
    # install_streamdeck
    cleanup

    generate_summary

    echo ""
    log_info "${BLUE}Installation log:${NC} ${LOG_FILE}\n"
    log_info "Next steps:"
    log_info "- Install core: zui.sh install-core"
}

# Run main function
main "$@"
