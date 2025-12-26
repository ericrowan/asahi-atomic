#!/bin/bash
set -ouex pipefail

echo "📦 Installing System Packages..."

# 1. Decrapify
rpm-ostree override remove \
    firefox firefox-langpacks \
    gnome-tour \
    gnome-software-rpm-ostree \
    yelp \
    gnome-user-docs

# 2. Install Core Tools (Clean Array Method)
PKG_FILE="/tmp/config/packages.txt"

if [ -f "$PKG_FILE" ]; then
    # Read file directly into array (assumes clean list)
    mapfile -t PACKAGES < "$PKG_FILE"

    if [ ${#PACKAGES[@]} -gt 0 ]; then
        echo "Installing ${#PACKAGES[@]} packages..."
        rpm-ostree install "${PACKAGES[@]}"
    else
        echo "⚠️  No packages found in list."
    fi
else
    echo "❌ Error: packages.txt not found."
    exit 1
fi

# 3. Install Starship (Manual Binary)
curl -sS https://starship.rs/install.sh | sh -s -- -y -b /usr/bin

# 4. Install Gum (Manual Binary)
GUM_VERSION="0.13.0"
GUM_URL="https://github.com/charmbracelet/gum/releases/download/v${GUM_VERSION}/gum_${GUM_VERSION}_linux_arm64.tar.gz"

cd /tmp
curl -L -o gum.tar.gz "$GUM_URL"
tar -xf gum.tar.gz
find . -type f -name "gum" -exec mv {} /usr/bin/gum \;
chmod +x /usr/bin/gum
rm -rf gum.tar.gz
