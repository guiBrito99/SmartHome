#!/bin/bash

# ============================================================
# Smart Home - Factory Reset
# Destructive operation: asks for confirmation, then stops the
# server, removes the openhab/ and karaf-home/ directories and
# pulls the latest changes from git.
# ============================================================

# Absolute paths derived from the script location (cwd-independent).
var_SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
var_PROJECT_DIR="$(cd "$var_SCRIPT_DIR/../.." && pwd)"

# Ask for explicit confirmation before doing anything destructive.
confirm_reset() {
    echo "=========================================="
    echo "      Smart Home - Factory Reset"
    echo "=========================================="
    echo ""
    echo "WARNING: This will delete all local changes and data!"
    echo "The following will be removed:"
    echo "  - openhab/ directory (runtime, config, userdata)"
    echo "  - karaf-home/ directory (client history)"
    echo "  - Any local config modifications"
    echo ""
    read -r -p "Are you sure you want to continue? [y/N] " var_answer
    case "$var_answer" in
        [yY]|[yY][eE][sS])
            echo "Proceeding with factory reset..."
            ;;
        *)
            echo "Aborted."
            return 1
            ;;
    esac
}

# Step 0: stop the server before deleting its files.
stop_server() {
    echo ""
    echo "Step 0: Stopping the server before deletion..."
    "$var_SCRIPT_DIR/stop_server.sh" || return 1
}

# Step 1: remove the whole openHAB runtime.
remove_openhab() {
    echo ""
    echo "Step 1: Removing local openhab/ directory..."
    rm -rf "$var_PROJECT_DIR/openhab"
    echo "  Done."
}

# Step 2: remove the Karaf client home history.
remove_karaf_home() {
    echo ""
    echo "Step 2: Removing karaf-home/ directory..."
    rm -rf "$var_PROJECT_DIR/karaf-home"
    echo "  Done."
}

# Step 3: pull the latest changes from the remote repository.
pull_latest() {
    echo ""
    echo "Step 3: Pulling latest changes from git..."
    cd "$var_PROJECT_DIR"
    git pull || return 1
    echo "  Done."
}

# Entry point: confirm -> stop -> delete -> pull. Single exit point.
main() {
    confirm_reset || return 1
    stop_server || return 1
    remove_openhab
    remove_karaf_home
    pull_latest || return 1

    echo ""
    echo "=========================================="
    echo "Factory reset complete!"
    echo "=========================================="
}

main
var_STATUS=$?
exit $var_STATUS