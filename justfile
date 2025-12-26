# 🛠️ WavyOS Build Center

default:
    @just --list

# 1. Git Workflow
push msg="update":
    bash scripts/lint.sh
    git add .
    git commit -m "{{ msg }}"
    git push

# 2. Testing
test tag="dev":
    bash scripts/test.sh {{ tag }}

test-clean tag="dev":
    podman system reset --force
    bash scripts/test.sh {{ tag }}

# 3. Development

# Enters the dev box defined in YOUR current system
dev:
    distrobox enter dev
