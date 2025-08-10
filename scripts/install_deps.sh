#!/bin/bash
# ZUI Dependencies Installation Script
# Installs all required system dependencies for ZUI

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
TMP_PATH=${TMP_PATH:-/tmp/zui}
LOG_FILE="${TMP_PATH}/install_deps.log"

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

# Check if running as root
check_not_root() {
    if [[ $EUID -eq 0 ]]; then
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
    log_info "Updating package repositories..."
    sudo apt update || { log_error "Failed to update repositories"; exit 1; }
    
    log_info "Upgrading system packages..."
    sudo apt dist-upgrade -y || { log_error "Failed to upgrade system"; exit 1; }

    log_info "Installing core build dependencies..."
    sudo apt install -y \
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
        curl git wget rsync || {
        log_error "Failed to install system packages"
        exit 1
    }
    
    log_success "System packages installed successfully"
}

# Install window manager components
install_window_manager() {
    log_info "Installing bspwm and sxhkd..."
    
    # Try package manager first, fallback to source
    if ! sudo apt install -y bspwm sxhkd; then
        log_info "Installing bspwm from source..."
        if [[ ! -d "${TMP_PATH}/bspwm" ]]; then
            git clone https://github.com/baskerville/bspwm.git "${TMP_PATH}/bspwm"
        fi
        cd "${TMP_PATH}/bspwm" && make && sudo make install
        
        log_info "Installing sxhkd from source..."
        if [[ ! -d "${TMP_PATH}/sxhkd" ]]; then
            git clone https://github.com/baskerville/sxhkd.git "${TMP_PATH}/sxhkd"
        fi
        cd "${TMP_PATH}/sxhkd" && make && sudo make install
    fi
    
    log_success "Window manager components installed"
}

# Install compositor
install_picom() {
    if command -v picom &> /dev/null; then
        log_info "Picom already installed"
        return 0
    fi

    log_info "Installing picom compositor..."
    if [[ ! -d "${TMP_PATH}/picom" ]]; then
        git clone https://github.com/ibhagwan/picom.git "${TMP_PATH}/picom"
    fi
    cd "${TMP_PATH}/picom"
    git submodule update --init --recursive
    meson --buildtype=release . build
    ninja -C build
    sudo ninja -C build install || {
        log_error "Failed to install picom"
        exit 1
    }
    
    log_success "Picom installed successfully"
}

# Install polybar
install_polybar() {
    if command -v polybar &> /dev/null; then
        log_info "Polybar already installed"
        return 0
    fi

    log_info "Installing polybar..."
    if [[ ! -d "${TMP_PATH}/polybar" ]]; then
        git clone --recursive https://github.com/polybar/polybar "${TMP_PATH}/polybar"
    fi
    cd "${TMP_PATH}/polybar"
    mkdir -p build && cd build/
    cmake ..
    make -j"$(nproc)"
    sudo make install || {
        log_error "Failed to install polybar"
        exit 1
    }
    
    log_success "Polybar installed successfully"
}

# Install audio components
install_audio_tools() {
    log_info "Installing audio tools..."
    pip3 install pulsectl || log_warn "Failed to install pulsectl via pip3"
    
    if [[ ! -d "${TMP_PATH}/zscroll" ]]; then
        git clone https://github.com/noctuid/zscroll "${TMP_PATH}/zscroll"
    fi
    cd "${TMP_PATH}/zscroll"
    sudo python3 setup.py install || log_warn "Failed to install zscroll"
    
    sudo apt install -y playerctl || log_warn "Failed to install playerctl"
    
    if check_snap; then
        sudo snap install spotify || log_warn "Failed to install Spotify via snap"
    fi
    
    log_success "Audio tools installation completed"
}

# Install application launcher and utilities
install_utilities() {
    log_info "Installing utilities..."
    
    # Rofi
    sudo apt install -y rofi || { log_error "Failed to install rofi"; exit 1; }
    
    # Feh for wallpapers
    sudo apt install -y feh || { log_error "Failed to install feh"; exit 1; }
    
    # Install i3lock-color
    if [[ ! -d "${TMP_PATH}/i3lock-color" ]]; then
        git clone https://github.com/Raymo111/i3lock-color.git "${TMP_PATH}/i3lock-color"
    fi
    cd "${TMP_PATH}/i3lock-color"
    ./install-i3lock-color.sh || log_warn "Failed to install i3lock-color"
    
    log_success "Utilities installed successfully"
}

# Install notification daemon
install_dunst() {
    if command -v dunst &> /dev/null; then
        log_info "Dunst already installed"
        return 0
    fi

    log_info "Installing dunst notification daemon..."
    if [[ ! -d "${TMP_PATH}/dunst" ]]; then
        git clone https://github.com/dunst-project/dunst.git "${TMP_PATH}/dunst"
    fi
    cd "${TMP_PATH}/dunst"
    make && sudo make install || {
        log_error "Failed to install dunst"
        exit 1
    }
    
    log_success "Dunst installed successfully"
}

# Install applications
install_applications() {
    log_info "Installing applications..."
    
    # Remove default Firefox if present
    sudo apt remove -y firefox || log_info "Firefox not installed via apt"
    
    if check_snap; then
        sudo snap install firefox || log_warn "Failed to install Firefox via snap"
        sudo snap install code --classic || log_warn "Failed to install VS Code via snap"
        sudo snap install sublime-text --classic || log_warn "Failed to install Sublime Text via snap"
    fi
    
    log_success "Applications installation completed"
}

# Install StreamDeck support (optional)
install_streamdeck() {
    log_info "Installing StreamDeck support..."
    
    pip3 install streamdeck_ui || log_warn "Failed to install StreamDeck UI"
    
    log_success "StreamDeck support installed"
}

# Cleanup
cleanup() {
    log_info "Cleaning up..."
    sudo apt autoremove -y || log_warn "Failed to autoremove packages"
    log_success "Cleanup completed"
}

# Main installation function
main() {
    log_info "Starting ZUI dependencies installation..."
    
    # Create temp directory and log file
    mkdir -p "${TMP_PATH}"
    touch "${LOG_FILE}"
    
    # Pre-flight checks
    check_not_root
    check_distro
    
    # Install components
    install_system_packages
    install_window_manager
    install_picom
    install_polybar
    install_audio_tools
    install_utilities
    install_dunst
    # install_applications
    # install_streamdeck
    cleanup
    
    log_success "All dependencies installed successfully!"
    log_info "Installation log saved to: ${LOG_FILE}"
}

# Run main function
main "$@"
