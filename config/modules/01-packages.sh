#!/bin/bash
set -ouex pipefail

# 1. Decrapify
rpm-ostree override remove \
    firefox firefox-langpacks \
    gnome-tour \
    gnome-software-rpm-ostree \
    yelp

# 2. Install System Tools (Bake these in!)
rpm-ostree install \
    fish \
    just \
    distrobox \
    tailscale \
    gnome-tweaks \
    sushi \
    btop \
    htop \
    fastfetch \
    git \
    neovim \
    openssl \
    cifs-utils \
    nfs-utils

# 3. Starship Binary
curl -sS https://starship.rs/install.sh | sh -s -- -y -b /usr/bin
