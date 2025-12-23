#!/bin/bash
set -ouex pipefail

echo "⚙️  Applying Cortex Tweaks..."

# 1. Enable Services
systemctl enable tailscaled
systemctl enable podman.socket

# 2. Set Default Shell to Fish (For root and new users)
usermod -s /usr/bin/fish root
sed -i 's|SHELL=/bin/bash|SHELL=/usr/bin/fish|' /etc/default/useradd

# 3. Add Flathub Repository (System-wide)
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
