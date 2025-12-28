# 🌊 WavyOS Command Center
# -----------------------------------------------------------------------------

set shell := ["bash", "-c"]

image_name := "wavyos"
registry := "ghcr.io/ericrowan"

# Get current branch

branch := `git rev-parse --abbrev-ref HEAD`

default:
    @just --list

# -----------------------------------------------------------------------------
# 1. THE "MAGIC" LOOP
# -----------------------------------------------------------------------------
# Commit, Push, Watch, and Launch VM

# Usage: just push "fix: something"
push msg="update":
    @echo "📦 Committing..."
    git add .
    git commit -m "{{ msg }}" || echo "⚠️ Nothing to commit, pushing anyway..."
    git push
    @echo "👀 Waiting for GitHub Action on branch '{{ branch }}'..."
    @sleep 5
    @# Get the latest Run ID for this branch and watch it. If it passes, run test.
    gh run watch $(gh run list --branch {{ branch }} --limit 1 --json databaseId -q '.[0].databaseId') --exit-status && just test

# -----------------------------------------------------------------------------
# 2. TESTING & VM
# -----------------------------------------------------------------------------

# Pull image, build VM, and boot (Only runs if build succeeded)
test:
    @echo "⬇️  Pulling latest image..."
    podman pull {{ registry }}/{{ image_name }}:latest
    @echo "🏗️  Building VM..."
    just build-vm "{{ registry }}/{{ image_name }}:latest"
    @echo "🚀 Booting..."
    just run-vm

# [Internal] Build the VM Image using bootc
build-vm image:
    #!/bin/bash
    set -e
    # Ensure root privileges
    if [ "$EUID" -ne 0 ]; then
        echo "⚠️  This recipe requires root privileges."
        exec sudo "$0" "$@"
    fi

    IMAGE="{{ image }}"
    OUTPUT_DIR="output"
    DISK_IMG="$OUTPUT_DIR/wavyos-vm.img"
    DISK_SIZE="15G"

    echo "─── 🏗️  Building VM Image from $IMAGE ───"
    mkdir -p "$OUTPUT_DIR"
    truncate -s "$DISK_SIZE" "$DISK_IMG"

    # Partitioning (GPT)
    sfdisk "$DISK_IMG" > /dev/null <<EOF
    label: gpt
    , 500M, U
    , , L
    EOF

    LOOP=$(losetup -P --find --show "$DISK_IMG")

    function cleanup {
        echo "🧹 Cleanup..."
        mountpoint -q /mnt/wavy_vm/boot/efi && umount /mnt/wavy_vm/boot/efi
        mountpoint -q /mnt/wavy_vm && umount /mnt/wavy_vm
        losetup -d "$LOOP" 2>/dev/null || true
    }
    trap cleanup EXIT

    mkfs.vfat -n "EFI" "${LOOP}p1" > /dev/null
    mkfs.btrfs -L "WavyOS" -f "${LOOP}p2" > /dev/null

    mkdir -p /mnt/wavy_vm
    mount "${LOOP}p2" /mnt/wavy_vm
    mkdir -p /mnt/wavy_vm/boot/efi
    mount "${LOOP}p1" /mnt/wavy_vm/boot/efi

    echo "🚀 Installing OS (bootc)..."
    podman run --rm --privileged --pid=host --security-opt label=type:unconfined_t \
        -v /dev:/dev -v /mnt/wavy_vm:/target \
        "$IMAGE" \
        /bin/bash -c "
            bootc install to-filesystem --disable-selinux --skip-finalize /target && \
            grub2-install --force --target=arm64-efi --efi-directory=/target/boot/efi --boot-directory=/target/boot --removable --recheck /dev/loop0
        "

    # Branding
    sed -i 's/Fedora Linux/WavyOS/g' /mnt/wavy_vm/boot/loader/entries/*.conf || true

    # GRUB Config
    mount -o remount,rw /mnt/wavy_vm || true
    mkdir -p /mnt/wavy_vm/boot/grub2 /mnt/wavy_vm/etc
    ROOT_UUID=$(blkid -s UUID -o value "${LOOP}p2")
    EFI_UUID=$(blkid -s UUID -o value "${LOOP}p1")

    echo "search --no-floppy --fs-uuid --set=root $ROOT_UUID" > /mnt/wavy_vm/boot/grub2/grub.cfg
    echo "set prefix=(\$root)/boot/grub2" >> /mnt/wavy_vm/boot/grub2/grub.cfg
    echo "insmod blscfg" >> /mnt/wavy_vm/boot/grub2/grub.cfg
    echo "blscfg" >> /mnt/wavy_vm/boot/grub2/grub.cfg

    echo "UUID=$ROOT_UUID / btrfs subvol=root 0 0" > /mnt/wavy_vm/etc/fstab
    echo "UUID=$EFI_UUID /boot/efi vfat defaults 0 2" >> /mnt/wavy_vm/etc/fstab

    if [ -n "$SUDO_USER" ]; then chown "$SUDO_USER:$SUDO_USER" "$DISK_IMG"; fi
    echo "✅ VM Ready."

# [Internal] Run the VM
run-vm:
    #!/bin/bash
    DISK_IMG="output/wavyos-vm.img"
    [ ! -f "$DISK_IMG" ] && echo "❌ Disk not found" && exit 1

    SUDO=""
    [ ! -w /dev/kvm ] && SUDO="sudo"

    echo "🚀 Booting WavyOS VM..."
    $SUDO qemu-system-aarch64 \
        -M virt,accel=kvm -m 6G -smp 4 -cpu host \
        -bios /usr/share/edk2/aarch64/QEMU_EFI.fd \
        -drive format=raw,file="$DISK_IMG" \
        -device virtio-gpu-pci,xres=1920,yres=1080 \
        -display gtk,gl=off \
        -device qemu-xhci -device usb-kbd -device usb-tablet \
        || true
