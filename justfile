# Local Development Justfile

# 1. Build & Push
push msg="update":
    bash scripts/lint.sh
    git add .
    git commit -m "{{msg}}"
    git push

# 2. Test Cloud (UPDATED FILENAME)
test tag="dev":
    bash scripts/test.sh {{tag}}

# 3. Nuke & Test (UPDATED FILENAME)
test-clean tag="dev":
    podman system reset --force
    bash scripts/test.sh {{tag}}
