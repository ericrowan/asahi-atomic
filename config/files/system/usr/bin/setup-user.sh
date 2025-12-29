#!/bin/bash
# ──────────────────────────────────────────────────────────────────────────────
#  PROJECT CORTEX: USER HYDRATION
# ──────────────────────────────────────────────────────────────────────────────
set -e
echo "💧 Hydrating User Space..."

# Debug Mode
if [[ "$1" == "--debug" ]]; then
    set -x
    echo "🐞 Debug Mode Enabled"
fi

# Define System Paths
CONFIG_DIR="/usr/share/asahi-atomic"
FLATPAK_LIST="$CONFIG_DIR/flatpaks.txt"
DISTROBOX_INI="$CONFIG_DIR/distrobox.ini"

# 1. PREPARE HOMEBREW
if [ ! -d "/home/linuxbrew/.linuxbrew" ]; then
    echo "🍺 Preparing Homebrew..."
    sudo mkdir -p /var/home/linuxbrew/.linuxbrew
    sudo chown -R "$(whoami):$(whoami)" /var/home/linuxbrew/.linuxbrew
    if [ ! -L "/home/linuxbrew" ]; then sudo ln -sf /var/home/linuxbrew /home/linuxbrew; fi

    echo "   Installing Homebrew..."
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Configure Fish path (Optimistic)
    mkdir -p ~/.config/fish
    echo 'eval (/home/linuxbrew/.linuxbrew/bin/brew shellenv)' >> ~/.config/fish/config.fish
fi

# 2. INSTALL CLI TOOLS (Brew)
echo "🍺 Installing CLI Power Tools..."
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

# The Definitive User Toolset
bat \
btop \
eza \
fastfetch \
fzf \
gh \
gum \
htop \
lazygit \
mc \
nvtop \
p7zip \
ripgrep \
starship \
zoxide

# 3. CONFIGURE SHELL (Post-Brew)
# Since Fish is now installed via Brew, add it to /etc/shells and chsh
if ! grep -q "$(which fish)" /etc/shells; then
    echo "🐟 Adding Fish to /etc/shells..."
    command -v fish | sudo tee -a /etc/shells
fi
# Note: We can't script chsh without password prompt, user must do it manually or via Gum prompt later

# 4. FLATHUB & APPS
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
if [ -f "$FLATPAK_LIST" ]; then
    echo "📦 Installing Flatpaks..."
    mapfile -t APPS < <(grep -vE '^\s*#|^\s*$' "$FLATPAK_LIST")
    if [ ${#APPS[@]} -gt 0 ]; then flatpak install -y flathub "${APPS[@]}"; fi
fi

# 5. DISTROBOX
if [ -f "$DISTROBOX_INI" ]; then
    echo "📦 Assembling Distroboxes..."
    if command -v distrobox &> /dev/null; then distrobox assemble create --file "$DISTROBOX_INI"; fi
fi

echo "✨ User Space Ready."
