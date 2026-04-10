# Setup

This page documents the shell and environment requirements that Loon-Env expects after installation.

## Shell Hooks

`install.bash` modifies user shell files to make logging and environment variables available automatically.

### `~/.bashrc`

The installer appends logic equivalent to:

```bash
if [ -f "$HOME/.loon-e-env" ]; then
    source "$HOME/.loon-e-env"
fi
LoonLog -i
```

This means:

- `~/.loon-e-env` must exist and be readable by the user.
- Interactive shells will automatically load Loon-Env variables.
- Interactive shells will automatically log a session start through `LoonLog -i`.

### `~/.bash_logout`

The installer appends:

```bash
LoonLog -o
```

This logs session termination when the shell exits.

## Environment File

The installer writes `~/.loon-e-env` with exports such as:

- `KNOWN_USERS_FILE`
- `LOG_FILE`
- `LOON_E_IMAGE`
- `ZED_X_IMAGE`
- `LOON_ENV_VERSION`
- `XAUTHORITY`
- `ASSET_DIR`

Additional compose and build overrides can also be exported there if desired, for example:

- `ZED_DOCKERFILE`
- `ZED_WRAPPER_REPO`
- `ZED_WRAPPER_GIT_REF`
- `ZED_EXAMPLES_REPO`
- `ZED_EXAMPLES_GIT_REF`
- `LOONE_DOCKERFILE`
- `LOONE_REPO`
- `LOONE_GIT_REF`

Runtime overrides commonly set there include:

- `DISPLAY`
- `QT_QPA_PLATFORM`
- `ROS_DOMAIN_ID`
- `ROS_LOCALHOST_ONLY`
- `RMW_IMPLEMENTATION`
- `ZED_CAMERA_MODEL`
- `ZED_SIM_MODE`
- `ZED_USE_SIM_TIME`
- `ZED_SIM_ADDRESS`
- `ZED_SIM_PORT`
- `ZED_STREAM_PORT`
- `ZED_STREAM_ADDRESS`
- `ZED_ENABLE_IPC`
- `ZED_STREAM_ENABLED`
- `ZED_DISABLE_NITROS`

For complete descriptions and defaults, see `wiki/compose.md`.

## Installation Requirements

- Run `install.bash` with `sudo`.
- The installer creates and uses the `loon-env-users` group.
- Users added to that group may need to log out and back in before permissions are correct.
- The installer copies scripts to the chosen bin directory and assets to the chosen share directory.

## Practical Checks

After installation, verify:

```bash
test -f "$HOME/.loon-e-env"
grep -n 'source "$HOME/.loon-e-env"' "$HOME/.bashrc"
grep -n 'LoonLog -i' "$HOME/.bashrc"
grep -n 'LoonLog -o' "$HOME/.bash_logout"
```

If GUI applications are expected inside containers, also verify:

```bash
command -v xhost
command -v xauth
test -f "$HOME/.Xauthority"
```