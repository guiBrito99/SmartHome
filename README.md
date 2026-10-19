# SmartHome HQ

Automated openHAB management for local development and deployment.

## Overview

This project provides a self-contained openHAB setup with automated Java version management, add-on configuration, and lifecycle scripts.

## Requirements

- Linux (tested on Ubuntu 24.04)
- `sudo` access (used to re-run `run` and to install the openJDK JDK if missing)
- `wget`, `tar` (used by the download step)
- `curl`, `unzip`, `awk` (used by the openHAB update script to download releases, extract them and parse the version)
- `ps` (used by the openHAB launcher to inspect the running server)

Missing tools and a missing JVM are installed automatically by
`resolveDependencies`, which needs the `sudo` access above.

## Quick Start

```bash
# Start the web UI (the control panel) and stop
./run

# Start the web UI, then the interactive menu
./run --menu

# Direct, non-interactive usage
./run --start
./run --stop
./run --reboot
./run --config
./run --install
./run --update
./run --factory-reset
```

The first release of openHAB is downloaded automatically. Either run `./run --install` (downloads, updates, configures add-ons, starts and verifies), pick an option in the web UI at <http://localhost:8081/>, or use the terminal menu.

Every mode brings the web server up first and prints the URL to open, so the
pages are served while the openHAB work runs.

## Scripts

### Entry point

| Script | Purpose |
|--------|---------|
| `run` | Control panel entry point. With no flag it starts the web server and stops; `--menu` adds the interactive menu (status + Start/Stop/Reboot/Configure/Install/Update/Factory reset); any other `--<mode>` runs that one operation non-interactively. Re-runs itself with `sudo` when needed. Every mode starts the web server first (see "Web UI"). |

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
| `resolveDependencies` | Checks every external dependency: the CLI tools the scripts call (`sed`, `grep`, `awk`, `dirname`, `head`, `sleep`, `mkdir`, `mv`, `rm`, `tar`, `wget`, `curl`, `unzip`, `git`, `pgrep`, `pkill`, `ps`, `clear`), `javac` to build the web server, and a JVM openHAB supports (Java 21 preferred, 17 as fallback, located under `/usr/lib/jvm`). Installs whatever is missing with `apt` (one run, all the tools plus `openjdk-<N>-jdk-headless` together) and returns non-zero if something is still missing. Prints the resolved `JAVA_HOME` on stdout, all progress on stderr. |
| `set_karaf_home` | Prints the Karaf client home path used to redirect the `.karaf` folder into the project directory. |
| `start_web_server` | Builds `webServer/src/com/smarthome/web/*.java` when any source is newer than the classes, starts the JVM detached (`setsid`) and waits for the port to answer. Reads the openHAB credentials from `webServer/config/openhab.auth` (falling back to `OPENHAB_USER`/`OPENHAB_PASS`) and hands them to the JVM as a system property. Prints the URL on stdout; returns 1 with a warning on stderr when the port is taken, the toolchain is missing or the build fails, so the openHAB work still runs. An already-running server is detected by an HTTP probe (the `X-Smarthome` marker); a foreign listener on the port is reported instead of mistaken for the UI. An edited source is reported as "not live yet": restart the web server to pick it up. |
| `web_server_responds` | Returns 0 when the web server answers on the given port, 1 when nothing listens or the listener is another program. Asks the port with a real HTTP request over `/dev/tcp` and looks for the `X-Smarthome` marker header, which is how a foreign listener is told apart from our own server. |

## Configuration

- **Dependencies** — `resolveDependencies` is the single place that installs what the project needs: the CLI tools the scripts execute and a JVM openHAB accepts. `start_server`, `stop_server` and `update_server` call it before touching the openHAB binaries, and `install` calls it as step 1 so `wget`/`tar` are guaranteed to exist before the download. `curl`, `unzip` and `awk` are included because the openHAB update script uses them to fetch, extract and parse releases, and `ps` because the openHAB launcher inspects the running server with it. Every other tool openHAB calls (`cat`, `chmod`, `chown`, `cp`, `ls`, `id`, `basename`, `readlink`, `realpath`) ships in `coreutils`, which is already covered.
- **Java version** — openHAB 4.x accepts only Java 17 and 21. `resolveDependencies` prefers 21, falls back to 17, and (re)checks `openhab/userdata/etc/jre.properties` when present. A missing JVM is installed via `apt` as `openjdk-<N>-jdk-headless`, never the bare JRE: the JDK carries the runtime openHAB needs and depends on `openjdk-<N>-jre-headless` anyway, so naming the JRE separately would be redundant.
- **Web server toolchain** — `webServer/` is a Java program built with `javac`, so `resolveDependencies` also checks for the compiler. A missing compiler and a missing JVM both resolve to the same package, `openjdk-<N>-jdk-headless` for the resolved version. The headless JRE alone would be enough to *run* the compiled server, since `jdk.httpserver` ships in the JRE image; only building needs the JDK, and the JDK pulls the JRE in as a dependency.
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
│       ├── start_web_server
│       ├── verify_installation
│       └── web_server_responds
├── webServer/                # Java web server (see "Web UI")
│   ├── assets/rooms/         # your per-room SVGs
│   ├── config/               # openhab.auth, floor-layout.json, thing-map.json (git-ignored)
│   ├── css/style.css         # the one stylesheet
│   ├── src/com/smarthome/web/# Template, OpenHabClient, HomeModel, Pages, Lifecycle, server
│   ├── templates/            # base, floor, room, control, config, confirm, builder, status, error
│   └── build/                # compiled classes + server.log (git-ignored)
├── openhab/                 # openHAB runtime (downloaded on first run, git-ignored)
├── README.md
└── .gitignore
```

## Web UI

`webServer/` is a small Java program (`com.sun.net.httpserver.HttpServer`, no
framework, no build tool, **no JavaScript**) that renders the control panel
server-side. `./run` starts it before anything else, so the pages are served
while the openHAB work happens and stay up afterwards.

- `./run` (any mode) calls `start_web_server`, which resolves the toolchain,
  compiles `webServer/src/com/smarthome/web/*.java` into
  `webServer/build/classes` when any source is newer than the build, and
  launches the JVM in its own session so it keeps running after `./run`
  returns. Plain `./run` starts it and stops there; `./run --menu` then shows
  the terminal menu.
- The port is **8081**, since openHAB's own UI already uses 8080. Override it
  with `SMARTHOME_WEB_PORT=<port> ./run`.
- A second `./run` finds the server up and reuses it (an HTTP probe looking
  for the `X-Smarthome` marker, not a plain port check, so a foreign listener
  on the port is reported instead of mistaken for the UI). An edited source is
  reported as "not live yet": restart the web server to pick it up.
- The port only serves `webServer/`'s own files; `src/`, `build/`, `templates/`
  and `config/` are refused. Requests are logged to `webServer/build/server.log`.

### Pages

| Path        | What it does                                                     |
| ----------- | ---------------------------------------------------------------- |
| `/`         | Redirects to `/floor`, or to `/config` when openHAB is not running |
| `/floor`    | Dashboard: one section per floor, rooms in a CSS grid             |
| `/room/NAME`| The room's SVG with each bound element linked and state-coloured |
| `/control`  | One Thing: every Item with its own form of buttons                |
| `/config`   | The same operations as the terminal menu, for the current state  |
| `/confirm`  | The question the two destructive operations ask first            |
| `/status`   | Spinner page that re-reads the state until openHAB is up         |
| `/builder`  | Home Builder: rooms, floor order and Thing bindings               |
| `/api/status` | The same state as JSON                                        |

Every action is a plain HTML form that POSTs and then redirects, and every
state is painted with CSS classes, so the whole UI works with JavaScript
switched off. There is no `confirm()` dialog anywhere: install and factory
reset are the two operations that destroy work, so their buttons lead to
`/confirm`, and that page's form is the "yes" the script reads. Install and
update POST to `/status`, which reloads on its own until the server answers.

### Credentials

The web server talks to the openHAB REST API on `127.0.0.1:8080`. Put
`user:pass` on one line in `webServer/config/openhab.auth` (mode `600`,
git-ignored), or export `OPENHAB_USER` and `OPENHAB_PASS` before `./run`;
the launcher hands them to the JVM as a system property, never on a command
line. With no credentials the header is simply not sent, which is what a
fresh openHAB with security off wants. Credentials become necessary the
moment openHAB security is turned on, and until they are set Thing states and
commands come back empty.

### Home Builder

Rooms are the SVGs you draw yourself:

- **Add a room** — give it a name (`assets/rooms/<name>.svg`) and paste its
  SVG. Put an `id` on every shape or group you want to click.
- **Bind an element** — pick the room, the element `id` and the openHAB Thing
  it stands for. The element then becomes clickable on the plan and shows its
  live state.
- **Arrange the floor** — tick the rooms in the order you want them in the
  grid. With no layout saved, the rooms are listed alphabetically on one floor.

The two generated files, `floor-layout.json` and `thing-map.json`, hold that
arrangement and those bindings. Both are git-ignored: they describe your home,
not the project. With no layout saved, the rooms are listed alphabetically on
one floor.

### Security

The web server has **no authentication of its own** and binds every interface,
so anything on the same network can reach it and can run the lifecycle
operations. It also runs with the privileges `run` was given, i.e. root. Keep
that in mind before exposing it beyond the home network.

## Git Workflow

- **Tracked**: `README.md`, `run`, `scripts/`, `webServer/`.
- **Ignored**: everything else (the `openhab/` runtime, downloaded archives, runtime data, the compiled web server) — `.gitignore` uses an allowlist of `README.md`, `run`, `scripts/` and `webServer/`.

## Version

openHAB 4.2.0 (pinned in `scripts/main/install`).