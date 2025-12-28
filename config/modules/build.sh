#!/bin/bash
set -ouex pipefail

echo "🚀 Starting System Build Module..."

# -----------------------------------------------------------------------------
# 1. PREPARE LISTS
# -----------------------------------------------------------------------------

REMOVE_PKGS=(
    "firefox"
    "firefox-langpacks"
    "gnome-software"
    "gnome-software-rpm-ostree"
    "gnome-tour"
    "yelp"
)

# Core Bootloader & Drivers
CORE_PKGS=(
    "grub2-efi-aa64"
    "grub2-efi-aa64-modules"
    "grub2-tools"
    "shim-aa64"
    "plymouth-plugin-script"
)

# Load User Packages
USER_PKGS=()
if [ -f "/tmp/config/packages.txt" ]; then
    mapfile -t RAW_PKGS < "/tmp/config/packages.txt"
    # Filter comments and empty lines
    for pkg in "${RAW_PKGS[@]}"; do
        [[ "$pkg" =~ ^#.*$ ]] && continue
        [[ -z "$pkg" ]] && continue
        # strip whitespace
        pkg="$(echo -e "${pkg}" | tr -d '[:space:]')"
        USER_PKGS+=("$pkg")
    done
fi

ALL_CANDIDATES=("${CORE_PKGS[@]}" "${USER_PKGS[@]}")

# -----------------------------------------------------------------------------
# 2. BATCH VERIFICATION (Resilient)
# -----------------------------------------------------------------------------
echo "🔍 Verifying package availability..."

# Use dnf repoquery to get the list of AVAILABLE packages from the candidates
# We use --queryformat '%{NAME}' to get exact names back
# 'sort -u' ensures unique list
mapfile -t AVAILABLE_PKGS < <(dnf repoquery --available --queryformat '%{NAME}' "${ALL_CANDIDATES[@]}" | sort -u)

# Calculate Missing Packages
MISSING_PKGS=()
FINAL_INSTALL_LIST=()

# Convert available array to an associative array for O(1) lookups
declare -A AVAIL_MAP
for pkg in "${AVAILABLE_PKGS[@]}"; do AVAIL_MAP["$pkg"]=1; done

for pkg in "${ALL_CANDIDATES[@]}"; do
    if [[ -n "${AVAIL_MAP[$pkg]-}" ]]; then
        FINAL_INSTALL_LIST+=("$pkg")
    else
        MISSING_PKGS+=("$pkg")
    fi
done

# Report Findings
if [ ${#MISSING_PKGS[@]} -gt 0 ]; then
    echo "⚠️  WARNING: The following packages were requested but NOT found in enabled repositories:"
    printf "   - %s\n" "${MISSING_PKGS[@]}"
    echo "   (Skipping them to allow build to proceed)"
else
    echo "✅ All requested packages are available."
fi

# -----------------------------------------------------------------------------
# 3. EXECUTE TRANSACTION
# -----------------------------------------------------------------------------

echo "📦 Executing rpm-ostree transaction..."

# Construct Arguments Safely (No string smashing)
INSTALL_ARGS=()
for pkg in "${FINAL_INSTALL_LIST[@]}"; do
    INSTALL_ARGS+=("--install=$pkg")
done

# Single atomic transaction
# We quote the arrays to prevent word splitting, but rpm-ostree needs individual arguments.
# The "${INSTALL_ARGS[@]}" expansion handles this correctly.
rpm-ostree override remove "${REMOVE_PKGS[@]}" "${INSTALL_ARGS[@]}"

# -----------------------------------------------------------------------------
# 4. SYSTEM TWEAKS
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

# Enable Services
systemctl enable podman.socket

# Flathub Repo
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

echo "✅ Build Module Complete."
