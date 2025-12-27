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

# echo "✨ Installing Starship..."
# curl -sS https://starship.rs/install.sh | sh -s -- -y -b /usr/bin

# echo "🍬 Installing Gum..."
# GUM_VERSION="0.13.0"
# curl -L -o /tmp/gum.tar.gz "https://github.com/charmbracelet/gum/releases/download/v${GUM_VERSION}/gum_${GUM_VERSION}_linux_arm64.tar.gz"
# tar -xf /tmp/gum.tar.gz -C /tmp
# mv /tmp/gum /usr/bin/gum
# chmod +x /usr/bin/gum

# -----------------------------------------------------------------------------
# 3. SYSTEM TWEAKS & CONFIGURATION
# -----------------------------------------------------------------------------

echo "⚙️  Applying System Tweaks..."

# --- AUDIO FIXES (Baked into OS) ---
echo "🔊 Configuring Audio Defaults..."

# 1. WirePlumber: Disable Suspend (Fixes "Pop" and 100% Volume bug)
# We place this in /usr/share/wireplumber so it applies to all users
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

# 2. PipeWire: Force High Quantum (Fixes Firefox Crackling)
# We place this in /etc/pipewire so it overrides defaults
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

# Shell Setup
# usermod -s /usr/bin/fish root
# sed -i 's|SHELL=/bin/bash|SHELL=/usr/bin/fish|' /etc/default/useradd

# Flathub Repository
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

# Cleanup Logic is handled by Containerfile final stage, but we can do local cleanup
rm -f /tmp/gum.tar.gz

echo "✅ Build Module Complete."
