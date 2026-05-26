# Copyright (c) 2026 Carson Fujita
# Copyright (c) 2026 Uday Chahal
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.


# This Dockerfile sets up the environment for ZED camera development using ROS 2 Humble on NVIDIA Jetson devices.
# It installs examples so you may want to edit this file to change that

FROM nvcr.io/nvidia/isaac/ros:aarch64-ros2_humble_4c0c55dddd2bbcc3e8d5f9753bee634c

ARG ZED_WRAPPER_REPO=https://github.com/HumberASV/zed-ros2-wrapper.git
ARG ZED_WRAPPER_GIT_REF=master
ARG ZED_EXAMPLES_REPO=https://github.com/stereolabs/zed-ros2-examples.git
ARG ZED_EXAMPLES_GIT_REF=master
ARG ZED_SDK_VERSION=5.2
ARG L4T_VERSION=36.4

ENV DEBIAN_FRONTEND=noninteractive
ENV CMAKE_PREFIX_PATH="/usr/local/zed:$CMAKE_PREFIX_PATH"
ENV ZED_DIR="/usr/local/zed"

# -----------------------------
# 0. Jetson APT keyring bootstrap
# -----------------------------
RUN set -eux; \
    mkdir -p /usr/share/keyrings; \
    curl -fsSL https://repo.download.nvidia.com/jetson/jetson-ota-public.asc \
    | gpg --dearmor -o /usr/share/keyrings/nvidia-jetson-archive-keyring.gpg; \
    curl -fsSL https://dl.yarnpkg.com/debian/pubkey.gpg \
    | gpg --dearmor -o /usr/share/keyrings/yarn-archive-keyring.gpg; \
    for f in /etc/apt/sources.list /etc/apt/sources.list.d/*.list; do \
        [ -f "$f" ] || continue; \
        sed -i 's|^deb \(\[[^]]*\] \)\?https://repo.download.nvidia.com/jetson/|deb [signed-by=/usr/share/keyrings/nvidia-jetson-archive-keyring.gpg] https://repo.download.nvidia.com/jetson/|g' "$f"; \
        sed -i 's|^deb \(\[[^]]*\] \)\?https://dl.yarnpkg.com/debian/|deb [signed-by=/usr/share/keyrings/yarn-archive-keyring.gpg] https://dl.yarnpkg.com/debian/|g' "$f"; \
    done

# -----------------------------
# 1. System dependencies & Isaac ROS Repo
# -----------------------------
RUN echo "run" && \
    apt-get update && apt-get install -y \
    wget curl gnupg2 lsb-release ca-certificates jq git zstd udev sudo \
    libusb-1.0-0 libv4l-0 kmod \
    libqt5xml5 libqt5core5a libqt5gui5 libqt5widgets5 libqt5opengl5 \
    && curl -fsSL https://isaac.download.nvidia.com/isaac-ros/repos.key | gpg --dearmor -o /usr/share/keyrings/nvidia-isaac-ros.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/nvidia-isaac-ros.gpg] https://isaac.download.nvidia.com/isaac-ros/release-3 jammy main" | tee /etc/apt/sources.list.d/nvidia-isaac-ros.list \
    && apt-get update && apt-get install -y \
    ros-humble-isaac-ros-yolov8 \
    ros-humble-isaac-ros-dnn-image-encoder \
    ros-humble-isaac-ros-tensor-rt \
    ros-humble-ament-cmake-clang-format \
    ros-humble-zed-msgs \
    time \
    ros-humble-depthimage-to-laserscan \
    ros-humble-zed-description \
    ros-humble-grid-map-rviz-plugin \
    && rm -rf /var/lib/apt/lists/*

# -----------------------------
# 2. ZED SDK Installation
# -----------------------------
WORKDIR /tmp

# l4t enviroment variables are in the form RXX.YY.ZZ so we need to extract the major and minor version for the download link
RUN L4T_VERSION_SHORT="$(printf '%s' "${L4T_VERSION#R}" | cut -d. -f1,2)" && \
    wget -q "https://download.stereolabs.com/zedsdk/${ZED_SDK_VERSION}/l4t${L4T_VERSION_SHORT}/jetsons" -O zed_sdk.run && \
    chmod +x zed_sdk.run && ./zed_sdk.run -- silent skip_cuda && rm zed_sdk.run

RUN python3 -m pip install --no-cache-dir "numpy<2"

# dpkg-statoverride can cause issues with plocate which is a dependency of the ZED SDK
# so we need to remove any overrides for plocate
RUN set -eux; \
    if grep -qE '(^|[[:space:]])plocate([[:space:]]|$)' /var/lib/dpkg/statoverride; then \
        sed -i.bak '/[[:space:]]plocate[[:space:]]/d' /var/lib/dpkg/statoverride; \
    fi

# Create a non-root user named "robo" if it doesn't already exist, and add to sudoers
RUN set -eux; \
    if ! id -u robo >/dev/null 2>&1; then \
        useradd --create-home --shell /bin/bash robo; \
    fi

# Ensure the ZED SDK directories are owned by the robo user
RUN set -eux; \
    for package in pyzed cython numpy; do \
        for path in /usr/local/lib/python3.10/dist-packages/${package}*; do \
            [ -e "$path" ] || continue; \
            chown -R robo:robo "$path"; \
        done; \
    done

# Ensure the ZED SDK directory is owned by the robo user
RUN set -eux; \
    printf 'robo ALL=(ALL) NOPASSWD:ALL\n' > /etc/sudoers.d/robo; \
    chmod 0440 /etc/sudoers.d/robo

# Ensure ZED CMake config is discoverable by CMake
# but it doesn't work 
RUN set -eux; \
    if [ -f /usr/local/zed/zed-config.cmake ]; then \
        mkdir -p /usr/local/lib/cmake/ZED; \
        ln -sf /usr/local/zed/zed-config.cmake /usr/local/lib/cmake/ZED/ZEDConfig.cmake; \
    fi


# -----------------------------
# 3. Set up ROS workspace
# -----------------------------
RUN mkdir -p /home/robo/ros2_ws/src
WORKDIR /home/robo/ros2_ws/

# -----------------------------
# 4. Install wrapper for camera and examples
# -----------------------------

# Install wrapper for camera
RUN echo "Using zed-ros2-wrapper ref: ${ZED_WRAPPER_GIT_REF}" && \
    git clone --recurse-submodules "${ZED_WRAPPER_REPO}" src/zed-ros2-wrapper && \
    cd src/zed-ros2-wrapper && \
    git fetch --all --tags && \
    git checkout "${ZED_WRAPPER_GIT_REF}" && \
    git submodule update --init --recursive

# (Optional) Install examples for wrapper
RUN echo "Using zed-ros2-examples ref: ${ZED_EXAMPLES_GIT_REF}" && \
    git clone --recurse-submodules "${ZED_EXAMPLES_REPO}" src/zed-ros2-examples && \
    cd src/zed-ros2-examples && \
    git fetch --all --tags && \
    git checkout "${ZED_EXAMPLES_GIT_REF}" && \
    git submodule update --init --recursive

# -----------------------------
# 5. Build ROS workspace
# -----------------------------

WORKDIR /home/robo/ros2_ws/

# TODO: move this to a script because it can cause connection issues for remote work
# RUN /bin/bash -c "source /opt/ros/humble/setup.bash && \
#   apt-get update && \
#   rosdep update && \
#   rosdep install --from-paths src --ignore-src -r -y && \
#   colcon build --parallel-workers 4 --symlink-install \
#     --event-handlers console_direct+ \
#     --base-paths src \
#     --cmake-clean-cache \
#     --cmake-args \
#       -DCMAKE_BUILD_TYPE=Release \
#       -DZED_SDK_ROOT=/usr/local/zed \
#       -DCMAKE_LIBRARY_PATH=/usr/local/cuda/lib64/stubs \
#       -DCMAKE_CXX_FLAGS=\"-Wl,--allow-shlib-undefined\" \
#       --no-warn-unused-cli && \
#   rm -rf /var/lib/apt/lists/*"

# -----------------------------
# 6. NGC Assets & Final Setup
# -----------------------------
ENV MAJOR_VERSION=3
ENV MINOR_VERSION=1
RUN VERSION_REQ_URL="https://catalog.ngc.nvidia.com/api/resources/versions?orgName=nvidia&teamName=isaac&name=isaac_ros_yolov8_assets&isPublic=true&pageNumber=0&pageSize=100&sortOrder=CREATED_DATE_DESC" && \
    LATEST_VERSION_ID=$(curl -s -H "Accept: application/json" "$VERSION_REQ_URL" | jq -r ".recipeVersions[] | .versionId as \$v | \$v | select(test(\"^\\\\d+\\\\.\\\\d+\\\\.\\\\d+$\")) | split(\".\") | {major: .[0]|tonumber, minor: .[1]|tonumber, patch: .[2]|tonumber} | select(.major == $MAJOR_VERSION and .minor <= $MINOR_VERSION) | \$v" | sort -V | tail -n 1) && \
    if [ -n "$LATEST_VERSION_ID" ]; then \
        mkdir -p /root/ros2_ws/src/isaac_ros_assets && \
        curl -LO --request GET "https://api.ngc.nvidia.com/v2/resources/nvidia/isaac/isaac_ros_yolov8_assets/versions/$LATEST_VERSION_ID/files/quickstart.tar.gz" && \
        tar -xf quickstart.tar.gz -C /root/ros2_ws/src/isaac_ros_assets && \
        rm quickstart.tar.gz; \
    fi

RUN test -f /usr/lib/aarch64-linux-gnu/tegra/libv4l2.so.0 && \
    ln -sf /usr/lib/aarch64-linux-gnu/tegra/libv4l2.so.0 /usr/lib/aarch64-linux-gnu/libv4l2.so || true

RUN sudo apt install ros-$ROS_DISTRO-rmw-cyclonedds-cpp

RUN echo "source /opt/ros/humble/setup.bash" >> /home/robo/.bashrc && \
    # echo "test -f /home/robo/ros2_ws/install/setup.bash && source /home/robo/ros2_ws/install/setup.bash" >> /home/robo/.bashrc && \
    echo "export ROS_LOCALHOST_ONLY=\${ROS_LOCALHOST_ONLY:-0}" >> /home/robo/.bashrc && \
    echo "export RMW_IMPLEMENTATION=\${RMW_IMPLEMENTATION:-rmw_cyclonedds_cpp}" >> /home/robo/.bashrc && \
    echo "export ROS_DOMAIN_ID=\${ROS_DOMAIN_ID:-0}" >> /home/robo/.bashrc && \
    echo "export ROS_DISTRO=\${ROS_DISTRO:-humble}" >> /home/robo/.bashrc

# export LT4T version as an environment variable for use in the ROS workspace build
ENV L4T_VERSION=${L4T_VERSION}
RUN echo "export L4T_VERSION=${L4T_VERSION}" >> /home/robo/.bashrc

# export ZED_SDK version as an environment variable for use in the ROS workspace build
ENV ZED_SDK_VERSION=${ZED_SDK_VERSION}
RUN echo "export ZED_SDK_VERSION=${ZED_SDK_VERSION}" >> /home/robo/.bashrc

WORKDIR /home/robo/ros2_ws

RUN chown -R robo:robo /home/robo/ros2_ws