# 📘 WavyOS Compendium (The Living Truth)

**Version:** 1.0 (The Great Convergence)
**Status:** Living Document
**Maintainer:** Atlas

---

## 🏛️ PART 1: STRATEGY (THE ARCHITECT)

### 1.1 Mission
To create a "Mac-like" Linux experience that is immutable, unbreakable, and aesthetically polished.
*   **Philosophy:** Surgeons, not Butchers. Gourmet Chefs, not Line Cooks.
*   **Base:** Fedora Silverblue (Asahi Remix).
*   **Architecture:** Native ARM64.

### 1.2 The "Knight of Pentacles" Methodology
*   **Un-hurried:** We prefer stability over speed.
*   **Verification:** We do not guess. We lint, build, and boot.
*   **One Source of Truth:** The `Justfile` and `recipe.yml` define the OS.

---

## 🎨 PART 2: IDENTITY (THE MUSE)

### 2.1 Branding
*   **OS Name:** **WavyOS** (Internal Codename), **Resonance** (Release Candidate).
*   **Repo Name:** `asahi-atomic`
*   **Vibe:** "Stained Glass," "Breathing Organism," "Reverberating Mountain Ridges."
*   **Banned Terms:** "Sacred Rebel" (Keep the vibe, lose the name), "Cyberdeck."

### 2.2 Visuals
*   **UI Font:** Inter Variable.
*   **Mono Font:** Monaspace Argon.
*   **Palette (Wavy Default):**
    *   Background: `#11111b` (Dark), `#eff1f5` (Light)
    *   Primary: `#89dceb`
    *   Secondary: `#cba6f7`
    *   Accent: `#f9e2af`

### 2.3 Copywriting Rules
*   **First Boot:** "You’ve arrived. Nothing here is owned. Everything is possible."
*   **Installer Success:** "System hydrated. Welcome to the new frequency."
*   **Tone:** Calm, Grounded, Empowered. No "Warning" unless it destroys data.

---

## 🛠️ PART 3: TACTICS & MAGIC NUMBERS (THE ENGINEER)

### 3.1 Partitioning (The "In-Place Split")
*   **Sector Target:** `56000000` (Approx 28GB point on 512GB drive).
*   **Math:** `(Target Size in GB * 1024^3) / 512`.
*   **Command:** `parted /dev/nvme0n1 unit s resizepart 6 56000000`

### 3.2 Audio Quantum Fix (The "Bankstown" Fix)
*   **Problem:** M1 Pro speakers crackle/pop due to buffer underruns.
*   **File:** `/etc/pipewire/pipewire.conf.d/99-quantum-fix.conf`
    ```conf
    context.properties = {
        default.clock.min-quantum = 1024
        default.clock.max-quantum = 2048
    }
    ```
*   **WirePlumber:** Disable suspension (`session.suspend-timeout-seconds = 0`).

### 3.3 The "Rescue USB" Fix
*   **Constraint:** Fedora 42 `mkosi` (v25) is too new for the Asahi script.
*   **Fix:** `pip install git+https://github.com/systemd/mkosi.git@v23 --break-system-packages`

---

## 🔐 PART 4: CODE VAULT (GOLD MASTER)

### 4.1 The Justfile (Command Center)
*   **Build:** `sudo podman build ...` (Must run as root for VM visibility).
*   **Test:** `just build-vm` -> `just run-vm`.
*   **Lint:** `shellcheck` all scripts.

### 4.2 The Installer (`scripts/install-os.sh`)
*   **Safety:** Requires user to type `DESTROY`.
*   **Fstab Logic:**
    ```bash
    UUID=$ROOT_UUID / btrfs subvol=root,compress=zstd:1 0 0
    UUID=$EFI_UUID /boot/efi vfat defaults 0 2
    ```

### 4.3 User Hydration (`scripts/setup-user.sh`)
*   **Homebrew:** Installs to `/home/linuxbrew/.linuxbrew`.
*   **Flatpaks:** Uses `mapfile` to strictly parse `flatpaks.txt` (The "Grep Trap" fix).
*   **Distrobox:** Assembles `distrobox.ini` for the `dev` container.

### 4.4 Build Module (`config/modules/build.sh`)
*   **Signal:** Installs via COPR (`elagostin/signal-desktop`).
*   **Branding:** Sed patches `/usr/lib/os-release`.
*   **Cleanup:** Removes `gnome-tour`, `firefox` (RPM).
