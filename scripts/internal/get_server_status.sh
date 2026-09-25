#!/bin/bash

# Internal script: get_server_status
# Usage: var_STATUS=$(scripts/internal/get_server_status.sh)
# Prints NOT INSTALLED / RUNNING (PID: <pid>) / STOPPED. Exits 0 if running.

var_INTERNAL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
var_OPENHAB_DIR="$(cd "$var_INTERNAL_DIR/../.." && pwd)/openhab"
var_INSTANCE_PROPS="$var_OPENHAB_DIR/userdata/tmp/instances/instance.properties"

# Not installed: the runtime binary (karaf) is missing.
if [ ! -f "$var_OPENHAB_DIR/runtime/bin/karaf" ]; then
    echo "NOT INSTALLED"
    exit 2
fi

# The instance file only exists after the server has started at least once,
# so treat a missing file as "not running".
if [ -f "$var_INSTANCE_PROPS" ]; then
    var_ROOT_PID="$(sed -n -e '/item\.0\.pid/ s/.*= *//p' "$var_INSTANCE_PROPS")"
else
    var_ROOT_PID=""
fi

# Installed and the recorded PID is alive -> RUNNING.
if [ -n "$var_ROOT_PID" ] && [ "$var_ROOT_PID" -ne 0 ] && kill -0 "$var_ROOT_PID" 2>/dev/null; then
    echo "RUNNING (PID: $var_ROOT_PID)"
    exit 0
fi

# Installed but the recorded PID is missing or dead -> STOPPED.
echo "STOPPED"
exit 1