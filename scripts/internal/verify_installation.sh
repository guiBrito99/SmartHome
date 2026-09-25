#!/bin/bash

# Internal script: verify_installation
# Usage: if scripts/internal/verify_installation.sh; then ... ; fi
# Exits 0 if openHAB is installed (runtime/bin/karaf present), 1 otherwise.

var_INTERNAL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
var_OPENHAB_DIR="$(cd "$var_INTERNAL_DIR/../.." && pwd)/openhab"

[ -f "$var_OPENHAB_DIR/runtime/bin/karaf" ]