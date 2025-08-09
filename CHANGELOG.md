# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Complete project refactoring with modular installation scripts
- Makefile for common operations (install, uninstall, test, lint)
- Comprehensive dependency checking with `scripts/check_deps.sh`
- Automated backup and restore functionality
- Test suite for validation and integration testing
- Improved error handling and logging throughout
- Shell script linting support with shellcheck
- Hardware-specific configuration (AMD/Intel graphics detection)
- Post-installation validation and summary
- Uninstallation script with configuration cleanup
- Theme management utilities
- Security and permission checks
- Performance testing capabilities
- CI/CD ready structure

### Changed
- Split monolithic install script into modular components:
  - `scripts/install_deps.sh` - Dependency installation
  - `scripts/install_core.sh` - Core ZUI setup
  - `scripts/install_theme.sh` - Theme installation
  - `scripts/post_install.sh` - Post-installation tasks
- Improved README.md with comprehensive documentation
- Better directory structure and organization
- Enhanced configuration validation
- Standardized logging and error reporting
- Architecture detection for package downloads

### Fixed
- Architecture-specific package downloads (no longer hardcoded to arm64)
- Better error handling in installation process
- Proper cleanup of temporary files
- Improved symlink management
- Fixed potential permission issues

### Removed
- Monolithic installation approach
- Hardcoded paths and configurations
- Redundant manual compilation when packages are available

## [Previous Versions]

### Legacy Version
- Initial BSPWM desktop environment setup
- Basic theme support (galaxy, haxor, nord)  
- Manual installation process
- Core components: bspwm, sxhkd, polybar, rofi, picom, dunst
- Shell configuration with zsh and powerlevel10k
- Basic wallpaper and theming system

---

**Note**: Version numbers will be assigned starting from the next release after this refactoring.
