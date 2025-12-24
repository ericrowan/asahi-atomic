#!/bin/bash
set -ouex pipefail

echo "📦 Installing System Packages..."

# --- VARIABLES ---
GUM_VERSION="0.13.0"
GUM_URL="https://github.com/charmbracelet/gum/releases/download/v${GUM_VERSION}/gum_${GUM_VERSION}_linux_arm64.tar.gz"

# 1. Decrapify (Remove stock bloat)
rpm-ostree override remove \
    firefox firefox-langpacks \
    gnome-tour \
    gnome-software-rpm-ostree \
    yelp \
    gnome-user-docs

# 2. Install Core Tools (System Layers)
rpm-ostree install \
    fish \
    just \
    distrobox \
    tailscale \
    gnome-tweaks \
    sushi \
    btop \
    htop \
    fastfetch \
    git \
    neovim \
    openssl \
    cifs-utils \
    nfs-utils

# 3. Install Starship (Shell Prompt)
# Using official script for architecture detection
curl -sS https://starship.rs/install.sh | sh -s -- -y -b /usr/bin

# 4. Install Gum (TUI Builder)
echo "🍬 Installing Gum v${GUM_VERSION}..."
cd /tmp
curl -L -o gum.tar.gz "$GUM_URL"
tar -xf gum.tar.gz

# Find the 'gum' binary anywhere in the extracted files and move it
find . -type f -name "gum" -exec mv {} /usr/bin/gum \;
chmod +x /usr/bin/gum

# Cleanup
rm -rf gum.tar.gz *gum*
