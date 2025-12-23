cd ~/Projects/asahi-atomic

# 1. Create .gitignore (Crucial: blocks build artifacts)
cat <<EOF > .gitignore
output/
*.img
.DS_Store
*.log
tmp/
EOF

# 2. Initialize Repo
git init
git branch -m main

# 3. Add Files
git add .

# 4. Commit
git commit -m "Initial Cortex Architecture: Base Build Pipeline Working"

echo "✅ Git Repository Initialized."
echo "   Next: Create a repo on GitHub and run:"
echo "   git remote add origin <your-github-url>"
echo "   git push -u origin main"
