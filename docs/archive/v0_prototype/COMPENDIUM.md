### 📘 The WavyOS Project Compendium

This is the **Master Record**. Save this to `docs/COMPENDIUM.md` or Google Docs.

# 🌊 WavyOS Project Compendium

**Version:** 1.0 (Draft)
**Date:** 2025-12-31
**Status:** Stabilization / Release Candidate Prep

---

## 1. Executive Summary

**WavyOS** (formerly `asahi-atomic`) is a custom, immutable Fedora Atomic (Silverblue) operating system image designed specifically for **Apple Silicon (M1/M2)** hardware.

*   **The Goal:** A "Mac-like" Linux experience that is unbreakable, aesthetically polished, and "Sacred/Rebellious" in spirit.
*   **The Philosophy:** "Surgeons, not Butchers." We do not fork core components. We configure, layer, and polish existing, proven technologies.
*   **The User:** A creative developer or power user moving from macOS who wants stability without friction.

---

## 2. Architecture & Tech Stack

### A. The Core
*   **Base Image:** `quay.io/fedora-asahi-remix-atomic-desktops/silverblue:42` (Bleeding Edge).
*   **Architecture:** `aarch64` (ARM64 Native).
*   **Build System:** GitHub Actions (Native ARM64 Runners).
*   **Framework:** **BlueBuild** (Templated build system for OSTree images).

### B. Package Management Strategy
1.  **RPM-OSTree (The Core):**
    *   Drivers, Kernel, Bootloader (`asahi-scripts`).
    *   Shells (`fish`, `zsh`).
    *   System Utilities (`gnome-tweaks`).
2.  **Flatpak (The User Space):**
    *   **All** GUI applications (Browser, Creative, Dev, Media).
    *   Managed via `recipe.yml` (System-wide) and `Warehouse`/`Bazaar` (User-side).
3.  **Homebrew (The Toolbox):**
    *   CLI tools (`starship`, `eza`, `git`, `fastfetch`).
    *   Installed on the Host (`/var/home/linuxbrew`).

### C. The Workflow
*   **Orchestration:** `Justfile` is the single source of truth for commands.
*   **Local Dev:** `just test` builds a QEMU VM to verify the image.
*   **Deployment:** `scripts/install-os.sh` ("The Installer") wipes a partition and applies the image.

---

## 3. The Repository Structure

```text
.
├── .github/workflows/   # CI/CD Pipelines (build.yml)
├── config/
│   ├── files/           # Static file overlays (etc/, usr/)
│   └── manifests/       # JSON data sources for recipe generation
├── docs/                # Process, Roles, Contributing
├── recipes/             # BlueBuild configuration (recipe.yml)
├── scripts/             # Utilities (install-os.sh, generate_recipe.py)
├── justfile             # Command runner
├── README.md            # Public documentation
├── GEMINI.md            # AI Context Protocol
└── LICENSE              # MIT License
```

---

## 4. The Roles (The Symphony)

*   **Eric (The Director):** Vision, Final Approval, Orchestration.
*   **Cortex (Gemini Web):** Architect, Strategist, Prompt Engineer.
*   **Atlas (Gemini CLI):** DevOps Engineer, Code Execution, Local Verification.
*   **Muse (ChatGPT):** Creative Director, Branding, Copywriting.

---

## 5. The Software Manifest

WavyOS follows a strict "Right Tool for the Job" packaging philosophy.

### A. System Layer (RPM-OSTree)
*These packages are baked into the immutable image. They modify the core OS behavior.*
*   **Drivers:** `asahi-scripts`, `steam-devices` (Hardware rules).
*   **Shells:** `fish` (Default), `zsh` (Compatibility).
*   **Core UI:** `gnome-tweaks` (Required for theme injection), `ptyxis` (Container-native terminal).
*   **Removed:** `gnome-tour`, `gnome-software` (Replaced by Warehouse), `firefox` (RPM version replaced by Flatpak).

### B. User Space (Flatpaks)
*The "Batteries Included" suite. Decoupled from the OS for safety and easy removal.*

**1. System & Management**
*   **Warehouse:** Flatpak management (downgrades, leftovers).
*   **Bazaar:** Alternative Flatpak manager.
*   **Flatseal:** Permissions management (Privacy).
*   **Extension Manager:** Manages GNOME Shell extensions without a browser.
*   **Mission Center:** Advanced system monitor (Activity Monitor equivalent).
*   **Baobab:** Disk usage analyzer.

**2. Development**
*   **Zed:** High-performance editor (ARM64 native).
*   **Pods:** GTK frontend for Podman containers.
*   **Boxes:** Virtualization.
*   **Black Box:** Alternative terminal.
*   **VSCodium:** Open-source VS Code.

**3. Productivity & Office**
*   **Obsidian:** Knowledge base.
*   **Papers:** PDF Viewer.
*   **Pika Backup:** Data safety.
*   **Tuba:** Mastodon client.
*   **DistroShelf:** Android integration.

**4. Creative & Media**
*   **Amberol:** Minimal music player.
*   **Shortwave:** Internet radio.
*   **Podcasts:** GNOME Podcasts.
*   **Celluloid:** Video player.
*   **Loupe:** Image viewer.
*   **EasyEffects:** System-wide Audio EQ (Critical for Asahi speaker tuning).

**5. Browsers**
*   **Firefox:** (Flathub version with full codecs).
*   **Chromium:** (Backup engine).

*Note: Steam and Signal are currently excluded from the default image due to ARM64 architecture mismatches on Flathub. Users install these via Distrobox/RPM if needed.*

### C. CLI Tools (Homebrew)
*Installed to `/var/home/linuxbrew` on first boot.*
*   `starship` (Prompt)
*   `fastfetch` (System Info)
*   `eza` (ls replacement)
*   `bat` (cat replacement)
*   `zoxide` (cd replacement)
*   `fzf` (Fuzzy finder)
*   `fd` / `ripgrep` (Search)

---

## 6. Brand Identity (The Soul)

**Codename:** WavyOS (Subject to change, likely "Resonance" or "Lumen").
**Archetype:** The Sacred Rebel / The Gourmet Chef.
*   *Not:* A "Distro."
*   *Is:* A Portal. A Frequency. An Instrument.

### Visual System
*   **Typography:**
    *   **UI:** Inter Variable (Humanist, Invisible).
    *   **Mono:** Monaspace Argon (Texture healed, organic tech).
*   **Colors (Catppuccin Mapping):**
    *   *Latte* → **Dawn**
    *   *Frappe* → **Horizon**
    *   *Macchiato* → **Twilight**
    *   *Mocha* → **Deep Space**
*   **Motion:** "Breathing." Ease-in-out-sine curves. No bouncing. 220ms timing.

### The Installer UX
*   **ASCII Art:** Blocky, retro-futuristic header.
*   **Language:** Technical precision for actions (Partition, Drive), Poetic for milestones (Success, Welcome).
*   **Constraint:** **ARM64 Only.** The installer must fail safely if run on x86 hardware.

---

## 7. Project Autopsy (Lessons Learned)

### What Failed (The "Line Cook" Approach)
1.  **Manual YAML Editing:** Trying to write complex BlueBuild v2 syntax by hand caused repeated build failures due to whitespace/indentation errors.
2.  **Context Mixing:** Feeding the CLI Agent (Atlas) prompts that combined Documentation, Code, and Git operations led to hallucinations and partial executions.
3.  **Blind Trust:** Pushing code without local validation (`just validate`) turned the CI pipeline into a slow, expensive debugger.
4.  **Cache Ghosts:** Podman aggressively cached old images, leading to "Groundhog Day" testing sessions where changes didn't appear.

### What Worked (The "Surgeon" Approach)
1.  **The Triad:** Strictly separating roles (Architect vs. Engineer) prevented logic loops.
2.  **Native Runners:** Switching to `ubuntu-24.04-arm` solved the QEMU emulation crashes immediately.
3.  **Living Spec:** Using `MISSION.md` as a state file prevents the AI from forgetting where it left off.
4.  **The "Nuclear" Clean:** Force-deleting `output/` and using `podman rmi -f` is the only way to guarantee a valid test.

---

### 8. The Path Forward (Strategy)

**Phase 1: The Baseline (Current)**
*   Establish a local BlueBuild CLI scaffold to generate a perfect `recipe.yml` template.
*   Lock the `Justfile` to ensure `validate` runs before `push`.

**Phase 2: The Installer**
*   Refine `install-os.sh` to be robust, branded, and safe.
*   Test "Takeover" on a dummy partition in the VM.

**Phase 3: The Launch**
*   Write the "Portal" README.
*   Tag RC1.
*   Release to early adopters (Asahi community).

---

## 9. Agent Configuration & Roles

To maintain the "Symphony," each AI agent must be prompted with specific parameters to ensure consistency.

### 🧠 Cortex (Gemini 3 Pro - Web)
*   **Role:** Architect / Project Manager.
*   **Settings:** Temperature 0.7 (Balanced creativity/logic).
*   **System Instruction:** "You are the Project Manager for WavyOS. You prioritize stability ('Surgeon') and polish ('Gourmet Chef'). You do not write code unless verified. You manage the roadmap."
*   **Usage:** Strategy, debugging logic, drafting prompts for Atlas/Muse.

### 🏗️ Atlas (Gemini 3 Pro - CLI)
*   **Role:** Site Reliability Engineer / QA.
*   **Settings:** Temperature 0.1 (Strict, deterministic).
*   **System Instruction:** (Defined in `GEMINI.md`) "You are Atlas. You follow the Living Spec (`MISSION.md`). You do not guess. You verify file paths before writing. You output minimal logs to console."
*   **Usage:** File manipulation, git operations, running builds, local validation.

### 🎨 Muse (ChatGPT - Web)
*   **Role:** Creative Director.
*   **Settings:** Temperature 0.9 (High creativity).
*   **System Instruction:** "You are a World-Class Brand Strategist (ex-Apple). You value 'Sacred/Rebellious' aesthetics. You write copy that feels grounded, but like a portal to another dimension."
*   **Usage:** Copywriting, SVG generation, color palette definition, vibe checks.

### 👤 Eric (The Director)
*   **Role:** Human-in-the-Loop.
*   **Strengths:** Vision, Pattern Recognition, Orchestration, "Vibe" Sensing.
*   **Weaknesses:** Patience for repetitive syntax errors (YAML/Bash), manual file management.
*   **Workflow:** Eric defines *What*. Cortex defines *How*. Atlas does *The Work*.

---

## 10. Development Environment

**Primary Dev Machine:**
*   **Hardware:** MacBook Pro 14" (M1 Pro).
*   **OS:** Fedora Silverblue (Asahi Remix) - *Native Metal.*
*   **Role:** The "Golden Standard." If it builds and runs here, it ships.

**Secondary / Test Machine:**
*   **Hardware:** MacBook Pro 16" (M4 Max).
*   **OS:** macOS + UTM (Virtualization).
*   **Role:** Clean-room testing. (Note: Asahi support for M3/M4 is currently **NOT POSSIBLE**; primary testing remains on M1).

---

## 11. The Immutable Thesis (Education)

*For the README/FAQ:*

**Why WavyOS is Immutable (Atomic):**
*   **The Myth:** "I can't change anything."
*   **The Reality:** You can change *everything*, but you can't break *anything*.
*   **The Mechanism:**
    *   **OS:** Read-only image. Updates are downloaded in the background (Staged). Reboot to apply. If an update breaks, you select the previous deployment in Bootloader. **You are invincible.**
    *   **Apps:** Flatpaks. Sandboxed, updated independently of the OS.
    *   **Tools:** Homebrew/Distrobox. Mess up your dev environment? Delete the container. Your OS remains pristine.

**Who is this for?**
*   The developer who is tired of `sudo apt upgrade` breaking their Nvidia drivers (or in this case, GPU drivers).
*   The creative who wants a system that "Just Works" like macOS, but respects their freedom like Linux.

---

## 12. Boot Process Strategy

The boot sequence on Apple Silicon is complex. We aim to hide the gears.

1.  **m1n1 / u-boot:** (Text scrolling).
    *   *Status:* Hard to hide without upstream Asahi changes.
    *   *Strategy:* Accept it as the "Matrix Code" aesthetic of the Sacred Rebel.
2.  **GRUB:** (The Menu).
    *   *Status:* Currently shows "Fedora Linux."
    *   *Fix:* Our installer already rebrands this to "WavyOS". We can set `GRUB_TIMEOUT=1` so it flashes briefly or is hidden unless `Esc` is pressed.
3.  **Plymouth:** (The Boot Splash).
    *   *Status:* Currently the Fedora Logo + Spinner.
    *   *Fix:* **BlueBuild `initramfs` module.** We will install a custom Plymouth theme (The Wavy/Sine Logo) that hides the kernel boot messages (`rhgb quiet`).
4.  **GDM:** (Login Screen).
    *   *Status:* Standard GNOME.
    *   *Fix:* Apply the Wavy branding (Logo + Wallpaper) to the GDM configuration via `dconf` system-wide profile.

---

## 13. Promotion & Community

**The Narrative:** "The Linux that feels like Home."

**Channels:**
1.  **r/AsahiLinux:** The core demographic. Focus on "Batteries Included" + "Polished UI."
2.  **r/unixporn:** Visual showcase. Show off the tiling (Pop Shell or Forge), the blur, the terminal aesthetics.
3.  **Hacker News:** Focus on the "Immutable/Atomic" architecture and the automated build pipeline.

**Assets:**
*   High-res screenshots (Dark Mode, Transparent Terminal).
*   A 30-second "Boot to Desktop" video.
*   The "One-Line Install" script snippet.

---

## 14. Compendium Conclusion

We are not just building a distro; we are building a **Workflow** and a **Standard**.
*   We rely on **BlueBuild** for the plumbing.
*   We rely on **Fedora Asahi** for the hardware support.
*   We add the **Soul** (Config, Apps, Brand).

**Immediate Next Action:**
Save this document.
Then, **execute the Strategic Reset**: Run the BlueBuild CLI locally to scaffold the "Perfect Template" and re-align our repo to it.

*(End of Compendium)*
