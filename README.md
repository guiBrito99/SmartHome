# SmartHome HQ

Automated openHAB management for local development and deployment.

## Overview

This project provides a self-contained openHAB setup with automated Java version management, add-on configuration, and lifecycle scripts.

## Requirements

- Linux (tested on Ubuntu 24.04)
- `sudo` access (used to re-run `run.sh` and to install the openJDK JRE if missing)
- `wget`, `tar` (used by the download step)

## Quick Start

```bash
# Interactive menu
./run.sh

# Direct, non-interactive usage
./run.sh --start
./run.sh --stop
./run.sh --reboot
./run.sh --config
./run.sh --install
./run.sh --update
./run.sh --factory-reset
```

The first release of openHAB is downloaded automatically. Either run `./run.sh --install` (downloads, updates, configures add-ons, starts and verifies) or pick an option from the menu.

## Scripts

### Entry point

| Script | Purpose |
|--------|---------|
| `run.sh` | Interactive menu (status + Start/Stop/Reboot/Configure/Install/Update/Factory reset). Re-runs itself with `sudo` when needed and accepts `--<mode>` flags for non-interactive use. |

### Lifecycle scripts (`scripts/main/`)

Every script below sources `scripts/internal/util.sh` and calls the internal
functions directly (no helper sub-processes).

| Script | Purpose |
|--------|---------|
| `start_server.sh` | Verifies openHAB is installed, resolves/installs a supported JVM, exports the environment vars openHAB requires (`JAVA_HOME`, `KARAF_HOME`), then launches `openhab/runtime/bin/start`. |
| `stop_server.sh` | Graceful shutdown: signals `runtime/bin/stop`, then waits on the Karaf instance PID (10s timeout) and force-kills if needed. `--clean` also wipes the cache/tmp directories. |
| `reboot_server.sh` | Stops the server (aborting if the stop fails), then starts it again. |
| `update_server.sh` | Fails if openHAB is not installed or the server is running (stop it manually first). Resolves a supported JVM and runs `openhab/runtime/bin/update` from the openHAB root. |
| `install.sh` | One-shot setup: downloads openHAB if missing and updates it, configures add-ons, then starts and verifies the server. Exits early when openHAB is already installed. |
| `config_server.sh` | Interactive add-on manager. Reads `org.openhab.jsonaddonservice:urls=` from `conf/services/runtime.cfg`, prompts keep/remove for currently installed add-ons and offers add-ons that are not yet installed. `--keep` skips the removal prompts. |
| `factoryReset_server.sh` | Requires an installed openHAB and a stopped server, then removes `openhab/` and `karaf-home/` and pulls the latest changes from git. Requires a `[y/N]` confirmation. |

### Internal helpers (`scripts/internal/`)

Not executable: every file hosts a single function, and `util.sh` sources all of
them. Main scripts source `util.sh` once and call the functions. `util.sh` also
resolves the shared paths the functions rely on (`var_PROJECT_DIR`,
`var_OPENHAB_DIR`, `var_INSTANCE_PROPS`, `var_JRE_PROPS`).

| File | Function | Purpose |
|------|----------|---------|
| `util.sh` | — | Entry point: sources every other script in this folder and defines the shared paths. |
| `verify_installation.sh` | `verify_installation` | Returns 0 if `openhab/runtime/bin/karaf` is present, 1 otherwise. |
| `get_server_status.sh` | `get_server_status` | Prints `NOT INSTALLED` / `RUNNING (PID: <pid>)` / `STOPPED`. Returns 0 when running, 1 when stopped, 2 when not installed. |
| `get_root_pid.sh` | `get_root_pid` | Prints the openHAB root instance PID from Karaf's `userdata/tmp/instances/instance.properties`. |
| `resolve_jvm.sh` | `resolve_jvm` | Picks a JVM openHAB supports (Java 21 preferred, 17 as fallback), locates it under `/usr/lib/jvm` and prints its home. Installs `openjdk-<N>-jre-headless` if missing. Only the home goes to stdout, progress to stderr. |
| `set_karaf_home.sh` | `set_karaf_home` | Prints the Karaf client home path used to redirect the `.karaf` folder into the project directory. |

## Configuration

- **Java version** — openHAB 4.x accepts only Java 17 and 21. `resolve_jvm` prefers 21, falls back to 17, and (re)checks `openhab/userdata/etc/jre.properties` when present. A missing JVM is installed via `apt` as `openjdk-<N>-jre-headless`.
- **Add-ons** — managed through `openhab/conf/services/runtime.cfg` (`org.openhab.jsonaddonservice:urls=`). Currently available add-on: **SmartHomeJ** (`https://download.smarthomej.org/addons.json`).

## Project Structure

```
.
├── run.sh                   # Interactive menu entry point
├── scripts/
│   ├── main/                # Lifecycle scripts
│   │   ├── config_server.sh
│   │   ├── factoryReset_server.sh
│   │   ├── install.sh
│   │   ├── reboot_server.sh
│   │   ├── start_server.sh
│   │   ├── stop_server.sh
│   │   └── update_server.sh
│   └── internal/            # Helper functions sourced through util.sh
│       ├── util.sh
│       ├── get_root_pid.sh
│       ├── get_server_status.sh
│       ├── resolve_jvm.sh
│       ├── set_karaf_home.sh
│       └── verify_installation.sh
├── openhab/                 # openHAB runtime (downloaded on first run, git-ignored)
├── README.md
└── .gitignore
```

## Git Workflow

- **Tracked**: `README.md`, `run.sh`, `scripts/`.
- **Ignored**: everything else (the `openhab/` runtime, downloaded archives, runtime data) — `.gitignore` uses an allowlist of `README.md`, `run.sh` and `scripts/`.

## Version

openHAB 4.2.0 (pinned in `scripts/main/install.sh`).