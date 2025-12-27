# 🌊 WavyOS Command Center

# -----------------------------------------------------------------------------
# GLOBAL SETTINGS
# -----------------------------------------------------------------------------
set shell := ["bash", "-c"]

default:
    @just --list

# -----------------------------------------------------------------------------
# 1. DEVELOPMENT WORKFLOW
# -----------------------------------------------------------------------------

# Build container locally (Run as Root to ensure VM builder can see image)
build:
    sudo podman build \
        --platform linux/arm64 \
        -f config/Containerfile \
        -t localhost/asahi-atomic:latest \
        .

# Lint all scripts
lint:
    @echo "🔍 Scanning scripts with ShellCheck..."
    @if ! command -v shellcheck &> /dev/null; then \
        echo "⚠️ ShellCheck not found."; \
        exit 1; \
    fi
    @find config/modules -name "*.sh" -print0 | xargs -0 shellcheck -x
    @echo "✅ Scripts passed."

# Commit and Push
push msg="update": lint
    git add .
    git commit -m "{{ msg }}"
    git push

# Enter dev environment
dev:
    distrobox enter dev

# -----------------------------------------------------------------------------
# 2. TESTING & VM
# -----------------------------------------------------------------------------

# Test locally (Build fresh image, then boots VM)
test tag="latest": build
    @echo "🧪 Testing Tag: {{ tag }}"
    just build-vm "localhost/asahi-atomic:{{ tag }}"
    just run-vm

# Clean test environment and re-test
test-clean tag="dev":
    sudo podman system reset --force
    just test {{ tag }}

# [Internal] Build the VM Image
build-vm image:
    #!/bin/bash
    set -ex
    
    # Ensure root privileges
    if [ "$EUID" -ne 0 ]; then
        echo "⚠️  This recipe requires root privileges for loopback mounting."
        exec sudo "$0" "$@"
    fi

    IMAGE="{{ image }}"
    OUTPUT_DIR="output"
    DISK_IMG="$OUTPUT_DIR/asahi-atomic-vm.img"
    DISK_SIZE="15G"
    
    echo "─── 🏗️  Building VM Image ($IMAGE) ───"
    mkdir -p "$OUTPUT_DIR"
    truncate -s "$DISK_SIZE" "$DISK_IMG"
    
    # Partitioning
    sfdisk "$DISK_IMG" > /dev/null <<EOF
    label: gpt
    , 500M, U
    , , L
    EOF
    
    LOOP=$(losetup -P --find --show "$DISK_IMG")
    
    # Robust Cleanup Trap
    function cleanup {
        echo "🧹 Cleanup..."
        mountpoint -q /mnt/asahi_vm/boot/efi && umount /mnt/asahi_vm/boot/efi
        mountpoint -q /mnt/asahi_vm && umount /mnt/asahi_vm
        losetup -d "$LOOP" 2>/dev/null || true
    }
    trap cleanup EXIT
    
    mkfs.vfat "${LOOP}p1" > /dev/null
    mkfs.btrfs -f "${LOOP}p2" > /dev/null
    
    mkdir -p /mnt/asahi_vm
    mount "${LOOP}p2" /mnt/asahi_vm
    mkdir -p /mnt/asahi_vm/boot/efi
    mount "${LOOP}p1" /mnt/asahi_vm/boot/efi
    
    echo "🚀 Installing OS..."
    podman run --rm --privileged --pid=host --security-opt label=type:unconfined_t \
        -e LANG=C.UTF-8 -e LC_ALL=C.UTF-8 \
        -v /dev:/dev -v /mnt/asahi_vm:/target \
        "$IMAGE" \
        /bin/bash -c "
            bootc install to-filesystem --disable-selinux --skip-finalize /target && \
            grub2-install --force --target=arm64-efi --efi-directory=/target/boot/efi --boot-directory=/target/boot --removable --recheck /dev/loop0
        "
    
    mount -o remount,rw /mnt/asahi_vm || true
    
    # Configs
    mkdir -p /mnt/asahi_vm/boot/grub2 /mnt/asahi_vm/etc
    ROOT_UUID=$(blkid -s UUID -o value "${LOOP}p2")
    EFI_UUID=$(blkid -s UUID -o value "${LOOP}p1")
    
    echo "search --no-floppy --fs-uuid --set=root $ROOT_UUID" > /mnt/asahi_vm/boot/grub2/grub.cfg
    echo "set prefix=(\$root)/boot/grub2" >> /mnt/asahi_vm/boot/grub2/grub.cfg
    echo "insmod blscfg" >> /mnt/asahi_vm/boot/grub2/grub.cfg
    echo "blscfg" >> /mnt/asahi_vm/boot/grub2/grub.cfg
    
    echo "UUID=$ROOT_UUID / btrfs subvol=root 0 0" > /mnt/asahi_vm/etc/fstab
    echo "UUID=$EFI_UUID /boot/efi vfat defaults 0 2" >> /mnt/asahi_vm/etc/fstab
    
    # Ownership fix for the user who called sudo
    if [ -n "$SUDO_USER" ]; then chown "$SUDO_USER:$SUDO_USER" "$DISK_IMG"; fi
    echo "✅ VM Ready."

# [Internal] Run the VM
run-vm:
    #!/bin/bash
    set -e
    DISK_IMG="output/asahi-atomic-vm.img"
    [ ! -f "$DISK_IMG" ] && echo "❌ Disk not found" && exit 1
    
    SUDO=""
    [ ! -w /dev/kvm ] && SUDO="sudo"
    
    echo "🚀 Booting VM..."
    $SUDO qemu-system-aarch64 \
        -M virt,accel=kvm -m 8G -smp 6 -cpu host \
        -bios /usr/share/edk2/aarch64/QEMU_EFI.fd \
        -drive format=raw,file="$DISK_IMG" \
        -device virtio-gpu-pci,xres=1920,yres=1080 \
        -display gtk,gl=off \
        -device qemu-xhci -device usb-kbd -device usb-tablet