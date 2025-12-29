#!/bin/bash
# ──────────────────────────────────────────────────────────────────────────────
#  WAVYOS: BARE METAL INSTALLER (Restored v9 Gold Master)
# ──────────────────────────────────────────────────────────────────────────────
# Usage: sudo bash scripts/install-os.sh --live
# Goal: Wipes a specific partition and installs the WavyOS image via bootc.

set -e

# Configuration
IMAGE="${IMAGE:-ghcr.io/ericrowan/wavyos:latest}"
MOUNT_DIR="/mnt/wavy_install"

# Branding Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

if [ "$1" != "--live" ]; then
    echo -e "${RED}⚠️  Usage: sudo bash $0 --live${NC}"
    echo "    This will DESTROY data on the target partition."
    exit 1
fi

echo -e "${BLUE}🌊 WavyOS Partition Installer${NC}"
echo "------------------------------"
echo "Available Partitions:"
lsblk -o NAME,SIZE,FSTYPE,UUID,MOUNTPOINT | grep -v "loop"

echo ""
read -p "Enter Target Partition (e.g. /dev/nvme0n1p8): " TARGET

# Safety Checks
if [ -z "$TARGET" ]; then echo "❌ No target specified."; exit 1; fi
if [ "$TARGET" == "$(findmnt / -o SOURCE -n)" ]; then echo "❌ Cannot overwrite active root."; exit 1; fi

echo -e "${RED}☢️  WARNING: Wiping $TARGET...${NC}"
echo "    Installing Image: $IMAGE"
read -p "Type 'DESTROY' to confirm: " CONFIRM
if [ "$CONFIRM" != "DESTROY" ]; then echo "Aborted."; exit 1; fi

# Execution
echo "formatting..."
mkfs.btrfs -f -L "WavyOS" "$TARGET"
mkdir -p "$MOUNT_DIR"
mount "$TARGET" "$MOUNT_DIR"

# Mount EFI for Bootloader Config
mkdir -p "$MOUNT_DIR/boot/efi"
# ⚠️ HARDCODED EFI PARTITION (M1 Pro Layout Standard)
# In future versions, we should auto-detect this.
EFI_PART="/dev/nvme0n1p4" 
if [ ! -b "$EFI_PART" ]; then
    echo "⚠️  Standard EFI partition ($EFI_PART) not found."
    read -p "Please enter your EFI partition (e.g. /dev/nvme0n1p1): " EFI_PART
fi
mount "$EFI_PART" "$MOUNT_DIR/boot/efi"

echo "🚀 Installing OS Image..."
# We use the 'bootc install' command inside the container to write to disk
podman run --rm --privileged --pid=host --security-opt label=type:unconfined_t \
    -v /dev:/dev -v "$MOUNT_DIR":/target \
    "$IMAGE" \
    bootc install to-filesystem --disable-selinux --skip-finalize --replace-bootloader /target

# Fix fstab immediately (Critical for boot)
echo "📝 Generating fstab..."
UUID=$(blkid -s UUID -o value "$TARGET")
EFI_UUID=$(blkid -s UUID -o value "$EFI_PART")
mkdir -p "$MOUNT_DIR/etc"
cat <<FSTAB > "$MOUNT_DIR/etc/fstab"
UUID=$UUID / btrfs subvol=root,compress=zstd:1 0 0
UUID=$EFI_UUID /boot/efi vfat defaults 0 2
FSTAB

# --- BRANDING: Rename Boot Entry ---
echo "🎨 Branding Boot Menu..."
# Search for the BLS config file and swap names to "WavyOS"
find "$MOUNT_DIR/boot/loader/entries" -name "*.conf" -exec sed -i 's/Silverblue/WavyOS/g' {} +
find "$MOUNT_DIR/boot/loader/entries" -name "*.conf" -exec sed -i 's/Fedora Linux/WavyOS/g' {} +

# Cleanup
echo "🧹 Unmounting..."
umount -R "$MOUNT_DIR"

echo -e "${GREEN}✅ Install Complete.${NC}"
echo "   Target UUID: $UUID"
echo "👉 You may need to update your main GRUB config to point to this UUID if it doesn't boot automatically."
