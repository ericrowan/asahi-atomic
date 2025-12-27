#!/bin/bash
# ──────────────────────────────────────────────────────────────────────────────
#  PROJECT CORTEX: USER HYDRATION
# ──────────────────────────────────────────────────────────────────────────────
set -e
echo "💧 Hydrating User Space..."

# Define System Paths (Absolute)
CONFIG_DIR="/usr/share/asahi-atomic"
FLATPAK_LIST="$CONFIG_DIR/flatpaks.txt"
DISTROBOX_INI="$CONFIG_DIR/distrobox.ini"

# 1. PREPARE HOMEBREW
# We split creation and ownership to ensure permissions are always fixed.
echo "🍺 Checking Homebrew Prerequisites..."

# Ensure the directory structure exists
if [ ! -d "/var/home/linuxbrew/.linuxbrew" ]; then
    echo "   Creating directory..."
    sudo mkdir -p /var/home/linuxbrew/.linuxbrew
fi

# Symlink /home/linuxbrew -> /var/home/linuxbrew (Silverblue Requirement)
if [ ! -L "/home/linuxbrew" ]; then
    echo "   Linking /home/linuxbrew..."
    sudo ln -sf /var/home/linuxbrew /home/linuxbrew
fi

# ALWAYS fix ownership to the current user (Fixes the "Insufficient permissions" error)
echo "   Fixing permissions..."
sudo chown -R "$(whoami):$(whoami)" /var/home/linuxbrew

# Install Brew if binary is missing
if [ ! -f "/home/linuxbrew/.linuxbrew/bin/brew" ]; then
    echo "   Running Installer..."
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Configure Fish path
    mkdir -p ~/.config/fish
    echo 'eval (/home/linuxbrew/.linuxbrew/bin/brew shellenv)' >> ~/.config/fish/config.fish
else
    echo "✅ Homebrew already installed."
fi

# 2. FLATHUB & APPS
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

if [ -f "$FLATPAK_LIST" ]; then
    echo "📦 Installing Flatpaks from $FLATPAK_LIST..."
    mapfile -t APPS < <(grep -vE '^\s*#|^\s*$' "$FLATPAK_LIST")

    if [ ${#APPS[@]} -gt 0 ]; then
        flatpak install -y flathub "${APPS[@]}"
    fi
else
    echo "⚠️  Warning: Config file not found at $FLATPAK_LIST"
fi

# 3. DISTROBOX
if [ -f "$DISTROBOX_INI" ]; then
    echo "📦 Assembling Distroboxes from $DISTROBOX_INI..."
    if command -v distrobox &> /dev/null; then
        distrobox assemble create --file "$DISTROBOX_INI"
    fi
fi

echo "✨ User Space Ready."
