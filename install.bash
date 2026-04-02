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

# ------------------- CONSTANTS ------------------
APP_NAME="loon-env"
INSTALL_BIN_DIR="/usr/local/bin"
INSTALL_SHARE_DIR="/usr/share/$APP_NAME"
CACHE_DIR="/var/cache/$APP_NAME"

# Where source scripts are located (assumes this script is in scripts/)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# ------------------- Directory Setup ------------------

# Ensure directories exist
sudo mkdir -p "$INSTALL_BIN_DIR"
sudo mkdir -p "$INSTALL_SHARE_DIR"
sudo mkdir -p "$CACHE_DIR"

# ------------------- Installation ------------------

# Copy executables and scripts from source folder
for f in "$ROOT_DIR/src"/*.sh "$ROOT_DIR/src"/*; do
    if [ -f "$f" ]; then
        sudo cp "$f" "$INSTALL_BIN_DIR/"
        sudo chmod 755 "$INSTALL_BIN_DIR/$(basename "$f")"
    fi
done

# Copy any static assets or content if exists
if [ -d "$ROOT_DIR/src/assets" ]; then
    sudo cp -r "$ROOT_DIR/src/assets"/* "$INSTALL_SHARE_DIR/"
fi

# Determine cache path for known users and logs
if [ -w "/var/cache/$APP_NAME" ] || sudo mkdir -p "/var/cache/$APP_NAME" && sudo chown "$USER" "/var/cache/$APP_NAME"; then
    CACHE_DIR="/var/cache/$APP_NAME"
else
    CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/$APP_NAME"
fi

mkdir -p "$CACHE_DIR"

KNOWN_USERS_FILE="$CACHE_DIR/known_users.txt"
LOG_FILE="$CACHE_DIR/log.txt"

# Persist environment to ~/.loon-e-env for login scripts
cat > "$HOME/.loon-e-env" <<EOF
KNOWN_USERS_FILE="$KNOWN_USERS_FILE"
LOG_FILE="$LOG_FILE"
EOF

# Ensure hooks in bashrc and bash_logout
if [ -f "$HOME/.bashrc" ] && ! grep -q "source \$HOME/.loon-e-env" "$HOME/.bashrc" 2>/dev/null; then
    cat >> "$HOME/.bashrc" <<'EOF'
# Loon-E logger environment
if [ -f "$HOME/.loon-e-env" ]; then
    source "$HOME/.loon-e-env"
fi
EOF
fi

if [ -f "$HOME/.bash_logout" ] && ! grep -q "source \$HOME/.loon-e-env" "$HOME/.bash_logout" 2>/dev/null; then
    cat >> "$HOME/.bash_logout" <<'EOF'
# Loon-E logger environment
if [ -f "$HOME/.loon-e-env" ]; then
    source "$HOME/.loon-e-env"
fi
EOF
fi

# Ensure log files exist
mkdir -p "$(dirname "$KNOWN_USERS_FILE")"
mkdir -p "$(dirname "$LOG_FILE")"
touch "$KNOWN_USERS_FILE" "$LOG_FILE"
chmod 660 "$KNOWN_USERS_FILE" "$LOG_FILE" || true

# optional: create wrapper for setup in /usr/local/bin
cat > /tmp/loon-env-setup-wrapped.sh <<'EOF'
#!/bin/bash
"/usr/local/bin/setup.bash"
EOF
sudo mv /tmp/loon-env-setup-wrapped.sh /usr/local/bin/loon-env-setup
sudo chmod 755 /usr/local/bin/loon-env-setup

cat <<EOF
Installation complete.
Scripts copied to: $INSTALL_BIN_DIR
Application assets copied to: $INSTALL_SHARE_DIR
Cache path set to: $CACHE_DIR
Run 'loon-env-setup' to reconfigure, or source ~/.bashrc and open a new shell.
EOF
