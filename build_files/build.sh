#!/bin/bash
set -ouex pipefail

# --- PACKAGES ---
# Install standard packages via dnf5
# (Add your custom tools here later, e.g., 'fish', 'zsh' if not in base)
dnf5 install -y tmux fastfetch

# --- SYSTEM UNITS ---
# Enable Podman socket for containers
systemctl enable podman.socket

# --- ASAHI POST-PROCESSING ---
# Critical: Regenerate initramfs so the machine can boot the new Asahi kernel
echo "⚡ Regenerating initramfs for Asahi..."
dracut --force --regenerate-all

# --- CLEANUP ---
# Ensure no temporary files persist
rm -rf /tmp/*