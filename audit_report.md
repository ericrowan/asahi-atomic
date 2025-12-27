# 🛡️ Audit Report: Asahi Atomic MVP Reset

**Date:** December 27, 2025  
**Auditor:** Gemini CLI DevOps Agent  
**Objective:** Reset repository to a reliable, debuggable, and minimal MVP state.

---

## 1. 🗑️ Files to Delete

The following files are identified as "Dead Code" or dangerous duplicates that have been superseded by the `justfile` orchestration.

| File Path | Reason |
| :--- | :--- |
| `scripts/install-os.sh` | **Dangerous.** Handles bare-metal installation (partition wiping) which duplicates logic in `build-vm` (for VMs). Violates "One Source of Truth". |

---

## 2. ⚙️ Build Chain Audit & Fixes (`justfile`)

The current `justfile` lacks local build capability (relying on `ghcr.io` pulls) and verbose debugging.

### Recommended Changes

#### A. Enable Debugging & Hygiene in `build-vm`
**Change:** Add `set -x` for verbosity. Ensure the image is fresh.

```make
# [Internal] Build the VM Image
build-vm image:
    #!/bin/bash
    set -ex  # <--- CHANGED: Added 'x' for debug logging
    
    # ... (rest of script) ...

    echo "🚀 Installing OS..."
    # CHANGED: Added --pull=newer to ensure we don't use a stale cache
    podman run --rm --pull=newer --privileged ... "$IMAGE" ...
```

#### B. Add Local Build Support
Currently, you must PUSH to GitHub to test changes. Add a local build recipe to shorten the loop.

```make
# Build container locally
build:
    podman build \
        --platform linux/arm64 \
        -f config/Containerfile \
        -t asahi-atomic:dev \
        .

# Update test to use local build
test tag="dev": build
    @echo "🧪 Testing Local Build..."
    just build-vm "localhost/asahi-atomic:{{ tag }}"
    just run-vm
```

---

## 3. 📦 Payload Simplification (The Skeleton)

### `config/packages.txt`
**Status:** Bloated. Contains GUI apps, dev tools, and redundancy.
**Action:** Reduce to boot + debug essentials.

```text
# --- Core Utils ---
git
vim
just
fish
tailscale

# --- Commented Out (Bloat) ---
# btop
# cifs-utils
# curl
# distrobox
# fastfetch
# gcc
# gnome-text-editor
# ... (rest of list)
```

### `config/flatpaks.txt`
**Status:** Extremely heavy (Steam, Blender, Discord).
**Action:** Comment out ALL flatpaks. The MVP should just boot the OS.

```text
# --- MVP: No Flatpaks initially ---
# com.bitwarden.desktop
# org.mozilla.firefox
# ... (all others)
```

---

## 4. ⚠️ Weak Spots & "Script Drift"

1.  **Unverified Downloaders (`config/modules/build.sh`)**:
    *   **Risk:** `curl -sS https://starship.rs/install.sh | sh` and the `gum` downloader are unverified. If these URLs break or are compromised, the build fails/compromises.
    *   **Fix:** Use Fedora repos for `starship` (if available) or vendor the binaries.

2.  **Architectural Friction (`aarch64`)**:
    *   **Risk:** `gum` is manually downloaded for `linux_arm64`. Hardcoding versions (`0.13.0`) causes drift.
    *   **Fix:** Check if `gum` is in Fedora repos or standardise the fetch logic.

3.  **Nuclear Clean (`test-clean`)**:
    *   **Risk:** `podman system reset --force` deletes ALL images/containers on your machine, not just this project's.
    *   **Fix:** Use `podman rmi -f asahi-atomic:dev` instead.

```
