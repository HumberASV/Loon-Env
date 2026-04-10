# LoonE

`LoonE` is the operator-facing command installed by Loon-Env for launching and interacting with the Docker-based Loon-E environment.

## What It Does

- Wraps Docker and Docker Compose operations behind a short command.
- Launches the `zed` and `loone` services defined in the installed `compose.yaml`.
- Prepares X11 access with `xhost` and `xauth` when GUI forwarding is needed.
- Uses environment variables from `~/.loon-e-env` to decide image names and runtime defaults.

## Usage

```bash
LoonE [OPTION] [IMAGE_NAME]
```

## Options

- `-b`, `--build`
  Builds `zed` and `loone`, then starts/recreates the compose stack.
  Accepts optional profile argument: `virtual` or `zedx`.

- `--build-zed`
  Builds only the `zed` service image.
  Accepts optional profile argument: `virtual` or `zedx`.

- `--build-loone`
  Builds only the `loone` service image.
  Accepts optional profile argument: `virtual` or `zedx`.

- `-n`, `--no-cache`
  Use Docker build without cache. Supported with `--build`, `--build-zed`, and `--build-loone`.

- `-e`, `--enter`
  Opens an interactive shell in a running container whose name matches the chosen image name.

- `--stop [SERVICE ...]`
  Stops compose services. Supported targets: `zed`, `loone`, `all`.
  If no service is provided, both `zed` and `loone` are stopped.

- `-h`, `--help`
  Prints help text.

- `-q`, `--quack`
  Prints `Quack!`.

- `-v`, `--version`
  Prints Loon-Env and LoonE version information.

- `-s`, `--start`
  Present in argument parsing, but currently wired to a missing `start_container` function. Do not rely on this option until the script is fixed.

## Environment Variables

- `LOON_E_IMAGE`
  Default image/container name used by the command.

- `ASSET_DIR`
  Location of installed assets, including `compose.yaml` and Dockerfiles.

- `DOCKERFILE`
  Declared by the script, but not currently used by compose operations.

- `DISPLAY`
  X11 display to forward into containers.

- `XAUTHORITY`
  X11 authentication file used when preparing GUI access. During setup, this may be replaced with `/tmp/.docker.xauth` if `xauth` is available.

- Compose pass-through variables
  Any variables documented in `wiki/compose.md` (for example `ROS_DOMAIN_ID`, `RMW_IMPLEMENTATION`, `ZED_*`, `LOONE_*`) can be exported before running `LoonE` and will be consumed by `docker compose`.

- Build profiles
  `virtual` exports `ZED_SIM_MODE=true` and `ZED_USE_SIM_TIME=true`.
  `zedx` exports `ZED_SIM_MODE=false` and `ZED_USE_SIM_TIME=false`.
  Both profiles export `ZED_CAMERA_MODEL=zedx`.

## Examples

Build and start the stack:

```bash
LoonE -b
```

Build and start without cache:

```bash
LoonE -b --no-cache
```

Build and start in virtual profile:

```bash
LoonE -b virtual
```

Build ZED in hardware profile without cache:

```bash
LoonE --build-zed zedx --no-cache
```

Build only ZED:

```bash
LoonE --build-zed
```

Stop both services:

```bash
LoonE --stop
```

Stop only ZED:

```bash
LoonE --stop zed
```

Enter a running container:

```bash
LoonE -e loon-e:latest
```

Build with a custom ZED wrapper fork:

```bash
export ZED_WRAPPER_REPO=https://github.com/your-org/zed-ros2-wrapper.git
export ZED_WRAPPER_GIT_REF=your-branch
LoonE -b
```

## Notes

- `LoonE -b` builds both services first, then calls `docker compose -f "$ASSET_DIR/compose.yaml" up -d --force-recreate`.
- The command grants local X access to `root` and `docker` before starting containers.
- If `xauth` is available, the script creates `/tmp/.docker.xauth` for container GUI access.
- Compose variable details are documented in `wiki/compose.md`.