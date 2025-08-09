# ZUI - Automated BSPWM Desktop Environment
# Makefile for common operations

.PHONY: help install install-ui-only install-deps install-core install-terminal install-theme post-install uninstall clean test lint check-deps backup restore list-themes

# Default target
help:
	@echo "ZUI - Automated BSPWM Desktop Environment"
	@echo ""
	@echo "Available targets:"
	@echo "  install          - Install ZUI with default theme"
	@echo "  install-deps     - Install only dependencies"
	@echo "  install-core     - Install only UI core components"
	@echo "  install-terminal - Install terminal configuration (optional)"
	@echo "  install-theme    - Install theme"
	@echo "  uninstall        - Remove ZUI installation"
	@echo "  clean            - Clean temporary files"
	@echo "  test             - Run tests"
	@echo "  lint             - Run shellcheck on scripts"
	@echo "  check-deps       - Check system dependencies"
	@echo "  backup           - Backup existing configurations"
	@echo "  restore          - Restore configurations from backup"
	@echo "  list-themes      - List available themes"
	@echo ""
	@echo "Usage examples:"
	@echo "  make install THEME=galaxy"
	@echo "  make install THEME=nord"
	@echo "  make install-core && make install-terminal && make install-theme THEME=galaxy"

# Variables
THEME ?= galaxy
BACKUP_DIR ?= $(HOME)/.zui-backup
INSTALL_DIR ?= $(HOME)/.zui
SCRIPTS_DIR = scripts
THEMES_DIR = themes

# Installation targets
install: check-deps backup install-deps install-core install-terminal install-theme post-install
	@echo "✓ ZUI installation completed!"
	@echo "Please log out and log back in to use ZUI."

install-ui-only: check-deps backup install-deps install-core install-theme post-install
	@echo "✓ ZUI UI-only installation completed!"
	@echo "Terminal configuration was skipped."
	@echo "Run 'make install-terminal' later if you want terminal configuration."

install-deps:
	@echo "Installing dependencies..."
	@bash $(SCRIPTS_DIR)/install_deps.sh

install-core:
	@echo "Installing core components..."
	@bash $(SCRIPTS_DIR)/install_core.sh

install-terminal:
	@echo "Installing terminal configuration..."
	@bash $(SCRIPTS_DIR)/install_terminal.sh

install-theme:
	@echo "Installing theme: $(THEME)"
	@bash $(SCRIPTS_DIR)/install_theme.sh $(THEME)

post-install:
	@echo "Running post-installation setup..."
	@bash $(SCRIPTS_DIR)/post_install.sh

# Uninstallation
uninstall:
	@echo "Uninstalling ZUI..."
	@bash $(SCRIPTS_DIR)/uninstall.sh

# Maintenance targets
clean:
	@echo "Cleaning temporary files..."
	@rm -rf /tmp/zui
	@find . -name "*.log" -delete
	@find . -name "*.tmp" -delete

test:
	@echo "Running tests..."
	@bash $(SCRIPTS_DIR)/run_tests.sh || true

lint:
	@echo "Running shellcheck..."
	@if command -v shellcheck >/dev/null 2>&1; then \
		find . -name "*.sh" -exec shellcheck {} \; ; \
	else \
		echo "shellcheck not installed. Install with: sudo apt install shellcheck"; \
	fi

check-deps:
	@echo "Checking system dependencies..."
	@bash $(SCRIPTS_DIR)/check_deps.sh || true

# Backup and restore
backup:
	@echo "Creating backup..."
	@bash $(SCRIPTS_DIR)/backup.sh $(BACKUP_DIR) || true

restore:
	@echo "Restoring from backup..."
	@bash $(SCRIPTS_DIR)/restore.sh $(BACKUP_DIR)

# Theme management
list-themes:
	@echo "Available themes:"
	@ls -1 $(THEMES_DIR) | grep -v "^\\."

apply-theme:
	@echo "Applying theme: $(THEME)"
	@bash $(SCRIPTS_DIR)/apply_theme.sh $(THEME)

# Development targets
format:
	@echo "Formatting shell scripts..."
	@find . -name "*.sh" -exec shfmt -w {} \;

validate:
	@echo "Validating configuration files..."
	@bash $(SCRIPTS_DIR)/validate_config.sh
