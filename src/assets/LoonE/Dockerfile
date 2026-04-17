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

FROM nvcr.io/nvidia/isaac/ros:aarch64-ros2_humble_4c0c55dddd2bbcc3e8d5f9753bee634c

ARG LOONE_REPO=https://github.com/HumberASV/Loon-E.git
ARG LOONE_GIT_REF=main
ARG ZED_SDK_VERSION=5.2
ARG L4T_VERSION=36.4

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
    wget curl gnupg2 lsb-release ca-certificates jq git zstd udev \
    libusb-1.0-0 libv4l-0 kmod \
    libqt5xml5 libqt5core5a libqt5gui5 libqt5widgets5 libqt5opengl5 \
    && curl -fsSL https://isaac.download.nvidia.com/isaac-ros/repos.key | gpg --dearmor -o /usr/share/keyrings/nvidia-isaac-ros.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/nvidia-isaac-ros.gpg] https://isaac.download.nvidia.com/isaac-ros/release-3 jammy main" | tee /etc/apt/sources.list.d/nvidia-isaac-ros.list \
    && apt-get update && apt-get install -y \
    ros-humble-isaac-ros-yolov8 \
    ros-humble-isaac-ros-dnn-image-encoder \
    ros-humble-isaac-ros-tensor-rt \
    ros-humble-ament-cmake-clang-format \
    time \
    ros-humble-depthimage-to-laserscan \
    ros-humble-zed-description \
    ros-humble-grid-map-rviz-plugin \
    && rm -rf /var/lib/apt/lists/*

# -----------------------------
# 2. ZED SDK Installation
# -----------------------------
COPY check-l4t-match.sh /usr/local/bin/check-l4t-match
RUN chmod +x /usr/local/bin/check-l4t-match

RUN wget -q "https://download.stereolabs.com/zedsdk/${ZED_SDK_VERSION}/l4t${L4T_VERSION}/jetsons" -O zed_sdk.run && \
    chmod +x zed_sdk.run && ./zed_sdk.run -- silent skip_cuda && rm zed_sdk.run

RUN python3 -m pip install --no-cache-dir numpy


# -----------------------------
# 3. Clone Repo
# -----------------------------
WORKDIR /root/

RUN echo "Using Loon-E ref: ${LOONE_GIT_REF}" && \
    git clone --recurse-submodules "${LOONE_REPO}" Loon-E && \
    cd /root/Loon-E && \
    git fetch --all --tags && \
    git checkout "${LOONE_GIT_REF}" && \
    git submodule update --init --recursive

# This may fail if the clone didn't work
WORKDIR /root/Loon-E/
RUN mkdir -p /root/Loon-E/src

RUN /bin/bash -c "colcon build --symlink-install \
    && source /opt/ros/humble/setup.bash \
    && source install/setup.bash"
# -----------------------------
# 4. NGC Assets & Final Setup
# -----------------------------
ENV MAJOR_VERSION=3
ENV MINOR_VERSION=1
RUN VERSION_REQ_URL="https://catalog.ngc.nvidia.com/api/resources/versions?orgName=nvidia&teamName=isaac&name=isaac_ros_yolov8_assets&isPublic=true&pageNumber=0&pageSize=100&sortOrder=CREATED_DATE_DESC" && \
    LATEST_VERSION_ID=$(curl -s -H "Accept: application/json" "$VERSION_REQ_URL" | jq -r ".recipeVersions[] | .versionId as \$v | \$v | select(test(\"^\\\\d+\\\\.\\\\d+\\\\.\\\\d+$\")) | split(\".\") | {major: .[0]|tonumber, minor: .[1]|tonumber, patch: .[2]|tonumber} | select(.major == $MAJOR_VERSION and .minor <= $MINOR_VERSION) | \$v" | sort -V | tail -n 1) && \
    if [ -n "$LATEST_VERSION_ID" ]; then \
        mkdir -p /root/Loon-E/src/isaac_ros_assets && \
        curl -LO --request GET "https://api.ngc.nvidia.com/v2/resources/nvidia/isaac/isaac_ros_yolov8_assets/versions/$LATEST_VERSION_ID/files/quickstart.tar.gz" && \
        tar -xf quickstart.tar.gz -C /root/Loon-E/src/isaac_ros_assets && \
        rm quickstart.tar.gz; \
    fi

RUN test -f /usr/lib/aarch64-linux-gnu/tegra/libv4l2.so.0 && \
    ln -sf /usr/lib/aarch64-linux-gnu/tegra/libv4l2.so.0 /usr/lib/aarch64-linux-gnu/libv4l2.so || true

RUN echo "source /opt/ros/humble/setup.bash" >> /root/.bashrc && \
    echo "test -f /root/Loon-E/install/setup.bash && source /root/Loon-E/install/setup.bash" >> /root/.bashrc && \
    echo "export ROS_LOCALHOST_ONLY=\${ROS_LOCALHOST_ONLY:-0}" >> /root/.bashrc && \
    echo "export RMW_IMPLEMENTATION=\${RMW_IMPLEMENTATION:-rmw_cyclonedds_cpp}" >> /root/.bashrc

WORKDIR /root/Loon-E