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
    "plymouth-plugin-script"
    "shim-aa64"
)

# Read User Packages (System Layer only)
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
# 2. SYSTEM TWEAKS & CONFIGURATION
# -----------------------------------------------------------------------------

echo "⚙️  Applying System Tweaks..."

# --- AUDIO FIXES (Baked into OS) ---
echo "🔊 Configuring Audio Defaults..."

# 1. WirePlumber: Disable Suspend (Fixes "Pop")
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

# 2. PipeWire: Force High Quantum (Fixes Crackling)
mkdir -p /etc/pipewire/pipewire.conf.d
cat <<EOF > /etc/pipewire/pipewire.conf.d/99-quantum-fix.conf
context.properties = {
    default.clock.min-quantum = 1024
    default.clock.max-quantum = 2048
}
EOF

# Enable Services
# systemctl enable tailscaled
systemctl enable podman.socket

# Flathub Repository
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

echo "✅ Build Module Complete."
