#!/bin/bash
set -ouex pipefail

echo "⚙️  Applying Cortex Tweaks..."

# 1. Make scripts executable (Files are already in /usr/bin via COPY)
chmod +x /usr/bin/welcome.sh

# 2. Enable Services
systemctl enable tailscaled
systemctl enable podman.socket

# 3. Set Default Shell to Fish
usermod -s /usr/bin/fish root
sed -i 's|SHELL=/bin/bash|SHELL=/usr/bin/fish|' /etc/default/useradd

# 4. Add Flathub
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
