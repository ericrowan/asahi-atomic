#!/bin/bash
set -ouex pipefail

# Enable Tailscale daemon
systemctl enable tailscaled

# Enable Docker socket (if using docker-compatible commands with Podman)
systemctl enable podman.socket