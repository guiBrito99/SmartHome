# ============================================================
# Smart Home - Get Root PID
# Internal function: get_root_pid
# Usage: var_ROOT_PID="$(get_root_pid)"
# Prints the openHAB root instance PID (from Karaf's
# instance.properties), or nothing when the file is missing — callers
# treat empty output as "no PID recorded". Also used by get_server_status.
# ============================================================

# Print the recorded root instance PID, if Karaf wrote one.
get_root_pid() {
    if [ -f "$var_INSTANCE_PROPS" ]; then
        sed -n -e '/item\.0\.pid/ s/.*= *//p' "$var_INSTANCE_PROPS"
    fi
}
