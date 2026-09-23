#!/bin/bash

OPENHAB_DIR="$(dirname "$0")/openhab"

OPENHAB_VERSION="4.2.0"
OPENHAB_URL="https://github.com/openhab/openhab-distro/releases/download/${OPENHAB_VERSION}/openhab-${OPENHAB_VERSION}.tar.gz"

# 0. Factory reset: delete the whole openhab directory (download will re-create it)
if [ "$1" = "--factory-reset" ]; then
    echo "Factory reset requested. Deleting the ${OPENHAB_DIR} directory..."
    rm -rf "$OPENHAB_DIR"
    echo "openhab directory removed."
fi

# 1. Download openHAB into ./openhab if not found
if [ ! -f "$OPENHAB_DIR/runtime/bin/karaf" ]; then
    echo "openHAB not found in ${OPENHAB_DIR}. Downloading openHAB ${OPENHAB_VERSION}..."
    mkdir -p "$OPENHAB_DIR"
    wget -q --show-progress -O "/tmp/openhab-${OPENHAB_VERSION}.tar.gz" "$OPENHAB_URL"
    tar -xzf "/tmp/openhab-${OPENHAB_VERSION}.tar.gz" -C "$OPENHAB_DIR"
    rm -f "/tmp/openhab-${OPENHAB_VERSION}.tar.gz"
    if [ ! -f "$OPENHAB_DIR/runtime/bin/karaf" ]; then
        echo "Error: openHAB download or extraction failed. Exiting."
        exit 1
    fi
    echo "openHAB ${OPENHAB_VERSION} downloaded to ${OPENHAB_DIR}."
fi

# 2. Try to update openHAB
echo "Trying to update openHAB..."
( cd "$OPENHAB_DIR" && sudo ./runtime/bin/update ) || echo "openHAB update skipped/failed; continuing with the existing installation."

# 2.5 Initial-state configuration (first clone or after --factory-reset).
# config.sh asks about the add-ons; afterwards this step is disabled in-process.
#./config.sh --keep && sed -i 's|^\./config\.sh|#./config.sh|' "$0"

# Determine the latest JVM version supported by openHAB from its jre.properties
# (the trailing "jre-N = ${jre-9}" lines declare the supported JRE versions).
JRE_PROPERTIES="$OPENHAB_DIR/userdata/etc/jre.properties"
TARGET_VERSION=$(grep -oE '^jre-[0-9]+[[:space:]]*=' "$JRE_PROPERTIES" | grep -oE '[0-9]+' | sort -V | tail -n 1)

if [ -z "$TARGET_VERSION" ]; then
    echo "Error: could not determine the JVM version from $JRE_PROPERTIES. Exiting."
    exit 1
fi

echo "Latest JVM version supported by openHAB: Java ${TARGET_VERSION}"

# Find an installed JVM for the target version.
JAVA_HOME=""
for candidate in /usr/lib/jvm/java-${TARGET_VERSION}-*/ /usr/lib/jvm/java-1.${TARGET_VERSION}.0-*/; do
    if [ -d "$candidate" ] && [ -x "$candidate/bin/java" ]; then
        JAVA_HOME="$candidate"
        break
    fi
done

# If none found, install the target version.
if [ -z "$JAVA_HOME" ]; then
    echo "No compatible JVM installed. Requesting sudo privileges to install openjdk-${TARGET_VERSION}-jre-headless..."
    sudo apt update
    sudo apt install -y openjdk-${TARGET_VERSION}-jre-headless

    # Abort if installation failed
    for candidate in /usr/lib/jvm/java-${TARGET_VERSION}-*/ /usr/lib/jvm/java-1.${TARGET_VERSION}.0-*/; do
        if [ -d "$candidate" ] && [ -x "$candidate/bin/java" ]; then
            JAVA_HOME="$candidate"
            break
        fi
    done
    if [ -z "$JAVA_HOME" ]; then
        echo "Error: Java ${TARGET_VERSION} installation failed. Exiting."
        exit 1
    fi
fi

# 2. Set JAVA_HOME strictly for this process tree
export JAVA_HOME="$JAVA_HOME"
echo "Smart Home booting with JAVA_HOME=$JAVA_HOME"

# 3. Executing openHAB (which validates the JVM version itself)
./openhab/runtime/bin/start
