# 🌊 WavyOS MVP Command Center

set shell := ["bash", "-c"]

branch := `git rev-parse --abbrev-ref HEAD`

default:
    @just --list

# Usage: just push "fix: attempt 1"
push msg="update":
    git add .
    git commit -m "{{ msg }}" || echo "⚠️ Nothing to commit..."
    git push --set-upstream origin {{ branch }}
    @echo "⏳ Waiting 10s for GitHub to start..."
    @sleep 10
    @# Watch the run. If it fails, exit.
    gh run watch $(gh run list --branch {{ branch }} --limit 1 --json databaseId -q '.[0].databaseId') --exit-status
