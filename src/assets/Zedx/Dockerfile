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

# -----------------------------
# 1. System dependencies & Isaac ROS Repo
# -----------------------------
RUN echo "run" && \
    apt-get update && apt-get install -y \
    wget curl gnupg2 lsb-release ca-certificates jq git zstd udev \
    libusb-1.0-0 libv4l-0 kmod \
    libqt5xml5 libqt5core5a libqt5gui5 libqt5widgets5 libqt5opengl5 \
    && curl -fsSL https://isaac.download.nvidia.com/isaac-ros/repos.key | gpg --dearmor -o /usr/share/keyrings/nvidia-isaac-ros.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/nvidia-isaac-ros.gpg] https://isaac.download.nvidia.com/isaac-ros/release-3 jammy release-3" | tee /etc/apt/sources.list.d/nvidia-isaac-ros.list \
    && apt-get update && apt-get install -y \
    ros-humble-isaac-ros-yolov8 \
    ros-humble-isaac-ros-dnn-image-encoder \
    ros-humble-isaac-ros-tensor-rt \
    ros-humble-rmw-cyclonedds-cpp \
    ros-humble-ament-cmake-clang-format \
    time \
    ros-humble-depthimage-to-laserscan \
    ros-humble-zed-description \
    ros-humble-grid-map-rviz-plugin \
    && rm -rf /var/lib/apt/lists/*

# -----------------------------
# 2. ZED SDK Installation
# -----------------------------
RUN wget -q https://download.stereolabs.com/zedsdk/5.2/l4t36.4/jetsons -O zed_sdk.run && \
    chmod +x zed_sdk.run && ./zed_sdk.run -- silent skip_cuda && rm zed_sdk.run

RUN python3 -m pip install --no-cache-dir numpy


# -----------------------------
# 3. Set up ROS workspace
# -----------------------------
RUN mkdir -p /root/ros2_ws/src
WORKDIR /root/ros2_ws/

# -----------------------------
# 4. Install wrapper for camera and examples
# -----------------------------

# Install wrapper for camera
RUN git clone --recurse-submodules https://github.com/stereolabs/zed-ros2-wrapper.git

# (Optional) Install examples for wrapper
RUN git clone --recurse-submodules https://github.com/stereolabs/zed-ros2-examples.git

# -----------------------------
# 5. Build ROS workspace
# -----------------------------

RUN /bin/bash -c "source /opt/ros/humble/setup.bash && \
  apt-get update && \
  rosdep update && \
  rosdep install --from-paths src --ignore-src -r -y && \
  colcon build --parallel-workers 4 --symlink-install \
    --event-handlers console_direct+ \
    --cmake-clean-cache \
    --cmake-args \
      -DCMAKE_BUILD_TYPE=Release \
      -DZED_SDK_ROOT=/usr/local/zed \
      -DCMAKE_LIBRARY_PATH=/usr/local/cuda/lib64/stubs \
      -DCMAKE_CXX_FLAGS=\"-Wl,--allow-shlib-undefined\" \
      --no-warn-unused-cli"

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

RUN echo "source /opt/ros/humble/setup.bash" >> /root/.bashrc && \
    echo "test -f /root/ros2_ws/install/setup.bash && source /root/ros2_ws/install/setup.bash" >> /root/.bashrc

WORKDIR /root/ros2_ws