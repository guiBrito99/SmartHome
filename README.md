# SmartHome HQ

Automated openHAB management for local development and deployment.

## Overview

This project provides a self-contained openHAB setup with automated Java version management, add-on configuration, and lifecycle scripts.

## Requirements

- Linux (tested on Ubuntu 24.04)
- `sudo` access for package installation (openJDK JRE)

## Quick Start

```bash
# Interactive menu
./run.sh

# Direct script usage
./scripts/start_server.sh          # Start server
./scripts/stop_server.sh           # Stop server
./scripts/stop_server.sh --clean   # Stop and wipe cache
./scripts/config_server.sh         # Configure add-ons interactively
./scripts/config_server.sh --keep  # Configure without removal prompts
```

## Scripts

| Script | Purpose |
|--------|---------|
| `run.sh` | Interactive menu (Start/Stop/Reboot/Exit) |
| `scripts/start_server.sh` | Downloads openHAB if missing, runs update, detects/installs required JRE from `userdata/etc/jre.properties`, launches openHAB. Supports `--factory-reset`. |
| `scripts/stop_server.sh` | Graceful shutdown using Karaf's PID file. 10s timeout, force-kill fallback. `--clean` wipes cache/tmp. |
| `scripts/config_server.sh` | Interactive add-on manager. Reads `org.openhab.jsonaddonservice:urls=` from `runtime.cfg`, prompts keep/remove for installed, offers uninstalled available add-ons. `--keep` skips removal prompts. |

## Configuration

- **Java version** — automatically derived from `openhab/userdata/etc/jre.properties` (highest `jre-N` entry). Installs `openjdk-<N>-jre-headless` if missing.
- **Add-ons** — managed via `openhab/conf/services/runtime.cfg` (`org.openhab.jsonaddonservice:urls=`). Current available add-on: **SmartHomeJ** (`https://download.smarthomej.org/addons.json`).
- **Auto-config** — on first run (or after `--factory-reset`), `start_server.sh` invokes `config_server.sh --keep` which preserves any already-configured add-ons and prompts only for new ones. After first run, the auto-config step is disabled in `start_server.sh`.

## Project Structure

```
.
├── run.sh                 # Interactive menu entry point
├── scripts/
│   ├── start_server.sh    # Start server
│   ├── stop_server.sh     # Stop server
│   └── config_server.sh   # Add-on configuration
├── openhab/               # openHAB runtime (downloaded on first run)
│   ├── conf/services/runtime.cfg   # Add-on URLs (git-tracked)
│   ├── userdata/etc/jre.properties # Java version matrix (git-tracked)
│   └── ...                # Runtime directories (git-ignored: userdata/, conf/ local changes)
├── .gitignore             # Ignores local config, runtime data, cache, secrets
```

## Git Workflow

- **Tracked**: `openhab/` pristine package contents (runtime, conf templates, scripts), `scripts/`, `run.sh`.
- **Ignored**: `openhab/userdata/` (logs, cache, jsondb, secrets), `openhab/conf/` local modifications, `openhab/openhab-4.2.0.tar.gz`.
- **Config changes**: Modifications to `runtime.cfg` (add-on URLs) are tracked — commit them to persist across environments.

## Version

openHAB 4.2.0 (pinned in `scripts/start_server.sh`).