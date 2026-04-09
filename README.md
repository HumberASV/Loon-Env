# Loon-Env

## Description

Setup and logging scripts for Loon-E.

- Tracks users online
- Uses enviroment variables
- Docker launching made easy for Loon-E!

## Global environment variables


| Name | Purpose |
|---|---|
| KNOWN_USERS_FILE | Path to the file tracking known users and their session counts. |
| LOG_FILE | Path to the log file where session events are recorded. |
| LOON_E_IMAGE | Name of the Docker image to build for Loon-E (default: `loon-e:latest`) |
| ZED_X_IMAGE | Name of the Docker image to build for ZED-X (default: `zed-x:latest`) |

---

## Requirements

- `bash` shell.
- `docker` (for image/container commands in `LoonE`/`containerstart.sh` flows).
- `xhost` (for GUI forwarding when entering containers with `LoonE`).
- `whoami`, `grep`, `awk`, `stat`, `mkdir`, `touch` (standard Unix tooling).

## Scripts

- `install.bash`: standard Ubuntu installer; deploys scripts, assets, configures cache paths, writes `~/.loon-e-env`, and patches `~/.bashrc` and `~/.bash_logout`.
- `src/LoonLog`: login/session logger; tracks user sessions, log file size checks, and sysadmin prompts with backup/clear options.
- `src/LoonE`: Docker wrapper with commands to build, start, enter, and manage the Loon-Env container environment.

## Usage

1. Run `sudo ./scripts/install.bash` once to install scripts, initialize file paths, and set up env startup hooks.
2. Start a shell session (or source `~/.bashrc`).
3. Run `./scripts/src/LoonLog -i` on login, and `./scripts/src/LoonLog -o` on logout (or rely on `~/.bashrc` and `~/.bash_logout` hooks).
4. Use `./scripts/src/LoonE` for Docker flow (build/start/enter container).

## Notes

- The logging system is designed to be lightweight and system-friendly, not a full audit trail.
- `KNOWN_USERS_FILE` uses a simple `user:given_name:session_count:warning` format.
- `install.bash` tries `/var/cache/loon-env` first; if not writable, it will use the user's cache directory.
