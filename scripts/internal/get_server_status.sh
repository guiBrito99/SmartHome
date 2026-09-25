# ============================================================
# Smart Home - Get Server Status
# Internal function: get_server_status
# Usage: var_STATUS="$(get_server_status)"
# Prints NOT INSTALLED / RUNNING (PID: <pid>) / STOPPED.
# Returns 0 if the server is running, 1 if stopped, 2 if not installed.
# This is the state check the lifecycle scripts rely on: start_server
# asks "already running?" while the config/update/factory flows ask
# "running?" and refuse to continue.
# ============================================================

# Report the openHAB server state (installation plus root process).
get_server_status() {
    # Not installed: the runtime binary (karaf) is missing.
    if ! verify_installation; then
        echo "NOT INSTALLED"
        return 2
    fi

    # The instance file only exists after the server has started at least once,
    # so treat a missing file as "not running".
    local var_ROOT_PID
    var_ROOT_PID="$(get_root_pid)"

    # Installed and the recorded PID is alive -> RUNNING.
    if [ -n "$var_ROOT_PID" ] && [ "$var_ROOT_PID" -ne 0 ] && kill -0 "$var_ROOT_PID" 2>/dev/null; then
        echo "RUNNING (PID: $var_ROOT_PID)"
        return 0
    fi

    # Installed but the recorded PID is missing or dead -> STOPPED.
    echo "STOPPED"
    return 1
}
