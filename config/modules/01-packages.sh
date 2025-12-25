#!/bin/bash
set -ouex pipefail

echo "📦 Processing System Packages..."

# 1. Decrapify
rpm-ostree override remove \
    firefox firefox-langpacks \
    gnome-tour \
    gnome-software-rpm-ostree \
    yelp \
    gnome-user-docs

# 2. Resilient Package Installer
# Reads config/packages.txt, checks availability, installs valid ones.
PKG_FILE="/tmp/config/packages.txt"
LOG_FILE="/tmp/skipped-packages.log"
INSTALL_LIST=""

if [ -f "$PKG_FILE" ]; then
    # Read file, strip comments/empty lines
    CANDIDATES=$(grep -vE '^\s*#|^\s*$' "$PKG_FILE")

    echo "🔍 Verifying package availability..."

    for pkg in $CANDIDATES; do
        # Use dnf repoquery to check if package exists in enabled repos
        if dnf repoquery --quiet --available "$pkg" &>/dev/null; then
            INSTALL_LIST="$INSTALL_LIST $pkg"
        else
            echo "⚠️  Skipping missing package: $pkg"
            echo "$pkg" >> "$LOG_FILE"
        fi
    done

    # Install the valid list
    if [ -n "$INSTALL_LIST" ]; then
        echo "⬇️  Installing verified packages..."
        rpm-ostree install $INSTALL_LIST
    else
        echo "⚠️  No valid packages found to install."
    fi

    # Dump log to build output if it exists
    if [ -f "$LOG_FILE" ]; then
        echo "--- SKIPPED PACKAGES ---"
        cat "$LOG_FILE"
        echo "------------------------"
        # Optional: Copy log to persistent location if needed
    fi
else
    echo "❌ Error: packages.txt not found."
    exit 1
fi

# 3. Manual Binary Installs
# Starship
curl -sS https://starship.rs/install.sh | sh -s -- -y -b /usr/bin

# Gum
GUM_VERSION="0.13.0"
GUM_URL="https://github.com/charmbracelet/gum/releases/download/v${GUM_VERSION}/gum_${GUM_VERSION}_linux_arm64.tar.gz"
cd /tmp
curl -L -o gum.tar.gz "$GUM_URL"
tar -xf gum.tar.gz
find . -type f -name "gum" -exec mv {} /usr/bin/gum \;
chmod +x /usr/bin/gum
rm -rf gum.tar.gz
