#!/bin/bash
# ==========================================
#           ZUI Linux - Backup Script
# ==========================================
# Creates comprehensive backup of existing configurations

# Configuration
BASE_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_PATH=${TMP_PATH:-/tmp/zui}
LOG_FILE="${TMP_PATH}/log_backup.log"

# Ensure log directory exists
mkdir -p "${TMP_PATH}"

# Imports
source "${BASE_PATH}/scripts/functions/logger.sh"
source "${BASE_PATH}/scripts/functions/colors.sh"

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
        elif [[ -L "${item_path}" ]]; then
            log_info "Skipped symlink: ${item} -> $(readlink "${item_path}")"
            ((skipped++))
        else
            log_warn "Not found: ${item}"
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

    if [[ ! ${backed_up} -gt 0 ]]; then
        log_warn "No items were backed up (all were symlinks or missing)"
        log_info "This is normal if ZUI is already installed and managing configs"
        rmdir "${backup_dir}" 2>/dev/null || true
        return 0  # Change this to 0 instead of 1 - it's not really an error
    fi
}

# Main function
main() {
    echo -e "${CYAN}╭─────────────────────────────────────────────────────────╮${NC}"
    echo -e "${CYAN}│                ${GREEN}ZUI Backup Current Config${CYAN}                │${NC}"
    echo -e "${CYAN}╰─────────────────────────────────────────────────────────╯${NC}"
    
    local backup_dir="${1:-}"
    
    create_backup "${backup_dir}"
}

# Run main function
main "$@"
