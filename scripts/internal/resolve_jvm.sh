# ============================================================
# Smart Home - Resolve JVM
# Internal function: resolve_jvm
# Usage: var_JAVA_HOME="$(resolve_jvm)" || return 1
# Determines a JVM version supported by openHAB (21 preferred, then 17),
# locates (and if necessary installs) a matching JVM, and prints its home
# directory. Returns non-zero if no JVM could be resolved.
# Only the resolved home goes to stdout; progress goes to stderr so the
# caller can capture the home without swallowing the messages.
# ============================================================

# Locate (or install) a JVM openHAB accepts and print its home directory.
resolve_jvm() {
    local var_TARGET_VERSION
    local var_JAVA_HOME_FOUND
    local var_CANDIDATE

    # openHAB rejects JVMs other than 17 and 21, so only consider those two.
    # Prefer 21, and fall back to 17 when 21 is not enabled in jre.properties.
    var_TARGET_VERSION="21"
    if [ -f "$var_JRE_PROPS" ]; then
        if grep -qE "^jre-21[[:space:]]*=" "$var_JRE_PROPS" 2>/dev/null; then
            var_TARGET_VERSION="21"
        elif grep -qE "^jre-17[[:space:]]*=" "$var_JRE_PROPS" 2>/dev/null; then
            var_TARGET_VERSION="17"
        fi
    fi
    echo "JVM version supported by openHAB: Java ${var_TARGET_VERSION}" >&2

    var_JAVA_HOME_FOUND=""
    for var_CANDIDATE in /usr/lib/jvm/java-${var_TARGET_VERSION}-*/ /usr/lib/jvm/java-1.${var_TARGET_VERSION}.0-*/; do
        if [ -d "$var_CANDIDATE" ] && [ -x "$var_CANDIDATE/bin/java" ]; then
            var_JAVA_HOME_FOUND="$var_CANDIDATE"
            break
        fi
    done

    if [ -z "$var_JAVA_HOME_FOUND" ]; then
        # No supported JVM on this host: install the headless package.
        # Needs root, which run.sh guarantees via its sudo re-exec, and
        # writes to stderr so stdout stays a single JVM home path.
        echo "No compatible JVM installed. Installing openjdk-${var_TARGET_VERSION}-jre-headless..." >&2
        apt update >&2
        apt install -y "openjdk-${var_TARGET_VERSION}-jre-headless" >&2

        for var_CANDIDATE in /usr/lib/jvm/java-${var_TARGET_VERSION}-*/ /usr/lib/jvm/java-1.${var_TARGET_VERSION}.0-*/; do
            if [ -d "$var_CANDIDATE" ] && [ -x "$var_CANDIDATE/bin/java" ]; then
                var_JAVA_HOME_FOUND="$var_CANDIDATE"
                break
            fi
        done

        if [ -z "$var_JAVA_HOME_FOUND" ]; then
            echo "Error: Java ${var_TARGET_VERSION} installation failed." >&2
            return 1
        fi
    fi

    echo "$var_JAVA_HOME_FOUND"
}
