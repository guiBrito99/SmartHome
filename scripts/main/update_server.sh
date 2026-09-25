#!/bin/bash

# ============================================================
# Smart Home - Update Server
# Updates an existing openHAB installation. Fails if openHAB is
# not installed yet (use 'run.sh --install' or install.sh to
# install it first). Requires a stopped server, resolves a JVM,
# and runs openhab/runtime/bin/update from the openHAB root.
# ============================================================

# Absolute paths derived from the script location (cwd-independent).
var_SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
var_OPENHAB_DIR="$(cd "$var_SCRIPT_DIR/../.." && pwd)/openhab"

# Fail with a helpful message if openHAB is not installed yet.
check_installation() {
    if ! "$var_SCRIPT_DIR/../internal/verify_installation.sh"; then
        echo "Error: openHAB is not installed at ${var_OPENHAB_DIR}."
        echo "Run 'run.sh --install' to install openHAB first."
        return 1
    fi
}

check_server_stopped() {
    if var_STATUS="$("$var_SCRIPT_DIR/../internal/get_server_status.sh")"; then
        echo "Server is running: $var_STATUS"
        echo "Please stop the server manually before continuing (run.sh --stop or menu option 2), then run this command again."
        return 1
    fi
    return 0
}

# Resolve a JVM supported by openHAB and export it as JAVA_HOME.
resolve_jvm() {
    var_JAVA_HOME="$("$var_SCRIPT_DIR/../internal/resolve_jvm.sh")" || return 1
    export JAVA_HOME="$var_JAVA_HOME"
}

# Run the openHAB update binary from the openHAB root directory.
run_update() {
    echo "Running openHAB update..."
    if (cd "$var_OPENHAB_DIR" && "$var_OPENHAB_DIR/runtime/bin/update"); then
        echo "openHAB update completed successfully."
        return 0
    fi
    echo "openHAB update skipped/failed."
    return 1
}

# Entry point: install check -> manual-stop check -> JVM -> update.
# Single exit point.
main() {
    echo "=========================================="
    echo "      Smart Home - Update Server"
    echo "=========================================="
    echo ""

    check_installation || return 1
    check_server_stopped || return 1
    resolve_jvm || return 1
    run_update || return 1

    echo ""
    echo "Update process complete."
}

main
var_STATUS=$?
exit $var_STATUS