# Contributing to ZUI

Thank you for your interest in contributing to ZUI! This document provides guidelines and information for contributors.

## 🤝 How to Contribute

### Reporting Issues
1. Check existing issues to avoid duplicates
2. Use the issue template (if available)
3. Provide system information:
   ```bash
   make check-deps > system-info.txt
   ```
4. Include relevant log files and error messages
5. Describe steps to reproduce the issue

### Suggesting Features
- Open an issue with the "enhancement" label
- Describe the feature and its use case
- Explain how it fits with ZUI's goals
- Consider implementation complexity

### Code Contributions
1. Fork the repository
2. Create a feature branch: `git checkout -b feature/your-feature-name`
3. Make your changes
4. Test thoroughly: `make test`
5. Lint your code: `make lint`
6. Update documentation if needed
7. Commit with clear messages
8. Submit a pull request

## 🏗️ Development Environment

### Prerequisites
- Linux system (Ubuntu/Debian preferred)
- Git
- Bash 4.0+
- Make
- shellcheck (for linting)

### Setup
```bash
git clone https://github.com/zurdi15/zui-linux.git
cd zui-linux
make check-deps
```

### Testing
```bash
# Run all tests
make test

# Run specific test categories
make test core
make test config
make test integration

# Lint shell scripts
make lint
```

## 📝 Code Guidelines

### Shell Scripts
- Use `#!/bin/bash` shebang
- Enable strict mode: `set -euo pipefail`
- Use consistent indentation (4 spaces)
- Add error handling for critical operations
- Use meaningful variable names
- Add comments for complex logic
- Follow existing logging patterns

### Directory Structure
```
scripts/           # Installation and utility scripts
themes/           # Theme configurations
common/           # Shared configurations
redist/           # Redistributable files
```

### Logging
Use the standard logging functions:
```bash
log_info "Information message"
log_warn "Warning message"
log_error "Error message"
log_success "Success message"
```

### Error Handling
```bash
# Exit on errors
set -euo pipefail

# Check command success
if command -v somecommand &> /dev/null; then
    log_success "Command available"
else
    log_error "Command not found"
    return 1
fi
```

## 🎨 Adding New Themes

### Theme Structure
```
themes/mytheme/
├── install              # Theme-specific installation script
├── wallpapers/         # Theme wallpapers
│   └── default        # Default wallpaper (symlink target)
├── polybar/           # Polybar configuration
│   ├── colors.ini
│   ├── main_bar.ini
│   ├── top_bars.ini
│   ├── bottom_bars.ini
│   └── launch.sh
├── rofi/              # Rofi themes
├── dunst/             # Notification styling
├── gtk-3.0/           # GTK3 theme
├── gtk-4.0/           # GTK4 theme
├── picom/             # Compositor config
├── nvim/              # Neovim configuration
├── .zshrc             # Shell configuration
└── .p10k.zsh          # Powerlevel10k config
```

### Theme Development Process
1. Copy existing theme: `cp -r themes/galaxy themes/mytheme`
2. Customize colors, wallpapers, and configurations
3. Test theme installation: `make install-theme THEME=mytheme`
4. Validate all components work correctly
5. Create theme-specific documentation
6. Submit pull request

### Theme Guidelines
- Use consistent color schemes across all components
- Provide high-quality wallpapers (1920x1080 minimum)
- Test with different screen resolutions
- Ensure good contrast for readability
- Include both light and dark variants if possible

## 🧪 Testing Guidelines

### Test Categories
- **Core Tests**: Basic functionality and structure
- **Config Tests**: Configuration file validation
- **Integration Tests**: Component interaction (requires X11)
- **Performance Tests**: Startup and operation speed
- **Security Tests**: Permission and safety checks

### Writing Tests
Add new test functions to `scripts/run_tests.sh`:
```bash
test_my_feature() {
    # Test implementation
    [[ condition ]] && return 0 || return 1
}
```

### Test Requirements
- All tests should be non-destructive
- Tests should clean up after themselves
- Use mocks for external dependencies when possible
- Document any special test requirements

## 📚 Documentation

### README Updates
- Keep installation instructions current
- Update screenshots when UI changes
- Document new features and options
- Include troubleshooting for common issues

### Code Documentation
- Comment complex shell functions
- Document configuration file formats
- Explain non-obvious design decisions
- Keep inline comments concise but helpful

### Changelog
- Follow Keep a Changelog format
- Document breaking changes clearly
- Group changes by category (Added, Changed, Fixed, Removed)
- Include migration notes for major changes

## 🚀 Release Process

### Version Numbering
Follow Semantic Versioning:
- MAJOR: Breaking changes
- MINOR: New features (backwards compatible)
- PATCH: Bug fixes

### Release Checklist
1. Update version numbers
2. Update CHANGELOG.md
3. Run full test suite
4. Test on clean system
5. Update documentation
6. Create git tag
7. Write release notes

## 🛠️ Tools and Utilities

### Recommended Development Tools
- **shellcheck**: Shell script linting
- **shfmt**: Shell script formatting  
- **git hooks**: Pre-commit validation
- **VSCode**: With shell script extensions

### Useful Make Targets
```bash
make help          # Show all available targets
make install       # Install ZUI
make test          # Run tests
make lint          # Lint shell scripts
make clean         # Clean temporary files
make format        # Format shell scripts (if shfmt available)
```

## ❓ Questions?

- Check the README.md for basic information
- Search existing issues and discussions
- Ask questions in issue comments
- Join community discussions (if available)

## 📜 License

By contributing to ZUI, you agree that your contributions will be licensed under the same license as the project (MIT License).

---

Thank you for helping make ZUI better! 🎉
