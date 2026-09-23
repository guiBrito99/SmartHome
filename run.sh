#!/bin/bash

SCRIPT_DIR="$(dirname "$0")/scripts"

show_menu() {
    clear
    echo "=========================================="
    echo "      Smart Home HQ - Server Control"
    echo "=========================================="
    echo ""
    echo "  1) Start server"
    echo "  2) Stop server"
    echo "  3) Reboot server"
    echo "  4) Exit"
    echo ""
    echo "=========================================="
}

read_choice() {
    local choice
    read -r -p "Enter your choice [1-4]: " choice
    echo "$choice"
}

start_server() {
    echo "Starting server..."
    "$SCRIPT_DIR/start_server.sh"
    echo ""
    read -r -p "Press Enter to continue..."
}

stop_server() {
    echo "Stopping server..."
    "$SCRIPT_DIR/stop_server.sh"
    echo ""
    read -r -p "Press Enter to continue..."
}

reboot_server() {
    echo "Rebooting server..."
    "$SCRIPT_DIR/stop_server.sh"
    echo ""
    echo "Waiting 2 seconds before restart..."
    sleep 2
    "$SCRIPT_DIR/start_server.sh"
    echo ""
    read -r -p "Press Enter to continue..."
}

main() {
    while true; do
        show_menu
        choice=$(read_choice)
        case "$choice" in
            1) start_server ;;
            2) stop_server ;;
            3) reboot_server ;;
            4) echo "Exiting..."; exit 0 ;;
            *) echo "Invalid choice. Please try again."; sleep 1 ;;
        esac
    done
}

main