#!/bin/bash

# ============================================================
# Smart Home - Auto Install & Start
# One-shot setup used by 'run.sh --auto' and menu option 5:
#   1. Download openHAB if missing and update it
#   2. Configure add-ons (interactive)
#   3. Start the server
#   4. Verify the server is actually running
# ============================================================

# Absolute paths derived from the script location (cwd-independent).
var_SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
var_OPENHAB_DIR="$(cd "$var_SCRIPT_DIR/../.." && pwd)/openhab"

# openHAB distribution to download when none is installed yet.
var_OPENHAB_VERSION="4.2.0"
var_OPENHAB_URL="https://github.com/openhab/openhab-distro/releases/download/${var_OPENHAB_VERSION}/openhab-${var_OPENHAB_VERSION}.tar.gz"

# Download and extract openHAB if it is not installed yet.
# Skips silently when runtime/bin/karaf is already present.
download_openhab() {
    if [ -f "$var_OPENHAB_DIR/runtime/bin/karaf" ]; then
        echo "openHAB is already installed at ${var_OPENHAB_DIR}."
        return 0
    fi
    echo "openHAB not found in ${var_OPENHAB_DIR}. Downloading openHAB ${var_OPENHAB_VERSION}..."
    mkdir -p "$var_OPENHAB_DIR" || return 1
    wget -q --show-progress -O "/tmp/openhab-${var_OPENHAB_VERSION}.tar.gz" "$var_OPENHAB_URL" || return 1
    tar -xzf "/tmp/openhab-${var_OPENHAB_VERSION}.tar.gz" -C "$var_OPENHAB_DIR" || return 1
    rm -f "/tmp/openhab-${var_OPENHAB_VERSION}.tar.gz"
    if [ ! -f "$var_OPENHAB_DIR/runtime/bin/karaf" ]; then
        echo "Error: openHAB download or extraction failed."
        return 1
    fi
    echo "openHAB ${var_OPENHAB_VERSION} downloaded to ${var_OPENHAB_DIR}."
}

# Step 1: ensure openHAB is present, then run the update routine.
install_openhab() {
    echo "Step 1: Installing/updating openHAB..."
    download_openhab || return 1
    "$var_SCRIPT_DIR/update_server.sh" || return 1
}

# Step 2: prompt the user to configure the add-ons.
configure_addons() {
    echo ""
    echo "Step 2: Configuring add-ons..."
    "$var_SCRIPT_DIR/config_server.sh" || return 1
}

# Step 3: start the server.
start_openhab() {
    echo ""
    echo "Step 3: Starting openHAB..."
    "$var_SCRIPT_DIR/start_server.sh" || return 1
}

# Step 4: check the server status and fail if it did not come up.
verify_running() {
    echo ""
    echo "Step 4: Verifying server status..."
    sleep 3
    var_STATUS="$("$var_SCRIPT_DIR/../internal/get_server_status.sh")"
    echo "Server Status: $var_STATUS"
    case "$var_STATUS" in
        RUNNING*) echo "openHAB is up and running." ;;
        *)
            echo "Error: openHAB is not running after the setup."
            return 1
            ;;
    esac
}

# Entry point: install/update -> configure -> start -> verify.
# Single exit point.
main() {
    echo "=========================================="
    echo "   Smart Home - Auto Install & Start"
    echo "=========================================="
    echo ""

    install_openhab || return 1
    configure_addons || return 1
    start_openhab || return 1
    verify_running || return 1
}

main
var_STATUS=$?
exit $var_STATUS