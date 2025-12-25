#!/bin/bash
set -e
cd "$(dirname "$0")/.."

CLEAN_MODE=false
if [[ "$1" == "--clean" ]]; then
    CLEAN_MODE=true
fi

echo "🔄 Starting Build Loop..."

# 1. Build the Container (Root Scope)
CLOUD_IMAGE="ghcr.io/ericrowan/asahi-atomic:latest"
podman pull $CLOUD_IMAGE

# 2. Build the VM Disk
IMAGE=$CLOUD_IMAGE sudo -E bash scripts/build-vm.sh

# 3. Run the VM
if command -v qemu-system-aarch64 &> /dev/null; then
    bash scripts/run-vm.sh
else
    echo "⚠️  QEMU not found on host. Running via Distrobox..."
    distrobox enter dev -- bash scripts/run-vm.sh
fi

# 4. Cleanup (If requested)
if [ "$CLEAN_MODE" = true ]; then
    echo "🧹 Janitor Mode: Pruning dangling images..."
    sudo podman image prune -f
fi
