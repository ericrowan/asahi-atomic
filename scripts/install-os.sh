#!/bin/bash
# 
# WAVYOS: BARE METAL INSTALLER (v11 - Sacred Echo)
# 
# Usage: sudo bash scripts/install-os.sh --live

set -e

# --- COLORS (Catppuccin/Wavy Palette) ---
RESET="\033[0m"
BOLD="\033[1m"
CYAN="\033[36m"     # Prompts
PURPLE="\033[35m"   # Identity
YELLOW="\033[33m"   # Success
RED="\033[31m"      # Danger
GRAY="\033[90m"     # Info

# --- CONFIGURATION ---
IMAGE="${IMAGE:-ghcr.io/ericrowan/wavyos:latest}"
MOUNT_DIR="/mnt/wavy_install"

# --- CLEANUP TRAP ---
function cleanup {
    if [ -d "$MOUNT_DIR" ]; then
        echo -e "${GRAY}🧹 Cleaning up mounts...${RESET}"
        umount -R "$MOUNT_DIR" 2>/dev/null || true
    fi
}
trap cleanup EXIT

# --- HEADER ---
clear
echo -e "${PURPLE}"
cat << "EOF"
██╗    ██╗ █████╗ ██╗   ██╗██╗   ██╗
██║    ██║██╔══██╗██║   ██║╚██╗ ██╔╝
██║ █╗ ██║███████║██║   ██║ ╚████╔╝ 
██║███╗██║██╔══██║╚██╗ ██╔╝  ╚██╔╝  
╚███╔███╔╝██║  ██║ ╚████╔╝    ██║   
 ╚══╝╚══╝ ╚═╝  ╚═╝  ╚═══╝     ╚═╝   

               WAVY   OS
EOF
echo -e "${RESET}"
echo -e "${GRAY}        Immutable Linux for Apple Silicon${RESET}"
echo ""

# --- LIABILITY WAIVER ---
if [ "$1" != "--live" ]; then
    echo -e "${RED}⚠️  Usage: sudo bash $0 --live${RESET}"
    exit 1
fi

echo -e "${CYAN}Enter Target Partition to WIPE (e.g. /dev/nvme0n1p8):${RESET}"
read -p "> " TARGET

# Safety Checks
if [ -z "$TARGET" ]; then echo "❌ No target specified."; exit 1; fi
if [ "$TARGET" == "$(findmnt / -o SOURCE -n)" ]; then echo "❌ Cannot overwrite active root."; exit 1; fi

# --- EFI DETECTION ---
echo -e "${GRAY}🔍 Detecting EFI Partition...${RESET}"
DETECTED_EFI=$(lsblk -o NAME,PARTTYPE -rn | grep "c12a7328-f81f-11d2-ba4b-00a0c93ec93b" | head -n1 | awk '{print "/dev/"$1}')

if [ -n "$DETECTED_EFI" ]; then
    echo -e "Found EFI: ${PURPLE}$DETECTED_EFI${RESET}"
    echo -e "${CYAN}Use this EFI partition? (y/n):${RESET}"
    read -p "> " USE_EFI
    if [[ "$USE_EFI" =~ ^[Yy]$ ]]; then
        EFI_PART="$DETECTED_EFI"
    else
        echo -e "${CYAN}Enter EFI Partition manually:${RESET}"
        read -p "> " EFI_PART
    fi
else
    echo -e "${YELLOW}⚠️  Could not auto-detect EFI.${RESET}"
    echo -e "${CYAN}Enter EFI Partition manually:${RESET}"
    read -p "> " EFI_PART
fi

if [ ! -b "$EFI_PART" ]; then echo "❌ Invalid EFI partition."; exit 1; fi

# --- FINAL CONFIRMATION ---
echo ""
echo -e "${RED}WARNING: This will wipe all data on ${BOLD}$TARGET${RESET}${RED}.${RESET}"
echo "Image: $IMAGE"
echo ""
echo -e "${CYAN}Type 'DESTROY' to confirm:${RESET}"
read -p "> " CONFIRM
if [ "$CONFIRM" != "DESTROY" ]; then echo "Aborted."; exit 1; fi

# --- EXECUTION ---
echo -e "${GRAY}Formatting $TARGET...${RESET}"
mkfs.btrfs -f -L \"WavyOS\" \"$TARGET\" > /dev/null

echo -e "${GRAY}Mounting...${RESET}"
mkdir -p "$MOUNT_DIR"
mountpoint -q "$MOUNT_DIR" || mount "$TARGET" "$MOUNT_DIR"
mkdir -p "$MOUNT_DIR/boot/efi"
mountpoint -q "$MOUNT_DIR/boot/efi" || mount "$EFI_PART" "$MOUNT_DIR/boot/efi"

echo -e "${PURPLE}Initializing Portal (Installing OS)...${RESET}"
podman run --rm --privileged --pid=host --security-opt label=type:unconfined_t \
    -v /dev:/dev -v "$MOUNT_DIR":/target \
    "$IMAGE" \
    bootc install to-filesystem --disable-selinux --skip-finalize --replace-bootloader /target

echo -e "${GRAY}Configuring system...${RESET}"
UUID=$(blkid -s UUID -o value "$TARGET")
EFI_UUID=$(blkid -s UUID -o value "$EFI_PART")
mkdir -p "$MOUNT_DIR/etc"
cat <<FSTAB > "$MOUNT_DIR/etc/fstab"
UUID=$UUID / btrfs subvol=root,compress=zstd:1 0 0
UUID=$EFI_UUID /boot/efi vfat defaults 0 2
FSTAB

# Branding
if [ -d "$MOUNT_DIR/boot/loader/entries" ]; then
    find "$MOUNT_DIR/boot/loader/entries" -name "*.conf" -exec sed -i 's/Silverblue/WavyOS/g' {} +
    find "$MOUNT_DIR/boot/loader/entries" -name "*.conf" -exec sed -i 's/Fedora Linux/WavyOS/g' {} +
fi

# --- SUCCESS ---
echo ""
echo -e "${YELLOW}Success! Reboot now.${RESET}"
echo -e "${YELLOW}System hydrated. Welcome to the new frequency.${RESET}"