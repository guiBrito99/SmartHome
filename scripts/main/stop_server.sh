#!/bin/bash

# ============================================================
# Smart Home - Stop Server
# Gracefully shuts openHAB down: sends the shutdown signal,
# waits for the Karaf instance to exit (10s timeout), and
# force-kills it if it hangs. The optional --clean flag also
# wipes the cache/tmp directories.
# ============================================================

# Absolute paths derived from the script location (cwd-independent).
var_SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
var_OPENHAB_DIR="$(cd "$var_SCRIPT_DIR/../.." && pwd)/openhab"

# Redirect Karaf client home (.karaf folder) to the project directory.
export KARAF_HOME="$("$var_SCRIPT_DIR/../internal/set_karaf_home.sh")"

# Ask openHAB to shut down gracefully via its stop binary.
# Only a JVM-resolution failure aborts; a stop failure is tolerated
# because the forced-kill fallback still kicks in afterwards.
stop_signal() {
    if [ -x "$var_OPENHAB_DIR/runtime/bin/stop" ]; then
        echo "Sending shutdown signal to openHAB..."
        var_JAVA_HOME="$("$var_SCRIPT_DIR/../internal/resolve_jvm.sh")" || return 1
        export JAVA_HOME="$var_JAVA_HOME"
        "$var_OPENHAB_DIR/runtime/bin/stop"
    else
        echo "openHAB installation not found. Skipping."
    fi
    return 0
}

# Wait for the root instance to terminate; force-kill if it hangs.
# Falls back to pgrep when the PID file is missing, as a safety net.
wait_for_shutdown() {
    var_ROOT_PID="$("$var_SCRIPT_DIR/../internal/get_root_pid.sh")"

    if [ -n "$var_ROOT_PID" ] && [ "$var_ROOT_PID" -ne 0 ]; then
        echo "Found openHAB root instance PID: $var_ROOT_PID"

        # Wait for the process to exit gracefully.
        echo "Waiting for the Java process to terminate..."
        var_TIMEOUT=10
        while [ "$var_TIMEOUT" -gt 0 ]; do
            if ! kill -0 "$var_ROOT_PID" 2>/dev/null; then
                echo "openHAB completely shut down."
                return 0
            fi
            sleep 1
            var_TIMEOUT=$((var_TIMEOUT-1))
        done

        # Failsafe: force-kill if it hung.
        if kill -0 "$var_ROOT_PID" 2>/dev/null; then
            echo "Warning: openHAB did not shut down in time. Forcing termination..."
            kill -9 "$var_ROOT_PID" 2>/dev/null
            echo "openHAB forcefully terminated."
        fi
        return 0
    fi

    echo "No running openHAB instance found (PID file missing or empty)."

    # Fallback: try pgrep as a safety net for stray Java processes.
    if ! pgrep -f "openhab.*java" > /dev/null; then
        return 0
    fi
    echo "Fallback: found stray Java processes matching openHAB..."
    var_TIMEOUT=10
    while [ "$var_TIMEOUT" -gt 0 ]; do
        if ! pgrep -f "openhab.*java" > /dev/null; then
            echo "openHAB completely shut down."
            return 0
        fi
        sleep 1
        var_TIMEOUT=$((var_TIMEOUT-1))
    done
    echo "Warning: openHAB did not shut down in time. Forcing termination..."
    pkill -9 -f "openhab.*java"
    echo "openHAB forcefully terminated."
    return 0
}

# Wipe the temporary cache/tmp directories when called with --clean.
clear_cache() {
    if [ "$1" = "--clean" ]; then
        echo "(--clean) Wiping openHAB temporary cache..."
        rm -rf "$var_OPENHAB_DIR/userdata/cache/"*
        rm -rf "$var_OPENHAB_DIR/userdata/tmp/"*
        echo "Cache cleared."
    fi
}

# Entry point: stop signal -> wait for exit -> optional cache wipe.
# Single exit point.
main() {
    echo "Initiating Smart Home shutdown..."

    stop_signal || return 1
    wait_for_shutdown || return 1
    clear_cache "$1"

    echo "Smart Home is fully stopped."
}

main "$@"
var_STATUS=$?
exit $var_STATUS