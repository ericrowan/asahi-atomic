#!/bin/bash
set -ouex pipefail

echo "📦 Installing System Packages..."

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
curl -sS https://starship.rs/install.sh | sh -s -- -y -b /usr/bin

# 4. Install Gum (The TUI Builder) - ARM64 Manual Install
# We fetch the binary directly to avoid repo missing errors
echo "🍬 Installing Gum..."
GUM_VERSION="0.13.0"
curl -sL "https://github.com/charmbracelet/gum/releases/download/v${GUM_VERSION}/gum_${GUM_VERSION}_linux_arm64.tar.gz" | tar xz -C /usr/bin --strip-components=1 "gum_${GUM_VERSION}_linux_arm64/gum"
chmod +x /usr/bin/gum
