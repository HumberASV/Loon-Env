# Loon-Env

## Description

Loon-Env provides installer, logging, and Docker wrapper scripts for the Loon-E stack. It's not very good, but it works for those who want it.

- Tracks users online
- Uses environment variables
- Simplifies Docker and Docker Compose workflows for Loon-E and ZED-X

## Global Environment Variables


| Name | Purpose |
|---|---|
| KNOWN_USERS_FILE | Path to the file tracking known users and their session counts. |
| LOG_FILE | Path to the log file where session events are recorded. |
| ASSET_DIR | Asset directory containing `compose.yaml` and Dockerfiles used by `LoonE`. |
| LOON_E_IMAGE | Name of the Docker image to build for Loon-E (default: `loon-e:latest`) |
| ZED_X_IMAGE | Name of the Docker image to build for ZED-X (default: `zed-x:latest`) |
| LOON_ENV_VERSION | Installed Loon-Env version written by `install.bash`. |
| XAUTHORITY | Host X11 auth file and compose mount source for GUI forwarding. |
| DISPLAY | X11 display value forwarded into containers (default in compose: `:1`). |
| QT_QPA_PLATFORM | Qt platform backend (default in compose: `offscreen`). |
| ROS_DOMAIN_ID | ROS 2 DDS domain id used by both services (default in compose: `5`). |
| ROS_LOCALHOST_ONLY | ROS 2 localhost-only toggle (default in compose: `0`). |
| RMW_IMPLEMENTATION | ROS 2 middleware implementation (default in compose: `rmw_fastrtps_cpp`). |
| ZED_DOCKERFILE | Optional override for ZED Dockerfile path in compose. |
| ZED_SDK_VERSION | ZED SDK version passed through to the Dockerfiles (default: `5.2`). |
| L4T_VERSION | L4T release used to select the ZED SDK installer (default: `36.4`). |
| ZED_WRAPPER_REPO | Optional Git repo used when building the ZED wrapper image. |
| ZED_WRAPPER_GIT_REF | Optional branch, tag, or commit for the ZED wrapper repo. |
| ZED_EXAMPLES_REPO | Optional Git repo used when building ZED examples. |
| ZED_EXAMPLES_GIT_REF | Optional branch, tag, or commit for the ZED examples repo. |
| ZED_CAMERA_MODEL | ZED launch camera model (default in compose: `zedx`). |
| ZED_SIM_MODE | ZED launch simulation mode toggle (default in compose: `true`). |
| ZED_USE_SIM_TIME | ZED launch simulated time toggle (default in compose: `true`). |
| ZED_SIM_ADDRESS | ZED simulator address (default in compose: `100.68.31.22`). |
| ZED_SIM_PORT | ZED simulator port (default in compose: `30000`). |
| ZED_STREAM_PORT | ZED stream server port (default in compose: `5006`). |
| ZED_STREAM_ADDRESS | ZED stream bind address (default in compose: `0.0.0.0`). |
| ZED_ENABLE_IPC | ZED launch IPC toggle (default in compose: `true`). |
| ZED_STREAM_ENABLED | ZED stream server enable toggle (default in compose: `true`). |
| ZED_DISABLE_NITROS | Disable Nitros acceleration when `true` (default in compose: `false`). |
| LOONE_DOCKERFILE | Optional override for Loon-E Dockerfile path in compose. |
| LOONE_REPO | Optional Git repo used when building the Loon-E image. |
| LOONE_GIT_REF | Optional branch, tag, or commit for the Loon-E repo. |

For full compose variable details, see `wiki/compose.md`.

---

## Requirements

- Ubuntu with `bash`.
- `docker` with Compose support (`docker compose`).
- NVIDIA container runtime support on the target Jetson system.
- `xhost` and `xauth` for GUI forwarding into containers.
- Standard Unix tooling used by the scripts: `whoami`, `grep`, `awk`, `stat`, `mkdir`, `touch`, `cp`, `tee`, `find`.
- `sudo` for installation and for writing system paths.

## Setup Requirements

- `install.bash` must be run with `sudo`.
- The installer appends shell hooks to `~/.bashrc` and `~/.bash_logout`.
- `~/.bashrc` must source `~/.loon-e-env` so runtime variables are available in interactive shells.
- `~/.bashrc` runs `LoonLog -i` on shell start, and `~/.bash_logout` runs `LoonLog -o` on logout.
- After installation, log out and back in if group membership changes were applied.

## Scripts

- `install.bash`: standard Ubuntu installer; deploys scripts, assets, configures cache paths, writes `~/.loon-e-env`, and patches `~/.bashrc` and `~/.bash_logout`.
- `src/LoonLog`: login/session logger; tracks user sessions, log file size checks, and sysadmin prompts with backup/clear options.
- `src/LoonE`: Docker wrapper with commands to build and manage the Loon-Env container environment.

## LoonE Command

`LoonE` is the main operator command for launching the stack.

Supported options:

- `-b`, `--build`: builds both services and starts the compose stack; accepts optional profile argument `virtual` or `zedx`.
- `--build-zed`: builds only the ZED service image; accepts optional profile argument `virtual` or `zedx`.
- `--build-loone`: builds only the Loon-E service image; accepts optional profile argument `virtual` or `zedx`.
- `--stop [SERVICE ...]`: stops compose services; supported targets are `zed`, `loone`, and `all` (defaults to both `zed` and `loone`).
- `-n`, `--no-cache`: disables Docker build cache when used with build flags.
- `-e`, `--enter`: enters a running container by image/container name.
- `-h`, `--help`: prints usage.
- `-q`, `--quack`: prints `Quack!`.
- `-s`, `--start`: reserved by the script, but currently calls a missing `start_container` function.
- `-v`, `--version`: prints version information.

Build profiles:

- `virtual`: exports `ZED_SIM_MODE=true`, `ZED_USE_SIM_TIME=true`, `ZED_CAMERA_MODEL=zedx`.
- `zedx`: exports `ZED_SIM_MODE=false`, `ZED_USE_SIM_TIME=false`, `ZED_CAMERA_MODEL=zedx`.

The command also prepares X11 access for container entry and compose launches.

## Usage

1. Run `sudo ./install.bash` once to install scripts, initialize file paths, and set up env startup hooks.
2. Start a shell session (or source `~/.bashrc`).
3. Let `~/.bashrc` and `~/.bash_logout` drive `LoonLog`, or run `LoonLog -i` and `LoonLog -o` manually.
4. Use `LoonE -b` to launch the compose stack.
5. Optionally override image or fork settings through environment variables before building.

## Wiki

- See `wiki/LoonE.md` for command behavior and examples.
- See `wiki/Setup.md` for shell hook and `~/.bashrc` requirements.
- See `wiki/compose.md` for complete compose variable definitions and defaults.

## Notes

- The logging system is designed to be lightweight and system-friendly, not a full audit trail.
- `KNOWN_USERS_FILE` uses a simple `user:given_name:session_count:warning` format.
- `install.bash` tries `/var/cache/loon-env` first; if not writable, it will use the user's cache directory.
- The ZED build can be redirected to a fork by setting `ZED_WRAPPER_REPO` and `ZED_WRAPPER_GIT_REF` before rebuilding the `zed` image.
