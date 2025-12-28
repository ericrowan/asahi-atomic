#!/bin/bash
set -ouex pipefail

echo "🚀 Starting System Build Module..."

# -----------------------------------------------------------------------------
# 1. DEFINE LISTS
# -----------------------------------------------------------------------------

# Bootloader & Core Tools (Must be present)
BOOTLOADER_PKGS=(
    "grub2-efi-aa64"
    "grub2-efi-aa64-modules"
    "grub2-tools"
    "shim-aa64"
    "plymouth-plugin-script"
)

# Packages to Remove (Decrapify)
REMOVE_PKGS=(
    "firefox"
    "firefox-langpacks"
    "gnome-software"
    "gnome-software-rpm-ostree"
    "gnome-tour"
    "yelp"
)

# -----------------------------------------------------------------------------
# 2. FAST PACKAGE RESOLUTION (Batch Mode)
# -----------------------------------------------------------------------------

USER_PKGS_RAW=()
VERIFIED_PKGS=()

if [ -f "/tmp/config/packages.txt" ]; then
    # Read file into array
    mapfile -t USER_PKGS_RAW < "/tmp/config/packages.txt"

    echo "🔍 Verifying ${#USER_PKGS_RAW[@]} packages in batch..."

    # SINGLE COMMAND: Ask DNF which packages exist from the list.
    # --available: Check repos
    # --qf '%{name}': Print only the package name
    # sort -u: Deduplicate results
    if [ ${#USER_PKGS_RAW[@]} -gt 0 ]; then
        mapfile -t VERIFIED_PKGS < <(dnf repoquery --available --qf '%{name}' "${USER_PKGS_RAW[@]}" | sort -u)
    fi

    echo "✅ Verified ${#VERIFIED_PKGS[@]} valid packages."
fi

# -----------------------------------------------------------------------------
# 3. EXECUTE TRANSACTION
# -----------------------------------------------------------------------------

echo "📦 Executing atomic transaction..."
# shellcheck disable=SC2046
rpm-ostree override remove "${REMOVE_PKGS[@]}" \
    $(printf -- "--install=%s " "${BOOTLOADER_PKGS[@]}") \
    $(printf -- "--install=%s " "${VERIFIED_PKGS[@]}")

# -----------------------------------------------------------------------------
# 4. SYSTEM TWEAKS
# -----------------------------------------------------------------------------

echo "⚙️  Applying System Tweaks..."

# Audio: Disable Suspend (Fixes "Pop")
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

# Audio: Force High Quantum (Fixes Crackling)
mkdir -p /etc/pipewire/pipewire.conf.d
cat <<EOF > /etc/pipewire/pipewire.conf.d/99-quantum-fix.conf
context.properties = {
    default.clock.min-quantum = 1024
    default.clock.max-quantum = 2048
}
EOF

# Branding: OS Release
sed -i 's/Fedora Linux/WavyOS/g' /usr/lib/os-release
sed -i 's/NAME="Fedora Linux"/NAME="WavyOS"/' /usr/lib/os-release
sed -i 's/^ID=fedora/ID=wavyos\nID_LIKE=fedora/' /usr/lib/os-release

# Services
systemctl enable podman.socket
systemctl enable spice-vdagentd

# Flathub
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

echo "✅ Build Module Complete."
