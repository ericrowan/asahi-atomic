#!/bin/bash
set -ouex pipefail

echo "📦 Installing System Packages..."

# 1. Decrapify (Only remove the useless stuff)
rpm-ostree override remove \
    firefox firefox-langpacks \
    gnome-tour \
    gnome-software-rpm-ostree \
    yelp

# 2. Install Core Tools (From text file)
PKG_FILE="/tmp/config/packages.txt"
if [ -f "$PKG_FILE" ]; then
    mapfile -t PACKAGES < "$PKG_FILE"
    rpm-ostree install "${PACKAGES[@]}"
fi

# 3. Manual Installs (Starship, Gum)
curl -sS https://starship.rs/install.sh | sh -s -- -y -b /usr/bin

GUM_VERSION="0.13.0"
cd /tmp
curl -L -o gum.tar.gz "https://github.com/charmbracelet/gum/releases/download/v${GUM_VERSION}/gum_${GUM_VERSION}_linux_arm64.tar.gz"
tar -xf gum.tar.gz
find . -type f -name "gum" -exec mv {} /usr/bin/gum \;
chmod +x /usr/bin/gum
rm -rf gum.tar.gz
