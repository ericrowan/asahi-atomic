#!/bin/bash
set -e
cd "$(dirname "$0")/.."

DISK_IMG="output/asahi-atomic-vm.img"

if [ ! -f "$DISK_IMG" ]; then
    echo "❌ Error: $DISK_IMG not found."
    exit 1
fi

echo "🚀 Booting High-Spec VM..."
echo "   - RAM: 8GB"
echo "   - CPU: 6 Cores"
echo "   - GPU: VirtIO"

# Check KVM
SUDO=""
if [ ! -r /dev/kvm ] || [ ! -w /dev/kvm ]; then
    echo "⚠️  User does not have KVM permissions. Using sudo."
    SUDO="sudo"
fi

$SUDO qemu-system-aarch64 \
    -M virt,accel=kvm \
    -m 8G \
    -smp 6 \
    -cpu host \
    -bios /usr/share/edk2/aarch64/QEMU_EFI.fd \
    -drive format=raw,file="$DISK_IMG" \
    -device virtio-gpu-pci,xres=1920,yres=1080 \
    -display gtk,gl=off \
    -device qemu-xhci \
    -device usb-kbd \
    -device usb-tablet \
    -device intel-hda -device hda-duplex
