#!/bin/bash
# ZUI Backup Script
# Creates comprehensive backup of existing configurations

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Create backup
create_backup() {
    local backup_dir="${1:-${HOME}/.zui-backup-$(date +%Y%m%d_%H%M%S)}"
    
    log_info "Creating backup in: ${backup_dir}"
    mkdir -p "${backup_dir}"
    
    # List of files and directories to backup
    local items_to_backup=(
        ".zshrc"
        ".p10k.zsh"
        ".vimrc"
        ".gitconfig"
        ".bashrc"
        ".profile"
        ".config/bspwm"
        ".config/sxhkd"
        ".config/polybar"
        ".config/rofi"
        ".config/dunst"
        ".config/picom"
        ".config/gtk-3.0"
        ".config/gtk-4.0"
        ".config/lsd"
        ".config/nvim"
        ".config/sublime-text"
    )
    
    local backed_up=0
    local skipped=0
    
    for item in "${items_to_backup[@]}"; do
        local item_path="${HOME}/${item}"
        
        if [[ -e "${item_path}" ]] && [[ ! -L "${item_path}" ]]; then
            # Create parent directory structure
            local parent_dir
            parent_dir=$(dirname "${backup_dir}/${item}")
            mkdir -p "${parent_dir}"
            
            # Copy item
            if cp -r "${item_path}" "${backup_dir}/${item}" 2>/dev/null; then
                log_info "Backed up: ${item}"
                ((backed_up++))
            else
                log_warn "Failed to backup: ${item}"
            fi
        else
            ((skipped++))
        fi
    done
    
    # Create backup manifest
    cat > "${backup_dir}/backup_manifest.txt" <<EOF
ZUI Configuration Backup
========================
Date: $(date)
User: ${USER}
Host: ${HOSTNAME}
Backed up items: ${backed_up}
Skipped items: ${skipped}

Items backed up:
$(find "${backup_dir}" -type f -o -type d | grep -v backup_manifest.txt | sort)
EOF
    
    if [[ ${backed_up} -gt 0 ]]; then
        log_success "Backup completed: ${backup_dir}"
        log_info "Backed up ${backed_up} items, skipped ${skipped} items"
        echo "${backup_dir}"
        return 0
    else
        log_warn "No items were backed up"
        rmdir "${backup_dir}" 2>/dev/null || true
        return 1
    fi
}

# Main function
main() {
    echo ""
    echo "================================"
    echo -e "${BLUE}ZUI Backup current configuration${NC}"
    echo "================================"
    echo ""

    local backup_dir="${1:-}"

    create_backup "${backup_dir}"
}

# Run main function
main "$@"
