#!/bin/bash
set -ouex pipefail

echo "🚀 Starting System Build Module..."

# -----------------------------------------------------------------------------
# 1. SETUP LISTS
# -----------------------------------------------------------------------------

# Packages to Remove (Decrapify)
REMOVE_PKGS=(
    "firefox"
    "firefox-langpacks"
    "gnome-software"
    "gnome-software-rpm-ostree"
    "gnome-tour"
    "yelp"
)

# Packages to Install (Bootloader + System Tools)
# We start with the critical bootloader tools
INSTALL_PKGS=(
    "grub2-efi-aa64"
    "grub2-efi-aa64-modules"
    "grub2-tools"
    "shim-aa64"
    "plymouth-plugin-script"
)

# Read User Packages from text file
# We use 'cat' and a loop to safely add them to the array
if [ -f "/tmp/config/packages.txt" ]; then
    while IFS= read -r pkg; do
        # Skip empty lines and comments
        [[ "$pkg" =~ ^#.*$ ]] && continue
        [[ -z "$pkg" ]] && continue
        INSTALL_PKGS+=("$pkg")
    done < "/tmp/config/packages.txt"
fi

# -----------------------------------------------------------------------------
# 2. CONSTRUCT TRANSACTION
# -----------------------------------------------------------------------------

# Build the argument list string manually
# This avoids the printf/array concatenation bug
INSTALL_ARGS=""
for pkg in "${INSTALL_PKGS[@]}"; do
    INSTALL_ARGS="$INSTALL_ARGS --install=$pkg"
done

echo "📦 Executing rpm-ostree transaction..."
echo "   Removing: ${REMOVE_PKGS[*]}"
echo "   Installing: ${INSTALL_PKGS[*]}"

# Run the single atomic transaction
# shellcheck disable=SC2086
rpm-ostree override remove "${REMOVE_PKGS[@]}" $INSTALL_ARGS

# -----------------------------------------------------------------------------
# 3. SYSTEM TWEAKS
# -----------------------------------------------------------------------------

echo "⚙️  Applying System Tweaks..."

# Audio: Disable Suspend
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

# Audio: Force High Quantum
mkdir -p /etc/pipewire/pipewire.conf.d
cat <<EOF > /etc/pipewire/pipewire.conf.d/99-quantum-fix.conf
context.properties = {
    default.clock.min-quantum = 1024
    default.clock.max-quantum = 2048
}
EOF

# Services
systemctl enable podman.socket
systemctl enable spice-vdagentd

# Flathub
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

# Branding
sed -i 's/Fedora Linux/WavyOS/g' /usr/lib/os-release
sed -i 's/NAME="Fedora Linux"/NAME="WavyOS"/' /usr/lib/os-release
sed -i 's/^ID=fedora/ID=wavyos\nID_LIKE=fedora/' /usr/lib/os-release

echo "✅ Build Module Complete."
