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
# Usage: sudo ./install.bash [INSTALL_BIN_DIR] [INSTALL_SHARE_DIR] [INSTALL_CACHE_DIR]
# Arguments:
# INSTALL_BIN_DIR     Directory to install executable scripts (default: /usr/local/bin)
# INSTALL_SHARE_DIR   Directory to install shared assets (default: /usr/share/loon-env)
# INSTALL_CACHE_DIR   Directory to use for cache and logs (default: /var/cache/loon-env)

set -euo pipefail

# ------------------- CONSTANTS ------------------
APP_NAME="Loon-Env"
VERSION="2.0.2"
GROUP_NAME="loon-env-users"

# Default installation paths (can be overridden by command-line arguments)
DEFAULT_INSTALL_BIN_DIR="/usr/local/bin"
DEFAULT_INSTALL_SHARE_DIR="/usr/share/$APP_NAME"
DEFAULT_CACHE_DIR="/var/cache/$APP_NAME"

# Where source scripts are located
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ------------------ FUNCTIONS ------------------

# ------------------ COMMON UTILITY FUNCTIONS -------------------

handle_help() {
    cat <<'EOF'
Usage: sudo ./install.bash [INSTALL_BIN_DIR] [INSTALL_SHARE_DIR] [INSTALL_CACHE_DIR]
Installs the Loon-Env scripts and assets, and configures the logging environment.
Arguments:
INSTALL_BIN_DIR     Directory to install executable scripts (default: /usr/local/bin)
INSTALL_SHARE_DIR   Directory to install shared assets (default: /usr/share/loon-env)
INSTALL_CACHE_DIR   Directory to use for cache and logs (default: /var/cache/loon-env)
EOF
    exit 0
}

require_root() {
    if [ "$EUID" -ne 0 ]; then
        echo "This installer must be run as root. Use sudo ./install.bash" >&2
        exit 1
    fi
}

# ------------------ INSTALLATION FUNCTIONS ------------------

# Checks for $GROUP_NAME and creates it if it doesn't exist, then adds the current user to the group
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
setup_directories() {
    echo "Setting up directories..."
    sudo mkdir -p "$INSTALLATION_BIN_DIR"
    sudo mkdir -p "$INSTALLATION_SHARE_DIR"
    sudo mkdir -p "$INSTALLATION_CACHE_DIR"
    echo "Directories set up successfully."
}

# Installs the Loon-Env scripts to the specified bin directory
install_scripts() {
    local script src_file

    echo "Installing Loon-Env..."
    for script in "LoonE" "LoonLog"; do
        src_file="$ROOT_DIR/src/$script"
        if [ -f "$src_file" ]; then
            sudo cp "$src_file" "$INSTALLATION_BIN_DIR/$script"
            sudo chmod 755 "$INSTALLATION_BIN_DIR/$script"
        else
            echo "Warning: $script not found at $src_file" >&2
        fi
    done
    echo "Scripts copied to $INSTALLATION_BIN_DIR"
}

# Copies the asset files to the specified share directory
copy_assets() {
    echo "Copying assets..."
    if [ -d "$ROOT_DIR/src/assets" ]; then
        sudo cp -r "$ROOT_DIR/src/assets"/* "$INSTALLATION_SHARE_DIR/"
    fi
    echo "Assets copied to $INSTALLATION_SHARE_DIR"
}

configure_cache_directory() {
    if [ -w "/var/cache/$APP_NAME" ] || { sudo mkdir -p "/var/cache/$APP_NAME" && sudo chown "$USER" "/var/cache/$APP_NAME"; }; then
        CACHE_DIR="/var/cache/$APP_NAME"
    else
        CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/$APP_NAME"
    fi

    echo "Cache directory set to $CACHE_DIR"
    mkdir -p "$CACHE_DIR"
    echo "Cache directory created if it did not exist."

    KNOWN_USERS_FILE="$CACHE_DIR/known_users.txt"
    LOG_FILE="$CACHE_DIR/log.txt"
    echo "Known users file: $KNOWN_USERS_FILE"
    echo "Log file: $LOG_FILE"
}

write_environment_file() {
    sudo cat > "$HOME/.loon-e-env" <<EOF
export KNOWN_USERS_FILE="$KNOWN_USERS_FILE"
export LOG_FILE="$LOG_FILE"
EOF
    echo "Environment variables written to ~/.loon-e-env"
}

update_shell_hooks() {
    if [ -f "$HOME/.bashrc" ] && ! grep -q "source \$HOME/.loon-e-env" "$HOME/.bashrc" 2>/dev/null; then
        sudo cat >> "$HOME/.bashrc" <<'EOF'
# Loon-E logger environment
if [ -f "$HOME/.loon-e-env" ]; then
    source "$HOME/.loon-e-env"
fi
LoonLog -i
EOF
    fi
    echo "Updated ~/.bashrc to source Loon-E environment and initialize logging."

    if [ -f "$HOME/.bash_logout" ] && ! grep -q "LoonLog -o" "$HOME/.bash_logout" 2>/dev/null; then
        echo "LoonLog -o" | sudo tee -a "$HOME/.bash_logout" > /dev/null
    fi
    echo "Updated ~/.bash_logout to log user logout with LoonLog."
}

ensure_log_files() {
    sudo mkdir -p "$(dirname "$KNOWN_USERS_FILE")"
    sudo mkdir -p "$(dirname "$LOG_FILE")"
    sudo touch "$KNOWN_USERS_FILE" "$LOG_FILE"
    sudo chmod 770 "$KNOWN_USERS_FILE" "$LOG_FILE" || true
    echo "Log files created and permissions set."
}

print_summary() {
    cat <<EOF
Installation complete.
Scripts copied to: $INSTALLATION_BIN_DIR
Application assets copied to: $INSTALLATION_SHARE_DIR
Cache path set to: $CACHE_DIR
EOF
}

# ------------------ MAIN ------------------

# Main function to orchestrate the installation steps
# Parameters:
#   $1 (optional): whether to update shell hooks (default: true)
main() {
    local update_shell_hooks="${1:-true}"
    require_root
    setup_user_group
    setup_directories
    install_scripts
    copy_assets
    configure_cache_directory
    write_environment_file
    if [ "$update_shell_hooks" = true ]; then
        update_shell_hooks
    fi
    ensure_log_files
    print_summary
}

parse_arguments() {
    case "${1:-}" in
        -h|--help)
            handle_help
            ;;
        -t|--test)
            INSTALLATION_BIN_DIR="./test-bin"
            INSTALLATION_SHARE_DIR="./test-share"
            INSTALLATION_CACHE_DIR="./test-cache"
            main false
            echo "Test installation complete. Check the test-bin, test-share, and test-cache directories"
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