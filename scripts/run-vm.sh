#!/bin/bash
# VERSION: v1.0
set -e
cd "$(dirname "$0")/.."

DISK_IMG="output/asahi-atomic-vm.img"

echo "🚀 Booting VM (v1.0)..."
SUDO=""
if [ ! -r /dev/kvm ] || [ ! -w /dev/kvm ]; then SUDO="sudo"; fi

$SUDO qemu-system-aarch64 \
    -M virt,accel=kvm \
    -m 4G -smp 4 \
    -cpu host \
    -bios /usr/share/edk2/aarch64/QEMU_EFI.fd \
    -drive format=raw,file="$DISK_IMG" \
    -device virtio-gpu-pci \
    -display gtk \
    -device qemu-xhci \
    -device usb-kbd -device usb-mouse
