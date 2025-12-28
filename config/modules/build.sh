#!/bin/bash
set -ouex pipefail

echo "🚀 Starting System Build Module..."

# 1. ADD EXTERNAL REPOS (Signal Desktop - Native ARM64)
curl -o /etc/yum.repos.d/signal.repo https://copr.fedorainfracloud.org/coprs/elagostin/signal-desktop/repo/fedora-rawhide/elagostin-signal-desktop-fedora-rawhide.repo

# -----------------------------------------------------------------------------
# 2. PACKAGE MANAGEMENT (Single Transaction)
# -----------------------------------------------------------------------------

# Bootloader & Core Tools
BOOTLOADER_PKGS=(
    "grub2-efi-aa64"
    "grub2-efi-aa64-modules"
    "grub2-tools"
    "shim-aa64"
    "plymouth-plugin-script"
)

# Read User Packages (System Layer)
USER_PKGS=()
if [ -f "/tmp/config/packages.txt" ]; then
    mapfile -t USER_PKGS < "/tmp/config/packages.txt"
fi

# Packages to Remove (Decrapify)
REMOVE_PKGS=(
    "firefox"
    "firefox-langpacks"
    "gnome-software"
    "gnome-software-rpm-ostree"
    "gnome-tour"
    "yelp"
)

echo "📦 Executing rpm-ostree transaction..."
# shellcheck disable=SC2046
rpm-ostree override remove "${REMOVE_PKGS[@]}" \
    $(printf -- "--install=%s " "${BOOTLOADER_PKGS[@]}") \
    $(printf -- "--install=%s " "${USER_PKGS[@]}")

# -----------------------------------------------------------------------------
# 3. MANUAL INSTALLS
# -----------------------------------------------------------------------------

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

# -----------------------------------------------------------------------------
# 4. SYSTEM TWEAKS
# -----------------------------------------------------------------------------

echo "⚙️  Applying System Tweaks..."

# WirePlumber: Disable Suspend
mkdir -p /usr/share/wireplumber/main.lua.d
cat <<EOF > /usr/share/wireplumber/main.lua.d/51-disable-suspend.lua
table.insert (default_access.rules, {
  matches = {
    {
      { "node.name", "matches", "alsa_output.*" }
    }
  },
  apply_properties = {
    ["session.suspend-timeout-seconds"] = 0
  },
})
EOF

# PipeWire: Force High Quantum
mkdir -p /etc/pipewire/pipewire.conf.d
cat <<EOF > /etc/pipewire/pipewire.conf.d/99-quantum-fix.conf
context.properties = {
    default.clock.min-quantum = 1024
    default.clock.max-quantum = 2048
}
EOF

# Services
systemctl enable podman.socket

# Flathub
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

echo "✅ Build Module Complete."
