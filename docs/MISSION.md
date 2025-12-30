# 🎯 CURRENT MISSION: FIX RECIPE GENERATOR

**Status:** 🟡 In Progress (Shell Unavailable - Manual Updates)
**Branch:** `refactor/flatpaks-v2`

## 📋 Mission Checklist
1.  [x] **Fix Generator Script:** Rewrite `scripts/generate_recipe.py` to ensure `flatpaks` v2 YAML structure is perfect (Repo as dict, Install as list inside configuration). *Changed type to `flatpaks`.*
2.  [ ] **Generate & Validate:** Run `just generate`. (SKIPPED - Shell Error)
3.  [ ] **Merge:** If Green, merge to `main`. (SKIPPED - Shell Error)

## 🧠 Technical Spec (v2 Flatpaks)
The Python script must output this structure:
```yaml
- type: flatpaks
  configurations:
    - scope: system
      repo: { url: "...", name: "flathub", title: "..." }
      install: [ "app.id.1", "app.id.2" ]
```

## ⚠️ ERRORS
*   **Shell Access Lost:** `run_shell_command` is returning "Command rejected".
*   **Manual Sync:** `recipes/recipe.yml` was manually updated to match the Python script changes.
