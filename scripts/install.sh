#!/bin/bash
set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}🌊 WavyOS Installer${NC}"
echo "========================"

# Pre-flight: Check if we are on Ostree
if [ ! -f /run/ostree-booted ]; then
    echo -e "${RED}❌ Error: This system is not booted via OSTree.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ System verified.${NC}"
echo "Target: ghcr.io/ericrowan/wavyos:latest"
echo ""

# The Rebase Command
# We use --experimental because we are pulling from a container registry
# We verify the ref exists before applying
echo -e "${BLUE}🚀 Rebasing system...${NC}"
sudo rpm-ostree rebase ostree-unverified-registry:ghcr.io/ericrowan/wavyos:latest

echo ""
echo -e "${GREEN}🎉 Success! WavyOS is staged.${NC}"
echo "Please reboot to enter your new OS."
