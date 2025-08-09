# ZUI - Automated BSPWM Desktop Environment

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Shell](https://img.shields.io/badge/shell-zsh-green.svg)](https://www.gnu.org/software/zsh/)
[![WM](https://img.shields.io/badge/window%20manager-bspwm-orange.svg)](https://github.com/baskerville/bspwm)

A complete, automated installation system for a modern tiling window manager desktop environment based on **bspwm**. ZUI provides a beautiful, functional, and customizable desktop experience with multiple themes and automated setup.

## ✨ Features

- **Automated Installation**: One-command setup with dependency management
- **Multiple Themes**: Beautiful, cohesive themes with matching components
- **Modern Tools**: Uses current tools like polybar, rofi, picom, and dunst
- **Modular Design**: Easy to customize and extend
- **Hardware Detection**: Automatic configuration based on your hardware
- **Backup System**: Preserves your existing configurations
- **Shell Integration**: Enhanced zsh with powerlevel10k and useful plugins

## 🖼️ Included Themes

| Theme | Description | Screenshot |
|-------|-------------|------------|
| **Galaxy** | Dark theme with purple/blue accents | [TODO] |
| **Nord** | Clean Nordic-inspired color scheme | [TODO] |
| **Haxor** | Cyberpunk/terminal aesthetic | [TODO] |

## 🔧 Components

- **Window Manager**: [bspwm](https://github.com/baskerville/bspwm) - Binary space partitioning window manager
- **Hotkey Daemon**: [sxhkd](https://github.com/baskerville/sxhkd) - Simple X hotkey daemon  
- **Status Bar**: [Polybar](https://github.com/polybar/polybar) - Fast and customizable status bar
- **Compositor**: [Picom](https://github.com/ibhagwan/picom) - Lightweight compositor for X11
- **Application Launcher**: [Rofi](https://github.com/davatorium/rofi) - Window switcher and launcher
- **Notifications**: [Dunst](https://github.com/dunst-project/dunst) - Lightweight notification daemon
- **Wallpaper**: [Feh](https://feh.finalrewind.org/) - Image viewer and wallpaper setter
- **Lock Screen**: [i3lock-color](https://github.com/Raymo111/i3lock-color) - Improved screen locker
- **Shell**: [Zsh](https://www.zsh.org/) with [Powerlevel10k](https://github.com/romkatv/powerlevel10k)
- **Terminal Tools**: [lsd](https://github.com/Peltoche/lsd), [bat](https://github.com/sharkdp/bat), [ranger](https://github.com/ranger/ranger)

## 📋 Prerequisites

### System Requirements
- **OS**: Ubuntu 20.04+ or Debian 11+ (primary support)
- **Display Server**: X11 (Wayland not supported)
- **Memory**: At least 2GB RAM recommended
- **Storage**: ~1GB free space for full installation

### Required Privileges
- User account with sudo access
- Internet connection for downloading packages

## 🚀 Quick Start

### Check System Compatibility
```bash
make check-deps
```

### Install ZUI with Default Theme
```bash
make install
```

### Install with Specific Theme
```bash
make install THEME=galaxy
# or
make install THEME=nord
# or  
make install THEME=haxor
```

### Manual Installation (Advanced)
```bash
# Install dependencies
make install-deps

# Install core components  
make install-core

# Install theme
make install-theme THEME=galaxy

# Run post-install setup
make post-install
```

## 🎨 Theme Management

### List Available Themes
```bash
make list-themes
# or
zui-theme list
```

### Switch Themes
```bash
make apply-theme THEME=nord
# or
zui-theme apply nord
```

### Create New Theme
```bash
# Copy existing theme as template
cp -r themes/galaxy themes/mytheme
# Edit configurations in themes/mytheme/
```

## ⌨️ Default Keybindings

| Shortcut | Action |
|----------|--------|
| `Super + Return` | Open terminal |
| `Super + D` | Application launcher |
| `Super + Shift + D` | Command launcher |
| `Super + X` | Window switcher |
| `Super + Q` | Power menu |
| `Super + L` | Lock screen |
| `Super + N` | Network menu |
| `Super + Shift + F` | Firefox |
| `Alt + Tab` | Cycle windows |
| `Super + 1-9` | Switch to desktop |
| `Super + Shift + 1-9` | Move window to desktop |

### Window Management
| Shortcut | Action |
|----------|--------|
| `Super + H/J/K/L` | Focus window (left/down/up/right) |
| `Super + Shift + H/J/K/L` | Move window |
| `Super + Ctrl + H/J/K/L` | Resize window |
| `Super + F` | Toggle fullscreen |
| `Super + T` | Toggle tiled/floating |
| `Super + W` | Close window |

## 🛠️ Customization

### Configuration Locations
- **ZUI Directory**: `~/.zui/`
- **Current Theme**: `~/.zui/current_theme/` (symlink)
- **System Config**: `~/.zui/common/system/config.yml`
- **User Configs**: `~/.config/` (symlinked to ZUI themes)

### Multi-Monitor Setup
Edit `~/.zui/common/system/config.yml`:

```yaml
monitors:
  HDMI-1:
    resolution: 1920x1080
    rotate: normal
    main: 1
    workspaces: [1, 2, 3, 4, 5]
  eDP-1:
    resolution: 1920x1080
    rotate: normal
    position: left
    workspaces: [6, 7, 8, 9, 0]
```

### Audio Device Configuration
```yaml
audio:
  alsa_output.pci-0000_00_1f.3.analog-stereo:
    alias: "Speakers"
    type: speakers
  alsa_output.usb-Device_Name:
    alias: "Headphones" 
    type: headset
```

## 🧪 Testing & Validation

### Run All Tests
```bash
make test
```

### Run Specific Tests
```bash
# Core functionality
make test-core

# Configuration validation
make test-config

# Integration tests (requires running session)
make test-integration
```

### Lint Shell Scripts
```bash
make lint
```

## 🔄 Maintenance

### Update ZUI
```bash
git pull origin master
make install  # Re-run installation
```

### Backup Configuration
```bash
make backup
# or specify backup location
make backup BACKUP_DIR=/path/to/backup
```

### Restore Configuration
```bash
make restore BACKUP_DIR=/path/to/backup
```

### Clean Temporary Files
```bash
make clean
```

## 🗑️ Uninstallation

### Complete Removal
```bash
make uninstall
```

This will:
- Remove ZUI directory and configurations
- Restore backed up configurations (if available)
- Remove system rules and desktop entries
- Preserve user data and installed packages

### Manual Cleanup
If you need to remove installed packages:
```bash
# Remove window manager components (optional)
sudo apt remove bspwm sxhkd polybar rofi dunst picom

# Remove development tools (be careful!)
sudo apt remove build-essential cmake
```

## 🐛 Troubleshooting

### Common Issues

**ZUI doesn't start after login**
- Ensure you selected "bspwm" session in your display manager
- Check if all dependencies are installed: `make check-deps`
- Verify installation: `make test`

**Polybar not showing**
- Check polybar configuration: `polybar --list-monitors`
- Restart polybar: `~/.config/polybar/launch.sh`
- Check logs: `journalctl --user -u polybar`

**Audio controls not working**
- Update audio configuration in `~/.zui/common/system/config.yml`
- List audio devices: `pactl list sinks`
- Restart polybar after audio config changes

**Wallpaper not loading**
- Check wallpaper link: `ls -la ~/.zui/current_theme/wallpapers/current_wallpaper`
- Manually set: `feh --bg-fill /path/to/wallpaper.jpg`

### Log Files
- Installation logs: `/tmp/zui/install_deps.log`
- System logs: `journalctl --user`
- Application logs: `~/.local/share/` (various applications)

### Getting Help
1. Check this README and documentation
2. Run diagnostics: `make check-deps && make test`
3. Check logs for error messages
4. Open an issue with system info and error logs

## 🤝 Contributing

### Development Setup
```bash
# Clone repository
git clone https://github.com/zurdi15/zui-linux.git
cd zui-linux

# Install development dependencies
make install-deps

# Run tests
make test

# Format code
make format

# Validate configurations
make validate
```

### Adding New Themes
1. Copy existing theme: `cp -r themes/galaxy themes/newtheme`
2. Customize configurations in `themes/newtheme/`
3. Test theme: `make install-theme THEME=newtheme`
4. Submit pull request

### Code Style
- Use shellcheck for shell scripts: `make lint`
- Follow existing code patterns and structure
- Add tests for new functionality
- Update documentation

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [baskerville](https://github.com/baskerville) - bspwm and sxhkd
- [polybar team](https://github.com/polybar/polybar) - Polybar status bar
- [All contributors](https://github.com/zurdi15/zui-linux/contributors) - Community improvements

## 📊 Project Stats

- **Languages**: Shell (95%), Python (3%), Other (2%)
- **Lines of Code**: ~5000+
- **Supported Themes**: 3
- **Supported Distros**: Ubuntu/Debian family

---

**Note**: This project is designed for X11 environments. Wayland support may be added in future versions.
