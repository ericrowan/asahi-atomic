# 🌊 WavyOS Command Center
set shell := ["bash", "-c"]
image_name := "wavyos"
registry := "ghcr.io/ericrowan"
branch := \`git rev-parse --abbrev-ref HEAD\`

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
    gh run watch \$(gh run list --branch {{branch}} --limit 1 --json databaseId -q '.[0].databaseId') --exit-status

# --- TESTING ---
test:
    @echo "🧹 Cleaning up old image..."
    -podman rmi {{ registry }}/{{ image_name }}:latest 2>/dev/null
    @echo "⬇️  Pulling latest image..."
    podman pull {{ registry }}/{{ image_name }}:latest
    @echo "🏗️  Building Main VM Disk..."
    just build-vm "{{ registry }}/{{ image_name }}:latest"
    @echo "💽 Creating Target Disk (for Installer Test)..."
    truncate -s 10G output/target-disk.img
    @echo "🚀 Booting..."
    just run-vm

build-vm image:
    #!/bin/bash
    set -e
    if [ "$EUID" -ne 0 ]; then echo "⚠️ Root required."; exec sudo "$0" "$@"; fi

    IMAGE="{{ image }}"
    OUTPUT_DIR="output"
    DISK_IMG="$OUTPUT_DIR/wavyos-vm.img"
    DISK_SIZE="15G"

    mkdir -p "$OUTPUT_DIR"
    truncate -s "$DISK_SIZE" "$DISK_IMG"

    sfdisk "$DISK_IMG" > /dev/null <<EOF
    label: gpt
    , 500M, U
    , , L
    EOF

    LOOP=\$(losetup -P --find --show "$DISK_IMG")
    function cleanup {
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

    echo "🚀 Installing OS..."
    podman run --rm --privileged --pid=host --security-opt label=type:unconfined_t \
        -v /dev:/dev -v /mnt/wavy_vm:/target \
        "$IMAGE" \
        /bin/bash -c "
            bootc install to-filesystem --disable-selinux --skip-finalize /target && \
            grub2-install --force --target=arm64-efi --efi-directory=/target/boot/efi --boot-directory=/target/boot --removable --recheck /dev/loop0
        "

    sed -i 's/Fedora Linux/WavyOS/g' /mnt/wavy_vm/boot/loader/entries/*.conf || true
    
    mount -o remount,rw /mnt/wavy_vm || true
    mkdir -p /mnt/wavy_vm/boot/grub2 /mnt/wavy_vm/etc
    ROOT_UUID=\$(blkid -s UUID -o value "${LOOP}p2")
    EFI_UUID=\$(blkid -s UUID -o value "${LOOP}p1")

    echo "search --no-floppy --fs-uuid --set=root $ROOT_UUID" > /mnt/wavy_vm/boot/grub2/grub.cfg
    echo "set prefix=(\$root)/boot/grub2" >> /mnt/wavy_vm/boot/grub2/grub.cfg
    echo "insmod blscfg" >> /mnt/wavy_vm/boot/grub2/grub.cfg
    echo "blscfg" >> /mnt/wavy_vm/boot/grub2/grub.cfg

    echo "UUID=$ROOT_UUID / btrfs subvol=root 0 0" > /mnt/wavy_vm/etc/fstab
    echo "UUID=$EFI_UUID /boot/efi vfat defaults 0 2" >> /mnt/wavy_vm/etc/fstab
    
    if [ -n "$SUDO_USER" ]; then 
        chown -R "$SUDO_USER:$SUDO_USER" "$OUTPUT_DIR"
    fi
    echo "✅ VM Ready."

run-vm:
    #!/bin/bash
    DISK_IMG="output/wavyos-vm.img"
    TARGET_IMG="output/target-disk.img"
    
    [ ! -f "$DISK_IMG" ] && echo "❌ Disk not found" && exit 1
    
    echo "🚀 Booting WavyOS..."
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
