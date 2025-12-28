#!/bin/bash
set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}🌊 WavyOS Installer${NC}"
echo "========================"

# 1. Pre-Flight Checks
if [ ! -f /run/ostree-booted ]; then
    echo -e "${RED}❌ Error: This script must be run on an Atomic (OSTree) system.${NC}"
    exit 1
fi

if ! grep -q "Fedora" /etc/os-release; then
    echo -e "${RED}❌ Error: This script is designed for Fedora Asahi Remix.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ System verified.${NC}"
echo "Target: ghcr.io/ericrowan/wavyos:latest"
echo ""
read -p "Are you ready to transform this system into WavyOS? (y/N) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 1
fi

# 2. The Rebase
echo -e "${BLUE}🚀 Rebasing to WavyOS... (This may take a few minutes)${NC}"

# We use --experimental because we are rebasing to an OCI artifact
sudo rpm-ostree rebase ostree-unverified-registry:ghcr.io/ericrowan/wavyos:latest

# 3. Success
echo ""
echo -e "${GREEN}🎉 Installation Complete!${NC}"
echo "The system has been rebased. Reboot to enter WavyOS."
echo ""
read -p "Reboot now? (y/N) " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    sudo systemctl reboot
fi
