#!/bin/bash

OPENHAB_DIR="$(dirname "$0")/../openhab"
INSTANCE_PROPS="$OPENHAB_DIR/userdata/tmp/instances/instance.properties"

echo "Initiating Smart Home shutdown..."

# 1. Stop signal to openHAB
if [ -x "$OPENHAB_DIR/runtime/bin/stop" ]; then
    echo "Sending shutdown signal to openHAB..."
    "$OPENHAB_DIR/runtime/bin/stop"
else
    echo "openHAB installation not found. Skipping."
fi

# 2. Get the root instance PID from Karaf's instance.properties
get_root_pid() {
    if [ -f "$INSTANCE_PROPS" ]; then
        sed -n -e '/item\.0\.pid/ s/.*= *//p' "$INSTANCE_PROPS"
    fi
}

ROOT_PID=$(get_root_pid)

if [ -n "$ROOT_PID" ] && [ "$ROOT_PID" -ne 0 ]; then
    echo "Found openHAB root instance PID: $ROOT_PID"

    # 3. Wait for the process to exit gracefully
    echo "Waiting for the Java process to terminate..."
    TIMEOUT=10
    while [ $TIMEOUT -gt 0 ]; do
        if ! kill -0 "$ROOT_PID" 2>/dev/null; then
            echo "openHAB completely shut down."
            break
        fi
        sleep 1
        TIMEOUT=$((TIMEOUT-1))
    done

    # 4. Failsafe: Force kill if it hung
    if kill -0 "$ROOT_PID" 2>/dev/null; then
        echo "Warning: openHAB did not shut down in time. Forcing termination..."
        kill -9 "$ROOT_PID" 2>/dev/null
        echo "openHAB forcefully terminated."
    fi
else
    echo "No running openHAB instance found (PID file missing or empty)."

    # Fallback: try pgrep as a safety net
    if pgrep -f "openhab.*java" > /dev/null; then
        echo "Fallback: found stray Java processes matching openHAB..."
TIMEOUT=10
        while [ $TIMEOUT -gt 0 ]; do
            if ! pgrep -f "openhab.*java" > /dev/null; then
                echo "openHAB completely shut down."
                break
            fi
            sleep 1
            TIMEOUT=$((TIMEOUT-1))
        done
        if pgrep -f "openhab.*java" > /dev/null; then
            echo "Warning: openHAB did not shut down in time. Forcing termination..."
            pkill -9 -f "openhab.*java"
            echo "openHAB forcefully terminated."
        fi
    fi
fi

# 5. Clear Cache if requested
if [ "$1" = "--clean" ]; then
    echo "(--clean) Wiping openHAB temporary cache..."
    rm -rf "$OPENHAB_DIR/userdata/cache/"*
    rm -rf "$OPENHAB_DIR/userdata/tmp/"*
    echo "Cache cleared."
fi

echo "Smart Home is fully stopped."
