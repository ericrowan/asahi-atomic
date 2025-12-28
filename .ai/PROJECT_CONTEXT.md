# 🧠 Project Cortex (WavyOS) Context

**Project:** Custom Fedora Atomic (Silverblue) OS image for Apple Silicon (Asahi Linux).
**Repo:** `ericrowan/asahi-atomic`
**Architecture:** BlueBuild (Declarative) on GitHub Actions.

## 🏗️ Technical Architecture
*   **Base Image:** `quay.io/fedora-asahi-remix-atomic-desktops/silverblue:42`
*   **Build System:** BlueBuild (via GitHub Actions).
*   **Manifest:** `recipes/recipe.yml` (Single Source of Truth).
*   **Target Hardware:** Apple Silicon (M1/M2/M3) -> `aarch64`.

## 🛡️ Critical Infrastructure
*   **`recipes/recipe.yml`**: Defines the OS layers, packages, and Flatpaks.
*   **`config/files/`**: Contains static configs (Fish, Starship, dconf) overlaid on the image.
*   **`justfile`**: The command runner for local maintenance and updates.

## 🚧 Current Status (BlueBuild Pivot)
*   **Phase:** Migration to BlueBuild.
*   **CI/CD:** Using `ubuntu-24.04-arm` (Native ARM64 runners).
*   **Installation Strategy:** "Rebase" model. Users install stock Fedora Asahi, then run `rpm-ostree rebase` to switch to WavyOS.

## 🛠️ Convention & Rules
1.  **No Imperative Scripts:** Do not use `setup-user.sh` or `build.sh`. Use `recipe.yml` modules.
2.  **Fish Shell:** The default shell. Configs live in `config/files/usr/share/fish/vendor_conf.d/`.
3.  **State Management:** Always generate a report in `.ai/status-report-YYYY-MM-DD.md` after major changes.
