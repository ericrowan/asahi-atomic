# 🌊 WavyOS Command Center
set shell := ["bash", "-c"]
branch := `git rev-parse --abbrev-ref HEAD`

default:
    @just --list

# 🚀 PUSH & WATCH (No Duplicates)
push msg="update":
    git add .
    git commit -m "{{ msg }}" || echo "⚠️ Nothing to commit..."
    git push
    @echo "⏳ Waiting for GitHub to register push..."
    @sleep 5
    @just watch

# 👀 WATCH LATEST RUN
watch:
    gh run watch $(gh run list --branch {{branch}} --limit 1 --json databaseId -q '.[0].databaseId') --exit-status
