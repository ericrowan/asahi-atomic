#!/bin/bash
# ──────────────────────────────────────────────────────────────────────────────
#  WAVYOS: BARE METAL INSTALLER (v10 - Hardened)
# ──────────────────────────────────────────────────────────────────────────────
# Usage: sudo bash scripts/install-os.sh --live
# Goal: Wipes a specific partition and installs the WavyOS image via bootc.

set -e

# --- CONFIGURATION ---
IMAGE="${IMAGE:-ghcr.io/ericrowan/wavyos:latest}"
MOUNT_DIR="/mnt/wavy_install"

# --- COLORS ---
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
NC='\033[0m'

# --- CLEANUP TRAP (Reliability) ---
function cleanup {
    if [ -d "$MOUNT_DIR" ]; then
        echo "🧹 Cleaning up mounts..."
        umount -R "$MOUNT_DIR" 2>/dev/null || true
    fi
}
trap cleanup EXIT

# --- LIABILITY DISCLAIMER ---
clear
echo -e "${RED}╔════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${RED}║                     ⚠️  NO WARRANTY  ⚠️                         ║${NC}"
echo -e "${RED}╠════════════════════════════════════════════════════════════════════╣${NC}"
echo -e "${RED}║ This software is provided 'as is' without warranty of any kind.    ║${NC}"
echo -e "${RED}║ The authors allow you to use this at your own risk.                ║${NC}"
echo -e "${RED}║                                                                    ║${NC}"
echo -e "${RED}║ THIS SCRIPT WILL PERMANENTLY ERASE DATA ON THE TARGET PARTITION.   ║${NC}"
echo -e "${RED}╚════════════════════════════════════════════════════════════════════╝${NC}"
echo ""
sleep 1

if [ "$1" != "--live" ]; then
    echo -e "Usage: sudo bash $0 --live"
    exit 1
fi

echo -e "${BLUE}🌊 WavyOS Partition Installer${NC}"
echo "------------------------------"

# --- PARTITION SELECTION ---
echo -e "${YELLOW}Available Partitions:${NC}"
lsblk -o NAME,SIZE,FSTYPE,UUID,MOUNTPOINT,PARTTYPE | grep -v "loop"

echo ""
read -p "Enter Target Partition to WIPE (e.g. /dev/nvme0n1p8): " TARGET

# Safety Checks
if [ -z "$TARGET" ]; then echo "❌ No target specified."; exit 1; fi
if [ "$TARGET" == "$(findmnt / -o SOURCE -n)" ]; then echo "❌ Cannot overwrite active root."; exit 1; fi

# --- EFI DETECTION (Smart) ---
echo "🔍 Detecting EFI Partition..."
# Try to find a partition with the EFI GUID type
DETECTED_EFI=$(lsblk -o NAME,PARTTYPE -rn | grep "c12a7328-f81f-11d2-ba4b-00a0c93ec93b" | head -n1 | awk '{print "/dev/"$1}')

if [ -n "$DETECTED_EFI" ]; then
    echo -e "Found candidate EFI partition: ${GREEN}$DETECTED_EFI${NC}"
    read -p "Use this EFI partition? (y/n): " USE_EFI
    if [[ "$USE_EFI" =~ ^[Yy]$ ]]; then
        EFI_PART="$DETECTED_EFI"
    else
        read -p "Enter EFI Partition manually (e.g. /dev/nvme0n1p1): " EFI_PART
    fi
else
    echo -e "${YELLOW}⚠️  Could not auto-detect EFI partition.${NC}"
    read -p "Enter EFI Partition manually (e.g. /dev/nvme0n1p1): " EFI_PART
fi

if [ ! -b "$EFI_PART" ]; then echo "❌ Invalid EFI partition."; exit 1; fi


# --- FINAL CONFIRMATION ---
echo ""
echo -e "${RED}--------------------------------------------------${NC}"
echo -e "TARGET (WIPE):  ${RED}$TARGET${NC}"
echo -e "EFI (BOOT):     ${GREEN}$EFI_PART${NC}"
echo -e "IMAGE:          $IMAGE"
echo -e "${RED}--------------------------------------------------${NC}"
read -p "Type 'DESTROY' to confirm data loss and proceed: " CONFIRM
if [ "$CONFIRM" != "DESTROY" ]; then echo "Aborted."; exit 1; fi

# --- EXECUTION ---
echo "🔨 Formatting $TARGET (Btrfs)..."
mkfs.btrfs -f -L "WavyOS" "$TARGET"

echo "📂 Mounting..."
mkdir -p "$MOUNT_DIR"
mountpoint -q "$MOUNT_DIR" || mount "$TARGET" "$MOUNT_DIR"

mkdir -p "$MOUNT_DIR/boot/efi"
mountpoint -q "$MOUNT_DIR/boot/efi" || mount "$EFI_PART" "$MOUNT_DIR/boot/efi"

echo "🚀 Installing OS Image (bootc)..."
# We use the 'bootc install' command inside the container to write to disk
podman run --rm --privileged --pid=host --security-opt label=type:unconfined_t \
    -v /dev:/dev -v "$MOUNT_DIR":/target \
    "$IMAGE" \
    bootc install to-filesystem --disable-selinux --skip-finalize --replace-bootloader /target

# --- FSTAB GENERATION ---
echo "📝 Generating fstab..."
UUID=$(blkid -s UUID -o value "$TARGET")
EFI_UUID=$(blkid -s UUID -o value "$EFI_PART")
mkdir -p "$MOUNT_DIR/etc"
cat <<FSTAB > "$MOUNT_DIR/etc/fstab"
UUID=$UUID / btrfs subvol=root,compress=zstd:1 0 0
UUID=$EFI_UUID /boot/efi vfat defaults 0 2
FSTAB

# --- BRANDING ---
echo "🎨 Branding Boot Menu..."
# Search for the BLS config file and swap names to "WavyOS"
if [ -d "$MOUNT_DIR/boot/loader/entries" ]; then
    find "$MOUNT_DIR/boot/loader/entries" -name "*.conf" -exec sed -i 's/Silverblue/WavyOS/g' {} +
    find "$MOUNT_DIR/boot/loader/entries" -name "*.conf" -exec sed -i 's/Fedora Linux/WavyOS/g' {} +
else
    echo "⚠️  Warning: Boot loader entries not found. Skipping branding."
fi

echo -e "${GREEN}✅ Install Complete.${NC}"
echo "   Target UUID: $UUID"
# Trap will handle unmounting
