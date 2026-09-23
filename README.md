# SmartHome HQ

Automated openHAB management for local development and deployment.

## Overview

This project provides a self-contained openHAB setup with automated Java version management, add-on configuration, and lifecycle scripts.

## Requirements

- Linux (tested on Ubuntu 24.04)
- `sudo` access for package installation (openJDK JRE)

## Quick Start

```bash
# First run - downloads openHAB 4.2.0, installs Java 21 JRE, configures add-ons
./start.sh

# Subsequent runs - uses existing installation
./start.sh

# Factory reset (wipes openhab/ directory, re-downloads)
./start.sh --factory-reset

# Stop openHAB gracefully
./stop.sh

# Stop with cache cleanup
./stop.sh --clean

# Configure add-ons interactively
./config.sh
```

## Scripts

| Script | Purpose |
|--------|---------|
| `start.sh` | Main entry point. Downloads openHAB if missing, runs updates, detects/installs the required JRE version from `userdata/etc/jre.properties`, launches openHAB. |
| `stop.sh` | Graceful shutdown using Karaf's PID file (`userdata/tmp/instances/instance.properties`). Falls back to `pgrep`. Supports `--clean` to wipe cache/tmp. |
| `config.sh` | Interactive add-on manager. Lists installed add-ons from `runtime.cfg`, prompts to keep/remove each, then offers uninstalled available add-ons. Use `--keep` to skip removal prompts. |

## Configuration

- **Java version** — automatically derived from `openhab/userdata/etc/jre.properties` (highest `jre-N` entry). Installs `openjdk-<N>-jre-headless` if missing.
- **Add-ons** — managed via `openhab/conf/services/runtime.cfg` (`org.openhab.jsonaddonservice:urls=`). Current available add-on: **SmartHomeJ** (`https://download.smarthomej.org/addons.json`).
- **Auto-config** — on first run (or after `--factory-reset`), `start.sh` invokes `config.sh --keep` which preserves any already-configured add-ons and prompts only for new ones. After first run, the auto-config step is disabled in `start.sh`.

## Project Structure

```
.
├── start.sh           # Main launcher
├── stop.sh            # Graceful shutdown
├── config.sh          # Add-on configuration
├── openhab/           # openHAB runtime (downloaded on first run)
│   ├── conf/services/runtime.cfg   # Add-on URLs (git-tracked)
│   ├── userdata/etc/jre.properties # Java version matrix (git-tracked)
│   └── ...          # Runtime directories (git-ignored: userdata/, conf/ local changes)
├── .gitignore         # Ignores local config, runtime data, cache, secrets
```

## Git Workflow

- **Tracked**: `openhab/` pristine package contents (runtime, conf templates, scripts).
- **Ignored**: `openhab/userdata/` (logs, cache, jsondb, secrets), `openhab/conf/` local modifications, `openhab/openhab-4.2.0.tar.gz`.
- **Config changes**: Modifications to `runtime.cfg` (add-on URLs) are tracked — commit them to persist across environments.

## Version

openHAB 4.2.0 (pinned in `start.sh`).