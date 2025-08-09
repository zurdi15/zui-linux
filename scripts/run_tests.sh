#!/bin/bash
# ZUI Test Runner
# Runs basic tests to validate ZUI installation

set -uo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
ZUI_PATH=${ZUI_PATH:-${HOME}/.zui}
CONFIG_PATH=${CONFIG_PATH:-${HOME}/.config}

# Test results
PASSED=0
FAILED=0

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

# Test function wrapper
run_test() {
    local test_name="$1"
    local test_func="$2"
    
    echo -n "Running $test_name ... "
    
    if $test_func 2>/dev/null; then
        echo -e "${GREEN}PASS${NC}"
        ((PASSED++))
        return 0
    else
        echo -e "${RED}FAIL${NC}"
        ((FAILED++))
        return 1
    fi
}

# Test ZUI directory structure
test_zui_structure() {
    [[ -d "$ZUI_PATH" ]] && \
    [[ -d "$ZUI_PATH/common" ]] && \
    [[ -d "$ZUI_PATH/themes" ]]
}

# Test current theme link
test_current_theme() {
    [[ -L "$ZUI_PATH/current_theme" ]] && \
    [[ -d "$ZUI_PATH/current_theme" ]]
}

# Test configuration symlinks
test_config_symlinks() {
    [[ -L "$CONFIG_PATH/bspwm" ]] && \
    [[ -L "$CONFIG_PATH/sxhkd" ]]
}

# Test essential executables
test_executables() {
    command -v bspwm >/dev/null && \
    command -v sxhkd >/dev/null && \
    command -v rofi >/dev/null
}

# Test ZUI utilities
test_zui_utilities() {
    [[ -x "$HOME/.local/bin/zui-theme" ]] && \
    [[ -x "$HOME/.local/bin/zui-wallpaper" ]]
}

# Test polybar configuration
test_polybar_config() {
    [[ -f "$CONFIG_PATH/polybar/launch.sh" ]] && \
    [[ -x "$CONFIG_PATH/polybar/launch.sh" ]]
}

# Test bspwm configuration
test_bspwm_config() {
    [[ -f "$CONFIG_PATH/bspwm/bspwmrc" ]] && \
    [[ -x "$CONFIG_PATH/bspwm/bspwmrc" ]]
}

# Test sxhkd configuration
test_sxhkd_config() {
    [[ -f "$CONFIG_PATH/sxhkd/sxhkdrc" ]]
}

# Test wallpaper setup
test_wallpaper() {
    [[ -L "$ZUI_PATH/current_theme/wallpapers/current_wallpaper" ]] && \
    [[ -f "$ZUI_PATH/current_theme/wallpapers/current_wallpaper" ]]
}

# Test shell configuration
test_shell_config() {
    [[ -L "$HOME/.zshrc" ]] || [[ -f "$HOME/.zshrc" ]]
}

# Test system modules
test_system_modules() {
    local modules_dir="$ZUI_PATH/common/system/modules"
    [[ -d "$modules_dir" ]] && \
    [[ -x "$modules_dir/audio/general/interface.sh" ]] && \
    [[ -x "$modules_dir/powermenu/interface.sh" ]]
}

# Test configuration files syntax
test_config_syntax() {
    # Test bspwmrc syntax (basic shell syntax)
    if [[ -f "$CONFIG_PATH/bspwm/bspwmrc" ]]; then
        bash -n "$CONFIG_PATH/bspwm/bspwmrc"
    fi
    
    # Test polybar config (basic ini syntax)
    if [[ -f "$CONFIG_PATH/polybar/colors.ini" ]]; then
        # Basic check for common ini syntax errors
        ! grep -q "^[[:space:]]*=" "$CONFIG_PATH/polybar/colors.ini"
    fi
}

# Integration tests (require running session)
test_integration() {
    if [[ -n "${DISPLAY:-}" ]]; then
        log_info "Running integration tests..."
        
        # Test if bspwm is running
        if pgrep -x bspwm >/dev/null; then
            log_success "bspwm is running"
            
            # Test bspwm queries
            if bspc query -D >/dev/null 2>&1; then
                log_success "bspwm queries work"
            else
                log_warn "bspwm queries failed"
            fi
        else
            log_warn "bspwm is not running"
        fi
        
        # Test rofi
        if rofi -help >/dev/null 2>&1; then
            log_success "rofi is functional"
        else
            log_warn "rofi test failed"
        fi
    else
        log_info "No display available, skipping integration tests"
    fi
}

# Performance tests
test_performance() {
    log_info "Running performance tests..."
    
    # Test startup time for key components
    if command -v bspwm >/dev/null; then
        local start_time
        start_time=$(date +%s%3N)
        bspwm --help >/dev/null 2>&1 || true
        local end_time
        end_time=$(date +%s%3N)
        local duration=$((end_time - start_time))
        
        if [[ $duration -lt 1000 ]]; then
            log_success "bspwm startup time: ${duration}ms"
        else
            log_warn "bspwm startup time slow: ${duration}ms"
        fi
    fi
}

# Security tests
test_security() {
    log_info "Running security tests..."
    
    # Check file permissions
    local secure=true
    
    # Check that system directories are not world-writable
    if [[ -d "$ZUI_PATH" ]]; then
        local perms
        perms=$(stat -c %a "$ZUI_PATH")
        if [[ "${perms: -1}" -gt 5 ]]; then
            log_warn "ZUI directory is world-writable: $ZUI_PATH ($perms)"
            secure=false
        fi
    fi
    
    # Check executable permissions on scripts
    if [[ -f "$HOME/.local/bin/zui-theme" ]]; then
        if [[ ! -x "$HOME/.local/bin/zui-theme" ]]; then
            log_warn "ZUI theme utility is not executable"
            secure=false
        fi
    fi
    
    if $secure; then
        log_success "Security checks passed"
    else
        log_warn "Some security issues found"
    fi
}

# Main test function
main() {
    log_info "Starting ZUI tests..."
    
    echo ""
    echo "=============================="
    echo "ZUI Test Suite"
    echo "=============================="
    echo ""
    
    # Core functionality tests
    echo "Core Tests:"
    run_test "ZUI directory structure" test_zui_structure
    run_test "Current theme link" test_current_theme
    run_test "Configuration symlinks" test_config_symlinks
    run_test "Essential executables" test_executables
    run_test "ZUI utilities" test_zui_utilities
    
    echo ""
    echo "Configuration Tests:"
    run_test "Polybar configuration" test_polybar_config
    run_test "bspwm configuration" test_bspwm_config
    run_test "sxhkd configuration" test_sxhkd_config
    run_test "Wallpaper setup" test_wallpaper
    run_test "Shell configuration" test_shell_config
    run_test "System modules" test_system_modules
    run_test "Configuration syntax" test_config_syntax
    
    echo ""
    
    # Additional tests
    test_integration
    test_performance
    test_security
    
    echo ""
    echo "=============================="
    echo "Test Results:"
    echo "  Passed: $PASSED"
    echo "  Failed: $FAILED"
    echo "  Total:  $((PASSED + FAILED))"
    
    if [[ $FAILED -eq 0 ]]; then
        echo -e "  Status: ${GREEN}ALL TESTS PASSED${NC}"
        echo "=============================="
        return 0
    else
        echo -e "  Status: ${RED}SOME TESTS FAILED${NC}"
        echo "=============================="
        return 1
    fi
}

# Show usage
show_usage() {
    echo "Usage: $0 [test_type]"
    echo ""
    echo "Test types:"
    echo "  all         - Run all tests (default)"
    echo "  core        - Run core functionality tests"
    echo "  config      - Run configuration tests"
    echo "  integration - Run integration tests"
    echo "  performance - Run performance tests"
    echo "  security    - Run security tests"
    echo ""
}

# Handle command line arguments
case "${1:-all}" in
    "all"|"")
        main
        ;;
    "core")
        run_test "ZUI directory structure" test_zui_structure
        run_test "Current theme link" test_current_theme
        run_test "Configuration symlinks" test_config_symlinks
        run_test "Essential executables" test_executables
        run_test "ZUI utilities" test_zui_utilities
        ;;
    "config")
        run_test "Polybar configuration" test_polybar_config
        run_test "bspwm configuration" test_bspwm_config
        run_test "sxhkd configuration" test_sxhkd_config
        run_test "Configuration syntax" test_config_syntax
        ;;
    "integration")
        test_integration
        ;;
    "performance")
        test_performance
        ;;
    "security")
        test_security
        ;;
    "help"|"-h"|"--help")
        show_usage
        exit 0
        ;;
    *)
        echo "Error: Unknown test type '$1'"
        show_usage
        exit 1
        ;;
esac
