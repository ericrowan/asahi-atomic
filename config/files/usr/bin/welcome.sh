#!/bin/bash
# Welcome Wizard (TUI)
# Runs on first login.

# Colors
PRIMARY="#06b6d4" # Cyan
SECONDARY="#8b5cf6" # Violet

clear

# 1. Branding / Intro
gum style \
	--border double \
	--margin "1 2" \
	--padding "2 4" \
	--border-foreground "$PRIMARY" \
	"👋  Welcome to Atomic" \
	"   Your system is ready."

echo ""
gum style --foreground "$SECONDARY" "Let's set up your workspace."
echo ""

# 2. Keybindings
gum style --foreground "$PRIMARY" "⌨️  Keyboard Layout"
if gum confirm "Enable macOS-style keybinds (Cmd=Ctrl)?"; then
    gsettings set org.gnome.desktop.input-sources xkb-options "['altwin:ctrl_win']"
    gum style --foreground "$GREEN" "✓ Keys swapped."
else
    echo "Skipping keybinds."
fi

# 3. User Setup Script Handoff
echo ""
gum style --foreground "$PRIMARY" "📦 Application Setup"
echo "We can run the hydration script to install Apps and Homebrew."

if gum confirm "Run setup-user.sh now?"; then
    # We assume the user has cloned the repo or we curl it.
    # For the VM test, we will check if the file exists in the repo path.
    SETUP_SCRIPT="$HOME/asahi-atomic/scripts/setup-user.sh"

    if [ -f "$SETUP_SCRIPT" ]; then
        bash "$SETUP_SCRIPT"
    else
        # Fallback if repo isn't cloned yet
        gum style --foreground "red" "❌ Setup script not found at $SETUP_SCRIPT"
        echo "Please clone the repository to run the full setup."
    fi
fi

# 4. Cleanup
echo ""
gum style --border normal --border-foreground "$PRIMARY" "✨ Complete. You may close this window."

# Disable this script from running again
mkdir -p ~/.config/autostart
echo "X-GNOME-Autostart-enabled=false" >> ~/.config/autostart/welcome.desktop
