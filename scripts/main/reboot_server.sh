#!/bin/bash

# ============================================================
# Smart Home - Reboot Server
# Stops the server (aborting if the stop fails), waits shortly,
# then starts it again.
# ============================================================

# Absolute path derived from the script location (cwd-independent).
var_SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Stop the server; abort the reboot if the stop fails.
stop_server() {
    echo "Step 1: Stopping server..."
    if ! "$var_SCRIPT_DIR/stop_server.sh"; then
        echo "Error: failed to stop the server. Aborting reboot."
        return 1
    fi
}

# Start the server again.
start_server() {
    echo ""
    echo "Step 2: Starting server..."
    "$var_SCRIPT_DIR/start_server.sh" || return 1
}

# Entry point: stop -> short pause -> start. Single exit point.
main() {
    echo "Rebooting server..."

    stop_server || return 1

    echo ""
    echo "Waiting 2 seconds before restart..."
    sleep 2

    start_server || return 1

    echo ""
    echo "Reboot complete."
}

main
var_STATUS=$?
exit $var_STATUS