#!/bin/bash
# ──────────────────────────────────────────────────────────────────────────────
#  PROJECT CORTEX: USER HYDRATION
# ──────────────────────────────────────────────────────────────────────────────
set -ex
echo "💧 Hydrating User Space..."

CONFIG_DIR="/usr/share/asahi-atomic"

# 1. PREPARE HOMEBREW
# We create the directory as root, then give it to the user.
if [ ! -d "/home/linuxbrew/.linuxbrew" ]; then
    echo "🍺 Preparing Homebrew Directory..."

    # Create directory (requires sudo)
    sudo mkdir -p /var/home/linuxbrew/.linuxbrew

    # Fix ownership
    sudo chown -R "$(whoami):$(whoami)" /var/home/linuxbrew/.linuxbrew

    # Symlink if needed (Standard on Silverblue)
    if [ ! -L "/home/linuxbrew" ]; then
        sudo ln -sf /var/home/linuxbrew /home/linuxbrew
    fi

    echo "   Installing Homebrew..."
    # Run installer as user
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Configure Fish
    mkdir -p ~/.config/fish
    echo 'eval (/home/linuxbrew/.linuxbrew/bin/brew shellenv)' >> ~/.config/fish/config.fish
fi

# 2. FLATHUB & APPS
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

# Point to the system-installed list
FLATPAK_LIST="$CONFIG_DIR/flatpaks.txt"

if [ -f "$FLATPAK_LIST" ]; then
    echo "📦 Installing Flatpaks from system config..."
    # Fix: prevent grep failure from exiting the script (return true if no matches)
    mapfile -t APPS < <(grep -vE '^\s*#|^\s*$' "$FLATPAK_LIST" || true)

    if [ ${#APPS[@]} -gt 0 ]; then
        flatpak install -y flathub "${APPS[@]}"
    fi
else
    echo "⚠️  Warning: $FLATPAK_LIST not found. Skipping Flatpaks."
fi

# 3. DISTROBOX
DISTROBOX_INI="$CONFIG_DIR/distrobox.ini"

if [ -f "$DISTROBOX_INI" ]; then
    echo "📦 Assembling Distroboxes..."
    if command -v distrobox &> /dev/null; then
        distrobox assemble create --file "$DISTROBOX_INI"
    fi
fi

echo "✨ User Space Ready."
