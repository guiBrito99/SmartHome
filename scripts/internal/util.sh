# ============================================================
# Smart Home - Internal Utilities
# Entry point of the internal helpers: resolves the shared project
# paths and sources every script in scripts/internal/, so the main
# scripts can call the helpers as functions instead of running them
# as standalone sub-processes.
#
# Conventions for the files in this folder:
#   * one function per file, named exactly after the file
#   * never executed directly (no shebang, not executable): source
#     this file to load the functions
#   * `return` instead of `exit`, so they stay usable as functions
#   * stdout carries only the documented value; messages go to stderr
#   * functions read the shared paths defined below instead of
#     recomputing the project location
# ============================================================

# Absolute paths derived from the script location (cwd-independent).
# BASH_SOURCE keeps these correct no matter which script sources util.sh.
var_INTERNAL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
var_PROJECT_DIR="$(cd "$var_INTERNAL_DIR/../.." && pwd)"
var_OPENHAB_DIR="$var_PROJECT_DIR/openhab"
var_INSTANCE_PROPS="$var_OPENHAB_DIR/userdata/tmp/instances/instance.properties"
var_JRE_PROPS="$var_OPENHAB_DIR/userdata/etc/jre.properties"

# Source every internal script except this one (self-sourcing would recurse).
for var_INTERNAL_SCRIPT in "$var_INTERNAL_DIR"/*.sh; do
    [ -f "$var_INTERNAL_SCRIPT" ] || continue
    [ "$var_INTERNAL_SCRIPT" = "$var_INTERNAL_DIR/util.sh" ] && continue
    source "$var_INTERNAL_SCRIPT"
done
