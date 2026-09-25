#!/bin/bash

# ============================================================
# Smart Home - Configure Add-ons
# Interactive add-on manager. Reads the currently installed
# add-on urls from org.openhab.jsonaddonservice:urls= in
# conf/services/runtime.cfg, lets the user keep/remove each one
# (or skip all prompts with --keep) and offers add-ons that are
# not installed yet. Updates the urls line, creating it if needed.
# ============================================================

var_SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
var_OPENHAB_DIR="$(cd "$var_SCRIPT_DIR/../.." && pwd)/openhab"

# Redirect Karaf client home (.karaf folder) to project directory
export KARAF_HOME="$var_OPENHAB_DIR/karaf-home"
var_RUNTIME_CFG="$var_OPENHAB_DIR/conf/services/runtime.cfg"
var_KEY="org.openhab.jsonaddonservice:urls="

check_server_stopped() {
    if var_STATUS="$("$var_SCRIPT_DIR/../internal/get_server_status.sh")"; then
        echo "Server is running: $var_STATUS"
        echo "Please stop the server manually before continuing (run.sh --stop or menu option 2), then run this command again."
        return 1
    fi
    return 0
}

# Available add-ons not part of the base distribution, as "name|url" entries.
var_AVAILABLE_ADDONS=(
    "SmartHomeJ|https://download.smarthomej.org/addons.json"
)

# Read the pipe-separated add-on urls from the active urls line in runtime.cfg.
get_urls() {
    grep -E "^${var_KEY}" "$var_RUNTIME_CFG" | head -n 1 | sed "s#^${var_KEY}##"
}

# Rewrite the active urls line (or create it) to hold the given pipe-separated value.
set_urls() {
    local var_newval="$1"
    local var_tmp="${var_RUNTIME_CFG}.tmp"
    local var_found=0
    local var_line
    while var_IFS= read -r var_line || [ -n "$var_line" ]; do
        case "$var_line" in
            "${var_KEY}"*)
                var_found=1
                if [ -n "$var_newval" ]; then
                    echo "${var_KEY}${var_newval}"
                fi
                ;;
            *)
                echo "$var_line"
                ;;
        esac
    done < "$var_RUNTIME_CFG" > "$var_tmp"
    if [ "$var_found" -eq 0 ] && [ -n "$var_newval" ]; then
        echo "${var_KEY}${var_newval}" >> "$var_tmp"
    fi
    mv "$var_tmp" "$var_RUNTIME_CFG"
}

# Join array values with the pipe separator used by runtime.cfg.
join_pipe() {
    local var_out="" var_v
    for var_v in "$@"; do
        [ -z "$var_v" ] && continue
        var_out="${var_out:+$var_out|}${var_v}"
    done
    echo "$var_out"
}

# Check whether a url is contained in the given list.
contains_url() {
    local var_needle="$1"
    shift
    local var_u
    for var_u in "$@"; do
        [ "$var_u" = "$var_needle" ] && return 0
    done
    return 1
}

# Resolve a human-readable name for an installed url, or fall back to the url.
addon_name() {
    local var_url="$1" var_name var_u var_entry
    for var_entry in "${var_AVAILABLE_ADDONS[@]}"; do
        var_name="${var_entry%%|*}"
        var_u="${var_entry##*|}"
        if [ "$var_u" = "$var_url" ]; then
            echo "$var_name"
            return
        fi
    done
    echo "$var_url"
}

main() {
    local var_keep_mode=false
    if [ "$1" = "--keep" ]; then
        var_keep_mode=true
    fi

    if [ ! -d "$var_OPENHAB_DIR/runtime" ] && [ ! -f "$var_RUNTIME_CFG" ]; then
        echo "openHAB is not installed yet. Run ./start_server.sh first." >&2
        return 1
    fi

    check_server_stopped || return 1
    var_INSTALLED=()
    var_IFS='|' read -r -a var_INSTALLED <<< "$(get_urls)"

    echo "Add-on configuration"
    echo "===================="
    echo ""
    echo "Add-ons already installed:"
    if [ "${#var_INSTALLED[@]}" -eq 0 ]; then
        echo "  (none)"
    else
        for var_url in "${var_INSTALLED[@]}"; do
            [ -z "$var_url" ] && continue
            echo "  - $(addon_name "$var_url")"
        done
    fi
    echo ""

    var_REMAINING=()
    if [ "$var_keep_mode" = true ]; then
        echo "(--keep) Installed add-ons are preserved."
        var_REMAINING=("${var_INSTALLED[@]}")
    else
        for var_url in "${var_INSTALLED[@]}"; do
            [ -z "$var_url" ] && continue
            var_local_name=$(addon_name "$var_url")
            read -r -p "Keep or remove '${var_local_name}'? [K/r] " var_answer
            case "$var_answer" in
                [rR])
                    echo "Removed '${var_local_name}'."
                    ;;
                *)
                    var_REMAINING+=("$var_url")
                    echo "Kept '${var_local_name}'."
                    ;;
            esac
        done
    fi

    echo ""
    echo "Available add-ons:"
    var_NEW_ADDONS=()
    var_available_found=0
    for var_entry in "${var_AVAILABLE_ADDONS[@]}"; do
        var_name="${var_entry%%|*}"
        var_url="${var_entry##*|}"
        if contains_url "$var_url" "${var_REMAINING[@]}" || contains_url "$var_url" "${var_NEW_ADDONS[@]}"; then
            continue
        fi
        var_available_found=1
        read -r -p "Do you want to install '${var_name}' (${var_url})? [y/N] " var_answer
        case "$var_answer" in
            [yY]|[yY][eE][sS])
                var_NEW_ADDONS+=("$var_url")
                echo "Added '${var_name}'."
                ;;
            *)
                echo "Skipped '${var_name}'."
                ;;
        esac
    done
    if [ "$var_available_found" -eq 0 ]; then
        echo "  (all available add-ons are already installed)"
    fi

    set_urls "$(join_pipe "${var_REMAINING[@]}" "${var_NEW_ADDONS[@]}")"
}

main "$@"
var_STATUS=$?
exit $var_STATUS