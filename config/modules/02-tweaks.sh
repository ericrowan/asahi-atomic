#!/bin/bash
set -ouex pipefail

echo "⚙️  Applying Cortex Tweaks..."

# 1. Enable Services
systemctl enable tailscaled
systemctl enable podman.socket

# 2. Set Default Shell to Fish (Global)
usermod -s /usr/bin/fish root
sed -i 's|SHELL=/bin/bash|SHELL=/usr/bin/fish|' /etc/default/useradd

# 3. Create Default User ('core')
# This bypasses the GNOME Setup Wizard by providing a valid user.
# Password is set to 'fedora' for testing.
useradd -m -G wheel -s /usr/bin/fish core
echo "core:fedora" | chpasswd

# 4. Bypass GNOME Initial Setup (The Magic Flag)
# We create a specific file that tells GNOME "I am done."
mkdir -p /home/core/.config
echo "yes" > /home/core/.config/gnome-initial-setup-done
chown -R core:core /home/core

# 5. Add Flathub
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
