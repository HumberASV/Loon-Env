#!/bin/bash
#
# check-l4t-match.sh - A script to check if L4T versions match between container and host
#

L4T_VERSION_CONTAINER="$(sed -n 's/^# \(R[0-9]\+\).*, REVISION: \([0-9.]\+\).*/\1.\2/p' /etc/nv_tegra_release 2>/dev/null || echo "unknown")"
L4T_VERSION_HOST="$(sed -n 's/^# \(R[0-9]\+\).*, REVISION: \([0-9.]\+\).*/\1.\2/p' /host-nv_tegra_release 2>/dev/null || echo "unknown")"

if [ "$L4T_VERSION_CONTAINER" = "$L4T_VERSION_HOST" ]; then
    echo "L4T versions match: $L4T_VERSION_CONTAINER"
    exit 0
else
    echo "L4T version mismatch: container has $L4T_VERSION_CONTAINER but host has $L4T_VERSION_HOST" >&2
    exit 1
fi
