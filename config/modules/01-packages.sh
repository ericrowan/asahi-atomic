#!/bin/bash
set -ouex pipefail

# Decrapify
rpm-ostree override remove \
    firefox firefox-langpacks \
    gnome-tour \
    gnome-software-rpm-ostree \
    yelp

# Core Layers
rpm-ostree install \
    fish \
    just \
    distrobox \
    tailscale \
    gnome-tweaks \
    sushi \
    fastfetch

# Manual Binary Installs (Starship)
curl -sS https://starship.rs/install.sh | sh -s -- -y -b /usr/bin
