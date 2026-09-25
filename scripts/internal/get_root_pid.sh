#!/bin/bash

# Internal script: get_root_pid
# Usage: var_ROOT_PID=$(scripts/internal/get_root_pid.sh)
# Prints the openHAB root instance PID (from Karaf's instance.properties), or nothing.

var_INTERNAL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
var_OPENHAB_DIR="$(cd "$var_INTERNAL_DIR/../.." && pwd)/openhab"
var_INSTANCE_PROPS="$var_OPENHAB_DIR/userdata/tmp/instances/instance.properties"

# The instance file only exists after the server has started at least once.
if [ -f "$var_INSTANCE_PROPS" ]; then
    sed -n -e '/item\.0\.pid/ s/.*= *//p' "$var_INSTANCE_PROPS"
fi