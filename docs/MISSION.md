# 🎯 CURRENT MISSION: STABILIZE RECIPE GENERATOR

**Status:** 🔴 Broken (Validation Failed)
**Owner:** Atlas
**Branch:** `refactor/flatpaks-v2`

## 📋 Mission Checklist
1.  [ ] **Diagnose:** Run validation manually to capture the specific error message (currently hidden by `just`).
2.  [ ] **Fix:** Edit `scripts/generate_recipe.py` to resolve the specific YAML structure error.
3.  [ ] **Verify:** Run `just generate` successfully.
4.  [ ] **Cleanup:** Remove temporary debug artifacts.

## 🧠 Context
*   **Issue:** `just generate` fails at the validation step.
*   **Hypothesis:** The Python script is generating invalid YAML for the BlueBuild v2 schema.
