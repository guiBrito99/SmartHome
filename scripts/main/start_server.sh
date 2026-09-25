#!/bin/bash

# ============================================================
# Smart Home - Start Server
# Verifies that openHAB is installed, resolves a JVM version
# supported by openHAB, exports the environment variables the
# openHAB binaries require, then launches the runtime.
# ============================================================

# Absolute paths derived from the script location (cwd-independent).
var_SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
var_OPENHAB_DIR="$(cd "$var_SCRIPT_DIR/../.." && pwd)/openhab"

# Redirect Karaf client home (.karaf folder) to the project directory.
export KARAF_HOME="$("$var_SCRIPT_DIR/../internal/set_karaf_home.sh")"

# Fail with a helpful message if openHAB is not installed yet.
check_installation() {
    if ! "$var_SCRIPT_DIR/../internal/verify_installation.sh"; then
        echo "Error: openHAB is not installed at ${var_OPENHAB_DIR}."
        echo "Run 'run.sh --install' to install openHAB first."
        return 1
    fi
}

check_server_status() {
    if var_STATUS="$("$var_SCRIPT_DIR/../internal/get_server_status.sh")"; then
        echo "Server is already running: $var_STATUS"
        return 0
    fi
    return 1
}

# Resolve a JVM supported by openHAB and export it as JAVA_HOME.
resolve_jvm() {
    var_JAVA_HOME="$("$var_SCRIPT_DIR/../internal/resolve_jvm.sh")" || return 1
    export JAVA_HOME="$var_JAVA_HOME"
    echo "Smart Home booting with JAVA_HOME=$JAVA_HOME"
}

# Launch the openHAB daemon (returns immediately).
start_openhab() {
    "$var_OPENHAB_DIR/runtime/bin/start"
}

# Entry point: running check -> install check -> JVM resolution -> start. Single exit point.
main() {
    if check_server_status; then
        return 0
    fi
    check_installation || return 1
    resolve_jvm || return 1
    start_openhab
}

main
var_STATUS=$?
exit $var_STATUS