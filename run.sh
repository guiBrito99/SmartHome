#!/bin/bash

# ============================================================
# Smart Home - Server Control
# Main entry point of the project.
#
#   ./run.sh                        -> interactive menu
#   ./run.sh --start                -> start the server
#   ./run.sh --stop                 -> stop the server
#   ./run.sh --reboot               -> restart the server
#   ./run.sh --config               -> configure add-ons
#   ./run.sh --auto                 -> install, configure, start and verify
#   ./run.sh --update               -> update openHAB
#   ./run.sh --factory-reset        -> wipe and restore the project
# ============================================================

# Re-run this script with sudo if it was started without root privileges.
if [ "$EUID" -ne 0 ]; then
    exec sudo "$0" "$@"
fi

# Absolute paths derived from the script location (cwd-independent).
var_SCRIPT_DIR="$(cd "$(dirname "$0")/scripts/main" && pwd)"
var_OPENHAB_DIR="$(cd "$var_SCRIPT_DIR/../.." && pwd)/openhab"

# Print the menu header and the current server status on screen.
show_menu() {
    clear
    echo "=========================================="
    echo "      Smart Home - Server Control"
    echo "=========================================="
    echo ""
    var_STATUS="$("$(dirname "$0")/scripts/internal/get_server_status.sh")"
    echo "  Server Status: $var_STATUS"
    echo ""
    echo "  1) Start server"
    echo "  2) Stop server"
    echo "  3) Reboot server"
    echo "  4) Configure add-ons"
    echo "  5) Auto install"
    echo "  6) Update server"
    echo "  7) Factory reset"
    echo "  8) Exit"
    echo ""
    echo "=========================================="
}

# Prompt the user to enter a menu choice and print the answer.
read_choice() {
    local var_choice
    read -r -p "Enter your choice [1-8]: " var_choice
    echo "$var_choice"
}

# Run one of the operation scripts, then wait for the user to press Enter.
# Returns the exit status of the executed script.
run_script() {
    local var_script_name="$1"

    echo "Running $var_script_name..."
    "$var_SCRIPT_DIR/$var_script_name"
    var_RUN_STATUS=$?
    echo ""
    read -r -p "Press Enter to continue..."
    return $var_RUN_STATUS
}

# Map a CLI mode name (--<mode>) to the script that implements that operation.
mode_to_script() {
    case "$1" in
        start)          echo "start_server.sh" ;;
        stop)           echo "stop_server.sh" ;;
        reboot)         echo "reboot_server.sh" ;;
        config)         echo "config_server.sh" ;;
        auto)           echo "auto_install.sh" ;;
        update)         echo "update_server.sh" ;;
        factory-reset)  echo "factoryReset_server.sh" ;;
        *)              return 1 ;;
    esac
}

# Non-interactive mode: run a single operation selected via --<mode>.
cli_mode() {
    local var_mode="$1"
    local var_script_name
    var_script_name=$(mode_to_script "$var_mode") || {
        echo "Unknown mode: '$var_mode'"
        echo "Usage: $0 --[start|stop|reboot|config|auto|update|factory-reset]"
        return 1
    }
    echo "Running $var_script_name..."
    "$var_SCRIPT_DIR/$var_script_name" || return 1
}

# Interactive mode: keep showing the menu until the user picks "Exit" (8).
# A failed operation returns to the menu instead of aborting it.
menu_mode() {
    local var_choice=0
    while [[ $var_choice -ne 8 ]]; do
        show_menu
        var_choice=$(read_choice)
        case "$var_choice" in
            1) run_script "start_server.sh" ;;
            2) run_script "stop_server.sh" ;;
            3) run_script "reboot_server.sh" ;;
            4) run_script "config_server.sh" ;;
            5) run_script "auto_install.sh" ;;
            6) run_script "update_server.sh" ;;
            7) run_script "factoryReset_server.sh" ;;
            8) echo "Exiting..." ; return 0 ;;
            *) echo "Invalid choice. Please try again." ; sleep 1 ;;
        esac
    done
}

# Entry point: dispatch to the menu (no args) or CLI mode (a single --flag).
main() {
    if [[ $# -eq 0 ]]; then
        menu_mode || return 1
    elif [[ $# -eq 1 ]]; then
        if [[ $1 == --* ]]; then
            echo "Running cli mode"
            cli_mode "${1#--}" || return 1
        else
            echo "Error: Invalid flag structure"
            return 1
        fi
    else
        echo "Error: Only one flag can be used in cli mode"
        return 1
    fi
}

# Execute the entry point and exit with its status (single exit point).
main "$@"
var_STATUS=$?
exit $var_STATUS