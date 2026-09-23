#!/bin/bash

OPENHAB_DIR="$(dirname "$0")/openhab"
RUNTIME_CFG="$OPENHAB_DIR/conf/services/runtime.cfg"
KEY="org.openhab.jsonaddonservice:urls="

KEEP_MODE=false
if [ "$1" = "--keep" ]; then
    KEEP_MODE=true
fi

# Available add-ons not part of the base distribution, as "name|url" entries.
AVAILABLE_ADDONS=(
    "SmartHomeJ|https://download.smarthomej.org/addons.json"
)

# Read the pipe-separated add-on urls from the active urls line in runtime.cfg.
get_urls() {
    grep -E "^${KEY}" "$RUNTIME_CFG" | head -n 1 | sed "s#^${KEY}##"
}

# Rewrite the active urls line (or create it) to hold the given pipe-separated value.
set_urls() {
    local newval="$1"
    local tmp="${RUNTIME_CFG}.tmp"
    local found=0
    local line
    while IFS= read -r line || [ -n "$line" ]; do
        case "$line" in
            "${KEY}"*)
                found=1
                if [ -n "$newval" ]; then
                    echo "${KEY}${newval}"
                fi
                ;;
            *)
                echo "$line"
                ;;
        esac
    done < "$RUNTIME_CFG" > "$tmp"
    if [ "$found" -eq 0 ] && [ -n "$newval" ]; then
        echo "${KEY}${newval}" >> "$tmp"
    fi
    mv "$tmp" "$RUNTIME_CFG"
}

# Join array values with the pipe separator used by runtime.cfg.
join_pipe() {
    local out="" v
    for v in "$@"; do
        [ -z "$v" ] && continue
        out="${out:+$out|}${v}"
    done
    echo "$out"
}

# Check whether a url is contained in the given list.
contains_url() {
    local needle="$1"
    shift
    local u
    for u in "$@"; do
        [ "$u" = "$needle" ] && return 0
    done
    return 1
}

# Resolve a human-readable name for an installed url, or fall back to the url.
addon_name() {
    local url="$1" name u entry
    for entry in "${AVAILABLE_ADDONS[@]}"; do
        name="${entry%%|*}"
        u="${entry##*|}"
        if [ "$u" = "$url" ]; then
            echo "$name"
            return
        fi
    done
    echo "$url"
}

if [ ! -d "$OPENHAB_DIR/runtime" ] && [ ! -f "$RUNTIME_CFG" ]; then
    echo "openHAB is not installed yet. Run ./start.sh first." >&2
    exit 1
fi

INSTALLED=()
IFS='|' read -r -a INSTALLED <<< "$(get_urls)"

echo "Add-on configuration"
echo "===================="
echo ""
echo "Add-ons already installed:"
if [ "${#INSTALLED[@]}" -eq 0 ]; then
    echo "  (none)"
else
    for url in "${INSTALLED[@]}"; do
        [ -z "$url" ] && continue
        echo "  - $(addon_name "$url")"
    done
fi
echo ""

REMAINING=()
if [ "$KEEP_MODE" = true ]; then
    echo "(--keep) Installed add-ons are preserved."
    REMAINING=("${INSTALLED[@]}")
else
    for url in "${INSTALLED[@]}"; do
        [ -z "$url" ] && continue
        local_name=$(addon_name "$url")
        read -r -p "Keep or remove '${local_name}'? [K/r] " answer
        case "$answer" in
            [rR])
                echo "Removed '${local_name}'."
                ;;
            *)
                REMAINING+=("$url")
                echo "Kept '${local_name}'."
                ;;
        esac
    done
fi

echo ""
echo "Available add-ons:"
NEW_ADDONS=()
available_found=0
for entry in "${AVAILABLE_ADDONS[@]}"; do
    name="${entry%%|*}"
    url="${entry##*|}"
    if contains_url "$url" "${REMAINING[@]}" || contains_url "$url" "${NEW_ADDONS[@]}"; then
        continue
    fi
    available_found=1
    read -r -p "Do you want to install '${name}' (${url})? [y/N] " answer
    case "$answer" in
        [yY]|[yY][eE][sS])
            NEW_ADDONS+=("$url")
            echo "Added '${name}'."
            ;;
        *)
            echo "Skipped '${name}'."
            ;;
    esac
done
if [ "$available_found" -eq 0 ]; then
    echo "  (all available add-ons are already installed)"
fi

set_urls "$(join_pipe "${REMAINING[@]}" "${NEW_ADDONS[@]}")"