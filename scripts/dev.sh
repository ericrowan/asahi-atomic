#!/bin/bash
set -e
cd "$(dirname "$0")/.."

echo "🔄 Starting Build Loop..."

# 1. Build the Container AS ROOT
# This fixes the "Split Brain" issue. We build into Root's storage
# so the next script (which runs as sudo) can see the correct image.
echo "🏗️  Building Image (Root Scope)..."
sudo podman build --pull --no-cache -f config/Containerfile -t localhost/asahi-atomic:latest .

# 2. Build the VM Disk
sudo bash scripts/build-vm.sh

# 3. Run the VM
if command -v qemu-system-aarch64 &> /dev/null; then
    bash scripts/run-vm.sh
else
    echo "⚠️  QEMU not found on host. Running via Distrobox..."
    distrobox enter dev -- bash scripts/run-vm.sh
fi
