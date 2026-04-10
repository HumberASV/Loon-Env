# Loon-Env

## Description

Loon-Env provides installer, logging, and Docker wrapper scripts for the Loon-E stack.

- Tracks users online
- Uses environment variables
- Simplifies Docker and Docker Compose workflows for Loon-E and ZED-X

## Global environment variables


| Name | Purpose |
|---|---|
| KNOWN_USERS_FILE | Path to the file tracking known users and their session counts. |
| LOG_FILE | Path to the log file where session events are recorded. |
| LOON_E_IMAGE | Name of the Docker image to build for Loon-E (default: `loon-e:latest`) |
| ZED_X_IMAGE | Name of the Docker image to build for ZED-X (default: `zed-x:latest`) |
| LOON_ENV_VERSION | Installed Loon-Env version written by `install.bash`. |
| XAUTHORITY | X11 auth file used for container GUI forwarding. |
| ZED_WRAPPER_REPO | Optional Git repo used when building the ZED wrapper image. |
| ZED_WRAPPER_GIT_REF | Optional branch, tag, or commit for the ZED wrapper repo. |
| ZED_EXAMPLES_REPO | Optional Git repo used when building ZED examples. |
| ZED_EXAMPLES_GIT_REF | Optional branch, tag, or commit for the ZED examples repo. |

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

- `-b`, `--build`: starts the ZED-X and Loon-E compose services.
- `-e`, `--enter`: enters a running container by image/container name.
- `-h`, `--help`: prints usage.
- `-q`, `--quack`: prints `Quack!`.
- `-s`, `--start`: reserved by the script, but currently calls a missing `start_container` function.
- `-v`, `--version`: prints version information.

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

## Notes

- The logging system is designed to be lightweight and system-friendly, not a full audit trail.
- `KNOWN_USERS_FILE` uses a simple `user:given_name:session_count:warning` format.
- `install.bash` tries `/var/cache/loon-env` first; if not writable, it will use the user's cache directory.
- The ZED build can be redirected to a fork by setting `ZED_WRAPPER_REPO` and `ZED_WRAPPER_GIT_REF` before rebuilding the `zed` image.
