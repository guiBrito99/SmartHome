#!/bin/bash

# Internal script: set_karaf_home
# Usage: var_KARAF_HOME=$(scripts/internal/set_karaf_home.sh)
# Prints the Karaf client home path (.karaf folder) within the project directory.

var_INTERNAL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
var_OPENHAB_DIR="$(cd "$var_INTERNAL_DIR/../.." && pwd)/openhab"

echo "$var_OPENHAB_DIR/karaf-home"