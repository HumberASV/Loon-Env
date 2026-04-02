# Loon-Env

## Name of application
Loon-Env

## Description
Setup the Loon-Env environment with convenient user commands, Docker orchestration utilities, and an integrated log-based user tracking system.

## Global environment variables
- `KNOWN_USERS_FILE` - path to the user tracking file (default from install: `/var/cache/loon-env/known_users.txt` or fallback `~/.cache/loon-env/known_users.txt`).
- `LOG_FILE` - path to the log file (default from install: `/var/cache/loon-env/log.txt` or fallback `~/.cache/loon-env/log.txt`).

## Requirements
- `bash` shell.
- `docker` (for image/container commands in `LoonE`/`containerstart.sh` flows).
- `xhost` (for GUI forwarding when entering containers with `LoonE`).
- (optional) `whoami`, `grep`, `awk`, `stat`, `mkdir`, `touch` (standard Unix tooling).

## Scripts
- `install.bash`: standard Ubuntu installer; deploys scripts, assets, configures cache paths, writes `~/.loon-e-env`, and patches `~/.bashrc` and `~/.bash_logout`.
- `src/LoonLog`: login/session logger; tracks user sessions, log file size checks, and sysadmin prompts with backup/clear options.
- `src/LoonExit`: logout handler; removes the `user:PID` entry from `KNOWN_USERS_FILE`.
- `src/LoonE`: Docker wrapper with commands to build, start, enter, and manage the Loon-Env container environment.
- `help-me.sh`: friendly help text for all main commands.
- `containerbuild.sh`: build Docker image with optional image name argument and overwrite confirmation.
- `containerenter.sh`: enter a running container and check existence before exec.

## Usage
1. Run `./scripts/install.bash` once to install scripts, initialize file paths, and set up env startup hooks.
2. Start a shell session (or source `~/.bashrc`).
3. Run `./scripts/src/LoonLog -i` on login, and `./scripts/src/LoonLog -o` on logout (or rely on `~/.bashrc` and `~/.bash_logout` hooks).
4. Use `./scripts/src/LoonE` for Docker flow (build/start/enter container).

## Notes
- The logging system is designed to be lightweight and system-friendly, not a full audit trail.
- `KNOWN_USERS_FILE` uses a simple `username:PID` format.
- `install.bash` tries `/var/cache/loon-env` first; if not writable, it will use the user's cache directory.

