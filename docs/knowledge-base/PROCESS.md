# ⚙️ WavyOS Process Protocol

**Status:** Active
**Version:** 2.0 (The Interpreter Update)

---

## 1. The Core Workflow: "Interpreter Mode"

To prevent "Context Decay" and "Hallucination Drift," we utilize a strict 3-tier prompting architecture.

### Tier 1: The Architect (Cortex)
*   **Role:** Strategy, Requirements, "The Why."
*   **Output:** High-level specifications and architectural decisions.
*   **Interaction:** Human <-> Cortex.

### Tier 2: The Interpreter (Echo)
*   **Role:** The Filter. A low-temperature model that sanitizes Cortex's output.
*   **Function:**
    1.  Reads Cortex's strategy.
    2.  Converts it into strict, unambiguous CLI commands for Atlas.
    3.  Strips "flavor text," "metaphors," and "tarot references."
*   **Output:** Pure Prompt Engineering for the Engineer.

### Tier 3: The Engineer (Atlas)
*   **Role:** Execution, "The How."
*   **Function:** Runs the commands, writes the code, verifies the build.
*   **Constraint:** Never makes strategic decisions. Only executes.

---

## 2. The Daily Ritual

### Start of Session
1.  **Read:** `docs/knowledge-base/COMPENDIUM.md` (Strategy).
2.  **Read:** `.ai/status-report-latest.md` (Context).

### During Session
1.  **Atomic Commits:** `feat:`, `fix:`, `chore:` conventional commits.
2.  **Linting:** `just lint` before every commit.

### End of Session (The Save Point)
1.  **Generate:** `STATUS_REPORT.md` containing:
    *   Current State (Green/Red).
    *   Critical blockers.
    *   Next steps (Specific commands).
2.  **Commit:** `chore: save session state`.

---

## 3. The "Definition of Done"
A feature is COMPLETE when:
*   [ ] It exists in `recipes/` or `config/`.
*   [ ] It passes `shellcheck` and `just lint`.
*   [ ] It has been verified via `just test` (VM Boot).
*   [ ] It is documented in `COMPENDIUM.md` if it changes architecture.
