# SmartHome HQ

Automated openHAB management for local development and deployment.

## Overview

This project provides a self-contained openHAB setup with automated Java version management, add-on configuration, and lifecycle scripts.

## Requirements

- Linux (tested on Ubuntu 24.04)
- `sudo` access (used to re-run `run` and to install the openJDK JRE if missing)
- `wget`, `tar` (used by the download step)
- `curl`, `unzip`, `awk` (used by the openHAB update script to download releases, extract them and parse the version)
- `ps` (used by the openHAB launcher to inspect the running server)

Missing tools and a missing JVM are installed automatically by
`resolveDependencies`, which needs the `sudo` access above.

## Quick Start

```bash
# Interactive menu
./run

# Direct, non-interactive usage
./run --start
./run --stop
./run --reboot
./run --config
./run --install
./run --update
./run --factory-reset
```

The first release of openHAB is downloaded automatically. Either run `./run --install` (downloads, updates, configures add-ons, starts and verifies) or pick an option from the menu.

## Scripts

### Entry point

| Script | Purpose |
|--------|---------|
| `run` | Interactive menu (status + Start/Stop/Reboot/Configure/Install/Update/Factory reset). Re-runs itself with `sudo` when needed and accepts `--<mode>` flags for non-interactive use. |

### Lifecycle scripts (`scripts/main/`)

Every script below sources `scripts/internal/util` and calls the internal
functions directly (no helper sub-processes).

| Script | Purpose |
|--------|---------|
| `start_server` | Verifies openHAB is installed, resolves/installs a supported JVM, exports the environment vars openHAB requires (`JAVA_HOME`, `KARAF_HOME`), then launches `openhab/runtime/bin/start`. |
| `stop_server` | Graceful shutdown: signals `runtime/bin/stop`, then waits on the Karaf instance PID (10s timeout) and force-kills if needed. `--clean` also wipes the cache/tmp directories. |
| `reboot_server` | Stops the server (aborting if the stop fails), then starts it again. |
| `update_server` | Fails if openHAB is not installed or the server is running (stop it manually first). Resolves a supported JVM and runs `openhab/runtime/bin/update` from the openHAB root. |
| `install` | One-shot setup: downloads openHAB if missing and updates it, configures add-ons, then starts and verifies the server. Exits early when openHAB is already installed. |
| `config_server` | Interactive add-on manager. Reads `org.openhab.jsonaddonservice:urls=` from `conf/services/runtime.cfg`, prompts keep/remove for currently installed add-ons and offers add-ons that are not yet installed. `--keep` skips the removal prompts. |
| `factoryReset_server` | Requires an installed openHAB and a stopped server, then removes `openhab/` and `karaf-home/` and pulls the latest changes from git. Requires a `[y/N]` confirmation. |

### Internal helpers (`scripts/internal/`)

Not executable: every file hosts a single function and is named after it, and
`util` sources all of them. Main scripts source `util` once and call the
functions. `util` also resolves the shared paths the functions rely on
(`var_PROJECT_DIR`, `var_OPENHAB_DIR`, `var_INSTANCE_PROPS`, `var_JRE_PROPS`).

| File = function | Purpose |
|-----------------|---------|
| `util` | Entry point: sources every other script in this folder and defines the shared paths. |
| `verify_installation` | Returns 0 if `openhab/runtime/bin/karaf` is present, 1 otherwise. |
| `get_server_status` | Prints `NOT INSTALLED` / `RUNNING (PID: <pid>)` / `STOPPED`. Returns 0 when running, 1 when stopped, 2 when not installed. |
| `get_root_pid` | Prints the openHAB root instance PID from Karaf's `userdata/tmp/instances/instance.properties`. |
| `resolveDependencies` | Checks every external dependency: the CLI tools the scripts call (`sed`, `grep`, `awk`, `dirname`, `head`, `sleep`, `mkdir`, `mv`, `rm`, `tar`, `wget`, `curl`, `unzip`, `git`, `pgrep`, `pkill`, `ps`, `clear`) and a JVM openHAB supports (Java 21 preferred, 17 as fallback, located under `/usr/lib/jvm`). Installs whatever is missing with `apt` (one run, tools and `openjdk-<N>-jre-headless` together) and returns non-zero if something is still missing. Prints the resolved `JAVA_HOME` on stdout, all progress on stderr. |
| `set_karaf_home` | Prints the Karaf client home path used to redirect the `.karaf` folder into the project directory. |

## Configuration

- **Dependencies** — `resolveDependencies` is the single place that installs what the project needs: the CLI tools the scripts execute and a JVM openHAB accepts. `start_server`, `stop_server` and `update_server` call it before touching the openHAB binaries, and `install` calls it as step 1 so `wget`/`tar` are guaranteed to exist before the download. `curl`, `unzip` and `awk` are included because the openHAB update script uses them to fetch, extract and parse releases, and `ps` because the openHAB launcher inspects the running server with it. Every other tool openHAB calls (`cat`, `chmod`, `chown`, `cp`, `ls`, `id`, `basename`, `readlink`, `realpath`) ships in `coreutils`, which is already covered.
- **Java version** — openHAB 4.x accepts only Java 17 and 21. `resolveDependencies` prefers 21, falls back to 17, and (re)checks `openhab/userdata/etc/jre.properties` when present. A missing JVM is installed via `apt` as `openjdk-<N>-jre-headless`.
- **Add-ons** — managed through `openhab/conf/services/runtime.cfg` (`org.openhab.jsonaddonservice:urls=`). Currently available add-on: **SmartHomeJ** (`https://download.smarthomej.org/addons.json`).

## Project Structure

```
.
├── run                   # Interactive menu entry point
├── scripts/
│   ├── main/                # Lifecycle scripts
│   │   ├── config_server
│   │   ├── factoryReset_server
│   │   ├── install
│   │   ├── reboot_server
│   │   ├── start_server
│   │   ├── stop_server
│   │   └── update_server
│   └── internal/            # Helper functions sourced through util
│       ├── util
│       ├── get_root_pid
│       ├── get_server_status
│       ├── resolveDependencies
│       ├── set_karaf_home
│       └── verify_installation
├── openhab/                 # openHAB runtime (downloaded on first run, git-ignored)
├── README.md
└── .gitignore
```

## Git Workflow

- **Tracked**: `README.md`, `run`, `scripts/`.
- **Ignored**: everything else (the `openhab/` runtime, downloaded archives, runtime data) — `.gitignore` uses an allowlist of `README.md`, `run` and `scripts/`.

## Version

openHAB 4.2.0 (pinned in `scripts/main/install`).