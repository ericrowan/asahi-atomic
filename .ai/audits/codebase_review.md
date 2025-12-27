# Codebase Review & Improvement Plan: asahi-atomic

## I. Codebase Analysis & Refactoring
*   **Redundancy Removal:** `config/modules/03-services.sh` is redundant. Its logic (enabling `tailscaled` and `podman.socket`) is already covered in `02-tweaks.sh`. Furthermore, it is not currently invoked by the `Containerfile`.
*   **Module Consolidation:** The naming convention `01-`, `02-`, etc., suggests a sequence that is partially ignored. These should be merged or clearly defined by responsibility (e.g., `packages.sh`, `system-config.sh`).
*   **Path Correction:** `config/files/usr/bin/setup-user.sh` currently uses relative paths (e.g., `config/flatpaks.txt`), which will fail unless the user is in a specific directory. It should reference the system location at `/usr/share/asahi-atomic/`.

## II. Build Time Optimization
*   **Consolidate `rpm-ostree` Calls:** The `Containerfile` performs an `rpm-ostree install` for bootloader tools and then calls `01-packages.sh` for another transaction. Consolidating these into a single transaction will significantly reduce build times by avoiding multiple metadata downloads and composition phases.
*   **External Binary Management:** `starship` and `gum` are installed via `curl`. While functional, sourcing these from a repository (if available) or handling them in a single layer with proper cleanup would be more efficient.
*   **Layer Optimization:** Minimize the number of `RUN` commands in the `Containerfile` to reduce image layers and metadata overhead.

## III. Code Structure Enhancement
*   **Branding Consistency:** There are several references to `wavyos` (e.g., `/usr/share/wavyos`, `welcome.sh`). These should be standardized to `asahi-atomic` or the intended project identity to avoid confusion.
*   **Justfile Integration:** The `scripts/` directory contains standalone scripts (`lint.sh`, `test.sh`, `build-vm.sh`, `run-vm.sh`). These logic blocks should be moved directly into the `justfile` recipes to provide a unified developer interface and reduce script "spaghetti".
*   **Config Location:** Standardize the location of configuration templates (Flatpaks, Distrobox) to `/usr/share/asahi-atomic/` instead of mixed locations.

## IV. Maintainability & Readability
*   **Error Handling:** Ensure all shell scripts consistently use `set -euo pipefail`.
*   **Declarative Setup:** Move away from imperative `chmod` calls in modules by ensuring the `COPY` phase or the system overlay handles permissions correctly.
*   **Centralized Configuration:** Move all package lists and environment tweaks into the `config/` directory and use the `Containerfile` to place them correctly.

## V. Actionable Next Steps
1.  **Standardize Project Name:** Rename `/usr/share/wavyos` to `/usr/share/asahi-atomic` across all files.
2.  **Clean up Modules:** Delete `03-services.sh` and merge unique logic into `02-tweaks.sh`.
3.  **Refactor `setup-user.sh`:** Use absolute paths for configuration files.
4.  **Optimize `Containerfile`:** Combine `rpm-ostree` operations into a single step.
5.  **Unify Task Runner:** Migrate `scripts/*.sh` logic into the root `justfile`.
