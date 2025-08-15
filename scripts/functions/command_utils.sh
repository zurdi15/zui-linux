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
