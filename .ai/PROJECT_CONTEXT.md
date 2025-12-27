# 🧠 Project Cortex (WavyOS) Context

**Project:** Custom Fedora Atomic (Silverblue) OS image for Apple Silicon (Asahi Linux).
**Repo:** `ericrowan/asahi-atomic`
**Base Image:** `quay.io/fedora-asahi-remix-atomic-desktops/silverblue:42`

## 🏗️ Architecture
*   **Build System:** GitHub Actions builds the image → Pushes to GHCR.
*   **Local Dev:** `just test` pulls the GHCR image, builds a VM disk, and boots QEMU.
*   **Installer:** `scripts/install-os.sh` performs a "Takeover" install on bare metal (wipes partition, installs image).
*   **User Setup:** `setup-user.sh` (baked into `/usr/bin/`) handles "Hydration" (Flatpaks, Homebrew, Distrobox) on first boot.

## 🛠️ Tech Stack & Decisions
1.  **Package Managers:**
    *   **RPM-OSTree:** Core system only (Drivers, VPN, Shell).
    *   **Flatpak:** All GUI Apps.
    *   **Homebrew:** User-space CLI tools (Starship, Eza, Gum).
    *   **Distrobox (DNF):** Heavy dev tools (Compilers, Python, Node).
2.  **Shell:** Fish is the default. Configured via `/etc/fish/conf.d/wavy-defaults.fish`.
3.  **Workarounds:**
    *   **Starship/Gum:** Installed via manual binary (`curl`) in build module because Fedora 42 AArch64 repos are missing them.
    *   **Audio:** Custom Wireplumber LUA script and Pipewire Quantum config baked in to fix M1 Pro crackling/volume bugs.
    *   **Boot:** `grub2-install` is forced manually in the VM builder to support QEMU booting of the Asahi kernel.

## 🚧 Current Status (Dec 2025)
*   **Build:** Green (GitHub Actions).
*   **VM:** Boots successfully into Silverblue.
*   **UX:** Custom "WavyOS" wallpaper and GSchema overrides (Dark mode, Bottom dock) applied.
*   **Known Issues:** 
    *   Software rendering in VM (slow).
    *   No native GPU compute for AI in containers yet.

## 🔮 Roadmap
1.  **First Boot:** Refine `welcome.sh` TUI.
2.  **Migration Guide:** Documentation for macOS users.
3.  **Real Metal:** Validate install on physical M1 Pro.
