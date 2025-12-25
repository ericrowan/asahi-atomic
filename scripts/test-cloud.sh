#!/bin/bash
# ──────────────────────────────────────────────────────────────────────────────
#  PROJECT CORTEX: CLOUD TEST RUNNER
# ──────────────────────────────────────────────────────────────────────────────
# Usage: bash scripts/test-cloud.sh
# Goal: Pulls the latest image from GitHub, makes a VM disk, and boots it.
#       SAVES YOUR SSD.

set -e
cd "$(dirname "$0")/.."

# CONFIGURATION
# Replace with your actual GitHub username
USERNAME="ericrowan"
IMAGE="ghcr.io/$USERNAME/asahi-atomic:dev"

echo "☁️  Syncing with Cloud Factory ($IMAGE)..."

# 1. Pull the latest image from GitHub
podman pull $IMAGE

# 2. Build the VM Disk using the Cloud Image
# We export the IMAGE variable so build-vm.sh uses the cloud image, not local
export IMAGE
sudo -E bash scripts/build-vm.sh

# 3. Run the VM
if command -v qemu-system-aarch64 &> /dev/null; then
    bash scripts/run-vm.sh
else
    echo "⚠️  QEMU not found on host. Launching via 'dev' container..."
    distrobox enter dev -- bash scripts/run-vm.sh
fi
