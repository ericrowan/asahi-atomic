#!/bin/bash
set -e

# Ensure we are in the project root
cd "$(dirname "$0")/.."

# Allow image override from environment
IMAGE="${IMAGE:-localhost/asahi-atomic:latest}"
OUTPUT_DIR="output"
DISK_IMG="$OUTPUT_DIR/asahi-atomic-vm.img"
DISK_SIZE="15G"

echo "─── 🏗️  Building VM Image ───"

# 1. Create Disk
mkdir -p "$OUTPUT_DIR"
truncate -s "$DISK_SIZE" "$DISK_IMG"
sfdisk "$DISK_IMG" > /dev/null <<EOF
label: gpt
, 500M, U
, , L
EOF

# 2. Loopback
LOOP=$(losetup -P --find --show "$DISK_IMG")

function cleanup {
    echo "🧹 Cleanup..."
    mountpoint -q /mnt/asahi_vm/boot/efi && umount /mnt/asahi_vm/boot/efi
    mountpoint -q /mnt/asahi_vm && umount /mnt/asahi_vm
    losetup -d "$LOOP" 2>/dev/null || true
    echo "✅ VM Ready: $DISK_IMG"
}
trap cleanup EXIT

# 3. Format (Force)
mkfs.vfat "${LOOP}p1" > /dev/null
mkfs.btrfs -f "${LOOP}p2" > /dev/null

# 4. Mount
mkdir -p /mnt/asahi_vm
mount "${LOOP}p2" /mnt/asahi_vm
mkdir -p /mnt/asahi_vm/boot/efi
mount "${LOOP}p1" /mnt/asahi_vm/boot/efi

# 5. Install OS & Force GRUB
echo "🚀 Installing OS..."
podman run --rm --privileged --pid=host --security-opt label=type:unconfined_t \
    -v /dev:/dev -v /mnt/asahi_vm:/target \
    "$IMAGE" \
    /bin/bash -c "
        bootc install to-filesystem --disable-selinux --skip-finalize /target && \
        echo '🔧 Forcing GRUB...' && \
        grub2-install --force --target=arm64-efi --efi-directory=/target/boot/efi --boot-directory=/target/boot --removable --recheck /dev/loop0
    "

# 6. Manual Configs
mkdir -p /mnt/asahi_vm/boot/grub2 /mnt/asahi_vm/etc
ROOT_UUID=$(blkid -s UUID -o value "${LOOP}p2")
EFI_UUID=$(blkid -s UUID -o value "${LOOP}p1")

# Static GRUB Config
cat <<EOF > /mnt/asahi_vm/boot/grub2/grub.cfg
search --no-floppy --fs-uuid --set=root $ROOT_UUID
set prefix=(\$root)/boot/grub2
insmod blscfg
blscfg
EOF

# Static fstab
cat <<EOF > /mnt/asahi_vm/etc/fstab
UUID=$ROOT_UUID / btrfs subvol=root 0 0
UUID=$EFI_UUID /boot/efi vfat defaults 0 2
EOF

# Fix ownership so user can run the VM
if [ -n "$SUDO_USER" ]; then
    chown "$SUDO_USER:$SUDO_USER" "$DISK_IMG"
fi
