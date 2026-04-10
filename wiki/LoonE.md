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
  Starts the compose stack defined by the installed asset directory.

- `-e`, `--enter`
  Opens an interactive shell in a running container whose name matches the chosen image name.

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
  Override for the Dockerfile path used by the script.

- `DISPLAY`
  X11 display to forward into containers.

- `XAUTHORITY`
  X11 authentication file used when preparing GUI access.

## Examples

Build and start the stack:

```bash
LoonE -b
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

- `LoonE -b` calls `docker compose -f "$ASSET_DIR/compose.yaml" up -d`.
- The command grants local X access to `root` and `docker` before starting containers.
- If `xauth` is available, the script creates `/tmp/.docker.xauth` for container GUI access.