#!/bin/bash
set -ouex pipefail

echo "⚙️  Applying System Tweaks..."

# 1. Install Configuration Files (The Fix)
# We copy everything from the temp build dir to the system root
cp -r /tmp/files/usr /usr
cp -r /tmp/files/etc /etc

# 2. Make scripts executable
chmod +x /usr/bin/welcome.sh

# 3. Enable Services
systemctl enable tailscaled
systemctl enable podman.socket

# 4. Set Default Shell to Fish
usermod -s /usr/bin/fish root
sed -i 's|SHELL=/bin/bash|SHELL=/usr/bin/fish|' /etc/default/useradd

# 5. Add Flathub
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
