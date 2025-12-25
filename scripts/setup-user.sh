#!/bin/bash
# ──────────────────────────────────────────────────────────────────────────────
#  PROJECT CORTEX: USER HYDRATION
# ──────────────────────────────────────────────────────────────────────────────
# Usage: bash scripts/setup-user.sh

set -e
echo "💧 Hydrating User Space..."

# 1. FLATHUB & APPS
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

# Define path to list (Assumes script runs from repo root)
FLATPAK_LIST="config/flatpaks.txt"

if [ -f "$FLATPAK_LIST" ]; then
    echo "📦 Installing Flatpaks from config..."
    # Read file, strip comments, install
    APPS=$(grep -vE '^\s*#|^\s*$' "$FLATPAK_LIST" | tr '\n' ' ')
    flatpak install -y flathub $APPS
else
    echo "⚠️  Warning: $FLATPAK_LIST not found. Skipping Flatpaks."
fi

# 2. HOMEBREW
if [ ! -d "/home/linuxbrew/.linuxbrew" ]; then
    echo "🍺 Installing Homebrew..."
    CI=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    mkdir -p ~/.config/fish
    echo 'eval (/home/linuxbrew/.linuxbrew/bin/brew shellenv)' >> ~/.config/fish/config.fish
fi

# 3. DISTROBOX
if [ -f "config/distrobox.ini" ]; then
    echo "📦 Assembling Distroboxes..."
    if command -v distrobox &> /dev/null; then
        distrobox assemble create --file config/distrobox.ini
    else
        echo "⚠️  Distrobox not found on host. Skipping."
    fi
fi

echo "✨ User Space Ready."
