# 🌊 WavyOS Command Center

set shell := ["bash", "-c"]

image_name := "wavyos"
registry := "ghcr.io/ericrowan"
branch := `git rev-parse --abbrev-ref HEAD`

default:
    @just --list

# --- DEVELOPMENT ---
push msg="update":
    git add .
    git commit -m "{{ msg }}" || echo "⚠️ Nothing to commit..."
    git push
    @echo "⏳ Waiting for GitHub..."
    @sleep 5
    @just watch

watch:
    gh run watch $(gh run list --branch {{ branch }} --limit 1 --json databaseId -q '.[0].databaseId') --exit-status

# --- TESTING ---
test:
    @echo "🧹 NUCLEAR CLEANUP: Deleting old images and disks..."
    sudo rm -rf output/

    @echo "🏗️  Building Main VM Disk..."
    # We pass the image name; build-vm handles the pull (as root) to ensure consistency
    just build-vm "{{ registry }}/{{ image_name }}:latest"

    @echo "💽 Creating Target Disk..."
    truncate -s 10G output/target-disk.img

    @echo "🚀 Booting..."
    just run-vm

build-vm image:
    #!/bin/bash
    set -e
    # Self-elevate to root for disk operations
    if [ "$EUID" -ne 0 ]; then echo "⚠️ Root required for loopback mounting."; exec sudo "$0" "$@"; fi

    IMAGE="{{ image }}"
    OUTPUT_DIR="output"
    DISK_IMG="$OUTPUT_DIR/wavyos-vm.img"
    DISK_SIZE="15G"

    echo "🔍 Checking Image Freshness for: $IMAGE"
    
    # 1. Get Local Hash (if exists)
    LOCAL_HASH=$(podman inspect --format '{{{{.Digest}}}}' "$IMAGE" 2>/dev/null || echo "none")
    
    # 2. Force Pull (Ensures we check the registry)
    echo "⬇️  Pulling latest manifest..."
    podman pull "$IMAGE"
    
    # 3. Get New Hash
    NEW_HASH=$(podman inspect --format '{{{{.Digest}}}}' "$IMAGE")

    if [ "$LOCAL_HASH" != "$NEW_HASH" ]; then
        echo "✅ UPDATE DETECTED: $LOCAL_HASH -> $NEW_HASH"
    else
        echo "✅ Image is up-to-date ($NEW_HASH)"
    fi

    # Ensure clean slate for the file itself
    rm -f "$DISK_IMG"
    mkdir -p "$OUTPUT_DIR"
    truncate -s "$DISK_SIZE" "$DISK_IMG"

    echo "💿 Partitioning Disk..."
    sfdisk "$DISK_IMG" > /dev/null <<EOF
    label: gpt
    , 500M, U
    , , L
    EOF

    LOOP=$(losetup -P --find --show "$DISK_IMG")
    
    # Cleanup Trap
    function cleanup {
        echo "🧹 Cleaning up loop devices..."
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

    echo "🚀 Installing OS to Disk (via bootc)..."
    # IMPORTANT: usage of the EXACT image hash or name we just pulled
    podman run --rm --privileged --pid=host --security-opt label=type:unconfined_t \
        -v /dev:/dev -v /mnt/wavy_vm:/target \
        "$IMAGE" \
        /bin/bash -c "
            bootc install to-filesystem --disable-selinux --skip-finalize /target && \
            grub2-install --force --target=arm64-efi --efi-directory=/target/boot/efi --boot-directory=/target/boot --removable --recheck /dev/loop0
        "

    # Post-Install Fixes
    echo "🔧 Applying Bootloader Fixes..."
    sed -i 's/Fedora Linux/WavyOS/g' /mnt/wavy_vm/boot/loader/entries/*.conf || true

    mount -o remount,rw /mnt/wavy_vm || true
    mkdir -p /mnt/wavy_vm/boot/grub2 /mnt/wavy_vm/etc
    
    ROOT_UUID=$(blkid -s UUID -o value "${LOOP}p2")
    EFI_UUID=$(blkid -s UUID -o value "${LOOP}p1")

    # GRUB Config
    cat <<GRUB > /mnt/wavy_vm/boot/grub2/grub.cfg
    search --no-floppy --fs-uuid --set=root $ROOT_UUID
    set prefix=(\$root)/boot/grub2
    insmod blscfg
    blscfg
    GRUB

    # Fstab
    cat <<FSTAB > /mnt/wavy_vm/etc/fstab
    UUID=$ROOT_UUID / btrfs subvol=root 0 0
    UUID=$EFI_UUID /boot/efi vfat defaults 0 2
    FSTAB

    # Fix permissions for the user who ran sudo
    if [ -n "$SUDO_USER" ]; then
        chown -R "$SUDO_USER:$SUDO_USER" "$OUTPUT_DIR"
    fi
    echo "✅ VM Disk Ready: $DISK_IMG"

run-vm:
    #!/bin/bash
    DISK_IMG="output/wavyos-vm.img"
    TARGET_IMG="output/target-disk.img"

    [ ! -f "$DISK_IMG" ] && echo "❌ Disk not found" && exit 1

    echo "🚀 Booting WavyOS..."
    # Using 'sudo' here to ensure KVM access permissions are fine, though often user is in kvm group
    sudo qemu-system-aarch64 \
        -M virt,accel=kvm -m 6G -smp 4 -cpu host \
        -bios /usr/share/edk2/aarch64/QEMU_EFI.fd \
        -drive format=raw,file="$DISK_IMG",if=virtio \
        -drive format=raw,file="$TARGET_IMG",if=virtio \
        -device virtio-gpu-pci,xres=1920,yres=1080 \
        -display gtk,gl=off \
        -device qemu-xhci -device usb-kbd -device usb-tablet \
        -device virtio-serial-pci \
        -spice port=5930,disable-ticketing=on \
        -device virtserialport,chardev=spicechannel0,name=com.redhat.spice.0 \
        -chardev spicevmc,id=spicechannel0,name=vdagent \
        || true
