# 🌊 The Wavy Protocol

**Philosophy:** Surgeons, not Butchers. Gourmet Chefs, not Line Cooks.
**Goal:** A stable, immutable, "Mac-like" Linux for Apple Silicon.

## 1. The Triad Workflow
1.  **The Architect (Gemini Web):** defines Strategy, Requirements, and Risk.
2.  **The Human (User):** Orchestrates, Reviews, and Approves.
3.  **The Engineer (Gemini CLI):** Executes, Lints, and Verifies locally.

## 2. Development Rules
*   **Atomic Commits:** One feature/fix per commit.
*   **Verify Locally:** Never push code that hasn't been syntax-checked locally.
*   **No Magic:** Do not use `sed` to patch files blindly. Rewrite the source of truth.
*   **State Awareness:** Always check the current directory (`pwd`) and file existence before writing.

## 3. The "Definition of Done"
A feature is NOT done until:
*   [ ] It passes linting (YAML/Shell).
*   [ ] The build is Green on GitHub.
*   [ ] It is verified in the VM (Boot + Functionality).

## 4. Branching Strategy
*   `main`: Protected. Gold Master candidates only.
*   `feat/name`: Feature development.
*   `fix/name`: Bug fixes.
*   **Merge Policy:** Squash and Merge.
