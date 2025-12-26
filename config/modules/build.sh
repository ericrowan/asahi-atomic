#!/bin/bash
set -ouex pipefail

echo "🚀 Starting System Build Module..."

# -----------------------------------------------------------------------------
# 1. PACKAGE MANAGEMENT (Single Transaction)
# -----------------------------------------------------------------------------

# Bootloader & Core Tools (Constraint 2)
BOOTLOADER_PKGS=(
    "grub2-efi-aa64"
    "grub2-efi-aa64-modules"
    "grub2-tools"
    "shim-aa64"
    "plymouth-plugin-script"
)

# Read User Packages
USER_PKGS=()
if [ -f "/tmp/config/packages.txt" ]; then
    mapfile -t USER_PKGS < "/tmp/config/packages.txt"
fi

# Packages to Remove
REMOVE_PKGS=(
    "firefox"
    "firefox-langpacks"
    "gnome-tour"
    "gnome-software-rpm-ostree"
    "yelp"
)

echo "📦 Executing rpm-ostree transaction..."
# shellcheck disable=SC2046
rpm-ostree override remove "${REMOVE_PKGS[@]}" \
    $(printf -- "--install=%s " "${BOOTLOADER_PKGS[@]}") \
    $(printf -- "--install=%s " "${USER_PKGS[@]}")

# -----------------------------------------------------------------------------
# 2. MANUAL INSTALLS (Constraint 1)
# -----------------------------------------------------------------------------

echo "✨ Installing Starship..."
curl -sS https://starship.rs/install.sh | sh -s -- -y -b /usr/bin

echo "🍬 Installing Gum..."
GUM_VERSION="0.13.0"
curl -L -o /tmp/gum.tar.gz "https://github.com/charmbracelet/gum/releases/download/v${GUM_VERSION}/gum_${GUM_VERSION}_linux_arm64.tar.gz"
tar -xf /tmp/gum.tar.gz -C /tmp
mv /tmp/gum /usr/bin/gum
chmod +x /usr/bin/gum

# -----------------------------------------------------------------------------
# 3. SYSTEM TWEAKS & CONFIGURATION
# -----------------------------------------------------------------------------

echo "⚙️  Applying System Tweaks..."

# Enable Services
systemctl enable tailscaled
systemctl enable podman.socket

# Shell Setup
usermod -s /usr/bin/fish root
sed -i 's|SHELL=/bin/bash|SHELL=/usr/bin/fish|' /etc/default/useradd

# Flathub Repository
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

# Cleanup Logic is handled by Containerfile final stage, but we can do local cleanup
rm -f /tmp/gum.tar.gz

echo "✅ Build Module Complete."
