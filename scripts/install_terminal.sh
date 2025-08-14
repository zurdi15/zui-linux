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
	mkdir -p "${ZUI_PATH}/shell"

	# Copy shell configuration files if they exist
	shopt -s dotglob  # Include dotfiles
	cp "${BASE_PATH}/core/shell/*" "${ZUI_PATH}/shell/" 2>/dev/null || true
	shopt -u dotglob  # Reset dotglob

	# Backup existing configs if they exist
	if [[ -f "${HOME}/.zshrc" && ! -L "${HOME}/.zshrc" ]]; then
		log_info "Backing up existing .zshrc to "${ZUI_PATH}/backup/shell/.zshrc"
		cp "${HOME}/.zshrc" "${ZUI_PATH}/backup/shell/.zshrc"
	fi

	if [[ -f "${HOME}/.p10k.zsh" && ! -L "${HOME}/.p10k.zsh" ]]; then
		log_info "Backing up existing .p10k.zsh to "${ZUI_PATH}/backup/shell/.p10k.zsh"
		cp "${HOME}/.p10k.zsh" "${ZUI_PATH}/backup/shell/.p10k.zsh"
	fi

	# Create symlinks to ZUI shell configs
	if [[ -f "${ZUI_PATH}/shell/.zshrc" ]]; then
		ln -sfn "${ZUI_PATH}/shell/.zshrc" "${HOME}/.zshrc" ||
			log_warn "Failed to create .zshrc symlink"
	fi

	if [[ -f "${ZUI_PATH}/shell/.p10k.zsh" ]]; then
		ln -sfn "${ZUI_PATH}/shell/.p10k.zsh" "${HOME}/.p10k.zsh" ||
			log_warn "Failed to create .p10k.zsh symlink"
	fi

	# Install vim-plug for neovim
	if [[ ! -f "${HOME}/.local/share/nvim/site/autoload/plug.vim" ]]; then
		log_info "Installing vim-plug for neovim"
		curl -fLo "${HOME}/.local/share/nvim/site/autoload/plug.vim" --create-dirs \
			https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim ||
			log_warn "Failed to install vim-plug"
	fi

	# Copy vim configuration
	if [[ -d "${BASE_PATH}/core/.vim" ]]; then
		cp -r "${BASE_PATH}/core/.vim" "${HOME}/.vim" || log_warn "Failed to copy vim config"
	fi

	log_success "Shell configurations installed"
}

# Install zsh plugins
install_zsh_plugins() {
	log_info "Installing zsh plugins..."

	# Create zsh plugins directory
	sudo mkdir -p /usr/share/zsh/zsh-plugins

	# Install popular zsh plugins
	local plugins=(
		"zsh-syntax-highlighting"
		"zsh-autosuggestions"
		"zsh-autocomplete"
	)

	for plugin in "${plugins[@]}"; do
		if [[ -d "/usr/share/zsh/zsh-plugins/${plugin}" ]]; then
			sudo rm -rf "/usr/share/zsh/zsh-plugins/${plugin}"
		fi
	done

	# Install plugins
	sudo git clone --quiet https://github.com/zsh-users/zsh-syntax-highlighting.git \
		/usr/share/zsh/zsh-plugins/zsh-syntax-highlighting ||
		log_warn "Failed to install zsh-syntax-highlighting"

	sudo git clone --quiet https://github.com/zsh-users/zsh-autosuggestions \
		/usr/share/zsh/zsh-plugins/zsh-autosuggestions ||
		log_warn "Failed to install zsh-autosuggestions"

	sudo git clone --quiet https://github.com/marlonrichert/zsh-autocomplete.git \
		/usr/share/zsh/zsh-plugins/zsh-autocomplete ||
		log_warn "Failed to install zsh-autocomplete"

	# Install ZUI-specific sudo plugin
	# if [[ -d "${BASE_PATH}/redist/zsh-plugins/zsh-sudo" ]]; then
	# 	sudo cp -r "${BASE_PATH}/redist/zsh-plugins/zsh-sudo" /usr/share/zsh/zsh-plugins/ ||
	# 		log_warn "Failed to install zsh-sudo plugin"
	# fi

	log_success "Zsh plugins installed"
}

# Install additional terminal tools
install_terminal_tools() {
	log_info "Installing additional terminal tools..."

	# Install fzf
	if [[ -d "${HOME}/.fzf" ]]; then
		rm -rf "${HOME}/.fzf"
	fi

	log_info "Installing terminal tools:"
	if ! run_with_progress_interactive "- lsd (LSDeluxe)" sudo apt install -y \
        lsd; then
        log_error "Failed to install lsd"
        exit 1
    fi
	if ! run_with_progress_interactive "- bat (A cat clone with wings)" sudo apt install -y \
        bat; then
        log_error "Failed to install bat"
        exit 1
    fi
	if ! run_with_progress_interactive "- ranger (Vim-like file manager)" sudo apt install -y \
        ranger; then
        log_error "Failed to install ranger"
        exit 1
    fi
	if ! run_with_progress_interactive "- neovim (Next-generation text editor)" sudo apt install -y \
        neovim; then
        log_error "Failed to install neovim"
        exit 1
    fi

	log_info "Installing fzf (fuzzy finder)"
	git clone --quiet --depth 1 https://github.com/junegunn/fzf.git "${HOME}/.fzf" ||
		log_warn "Failed to clone fzf"
	echo -e 'y\ny\ny\n' | "${HOME}/.fzf/install" >/dev/null ||
		log_warn "Failed to install fzf"

	# log_info "Installing terminal tools:\n- lsd (LSDeluxe)\n- bat (A cat clone with wings)\n- ranger (Vim-like file manager)\n- neovim (Next-generation text editor)"
	# sudo apt install lsd bat ranger neovim -y || log_warn "Failed to install terminal tools"

	# log_info "Installing bat (A cat clone with wings)"
	# sudo apt install bat -y || log_warn "Failed to install bat"

	# log_info "Installing ranger (Vim-like file manager)"
	# sudo apt install ranger -y || log_warn "Failed to install ranger"

	# log_info "Installing neovim (Next-generation text editor)"
	# sudo apt install neovim -y || log_warn "Failed to install neovim"

	log_success "Additional terminal tools installed"
}

install_omz() {
	log_info "Installing Oh My Zsh"

	# Install for user
	if [[ ! -d "${HOME}/.oh-my-zsh" ]]; then
		sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended 2>/dev/null ||
			log_warn "Failed to install user Oh My Zsh"
	else
		log_info "Oh My Zsh already exists for user"
	fi

	# Install for root
	# if [[ ! -d "/root/.oh-my-zsh" ]]; then
	# 	sudo sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended 2>/dev/null ||
	# 		log_warn "Failed to install root Oh My Zsh"
	# else
	# 	log_info "Oh My Zsh already exists for root"
	# fi

	log_success "Oh My Zsh installed"
}

# Install Powerlevel10k theme
install_p10k() {
	log_info "Installing Powerlevel10k theme..."

	# Install for user
	if [[ ! -d "${ZSH_CUSTOM:-${HOME}/.oh-my-zsh/custom}/themes/powerlevel10k" ]]; then
		git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${ZSH_CUSTOM:-${HOME}/.oh-my-zsh/custom}/themes/powerlevel10k" 2>/dev/null ||
			log_warn "Failed to install user Powerlevel10k"
	else
		log_info "Powerlevel10k already exists for user"
	fi

	# Install for root
	# if [[ ! -d "/root/.oh-my-zsh/custom/themes/powerlevel10k" ]]; then
	# 	git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "/root/.oh-my-zsh/custom/themes/powerlevel10k" 2>/dev/null ||
	# 		log_warn "Failed to install root Powerlevel10k"
	# else
	# 	log_info "Powerlevel10k already exists for root"
	# fi

	log_success "Powerlevel10k theme installed"
}

# Set zsh as default shell
set_default_shell() {
	log_info "Setting zsh as default shell..."

	# Check if zsh is installed
	if ! command -v zsh &>/dev/null; then
		log_error "Zsh is not installed. Please install zsh first."
		return 1
	fi

	# Change default shell for user
	if [[ ${SHELL} != *"zsh"* ]]; then
		log_info "Changing default shell to zsh for user"
		sudo usermod --shell /usr/bin/zsh "${USER}" ||
			log_warn "Failed to change user shell to zsh"
	else
		log_info "User shell is already zsh"
	fi

	# Change default shell for root
	# local root_shell
	# root_shell=$(sudo grep "^root:" /etc/passwd | cut -d: -f7)
	# if [[ ${root_shell} != *"zsh"* ]]; then
	# 	log_info "Changing default shell to zsh for root"
	# 	sudo usermod --shell /usr/bin/zsh root ||
	# 		log_warn "Failed to change root shell to zsh"
	# else
	# 	log_info "Root shell is already zsh"
	# fi

	log_success "Default shell configuration completed"
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
	echo "========================="
	echo -e "${BLUE}ZUI Terminal Installation${NC}"
	echo "========================="
	echo ""

	# Check if ZUI is installed
	if [[ ! -d ${ZUI_PATH} ]]; then
		log_error "ZUI core installation not found at: ${ZUI_PATH}"
		log_error "Please install ZUI core first with: zui.sh install-core"
		exit 1
	fi

	confirm_terminal_installation

	install_omz
	install_p10k
	install_shell_configs
	install_zsh_plugins
	install_terminal_tools
	set_default_shell
	# configure_root_environment

	log_info "Please restart the shell to use the new configuration."
}

# Run main function if script is executed directly
if [[ ${BASH_SOURCE[0]} == "${0}" ]]; then
	main "$@"
fi
