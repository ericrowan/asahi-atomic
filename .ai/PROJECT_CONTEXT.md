# 🧠 Project Cortex (WavyOS) Context

**Project:** Custom Fedora Atomic (Silverblue) OS image for Apple Silicon (Asahi Linux).
**Repo:** `ericrowan/asahi-atomic`
**Base Image:** `quay.io/fedora-asahi-remix-atomic-desktops/silverblue:42`

## 🏗️ Architecture
*   **Build System:** GitHub Actions builds the image → Pushes to GHCR.
*   **Local Dev:** `just test` pulls the GHCR image, builds a VM disk, and boots QEMU.
*   **User Setup:** `setup-user.sh` (baked into `/usr/bin/`) handles "Hydration" (Flatpaks, Homebrew, Distrobox) on first boot.

## 🛡️ Critical Infrastructure (DO NOT DELETE)
*   **`scripts/install-os.sh`**: This is the **Bare Metal Bootstrap**. It is NOT used in the CI/VM loop, but it is the **Product**. It performs the "Takeover" install on physical hardware. **Never delete this file.**
*   **`config/packages.txt`**: The source of truth for System RPMs.
*   **`config/flatpaks.txt`**: The source of truth for User Apps.

## 🛠️ Tech Stack & Decisions
1.  **Package Managers:**
    *   **RPM-OSTree:** Minimal Core only (Drivers, VPN, Shell, GCC/Make).
    *   **Homebrew:** **Primary CLI Package Manager.** (Starship, Eza, Gum, Git, Lazygit).
    *   **Flatpak:** All GUI Apps.
    *   **Distrobox (DNF):** Heavy dev tools (Node, Python).
2.  **Shell:** Fish is the default. Configured via `/etc/fish/conf.d/wavy-defaults.fish`.
3.  **Workarounds:**
    *   **Audio:** Custom Wireplumber/Pipewire configs baked into `/usr/share` and `/etc` to fix M1 Pro crackling/volume bugs.
    *   **Boot:** `grub2-install` is forced manually in `Justfile` (build-vm) to support QEMU booting.

## 🚧 Current Status (Dec 2025)
*   **Build:** Green (GitHub Actions).
*   **VM:** Boots successfully into Silverblue.
*   **UX:** Custom "WavyOS" wallpaper and GSchema overrides (Dark mode, Bottom dock) applied.
*   **Workflow:** `just push` triggers cloud build. `just test` validates it.
