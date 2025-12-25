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

# 2. Install Core Tools (Resilient Array Method)
# We read the config file into a Bash Array to satisfy ShellCheck SC2086
PKG_FILE="/tmp/config/packages.txt"

if [ -f "$PKG_FILE" ]; then
    # Read non-comment lines into the PACKAGES array
    mapfile -t PACKAGES < <(grep -vE '^\s*#|^\s*$' "$PKG_FILE")

    if [ ${#PACKAGES[@]} -gt 0 ]; then
        echo "Installing ${#PACKAGES[@]} packages..."
        # Quoting the array expands to individual arguments safely
        rpm-ostree install "${PACKAGES[@]}"
    else
        echo "⚠️ No packages found in list."
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
