#!/bin/bash
# ──────────────────────────────────────────────────────────────────────────────
#  PROJECT CORTEX: CLOUD VERIFICATION
# ──────────────────────────────────────────────────────────────────────────────
# Usage: bash scripts/test-cloud.sh [tag]
# Example: bash scripts/test-cloud.sh dev

set -e

# Guard: Ensure we are running on the Host
if [ -f /run/.containerenv ]; then
echo "❌ Error: This script controls the Hypervisor and Disk Images."
echo "Please run 'just test' from your HOST terminal, not inside a Distrobox."
exit 1
fi

cd "$(dirname "$0")/.."

# CONFIGURATION
USERNAME="ericrowan"
TAG="${1:-latest}" # Default to 'latest' if no argument provided
IMAGE_URL="ghcr.io/$USERNAME/asahi-atomic:$TAG"

echo "☁️  Syncing with Cloud Factory..."
echo "   Target: $IMAGE_URL"

# 1. Pull the image
sudo podman pull "$IMAGE_URL"

# 2. Build the VM Disk
echo "💿 Generating Disk Image..."
export IMAGE="$IMAGE_URL"
sudo -E bash scripts/build-vm.sh

# 3. Run the VM
if command -v qemu-system-aarch64 &> /dev/null; then
    bash scripts/run-vm.sh
else
    echo "⚠️  QEMU not found on host. Launching via 'dev' container..."
    distrobox enter dev -- bash scripts/run-vm.sh
fi
