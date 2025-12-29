# 🛡️ System Audit: Installer & Repository Hygiene

**Date:** 2025-12-29
**Auditor:** Gemini (Senior Systems Engineer)
**Target:** `scripts/install-os.sh` & Repository Structure

## 🧹 Repository Hygiene
**Status:** ✅ Cleaned
**Actions Taken:**
*   Deleted legacy/orphaned scripts:
    *   `config/files/system/usr/bin/setup-user.sh` (Dead code)
    *   `config/files/system/usr/bin/welcome.sh` (Legacy)
    *   `config/files/system/etc/justfile` (Redundant)
    *   `config/scripts` (Empty directory)
*   **Source of Truth Check:** The only remaining executable logic resides in `justfile`, `.github/workflows/`, and `scripts/install-os.sh`.

## 🚨 Installer Audit (`scripts/install-os.sh`)

### 1. Safety & Data Protection
*   **✅ PASSED:** The script correctly uses `mkfs.btrfs` with a mandatory user confirmation (`read -p ... CONFIRM`).
*   **✅ PASSED:** Logic prevents overwriting the active root (`if [ "$TARGET" == "$(findmnt / ...)" ]`).

### 2. Error Handling & Stability
*   **⚠️ RISK:** **Missing Cleanup Trap.**
    *   **Issue:** The script uses `set -e` but does not implement a `trap` to unmount partitions on failure.
    *   **Scenario:** If `podman run` fails, the script exits, leaving `/mnt/wavy_install` (and EFI) mounted. Subsequent runs will fail at the `mount` command.
    *   **Recommendation:** Add a cleanup function:
        ```bash
        cleanup() {
            echo "🧹 Cleaning up..."
            umount -R "$MOUNT_DIR" || true
        }
        trap cleanup EXIT
        ```

### 3. Logic & Hardcoding
*   **❌ FAIL:** **Hardcoded EFI Partition.**
    *   **Issue:** `EFI_PART="/dev/nvme0n1p4"` is hardcoded.
    *   **Risk:** While this defaults to standard M1 layouts, it blindly assumes `p4` is correct if the device node exists. It does not verify if it is actually an EFI partition (ESP).
    *   **Recommendation:** Use `lsblk` to find the partition with `PARTTYPE` matching EFI (usually `c12a7328-f81f-11d2-ba4b-00a0c93ec93b`) or `FSTYPE="vfat"`.
    *   **Snippet:**
        ```bash
        # Auto-detect EFI
        EFI_PART=$(lsblk -o NAME,PARTTYPE,MOUNTPOINT -rn | grep "c12a7328-f81f-11d2-ba4b-00a0c93ec93b" | head -n1 | awk '{print "/dev/"$1}')
        ```

### 4. Idempotency
*   **⚠️ RISK:** **Re-entrancy Failure.**
    *   **Issue:** `mkdir -p "$MOUNT_DIR"` is fine, but `mount "$TARGET" "$MOUNT_DIR"` will error if already mounted.
    *   **Recommendation:** Check before mounting:
        ```bash
        mountpoint -q "$MOUNT_DIR" || mount "$TARGET" "$MOUNT_DIR"
        ```

## 📝 Summary & Recommendations
The installer is **functional but fragile**. It relies on the "Happy Path" (user has standard M1 partition layout, nothing fails).

**Immediate Next Steps:**
1.  Implement the `trap cleanup EXIT` to ensure clean state on failure.
2.  Replace hardcoded `EFI_PART` with dynamic detection logic.
3.  Add `mountpoint` checks for idempotency.
