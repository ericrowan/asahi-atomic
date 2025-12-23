#!/bin/bash
# ──────────────────────────────────────────────────────────────────────────────
#  PROJECT CORTEX: USER HYDRATION
# ──────────────────────────────────────────────────────────────────────────────
# Usage: Run once after installing the OS to set up your /home folder.

set -e
echo "💧 Hydrating User Space..."

# 1. FLATHUB (Applications)
# We use a declarative list. If you want to change apps, edit this list.
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

APPS=(
    "com.github.tchx84.Flatseal"
    "com.mattjakeman.ExtensionManager"
    "org.gnome.World.PikaBackup"
    "dev.zed.Zed"
    "org.mozilla.firefox"
    "org.signal.Signal"
    "com.bitwig.BitwigStudio"
    "com.valvesoftware.Steam"
    "io.github.flattool.Warehouse" # (Bazaar replacement)
)

echo "📦 Installing Flatpaks..."
flatpak install -y flathub "${APPS[@]}"

# 2. HOMEBREW (The Package Manager for /home)
if [ ! -d "/home/linuxbrew/.linuxbrew" ]; then
    echo "🍺 Installing Homebrew..."
    CI=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Configure Fish path
    mkdir -p ~/.config/fish
    echo 'eval (/home/linuxbrew/.linuxbrew/bin/brew shellenv)' >> ~/.config/fish/config.fish
fi

# 3. DISTROBOX (The Dev Container)
# We use the declarative config file we created earlier!
if [ -f "config/distrobox.ini" ]; then
    echo "📦 Assembling Distroboxes..."
    distrobox assemble create --file config/distrobox.ini
fi

echo "✨ User Space Ready."
