# 🕵️‍♂️ Status Report: Build Pipeline Forensics

**Date:** 2025-12-29
**Status:** 🟡 Testing Revert
**Branch:** `feat/polish-v1`

## 🔎 The Investigation
The build pipeline was failing on the "Generate Containerfile" step.
*   **Comparison:** We compared the current failing state against commit `0cfb7f3` (Last Known Good).
*   **Findings:** The `docker run` command in the failing state (specifically my recent attempt to add `--entrypoint=""`) was hypothesized to be incorrect or unnecessary if the image hasn't changed. The user mandate was to restore the **exact logic** of `0cfb7f3`.

## 🛠️ The Fix
1.  **Workflow Revert (`.github/workflows/build.yml`):**
    *   **Action:** Removed `--entrypoint=""`.
    *   **Restored Command:** 
        ```bash
        docker run --rm \
          -v ${{ github.workspace }}:/app \
          -w /app \
          ghcr.io/blue-build/cli:latest \
          bluebuild generate -o Containerfile recipes/recipe.yml
        ```
    *   **Rationale:** This command structure was proven to work in `0cfb7f3`.

2.  **Recipe Verification (`recipes/recipe.yml`):**
    *   **Action:** Visually inspected for "duplicate paste" errors or invalid YAML.
    *   **Result:** The file contains a single, valid `modules:` block with correct indentation. No duplicates found.

## ⏭️ Next Steps
The workflow has been reset to the known-good configuration. We now await the build results to see if the regression is resolved or if the issue lies within the *content* of the new recipe modules (e.g., `brew` or `fonts`).
