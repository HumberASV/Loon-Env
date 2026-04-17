# Compose Environment Variables

This page documents every variable used in [src/assets/compose.yaml](../src/assets/compose.yaml).

The compose file uses bash-style defaults:

- `${VAR:-value}` means use `VAR` if set, otherwise use `value`.
- Variables can be set in a `.env` file or exported in your shell before running compose.

## How To Set Variables

Example `.env` file:

```env
ROS_DOMAIN_ID=5
DISPLAY=:1
ZED_SIM_ADDRESS=100.68.31.22
ZED_SIM_PORT=30000
ZED_STREAM_PORT=5006
```

Then run:

```bash
docker compose -f src/assets/compose.yaml up -d --build
```

## Build And Image Variables

| Variable | Default | Used By | Purpose |
|---|---|---|---|
| `ZED_X_IMAGE` | `zed-x:latest` | `zed.image` | Image name/tag for the ZED service. |
| `ZED_DOCKERFILE` | `Zedx/Dockerfile` | `zed.build.dockerfile` | Dockerfile path used to build the ZED image. |
| `ZED_SDK_VERSION` | `5.2` | `zed.build.args`, `loone.build.args` | ZED SDK version passed to the installer URL. |
| `L4T_VERSION` | `36.4` | `zed.build.args`, `loone.build.args` | L4T release used to select the ZED SDK installer. |
| `ZED_WRAPPER_REPO` | `https://github.com/HumberASV/zed-ros2-wrapper.git` | `zed.build.args` | Source repository for the ZED ROS2 wrapper. |
| `ZED_WRAPPER_GIT_REF` | `master` | `zed.build.args` | Git branch/tag/commit for `ZED_WRAPPER_REPO`. |
| `ZED_EXAMPLES_REPO` | `https://github.com/stereolabs/zed-ros2-examples.git` | `zed.build.args` | Source repository for ZED ROS2 examples. |
| `ZED_EXAMPLES_GIT_REF` | `master` | `zed.build.args` | Git branch/tag/commit for `ZED_EXAMPLES_REPO`. |
| `LOON_E_IMAGE` | `loon-e:latest` | `loone.image` | Image name/tag for the Loon-E service. |
| `LOONE_DOCKERFILE` | `LoonE/Dockerfile` | `loone.build.dockerfile` | Dockerfile path used to build the Loon-E image. |
| `LOONE_REPO` | `https://github.com/HumberASV/Loon-E.git` | `loone.build.args` | Source repository for Loon-E. |
| `LOONE_GIT_REF` | `main` | `loone.build.args` | Git branch/tag/commit for `LOONE_REPO`. |

## Runtime Variables (Both Services)

These are set in the `environment` section for both `zed` and `loone` unless noted.

| Variable | Default In Compose | Used By | Purpose |
|---|---|---|---|
| `DISPLAY` | `:1` | `zed`, `loone` | X11 display target for GUI/OpenGL apps. |
| `QT_QPA_PLATFORM` | `offscreen` | `zed`, `loone` | Qt platform backend. `offscreen` avoids direct window rendering. |
| `QT_X11_NO_MITSHM` | `1` | `zed`, `loone` | Disables MIT-SHM for X11 compatibility in containers. |
| `NVIDIA_DRIVER_CAPABILITIES` | `all` | `zed`, `loone` | Exposes NVIDIA driver capabilities inside containers. |
| `XAUTHORITY` | `/root/.Xauthority` | `zed`, `loone` | Path to X11 auth file inside container. |
| `ROS_DOMAIN_ID` | `5` | `zed`, `loone` | DDS domain ID; must match across ROS 2 nodes that should communicate. |
| `ROS_LOCALHOST_ONLY` | `0` | `zed`, `loone` | `1` restricts ROS 2 traffic to localhost; `0` allows network communication. |
| `RMW_IMPLEMENTATION` | `rmw_fastrtps_cpp` | `zed`, `loone` | ROS 2 middleware implementation. |
| `LOGNAME` | `root` | `zed` only | Sets process username environment value. |
| `HOST_L4T_RELEASE_FILE` | `/host-nv_tegra_release` | `zed`, `loone` | Host-side L4T release file mounted into the container for the startup mismatch check. The startup guard also verifies the container CUDA version for the supported L4T family. |

## ZED Launch Variables

These variables are used in the `zed` service command when running `zed_camera.launch.py`.

| Variable | Default | Launch Arg | Purpose |
|---|---|---|---|
| `ZED_CAMERA_MODEL` | `zedx` | `camera_model` | Selects camera model profile. |
| `ZED_SIM_MODE` | `true` | `sim_mode` | Enables simulation mode. |
| `ZED_USE_SIM_TIME` | `true` | `use_sim_time` | Uses ROS simulated time source. |
| `ZED_SIM_ADDRESS` | `100.68.31.22` | `sim_address` | Simulator IP/address for ZED data stream. |
| `ZED_SIM_PORT` | `30000` | `sim_port` | Simulator port. |
| `ZED_STREAM_PORT` | `5006` | `stream_port` and `param_overrides.stream_server.port` | Port used by stream server. |
| `ZED_STREAM_ADDRESS` | `0.0.0.0` | `stream_address` | Bind address for stream server. |
| `ZED_ENABLE_IPC` | `true` | `enable_ipc` | Enables IPC transport option in launch config. |
| `ZED_STREAM_ENABLED` | `true` | `param_overrides.stream_server.stream_enabled` | Enables stream server output. |
| `ZED_DISABLE_NITROS` | `false` | `param_overrides.debug.disable_nitros` | Disables Nitros acceleration when set to `true`. |

## Volume Path Variable

| Variable | Default | Used By | Purpose |
|---|---|---|---|
| `XAUTHORITY` | `/home/robo/.Xauthority` | `zed.volumes` | Host-side Xauthority file mounted into `/root/.Xauthority` for X11 auth. |

Note: `XAUTHORITY` appears in two contexts:

- Host path selection for the volume mount (`/home/robo/.Xauthority` default).
- In-container env value (`/root/.Xauthority` fixed in compose).

## Quick Tips

- Keep `ROS_DOMAIN_ID`, `ROS_LOCALHOST_ONLY`, and `RMW_IMPLEMENTATION` aligned across both services.
- If GUI tools fail, verify `DISPLAY`, the `/tmp/.X11-unix` mount, and `XAUTHORITY` host path.
- If simulation does not connect, check `ZED_SIM_ADDRESS`, `ZED_SIM_PORT`, `ZED_STREAM_PORT`, and `ZED_STREAM_ADDRESS`.
- The containers now refuse to start if the host `/etc/nv_tegra_release` does not match the container's L4T release, and they validate the container CUDA version for the matching JetPack/L4T family.
