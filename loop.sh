# 1. Attach Disk
LOOP=$(sudo losetup -P --find --show output/asahi-atomic-vm.img)

# 2. Mount Root Partition
sudo mkdir -p /mnt/forensic_check
sudo mount ${LOOP}p2 /mnt/forensic_check

# 3. THE TRUTH TEST: Does the binary exist?
if [ -f "/mnt/forensic_check/usr/bin/gnome-shell" ]; then
    echo "✅ SUCCESS: gnome-shell found on disk."
else
    echo "❌ FAILURE: gnome-shell missing from disk."
fi

# 4. Cleanup
sudo umount /mnt/forensic_check
sudo losetup -d $LOOP
