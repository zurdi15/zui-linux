# ZUI - Automated BSPWM Desktop Environment

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Shell](https://img.shields.io/badge/shell-zsh-green.svg)](https://www.gnu.org/software/zsh/)
[![WM](https://img.shields.io/badge/window%20manager-bspwm-orange.svg)](https://github.com/baskerville/bspwm)

A complete, automated installation system for a modern tiling window manager desktop environment based on **bspwm**. ZUI provides a beautiful, functional, and customizable desktop experience with multiple themes and modular installation options.

## Design Philosophy

ZUI follows a **modular approach** that separates UI window manager components from terminal configuration:

- **🖼️ UI Components**: Window manager, status bar, compositor, themes, and visual elements
- **💻 Terminal Setup**: Shell configuration, prompt theme, CLI tools, and terminal-specific settings
- **🔧 User Choice**: Install both together or independently based on your needs

This separation means you can:
- Use ZUI's window manager with your existing terminal setup
- Enhance your terminal with ZUI's configuration while keeping your current window manager
- Install everything together for a complete desktop transformation
- Safely experiment with themes without affecting your shell environment
- Configure ZUI's enhanced terminal without the window manager  
- Mix and match components as needed
- Preserve your terminal customizations when changing UI themes

## Features

### 🏗️ **Modular Architecture**
- **Component Independence**: UI and terminal configurations work separately
- **Installation Flexibility**: Choose UI-only, terminal-only, or combined setup
- **Configuration Preservation**: Respects your existing dotfiles and settings
- **Easy Maintenance**: Update components without affecting others

### 🎨 **Professional Themes**
- **Multiple Options**: Galaxy, Nord, and Haxor themes included
- **Cohesive Design**: Matching colors across all components
- **Safe Switching**: Change themes without losing terminal configurations
- **Visual Consistency**: Coordinated UI and terminal styling

### 🖥️ **Modern Window Management**
- **Tiling Layout**: Efficient bspwm window manager with intuitive controls
- **Smart Bars**: Polybar status bars with system monitoring and controls
- **Quick Launch**: Rofi application launcher and system menus  
- **Visual Effects**: Picom compositor with smooth animations
- **Notification System**: Clean dunst notifications
- **Hardware Detection**: Automatic configuration based on your system

### 💻 **Enhanced Terminal Experience**  
- **Powerlevel10k**: Beautiful, fast zsh prompt with git integration
- **Optimized Zsh**: Pre-configured shell with useful aliases and functions
- **Independent Installation**: Works with any window manager
- **Theme Coordination**: Matches UI themes when installed together

## Included Themes

| Theme | Description | Screenshot |
|-------|-------------|------------|
| **Galaxy** | Dark theme with purple/blue accents | [TODO] |
| **Nord** | Clean Nordic-inspired color scheme | [TODO] |
| **Haxor** | Cyberpunk/terminal aesthetic | [TODO] |

## Components

### UI Components (Window Manager)
- **Window Manager**: [bspwm](https://github.com/baskerville/bspwm) - Binary space partitioning window manager
- **Hotkey Daemon**: [sxhkd](https://github.com/baskerville/sxhkd) - Simple X hotkey daemon  
- **Status Bar**: [Polybar](https://github.com/polybar/polybar) - Fast and customizable status bar
- **Compositor**: [Picom](https://github.com/ibhagwan/picom) - Lightweight compositor for X11
- **Application Launcher**: [Rofi](https://github.com/davatorium/rofi) - Window switcher and launcher
- **Notifications**: [Dunst](https://github.com/dunst-project/dunst) - Lightweight notification daemon
- **Wallpaper**: [Feh](https://feh.finalrewind.org/) - Image viewer and wallpaper setter
- **Lock Screen**: [i3lock-color](https://github.com/Raymo111/i3lock-color) - Improved screen locker

### Terminal Components (Optional)
- **Shell**: [Zsh](https://www.zsh.org/) with enhanced configuration
- **Prompt**: [Powerlevel10k](https://github.com/romkatv/powerlevel10k) - Fast and customizable prompt
- **File Listing**: [lsd](https://github.com/Peltoche/lsd) - Modern ls replacement with colors and icons
- **File Viewer**: [bat](https://github.com/sharkdp/bat) - Cat with syntax highlighting
- **File Manager**: [ranger](https://github.com/ranger/ranger) - Console file manager
- **Editor**: [Neovim](https://neovim.io/) - Hyperextensible text editor
- **Fuzzy Finder**: [fzf](https://github.com/junegunn/fzf) - Command-line fuzzy finder
- **Plugins**: Syntax highlighting, autosuggestions, and productivity enhancements

## Prerequisites

### System Requirements
- **OS**: Ubuntu 20.04+ or Debian 11+ (primary support)
- **Display Server**: X11 (Wayland not supported)
- **Memory**: At least 2GB RAM recommended
- **Storage**: ~1GB free space for full installation

### Required Privileges
- User account with sudo access
- Internet connection for downloading packages

## Installation

### Quick Setup
```bash
# Check system compatibility
zui.sh check-deps

# Full installation (UI + Terminal)
zui.sh install

# Or specify a theme
zui.sh install -t nord
```

### Modular Installation

**UI Only** (preserve your terminal setup):
```bash
zui.sh install-ui-only
```

**Terminal Only** (enhance shell without UI):
```bash
zui.sh install-terminal
```

**Step by Step** (maximum control):
```bash
zui.sh install-deps
zui.sh install-core        # Install UI components
zui.sh install-terminal    # Configure terminal (optional)
zui.sh install-theme -t galaxy  # Apply theme
```

## 🎨 Theme Management

### List Available Themes
```bash
zui.sh list-themes
# or
zui-theme list
```

### Switch Themes
```bash
zui.sh apply-theme -t nord
# or
zui-theme nord
```

### Create New Theme
```bash
# Copy existing theme as template
cp -r themes/galaxy themes/mytheme
# Edit configurations in themes/mytheme/
```

## 💻 Terminal Configuration

ZUI provides optional terminal enhancement that works independently from UI themes.

### Features
- **Powerlevel10k**: Beautiful, fast zsh prompt
- **Enhanced Shell**: Zsh with useful plugins and modern tools
- **Backup Protection**: Preserves existing shell configurations
- **Independence**: Works with or without ZUI themes

### Installation
```bash
zui.sh install-terminal
```

## 🔧 Configuration Management

### Configuration Locations
```
~/.config/bspwm/           # Window manager settings
~/.config/polybar/         # Status bars  
~/.config/sxhkd/           # Keybindings
~/.config/rofi/            # Application launcher
~/.config/picom/           # Compositor effects
~/.zui/                    # ZUI installation directory
~/.zui/shell/              # Default terminal configurations
~/.p10k.zsh               # Your active P10k config (if installed)
~/.zshrc                  # Your active zsh config (if installed)
```

### Terminal Configuration Preservation
ZUI respects your existing terminal setup:

- **Existing configurations**: If you already have `~/.zshrc` or `~/.p10k.zsh`, theme installation won't overwrite them
- **Clean installations**: New users get default terminal configurations automatically
- **Modular updates**: You can update UI themes without affecting terminal settings
- **Independent terminal**: Terminal configuration works with or without ZUI themes

### Switching Between Themes
```bash
# Safely switch themes (preserves terminal config)
zui.sh install-theme -t nord
zui.sh install-theme -t galaxy
zui.sh install-theme -t haxor
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

### Configuration Files
- **System Config**: `~/.zui/common/system/config.yml`
- **Shell Config**: `~/.zui/shell/` 
- **Theme Configs**: `~/.config/` (bspwm, polybar, rofi, etc.)

### Multi-Monitor Setup
Edit `~/.zui/common/system/config.yml`:

```yaml
monitors:
  HDMI-1:
    resolution: 1920x1080
    main: 1
    workspaces: [1, 2, 3, 4, 5]
  eDP-1:
    resolution: 1920x1080
    position: left
    workspaces: [6, 7, 8, 9, 0]
```

## 🔄 Maintenance

### Update ZUI
```bash
git pull origin master
zui.sh install  # Re-run installation
```

### Backup Configuration
```bash
zui.sh backup
# or specify backup location
zui.sh backup -b /path/to/backup
```

### Restore Configuration
```bash
zui.sh restore -b /path/to/backup
```

### Clean Temporary Files
```bash
zui.sh clean
```

## 🗑️ Uninstallation

### UI-Focused Removal (Recommended)
```bash
zui.sh uninstall
```

This will:
- Remove ZUI directory and UI configurations
- Remove system rules and desktop entries
- **Preserve terminal configurations** (.zshrc, .p10k.zsh, shell tools)
- Restore backed up configurations (if available)
- Keep user data and most installed packages

### Complete Terminal Cleanup (Optional)
If you also want to remove terminal configurations:
```bash
# After running make uninstall, manually remove:
rm ~/.zshrc ~/.p10k.zshmake
rm -rf ~/powerlevel10k/

# Restore backups if they exist
if [ -f ~/.zshrc.backup ]; then mv ~/.zshrc.backup ~/.zshrc; fi
if [ -f ~/.p10k.zsh.backup ]; then mv ~/.p10k.zsh.backup ~/.p10k.zsh; fi
```

### Manual Package Cleanup
If you need to remove installed packages (be careful!):
```bash
# Remove window manager components (optional)
sudo apt remove bspwm sxhkd polybar rofi dunst picom

# Remove development tools (be careful!)
sudo apt remove build-essential cmake

# Remove terminal tools (optional)
sudo apt remove zsh lsd bat ranger neovim fzf
```

**Note**: The default uninstall preserves terminal configurations since they're user-specific and may be used outside of ZUI.

## 🤝 Contributing

We welcome contributions! Here's how you can help:

### Adding New Themes
1. Copy existing theme: `cp -r themes/galaxy themes/newtheme`
2. Customize configurations in `themes/newtheme/`
3. Test theme: `make install-theme THEME=newtheme`
4. Submit pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [baskerville](https://github.com/baskerville) - bspwm and sxhkd
- [polybar team](https://github.com/polybar/polybar) - Polybar status bar
- [All contributors](https://github.com/zurdi15/zui-linux/contributors) - Community improvements

**Note**: This project is designed for X11 environments. Wayland support may be added in future versions.
