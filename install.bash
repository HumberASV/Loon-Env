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

# install.bash
# Standard installer for Ubuntu: deploys Loon-Env script files and data resources and configures logging environment.

set -euo pipefail

# Require root privileges
if [ "$EUID" -ne 0 ]; then
    echo "This installer must be run as root. Use sudo ./install.bash" >&2
    exit 1
fi

# ------------------- CONSTANTS ------------------
APP_NAME="loon-env"
INSTALL_BIN_DIR="/usr/local/bin"
INSTALL_SHARE_DIR="/usr/share/$APP_NAME"
CACHE_DIR="/var/cache/$APP_NAME"

# Where source scripts are located
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ------------------- Directory Setup ------------------

echo "Setting up directories..."
# Ensure directories exist
sudo mkdir -p "$INSTALL_BIN_DIR"
sudo mkdir -p "$INSTALL_SHARE_DIR"
sudo mkdir -p "$CACHE_DIR"

# ------------------- Installation ------------------
echo "Installing Loon-Env..."
# Copy specific Loon-Env core scripts from source folder
for script in "LoonE" "LoonLog"; do
    src_file="$ROOT_DIR/src/$script"
    if [ -f "$src_file" ]; then
        sudo cp "$src_file" "$INSTALL_BIN_DIR/$script"
        sudo chmod 755 "$INSTALL_BIN_DIR/$script"
    else
        echo "Warning: $script not found at $src_file" >&2
    fi
done
echo "Scripts copied to $INSTALL_BIN_DIR"

echo "Copying assets..."
# Copy any static assets or content if exists
if [ -d "$ROOT_DIR/src/assets" ]; then
    sudo cp -r "$ROOT_DIR/src/assets"/* "$INSTALL_SHARE_DIR/"
fi
echo "Assets copied to $INSTALL_SHARE_DIR"

# Determine cache path for known users and logs
if [ -w "/var/cache/$APP_NAME" ] || sudo mkdir -p "/var/cache/$APP_NAME" && sudo chown "$USER" "/var/cache/$APP_NAME"; then
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

# Persist environment to ~/.loon-e-env for login scripts
cat > "$HOME/.loon-e-env" <<EOF
KNOWN_USERS_FILE="$KNOWN_USERS_FILE"
LOG_FILE="$LOG_FILE"
EOF
echo "Environment variables written to ~/.loon-e-env"

# Ensure hooks in bashrc and bash_logout
if [ -f "$HOME/.bashrc" ] && ! grep -q "source \$HOME/.loon-e-env" "$HOME/.bashrc" 2>/dev/null; then
    cat >> "$HOME/.bashrc" <<'EOF'
# Loon-E logger environment
if [ -f "$HOME/.loon-e-env" ]; then
    source "$HOME/.loon-e-env"
fi
LoonLog -i
EOF
fi
echo "Updated ~/.bashrc to source Loon-E environment and initialize logging."

if [ -f "$HOME/.bash_logout" ] && ! grep -q "LoonLog -o" 2>/dev/null; then
    cat >> "$HOME/.bash_logout" <<'EOF'
LoonLog -o
EOF
fi
echo "Updated ~/.bash_logout to log user logout with LoonLog."

# Ensure log files exist
mkdir -p "$(dirname "$KNOWN_USERS_FILE")"
mkdir -p "$(dirname "$LOG_FILE")"
touch "$KNOWN_USERS_FILE" "$LOG_FILE"
chmod 660 "$KNOWN_USERS_FILE" "$LOG_FILE" || true
echo "Log files created and permissions set."

cat <<EOF
Installation complete.
Scripts copied to: $INSTALL_BIN_DIR
Application assets copied to: $INSTALL_SHARE_DIR
Cache path set to: $CACHE_DIR
EOF