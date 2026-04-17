#!/bin/bash

# Copyright (c) 2026 Carson Fujita
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

# Standard installer for Ubuntu: 
# deploys Loon-Env script files and data resources and configures logging environment.
# Usage: sudo ./install.bash [--sync-delete-assets] [INSTALL_BIN_DIR] [INSTALL_SHARE_DIR] [INSTALL_CACHE_DIR]
# Arguments:
# INSTALL_BIN_DIR     Directory to install executable scripts (default: /usr/local/bin)
# INSTALL_SHARE_DIR   Directory to install shared assets (default: /usr/share/loon-env)
# INSTALL_CACHE_DIR   Directory to use for cache and logs (default: /var/cache/loon-env)
# Options:
# --sync-delete-assets  Use rsync --delete for asset sync when rsync is available

set -euo pipefail

# ------------------- CONSTANTS ------------------
APP_NAME="Loon-Env"
VERSION="2.0.2"
GROUP_NAME="loon-env-users"
HOME="$(eval echo "~${SUDO_USER:-$USER}")" # Determine the home directory of the user running the script with sudo

# Default installation paths (can be overridden by command-line arguments)
DEFAULT_INSTALL_BIN_DIR="/usr/local/bin"
DEFAULT_INSTALL_SHARE_DIR="/usr/share/$APP_NAME"
DEFAULT_CACHE_DIR="/var/cache/$APP_NAME"

# Docker image defaults
LOON_E_IMAGE="loon-e:latest"
ZED_X_IMAGE="zed-x:latest"
ASSET_SYNC_DELETE="${ASSET_SYNC_DELETE:-false}"

# Managed shell hook markers
BASHRC_BLOCK_START="# >>> Loon-E managed block >>>"
BASHRC_BLOCK_END="# <<< Loon-E managed block <<<"
BASHLOGOUT_BLOCK_START="# >>> Loon-E logout managed block >>>"
BASHLOGOUT_BLOCK_END="# <<< Loon-E logout managed block <<<"

# Where source scripts are located
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ASSETS_DIR="$ROOT_DIR/src/assets"

# ------------------ FUNCTIONS ------------------

# ------------------ COMMON UTILITY FUNCTIONS -------------------

# Prints installer usage/help text and exits.
# Version: 2.0.0
# Returns
# 0: if help text is printed successfully
handle_help() {
    cat <<'EOF'
Usage: sudo ./install.bash [--sync-delete-assets] [INSTALL_BIN_DIR] [INSTALL_SHARE_DIR] [INSTALL_CACHE_DIR]
Installs the Loon-Env scripts and assets, and configures the logging environment.
Arguments:
INSTALL_BIN_DIR     Directory to install executable scripts (default: /usr/local/bin)
INSTALL_SHARE_DIR   Directory to install shared assets (default: /usr/share/loon-env)
INSTALL_CACHE_DIR   Directory to use for cache and logs (default: /var/cache/loon-env)
Options:
--sync-delete-assets Use rsync --delete for asset sync when rsync is available
Environment:
ASSET_SYNC_DELETE=true enables delete-sync mode without passing a CLI option
EOF
    exit 0
}

# Verifies the script is running as root.
# Version: 2.0.0
# Returns
# 0: if running as root
require_root() {
    if [ "$EUID" -ne 0 ]; then
        echo "This installer must be run as root. Use sudo ./install.bash" >&2
        exit 1
    fi
}

# Inserts or replaces a managed block delimited by markers in a target file.
# Version: 2.0.0
# Parameters:
#     $1: target file path
#     $2: start marker string
#     $3: end marker string
#     $4: block content to insert or replace
# Returns
# 0: if the managed block is upserted successfully
upsert_managed_block() {
    local file="$1"
    local start_marker="$2"
    local end_marker="$3"
    local block_content="$4"
    local tmp_file

    sudo touch "$file"
    tmp_file="$(mktemp)"

    awk -v start="$start_marker" -v end="$end_marker" -v block="$block_content" '
BEGIN {
    in_block = 0
    inserted = 0
}
$0 == start {
    in_block = 1
    if (!inserted) {
        print block
        inserted = 1
    }
    next
}
$0 == end {
    in_block = 0
    next
}
in_block == 0 {
    print
}
END {
    if (!inserted) {
        if (NR > 0) {
            print ""
        }
        print block
    }
}
' "$file" > "$tmp_file"

    sudo tee "$file" > /dev/null < "$tmp_file"
    rm -f "$tmp_file"
}

# ------------------ INSTALLATION FUNCTIONS ------------------

# Setup for Zedx
setup_zedx() {
    echo "Setting up ZED-X dependencies..."

    # Check if ROS_DISTRO is set, default to 'humble' if not
    ROS_DISTRO="${ROS_DISTRO:-humble}"
    echo "Using ROS distribution: $ROS_DISTRO"

    sudo apt install ros-$ROS_DISTRO-rmw-cyclonedds-cpp -y

    # Set ipfrag_time to 3 seconds to prevent fragmentation issues with the ZED camera stream
    echo \"setting ipfrag_time to 3\" &&
    sudo sysctl -w net.ipv4.ipfrag_time=3

    # Set ipfrag_high_thresh to 128MB to allow larger fragmented packets from the ZED stream without dropping them
    echo \"setting ipfrag_high_thresh to 128MB\" &&
    sudo sysctl -w net.ipv4.ipfrag_high_thresh=134217728

    # Increase the maximum receive buffer size for network packets to accommodate the high bandwidth of the ZED stream
    echo \"checking ipfrag_high_thresh\" &&
    sudo sysctl -w net.core.rmem_max=2147483647

    echo "Reccomend accepting overwriting buffers.conf to make these settings permanent. If you choose not to, you may need to run the above sysctl commands manually after each reboot to ensure proper ZED-X performance."
    sudo cp -i ${ASSETS_DIR}/buffers.conf /etc/sysctl.d/60-zed-buffers.conf

    # Apply the new sysctl settings immediately
    sudo sysctl -p /etc/sysctl.d/60-zed-buffers.conf

    # Validate
    if [ "$(sysctl -n net.core.rmem_max)" != "2147483647" ]; then
        echo "Error: net.core.rmem_max is not set to 2147483647" >&2
        exit 1
    fi
    if [ "$(sysctl -n net.ipv4.ipfrag_time)" != "3" ]; then
        echo "Error: net.ipv4.ipfrag_time is not set to 3" >&2
        exit 1
    fi
    if [ "$(sysctl -n net.ipv4.ipfrag_high_thresh)" != "134217728" ]; then
        echo "Error: net.ipv4.ipfrag_high_thresh is not set to 134217728" >&2
        exit 1
    fi
    
    sudo cp -f "$ASSETS_DIR/cyclonedds.xml" "$HOME/cyclonedds.xml"
    echo "ZED-X dependencies set up successfully."
}

# Checks for $GROUP_NAME and creates it if it doesn't exist, then adds the current user to the group
# Ensures installer group exists and current user is a member.
# Version: 2.0.0
# Returns
# 0: if group and membership checks complete successfully
setup_user_group() {
    if ! getent group "$GROUP_NAME" > /dev/null; then
        echo "Creating group '$GROUP_NAME'..."
        sudo groupadd "$GROUP_NAME"
    else
        echo "Group '$GROUP_NAME' already exists."
    fi
    current_user=$(logname)
    if id -nG "$current_user" | grep -qw "$GROUP_NAME"; then
        echo "User '$current_user' is already in group '$GROUP_NAME'."
    else
        echo "Adding user '$current_user' to group '$GROUP_NAME'..."
        sudo usermod -aG "$GROUP_NAME" "$current_user"
        echo "User '$current_user' added to group '$GROUP_NAME'. Please log out and log back in for group changes to take effect."
    fi
}

# Sets the directorys for installation, creating them if necessary
# Creates installation directories for bin, share, and cache paths.
# Version: 2.0.0
# Returns
# 0: if installation directories are created successfully
setup_directories() {
    echo "Setting up directories..."
    sudo mkdir -p "$INSTALLATION_BIN_DIR"
    sudo mkdir -p "$INSTALLATION_SHARE_DIR"
    sudo mkdir -p "$INSTALLATION_CACHE_DIR"
    echo "Directories set up successfully."
}

# Installs the Loon-Env scripts to the specified bin directory
# Copies executable scripts into the installation bin directory.
# Version: 2.0.0
# Returns
# 0: if script installation completes successfully
install_scripts() {
    local script src_file

    echo "Installing Loon-Env..."
    if [ -f "$ROOT_DIR/src/LoonE" ]; then
        sudo cp -f "$ROOT_DIR/src/LoonE" "$INSTALLATION_BIN_DIR/LoonE"
        sudo chmod 755 "$INSTALLATION_BIN_DIR/LoonE"
    else
        echo "Warning: LoonE script not found at $ROOT_DIR/src/LoonE"
    fi
    echo "Scripts copied to $INSTALLATION_BIN_DIR"
}

# Copies the asset files to the specified share directory
# Copies or syncs assets into the installation share directory.
# Version: 2.0.0
# Returns
# 0: if asset copy or sync completes successfully
copy_assets() {
    echo "Copying assets..."
    if [ -d "$ROOT_DIR/src/assets" ]; then
        if [ "$ASSET_SYNC_DELETE" = "true" ] && command -v rsync > /dev/null 2>&1; then
            sudo rsync -a --delete "$ROOT_DIR/src/assets/" "$INSTALLATION_SHARE_DIR/"
            echo "Assets synced with rsync --delete"
        else
            sudo cp -frv "$ROOT_DIR/src/assets"/* "$INSTALLATION_SHARE_DIR/"
            if [ "$ASSET_SYNC_DELETE" = "true" ]; then
                echo "ASSET_SYNC_DELETE=true but rsync not found; fell back to copy mode." >&2
            fi
        fi
    fi
    echo "Assets copied to $INSTALLATION_SHARE_DIR"
}

# Sets cache location and derives known-users and log file paths.
# Version: 2.0.0
# Returns
# 0: if cache paths are configured successfully
configure_cache_directory() {
    CACHE_DIR="$INSTALLATION_CACHE_DIR"

    echo "Cache directory set to $CACHE_DIR"
    sudo mkdir -p "$CACHE_DIR"
    echo "Cache directory created if it did not exist."
}

# Writes the runtime environment file used by shell sessions.
# Version: 2.0.0
# Returns
# 0: if environment file is written successfully
write_environment_file() {
    echo "Writing environment variables to ~/.loon-e-env..."
    touch "$HOME/.loon-e-env"
    sudo chgrp "$GROUP_NAME" "$HOME/.loon-e-env"
    sudo chmod 660 "$HOME/.loon-e-env"
    sudo cat > "$HOME/.loon-e-env" <<EOF
export LOON_E_IMAGE="${LOON_E_IMAGE}"
export ZED_X_IMAGE="${ZED_X_IMAGE}"
export LOON_ENV_VERSION="${VERSION}"
export XAUTHORITY="${HOME}/.Xauthority"
export CYCLONEDDS_URI="file://${HOME}/cyclonedds.xml"
export RMW_IMPLEMENTATION=rmw_cyclonedds_cpp
export ROS_DOMAIN_ID=0
export ROS_LOCALHOST_ONLY=0
EOF
    result=$(ls -l "$HOME/.loon-e-env" | grep ".loon-e-env")
    if [ -n "$result" ]; then
        echo "Environment file permissions: $result"
    else
        echo "Failed to verify permissions for ~/.loon-e-env" >&2
    fi
    echo "Environment variables written to ~/.loon-e-env"
}

# Checks whether an existing installation marker is present.
# Version: 2.0.0
# Returns
# 0: if install state check completes successfully
check_existing_install() {
    VERSION_MARKER_FILE="$INSTALLATION_SHARE_DIR/.loon-env-version"
    PREVIOUS_VERSION=""

    if [ -f "$VERSION_MARKER_FILE" ]; then
        PREVIOUS_VERSION="$(tr -d '[:space:]' < "$VERSION_MARKER_FILE")"
        if [ "$PREVIOUS_VERSION" = "$VERSION" ]; then
            echo "$APP_NAME version $VERSION is already installed. Re-applying idempotent install."
        else
            echo "Existing $APP_NAME installation detected (version: ${PREVIOUS_VERSION:-unknown}). Updating to $VERSION."
        fi
    else
        echo "No existing version marker found. Proceeding with fresh install."
    fi
}

# Writes the current installer version marker to the share directory.
# Version: 2.0.0
# Returns
# 0: if version marker is written successfully
write_version_marker() {
    local marker_file="$INSTALLATION_SHARE_DIR/.loon-env-version"
    echo "$VERSION" | sudo tee "$marker_file" > /dev/null
    sudo chmod 664 "$marker_file"
    echo "Version marker written to $marker_file"
}

# Upserts managed shell hook blocks in bash init/logout files.
# Version: 2.0.0
# Returns
# 0: if shell hooks are updated successfully
update_shell_hooks() {
    local bashrc_file="$HOME/.bashrc"
    local bash_logout_file="$HOME/.bash_logout"
    local bashrc_block bashrc_block

    bashrc_block="# Loon-E environment initialization
if [ -f \"\$HOME/.loon-e-env\" ]; then
    source \"\$HOME/.loon-e-env\"
fi"
    upsert_managed_block "$bashrc_file" "$BASHRC_BLOCK_START" "$BASHRC_BLOCK_END" "$bashrc_block"
    echo "Updated ~/.bashrc managed block for Loon-E environment and login logging."

}

# Applies group ownership and permissions to installed resources.
# Version: 2.0.0
# Returns
# 0: if group permissions are configured successfully
ensure_group_permissions() {
    local target

    echo "Ensuring '$GROUP_NAME' has access to installed files and directories..."

    for target in "$INSTALLATION_SHARE_DIR" "$INSTALLATION_CACHE_DIR"; do
        [ -e "$target" ] || continue
        sudo chgrp -R "$GROUP_NAME" "$target"
        sudo chmod -R g+rwX "$target"
        # setgid keeps new files/dirs in these paths under the installer group
        sudo find "$target" -type d -exec chmod g+s {} +
    done

    echo "Group permissions configured."
}

# Prints a short post-install summary.
# Version: 2.0.0
# Returns
# 0: if summary is printed successfully
print_summary() {
    cat <<EOF
Installation complete.
Scripts copied to: $INSTALLATION_BIN_DIR
Application assets copied to: $INSTALLATION_SHARE_DIR
Cache path set to: $CACHE_DIR
EOF
}

temporary_xhost_permissions() {
    # Grant temporary X11 permissions for the current user to allow GUI applications in the container to connect to the host's X server
    xhost +local:root
    xhost +local:docker
}

perminent_xhost_permissions() {
    # Grant permanent X11 permissions for the current user to allow GUI applications in the container to connect to the host's X server
    local xhost_entry="local:root"
    if ! xhost | grep -q "$xhost_entry"; then
        xhost +local:root
    fi
    xhost +local:docker
}

select_interface() {
    local interfaces
    local interface
    local selection

    mapfile -t interfaces < <(ip link show | grep '^[0-9]' | awk '{print $2}' | sed 's/:$//')
    if [ ${#interfaces[@]} -eq 0 ]; then
        echo "No network interfaces found." >&2
        return 1
    fi

    echo "Available network interfaces:" >&2
    PS3="Select interface: "
    select interface in "${interfaces[@]}"; do
        if [ -n "$interface" ]; then
            selection="$interface"
            break
        else
            echo "Invalid selection. Please try again." >&2
        fi
    done >&2

    printf '%s' "$selection"
}

# Sets MTU temporarily for the current session (reverts after reboot)
temporary_mtu() {
    local interface
    local mtu="${2:-9000}"
    
    interface=$(select_interface) || exit 1
    
    echo "Setting temporary MTU to $mtu on $interface..."
    
    # Check if interface exists
    if ! ip link show "$interface" > /dev/null 2>&1; then
        echo "Error: Interface '$interface' not found" >&2
        echo "Available interfaces:" >&2
        ip link show | grep '^[0-9]' | awk '{print "  " $2}' >&2
        return 1
    fi
    
    # Set the MTU
    if sudo ip link set dev "$interface" mtu "$mtu"; then
        echo "MTU set to $mtu on $interface"
        
        # Verify the change
        local actual_mtu=$(ip link show "$interface" | grep -oP '(?<=mtu )\d+')
        if [ "$actual_mtu" = "$mtu" ]; then
            echo "Verification successful: MTU is now $mtu"
            echo "Note: This setting will revert after a reboot. Use permanent_mtu() to make it persistent."
            return 0
        else
            echo "Error: MTU verification failed. Expected $mtu but got $actual_mtu" >&2
            return 1
        fi
    else
        echo "Error: Failed to set MTU on $interface" >&2
        return 1
    fi
}

# Sets MTU permanently using Netplan configuration
permanent_mtu() {
    local interface
    local mtu="${2:-9000}"
    local netplan_dir="/etc/netplan"
    local config_file=""
    
    interface=$(select_interface) || exit 1
    
    echo "Setting permanent MTU to $mtu on $interface via Netplan..."
    
    # Check if netplan is installed
    if ! command -v netplan &> /dev/null; then
        echo "Netplan not found. Installing netplan.io..." >&2
        sudo apt-get update && sudo apt-get install -y netplan.io
    fi
    
    # Check if interface exists
    if ! ip link show "$interface" > /dev/null 2>&1; then
        echo "Error: Interface '$interface' not found" >&2
        echo "Available interfaces:" >&2
        ip link show | grep '^[0-9]' | awk '{print "  " $2}' >&2
        return 1
    fi
    
    # Find or create the Netplan config file
    if [ -d "$netplan_dir" ]; then
        # Look for existing config file
        config_file=$(sudo find "$netplan_dir" -maxdepth 1 -name "*.yaml" -o -name "*.yml" | head -1)
        
        if [ -z "$config_file" ]; then
            # Create a new config file if none exists
            config_file="$netplan_dir/60-loon-env-mtu.yaml"
            echo "Creating new Netplan config file: $config_file"
            sudo tee "$config_file" > /dev/null <<EOF
network:
  version: 2
  ethernets:
    $interface:
      dhcp4: true
      mtu: $mtu
EOF
        else
            echo "Using existing Netplan config: $config_file"
            
            # Back up the original file
            sudo cp "$config_file" "$config_file.backup.$(date +%Y%m%d_%H%M%S)"
            echo "Backup created: $config_file.backup.*"
            
            # Add or modify the MTU setting
            # This is a simple approach using sed; more complex configs may need special handling
            if grep -q "^ *$interface:" "$config_file"; then
                # Interface section exists, add mtu if not present
                if ! grep -A 5 "^ *$interface:" "$config_file" | grep -q "mtu:"; then
                    sudo sed -i "/^ *$interface:/a\\      mtu: $mtu" "$config_file"
                else
                    # Replace existing MTU value
                    sudo sed -i "/^ *$interface:/,/^[^ ]/ s/mtu: [0-9]*/mtu: $mtu/" "$config_file"
                fi
            else
                # No interface section, add it
                sudo tee -a "$config_file" > /dev/null <<EOF

  ethernets:
    $interface:
      dhcp4: true
      mtu: $mtu
EOF
            fi
        fi
    else
        echo "Error: Netplan directory not found at $netplan_dir" >&2
        return 1
    fi
    
    # Verify the config is valid YAML
    echo "Validating Netplan configuration..."
    if sudo netplan validate > /dev/null 2>&1; then
        echo "Configuration validation passed"
    else
        echo "Error: Netplan configuration validation failed" >&2
        echo "Restoring backup..." >&2
        if [ -n "$config_file" ] && sudo test -f "$config_file.backup".*; then
            sudo cp "$config_file.backup".* "$config_file"
        fi
        return 1
    fi
    
    # Apply the configuration
    echo "Applying Netplan configuration..."
    if sudo netplan apply; then
        echo "Configuration applied successfully"
        
        # Verify the change
        sleep 1
        local actual_mtu=$(ip link show "$interface" | grep -oP '(?<=mtu )\d+')
        if [ "$actual_mtu" = "$mtu" ]; then
            echo "Verification successful: MTU is now $mtu"
            echo "This setting will persist after reboot."
            return 0
        else
            echo "Warning: MTU verification shows $actual_mtu instead of $mtu" >&2
            echo "This may be normal if the interface is still reconfiguring." >&2
        fi
    else
        echo "Error: Failed to apply Netplan configuration" >&2
        return 1
    fi
}
# ------------------ MAIN ------------------

# Main function to orchestrate the installation steps
# Parameters:
#   $1 (optional): whether to update shell hooks (default: true)
# Orchestrates full installation flow in a deterministic order.
# Version: 2.0.0
# Parameters:
#     $1 (optional): whether to update shell hooks (default: true)
# Returns
# 0: if installation flow completes successfully
main() {
    local update_shell_hooks="${1:-true}"
    local perminent_xhost="${2:-false}"
    local perminent_mtu="${3:-false}"
    require_root
    setup_zedx
    setup_user_group
    setup_directories
    check_existing_install
    install_scripts
    copy_assets
    configure_cache_directory
    write_environment_file
    if [ "$perminent_xhost" = true ]; then
        perminent_xhost_permissions
    else
        temporary_xhost_permissions
    fi
    if [ "$perminent_mtu" = true ]; then
        perminent_mtu
    else 
        temporary_mtu
    fi
    if [ "$update_shell_hooks" = true ]; then
        update_shell_hooks
    fi
    ensure_group_permissions
    print_summary
}

# Parses CLI options/arguments and dispatches installation mode.
# Version: 2.0.0
# Parameters:
#     $1 (optional): first CLI argument token (default: empty)
# Returns
# 0: if argument parsing and selected action complete successfully
parse_arguments() {
    case "${1:-}" in
        -h|--help)
            handle_help
            ;;
        --sync-delete-assets)
            ASSET_SYNC_DELETE="true"
            shift
            parse_arguments "$@"
            ;;
        -t|--test)
            INSTALLATION_BIN_DIR="./test-bin"
            INSTALLATION_SHARE_DIR="./test-share"
            INSTALLATION_CACHE_DIR="./test-cache"
            main false
            echo "Test installation complete. Check the test-bin, test-share, and test-cache directories"
            ;;
        -p | --perminent)
            main true true true
            echo "Installation complete with permanent X11 permissions and MTU settings. Please log out and log back in for group changes to take effect."
            ;;
        "")
            INSTALLATION_BIN_DIR="$DEFAULT_INSTALL_BIN_DIR"
            INSTALLATION_SHARE_DIR="$DEFAULT_INSTALL_SHARE_DIR"
            INSTALLATION_CACHE_DIR="$DEFAULT_CACHE_DIR"
            main
            ;;
        -* )
            echo "Unknown option: $1" >&2
            echo "Use -h or --help for usage information." >&2
            exit 1
            ;;
        *)
            INSTALLATION_BIN_DIR="$1"
            INSTALLATION_SHARE_DIR="${2:-$DEFAULT_INSTALL_SHARE_DIR}"
            INSTALLATION_CACHE_DIR="${3:-$DEFAULT_CACHE_DIR}"
            main
            ;;
    esac
}

parse_arguments "$@"