#!/bin/bash
# 🌊 WavyOS Welcome
# The "First Breath" experience.

# Colors
PRIMARY="#06b6d4"   # Cyan
SECONDARY="#8b5cf6" # Violet
TEXT="#e2e8f0"      # Slate

clear

# 1. Branding
gum style \
	--border double \
	--margin "1 2" \
	--padding "2 4" \
	--border-foreground "$PRIMARY" \
	--foreground "$PRIMARY" \
	"🌊  Welcome to WavyOS" \
	"   The atomic, creative bridge."

echo ""

# 2. Instructions
gum style --foreground "$TEXT" "Your system is ready. To install apps, Homebrew,"
gum style --foreground "$TEXT" "and developer tools, run this command:"

echo ""
gum style \
    --foreground "$SECONDARY" \
    --border rounded \
    --padding "0 2" \
    --border-foreground "$SECONDARY" \
    "just --justfile /etc/justfile setup"
echo ""

# 3. Interactive Pause
# We pause here so they see the message before the window vanishes (if not in a persistent shell)
gum confirm "Close this window?" && {
    # Disable autostart so this doesn't appear next boot
    mkdir -p ~/.config/autostart
    echo "[Desktop Entry]" > ~/.config/autostart/welcome.desktop
    echo "Type=Application" >> ~/.config/autostart/welcome.desktop
    echo "Hidden=true" >> ~/.config/autostart/welcome.desktop
    echo "X-GNOME-Autostart-enabled=false" >> ~/.config/autostart/welcome.desktop
}
