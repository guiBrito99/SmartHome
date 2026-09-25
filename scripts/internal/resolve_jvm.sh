#!/bin/bash

# Internal script: resolve_jvm
# Usage: var_JAVA_HOME=$(scripts/internal/resolve_jvm.sh)
# Determines a JVM version supported by openHAB (21 preferred, then 17),
# locates (and if necessary installs) a matching JVM, and prints its home directory.
# Exits non-zero if no JVM could be resolved.

var_INTERNAL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
var_OPENHAB_DIR="$(cd "$var_INTERNAL_DIR/../.." && pwd)/openhab"
var_JRE_PROPS="$var_OPENHAB_DIR/userdata/etc/jre.properties"

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

var_JAVA_HOME=""
for var_CANDIDATE in /usr/lib/jvm/java-${var_TARGET_VERSION}-*/ /usr/lib/jvm/java-1.${var_TARGET_VERSION}.0-*/; do
    if [ -d "$var_CANDIDATE" ] && [ -x "$var_CANDIDATE/bin/java" ]; then
        var_JAVA_HOME="$var_CANDIDATE"
        break
    fi
done

if [ -z "$var_JAVA_HOME" ]; then
    echo "No compatible JVM installed. Installing openjdk-${var_TARGET_VERSION}-jre-headless..."
    apt update
    apt install -y "openjdk-${var_TARGET_VERSION}-jre-headless"

    for var_CANDIDATE in /usr/lib/jvm/java-${var_TARGET_VERSION}-*/ /usr/lib/jvm/java-1.${var_TARGET_VERSION}.0-*/; do
        if [ -d "$var_CANDIDATE" ] && [ -x "$var_CANDIDATE/bin/java" ]; then
            var_JAVA_HOME="$var_CANDIDATE"
            break
        fi
    done

    if [ -z "$var_JAVA_HOME" ]; then
        echo "Error: Java ${var_TARGET_VERSION} installation failed." >&2
        exit 1
    fi
fi

echo "$var_JAVA_HOME"