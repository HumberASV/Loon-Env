#!/bin/sh

set -eu

HOST_L4T_RELEASE_FILE="${HOST_L4T_RELEASE_FILE:-/host-nv_tegra_release}"
CONTAINER_L4T_RELEASE_FILE="${CONTAINER_L4T_RELEASE_FILE:-/etc/nv_tegra_release}"

parse_l4t_version() {
    file_path="$1"

    if [ ! -f "$file_path" ]; then
        return 1
    fi

    sed -n 's/^# R\([0-9][0-9]*\) (release), REVISION: \([0-9][0-9]*\)\.\([0-9][0-9]*\).*/\1.\2/p' "$file_path" | head -n 1
}

detect_cuda_version() {
    if command -v nvcc >/dev/null 2>&1; then
        nvcc --version | sed -n 's/^Cuda compilation tools, release \([0-9][0-9]*\.[0-9][0-9]*\).*/\1/p' | head -n 1
        return 0
    fi

    if [ -f /usr/local/cuda/version.json ]; then
        sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([0-9][0-9]*\.[0-9][0-9]*\)\..*".*/\1/p' /usr/local/cuda/version.json | head -n 1
    fi
}

expected_cuda_version() {
    case "$1" in
        36.4)
            echo "12.6"
            ;;
    esac
}

host_l4t_version="$(parse_l4t_version "$HOST_L4T_RELEASE_FILE" || true)"
container_l4t_version="$(parse_l4t_version "$CONTAINER_L4T_RELEASE_FILE" || true)"
container_cuda_version="$(detect_cuda_version || true)"
expected_container_cuda_version="$(expected_cuda_version "$container_l4t_version" || true)"

if [ -z "$host_l4t_version" ]; then
    echo "Error: host L4T release file is missing or unreadable at $HOST_L4T_RELEASE_FILE." >&2
    echo "Mount the host /etc/nv_tegra_release into the container at that path." >&2
    exit 1
fi

if [ -z "$container_l4t_version" ]; then
    echo "Error: container L4T release file is missing or unreadable at $CONTAINER_L4T_RELEASE_FILE." >&2
    exit 1
fi

if [ "$host_l4t_version" != "$container_l4t_version" ]; then
    echo "Error: host L4T version $host_l4t_version does not match container L4T version $container_l4t_version." >&2
    echo "Rebuild or retag the container so it matches the host JetPack/L4T release." >&2
    exit 1
fi

if [ -n "$expected_container_cuda_version" ] && [ -n "$container_cuda_version" ] && [ "$container_cuda_version" != "$expected_container_cuda_version" ]; then
    echo "Error: container CUDA version $container_cuda_version does not match the expected CUDA version $expected_container_cuda_version for L4T $container_l4t_version." >&2
    echo "Use a container built for the same JetPack/L4T family as the host system." >&2
    exit 1
fi

if [ -n "$expected_container_cuda_version" ]; then
    echo "L4T check passed: host and container are both $host_l4t_version; container CUDA is $container_cuda_version (expected $expected_container_cuda_version)."
else
    echo "L4T check passed: host and container are both $host_l4t_version."
fi
