#!/bin/bash
# ZUI Terminal Installation Script
# Optional terminal configuration and tools installation

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
BASE_PATH=${BASE_PATH:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}
ZUI_PATH=${ZUI_PATH:-${HOME}/.zui}
TMP_PATH=${TMP_PATH:-/tmp/zui}
LOG_FILE="${TMP_PATH}/install_terminal.log"

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

# Silent command execution with progress
run_with_progress() {
    local message="$1"
    shift

    # For sudo commands, ensure credentials are fresh
    if [[ "$1" == "sudo" ]]; then
        sudo -v 2>/dev/null || true
    fi

    # Run command in background and capture output
    "$@" >> "${LOG_FILE}" 2>&1 &
    local pid=$!

    show_progress "${pid}" "${message}"

    # Wait for completion and check exit code
    wait "${pid}"
    return $?
}

# Ensure sudo credentials are cached
authenticate_sudo() {
    # Test sudo access and cache credentials
    if ! sudo -v; then
        log_error "Failed to authenticate sudo access"
        exit 1
    fi
}

# Check if user wants terminal configuration
confirm_terminal_installation() {
	log_warn "Note: This will modify your shell configuration."
	log_warn "If you already have a customized terminal setup, you may want to skip this."
	echo ""

	read -p "Install terminal configuration? [y/N]: " -n 1 -r
	echo -e "\n"

	if [[ ! ${REPLY} =~ ^[Yy]$ ]]; then
		log_info "Terminal installation skipped by user choice."
		exit 0
	fi
}

# Install shell configurations
install_shell_configs() {
	log_info "Installing shell configurations"

	# Create shell config directory in ZUI
	if ! run_with_progress "- Creating shell configuration directory" mkdir -p "${ZUI_PATH}/shell" "${ZUI_PATH}/backups/shell"; then
		log_error "Failed to create shell directories"
		exit 1
	fi

	# Copy shell configuration files if they exist
	if [[ -d "${BASE_PATH}/common/shell" ]]; then
		if ! run_with_progress "- Installing shell configuration files" bash -c "shopt -s dotglob && cp '${BASE_PATH}/common/shell'/* '${ZUI_PATH}/shell/' 2>/dev/null; shopt -u dotglob"; then
			log_warn "Failed to copy shell configuration files"
		fi
	fi

	# Backup existing configs if they exist
	if [[ -f "${HOME}/.zshrc" && ! -L "${HOME}/.zshrc" ]]; then
		if ! run_with_progress "- Backing up existing .zshrc" cp "${HOME}/.zshrc" "${ZUI_PATH}/backups/shell/.zshrc"; then
			log_warn "Failed to backup existing .zshrc"
		fi
	fi

	if [[ -f "${HOME}/.p10k.zsh" && ! -L "${HOME}/.p10k.zsh" ]]; then
		if ! run_with_progress "- Backing up existing .p10k.zsh" cp "${HOME}/.p10k.zsh" "${ZUI_PATH}/backups/shell/.p10k.zsh"; then
			log_warn "Failed to backup existing .p10k.zsh"
		fi
	fi

	# Create symlinks to ZUI shell configs
	if [[ -f "${ZUI_PATH}/shell/.zshrc" ]]; then
		if ! run_with_progress "- Creating .zshrc symlink" ln -sfn "${ZUI_PATH}/shell/.zshrc" "${HOME}/.zshrc"; then
			log_warn "Failed to create .zshrc symlink"
		fi
	fi

	if [[ -f "${ZUI_PATH}/shell/.p10k.zsh" ]]; then
		if ! run_with_progress "- Creating .p10k.zsh symlink" ln -sfn "${ZUI_PATH}/shell/.p10k.zsh" "${HOME}/.p10k.zsh"; then
			log_warn "Failed to create .p10k.zsh symlink"
		fi
	fi

	# Install vim-plug for neovim
	if [[ ! -f "${HOME}/.local/share/nvim/site/autoload/plug.vim" ]]; then
		if ! run_with_progress "- Installing vim-plug for neovim" bash -c "curl -fLo '${HOME}/.local/share/nvim/site/autoload/plug.vim' --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim"; then
			log_warn "Failed to install vim-plug"
		fi
	fi

	# Copy vim configuration
	if [[ -d "${BASE_PATH}/common/.vim" ]]; then
		if ! run_with_progress "- Installing vim configuration" cp -r "${BASE_PATH}/common/.vim" "${HOME}/.vim"; then
			log_warn "Failed to copy vim config"
		fi
	fi
	echo ""
}

# Install zsh plugins
install_zsh_plugins() {
	log_info "Installing zsh plugins"

	# Create zsh plugins directory
	if ! run_with_progress "- Creating zsh plugins directory" sudo mkdir -p /usr/share/zsh/zsh-plugins; then
		log_error "Failed to create zsh plugins directory"
		exit 1
	fi

	# Remove existing plugins to ensure clean installation
	local plugins=(
		"zsh-syntax-highlighting"
		"zsh-autosuggestions" 
		"zsh-autocomplete"
	)

	for plugin in "${plugins[@]}"; do
		if [[ -d "/usr/share/zsh/zsh-plugins/${plugin}" ]]; then
			if ! run_with_progress "- Removing existing ${plugin}" sudo rm -rf "/usr/share/zsh/zsh-plugins/${plugin}"; then
				log_warn "Failed to remove existing ${plugin}"
			fi
		fi
	done

	# Install plugins
	if ! run_with_progress "- Installing zsh-syntax-highlighting" sudo git clone --quiet https://github.com/zsh-users/zsh-syntax-highlighting.git /usr/share/zsh/zsh-plugins/zsh-syntax-highlighting; then
		log_warn "Failed to install zsh-syntax-highlighting"
	fi

	if ! run_with_progress "- Installing zsh-autosuggestions" sudo git clone --quiet https://github.com/zsh-users/zsh-autosuggestions /usr/share/zsh/zsh-plugins/zsh-autosuggestions; then
		log_warn "Failed to install zsh-autosuggestions"
	fi

	if ! run_with_progress "- Installing zsh-autocomplete" sudo git clone --quiet https://github.com/marlonrichert/zsh-autocomplete.git /usr/share/zsh/zsh-plugins/zsh-autocomplete; then
		log_warn "Failed to install zsh-autocomplete"
	fi
	echo ""
}

# Install additional terminal tools
install_terminal_tools() {
	log_info "Installing terminal tools"

	if ! run_with_progress "- Installing lsd (LSDeluxe)" sudo apt install -y lsd; then
		log_error "Failed to install lsd"
		exit 1
	fi

	if ! run_with_progress "- Installing bat (A cat clone with wings)" sudo apt install -y bat; then
		log_error "Failed to install bat"
		exit 1
	fi

	if ! run_with_progress "- Installing ranger (Vim-like file manager)" sudo apt install -y ranger; then
		log_error "Failed to install ranger"
		exit 1
	fi

	if ! run_with_progress "- Installing neovim (Next-generation text editor)" sudo apt install -y neovim; then
		log_error "Failed to install neovim"
		exit 1
	fi

	# Install fzf (fuzzy finder)
	if [[ -d "${HOME}/.fzf" ]]; then
		if ! run_with_progress "- Removing existing fzf installation" rm -rf "${HOME}/.fzf"; then
			log_warn "Failed to remove existing fzf"
		fi
	fi

	if ! run_with_progress "- Cloning fzf repository" git clone --quiet --depth 1 https://github.com/junegunn/fzf.git "${HOME}/.fzf"; then
		log_warn "Failed to clone fzf"
	else
		if ! run_with_progress "- Installing fzf" bash -c "echo -e 'y\ny\ny\n' | '${HOME}/.fzf/install' >/dev/null"; then
			log_warn "Failed to install fzf"
		fi
	fi
	echo ""
}

configure_prompt() {
	log_info "Configure shell prompt"

	# Install omz
	if [[ ! -d "${HOME}/.oh-my-zsh" ]]; then
		if ! run_with_progress "- Installing Oh My Zsh" bash -c "sh -c \"\$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)\" \"\" --unattended"; then
			log_warn "Failed to install user Oh My Zsh"
		fi
	else
		log_info "- Oh My Zsh already exists, skipping..."
	fi
	if [[ ! -d "${ZSH_CUSTOM:-${HOME}/.oh-my-zsh/custom}/themes/powerlevel10k" ]]; then
		if ! run_with_progress "- Installing Powerlevel10k" git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${ZSH_CUSTOM:-${HOME}/.oh-my-zsh/custom}/themes/powerlevel10k"; then
			log_warn "Failed to install Powerlevel10k"
		fi
	else
		log_info "- Powerlevel10k already exists, skiping..."
	fi
	echo ""

}

# Set zsh as default shell
set_default_shell() {
	log_info "Setting zsh as default shell"

	# Check if zsh is installed
	if ! command -v zsh &>/dev/null; then
		log_error "Zsh is not installed. Please install zsh first."
		return 1
	fi

	# Change default shell for user
	if [[ ${SHELL} != *"zsh"* ]]; then
		if ! run_with_progress "- Changing default shell to zsh for user" sudo usermod --shell /usr/bin/zsh "${USER}"; then
			log_warn "Failed to change user shell to zsh"
		fi
	else
		log_info "User shell is already zsh"
	fi
	echo ""
}

# Configure root environment
# configure_root_environment() {
# 	log_info "Configuring root terminal environment..."

# 	# Create root symlinks for terminal configs
# 	if [[ -f "${ZUI_PATH}/shell/.zshrc" ]]; then
# 		sudo ln -sfn "${ZUI_PATH}/shell/.zshrc" /root/.zshrc ||
# 			log_warn "Failed to create root .zshrc symlink"
# 	fi

# 	if [[ -f "${ZUI_PATH}/shell/.p10k.zsh" ]]; then
# 		sudo ln -sfn "${ZUI_PATH}/shell/.p10k.zsh" /root/.p10k.zsh ||
# 			log_warn "Failed to create root .p10k.zsh symlink"
# 	fi

# 	# Copy root profile if it exists
# 	if [[ -f "${BASE_PATH}/redist/root/.profile" ]]; then
# 		sudo cp "${BASE_PATH}/redist/root/.profile" /root/ ||
# 			log_warn "Failed to copy root profile"
# 	fi

# 	log_success "Root terminal environment configured"
# }

# Main installation function
main() {
	echo ""
	echo "======================"
	echo -e "${BLUE}ZUI Shell Installation${NC}"
	echo "======================"
	echo ""

	# Check if ZUI is installed
	if [[ ! -d ${ZUI_PATH} ]]; then
		log_error "ZUI core installation not found at: ${ZUI_PATH}"
		log_error "Please install ZUI core first with: zui.sh install-core"
		exit 1
	fi

	confirm_terminal_installation
	authenticate_sudo

	configure_prompt
	install_shell_configs
	install_zsh_plugins
	install_terminal_tools
	set_default_shell

	log_info "Terminal installation completed successfully!"
	log_info "Please restart your terminal or run 'exec zsh' to use the new configuration."
}

# Run main function if script is executed directly
if [[ ${BASH_SOURCE[0]} == "${0}" ]]; then
	main "$@"
fi
