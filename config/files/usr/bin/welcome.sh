#!/bin/bash
# 🌊 WavyOS Welcome Wizard
# Uses 'gum' for the UI.

# Colors (Wavy Palette)
PRIMARY="#06b6d4" # Cyan
SECONDARY="#8b5cf6" # Violet

# 1. The Splash Screen
clear
gum style \
	--border double \
	--margin "1 2" \
	--padding "2 4" \
	--border-foreground "$PRIMARY" \
	"🌊  Welcome to WavyOS" \
	"   The atomic, creative bridge."

gum style --foreground "$SECONDARY" "Let's set up your workspace."
echo ""

# 2. Keybindings Check
gum style --foreground "$PRIMARY" "⌨️  Keyboard Layout"
gum confirm "Enable macOS-style keybinds (Cmd=Ctrl)?" && {
    gsettings set org.gnome.desktop.input-sources xkb-options "['altwin:ctrl_win']"
    gum style --foreground "$GREEN" "✓ Keys swapped."
} || echo "Skipping keybinds."

# 3. The App Hydration
echo ""
gum style --foreground "$PRIMARY" "📦 Application Suite"
echo "We can install the WavyOS standard suite (Zed, Discord, Pika, etc.)"
gum confirm "Install standard applications?" && {
    # Run the setup logic (We can source the setup script or run commands directly)
    # For now, we inline the critical Flatpak logic
    gum spin --title "Configuring Flathub..." -- flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
    
    APPS=(
        "com.mattjakeman.ExtensionManager"
        "dev.zed.Zed"
        "org.gnome.Sushi"
        "org.gnome.World.PikaBackup"
        "org.mozilla.firefox"
        "io.github.flattool.Warehouse"
    )
    
    # Simple loop with spinner
    for app in "${APPS[@]}"; do
        gum spin --title "Installing $app..." -- flatpak install -y flathub "$app"
    done
    gum style --foreground "$SECONDARY" "✓ Apps installed."
}

# 4. Homebrew
echo ""
gum style --foreground "$PRIMARY" "🍺 Homebrew"
gum confirm "Install Homebrew (CLI Tools)?" && {
    # Non-interactive brew install
    gum spin --title "Downloading Homebrew..." -- \
    /bin/bash -c "NONINTERACTIVE=1 $(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # Path setup
    echo 'eval (/home/linuxbrew/.linuxbrew/bin/brew shellenv)' >> ~/.config/fish/config.fish
    gum style --foreground "$SECONDARY" "✓ Homebrew installed."
}

# 5. Cleanup & Self-Destruct
echo ""
gum style --border normal --border-foreground "$PRIMARY" "✨ Setup Complete. Enjoy the waves."
sleep 2

# Remove the autostart entry so this doesn't run again
rm -f ~/.config/autostart/wavy-welcome.desktop 2>/dev/null
# Also remove system-wide if we copied it to user home
