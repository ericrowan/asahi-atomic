#!/bin/bash
# ──────────────────────────────────────────────────────────────────────────────
#  PROJECT CORTEX: OS INSTALLER
# ──────────────────────────────────────────────────────────────────────────────
set -e

IMAGE="ghcr.io/ericrowan/asahi-atomic:latest"
MOUNT_DIR="/mnt/atomic_install"

if [ "$1" != "--live" ]; then
    echo "⚠️  Usage: sudo bash $0 --live"
    echo "    This will DESTROY data on the target partition."
    exit 1
fi

echo -e "\nAvailable Partitions:"
lsblk -o NAME,SIZE,FSTYPE,UUID,MOUNTPOINT | grep -v "loop"

read -rp "Enter Target Partition (e.g. /dev/nvme0n1p8): " TARGET

# Safety Checks
if [ -z "$TARGET" ]; then echo "❌ No target specified."; exit 1; fi
if [ "$TARGET" == "$(findmnt / -o SOURCE -n)" ]; then echo "❌ Cannot overwrite active root."; exit 1; fi

echo "☢️  WARNING: Wiping $TARGET..."
read -rp "Type 'DESTROY' to confirm: " CONFIRM
if [ "$CONFIRM" != "DESTROY" ]; then exit 1; fi

# Execution
echo "formatting..."
mkfs.btrfs -f -L "wavy-atomic" "$TARGET"
mkdir -p "$MOUNT_DIR"
mount "$TARGET" "$MOUNT_DIR"

# Mount EFI for Bootloader
mkdir -p "$MOUNT_DIR/boot/efi"
EFI_PART="/dev/nvme0n1p4"
mount "$EFI_PART" "$MOUNT_DIR/boot/efi"

echo "🚀 Installing OS Image..."
podman run --rm --privileged --pid=host --security-opt label=type:unconfined_t \
    -v /dev:/dev -v "$MOUNT_DIR":/target \
    "$IMAGE" \
    bootc install to-filesystem --disable-selinux --skip-finalize --replace-bootloader /target

# Fix fstab immediately
echo "📝 Generating fstab..."
UUID=$(blkid -s UUID -o value "$TARGET")
EFI_UUID=$(blkid -s UUID -o value "$EFI_PART")
mkdir -p "$MOUNT_DIR/etc"
cat <<EOF > "$MOUNT_DIR/etc/fstab"
UUID=$UUID / btrfs subvol=root,compress=zstd:1 0 0
UUID=$EFI_UUID /boot/efi vfat defaults 0 2
EOF

echo "✅ Install Complete. Target UUID: $UUID"
echo "👉 You may need to update your main GRUB config to point to this UUID."
umount -R "$MOUNT_DIR"

# --- BRANDING: Rename Boot Entry ---
echo "🎨 Branding Boot Menu..."
# Search for the BLS config file and swap names
# We use 'chroot' or direct modification if the path is accessible
find "$MOUNT_DIR/boot/loader/entries" -name "*.conf" -exec sed -i 's/Silverblue/Asahi Atomic/g' {} +
find "$MOUNT_DIR/boot/loader/entries" -name "*.conf" -exec sed -i 's/Fedora Linux/Asahi Atomic/g' {} +

echo "✅ Install Complete. Target UUID: $UUID"
# ... existing code ...
