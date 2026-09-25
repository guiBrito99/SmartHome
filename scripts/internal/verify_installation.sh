# ============================================================
# Smart Home - Verify Installation
# Internal function: verify_installation
# Usage: if verify_installation; then ... ; fi
# Returns 0 if openHAB is installed (runtime/bin/karaf present), 1 otherwise.
# Single source of truth for "is openHAB installed?", shared with
# get_server_status and the install/update/config/reboot/factory flows.
# ============================================================

# Report whether the openHAB runtime is present in the project directory.
# Prints nothing, so callers use it as `if verify_installation; then`.
verify_installation() {
    [ -f "$var_OPENHAB_DIR/runtime/bin/karaf" ]
}
