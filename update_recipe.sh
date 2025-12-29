#!/bin/bash
set -e

echo "🔧 Hydrating recipes/recipe.yml with Core Packages..."

cat << 'YAML' > recipes/recipe.yml
name: wavyos
description: A polished, immutable Fedora Asahi Remix experience.
base-image: quay.io/fedora-asahi-remix-atomic-desktops/silverblue
image-version: 42

modules:
  # 1. System Overlays (Configs)
  # Populates /etc and /usr/share from local config/files
  - type: files
    files:
      - source: config/files
        destination: /

  # 2. Core Packages (RPMs)
  - type: rpm-ostree
    install:
      # --- Shell & Terminal ---
      - fish
      - starship
      - zoxide
      - eza
      - bat
      - fd-find
      - ripgrep
      - fzf
      - btop
      - fastfetch
      
      # --- System Utils ---
      - git
      - wget
      - curl
      - 7zip
      - fuse
      
      # --- Asahi Specifics ---
      # Essential tools for boot management on Apple Silicon
      - asahi-bless
      - asahi-scripts

  # 3. Font Support (Required for Starship/Terminal icons)
  - type: fonts
    fonts:
      nerd-fonts:
        - JetBrainsMono
        - FiraCode
YAML

echo "📦 Committing and Pushing..."
# Using your 'just push' workflow which handles the git add/commit/push + watch loop
just push "feat: add core cli packages and fonts"
