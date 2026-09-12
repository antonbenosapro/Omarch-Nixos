#!/usr/bin/env bash
# ==============================================================================
# Dotfiles Setup & Deployment Script for Omarchy (Arch) + Nix
# ==============================================================================
set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info()  { echo -e "${BLUE}==>${NC} $1"; }
ok()    { echo -e "${GREEN}✓${NC} $1"; }
warn()  { echo -e "${YELLOW}WARNING:${NC} $1"; }
error() { echo -e "${RED}ERROR:${NC} $1"; exit 1; }

echo ""
echo "🚀 Setting up Omarchy + Nix Dotfiles..."
echo "   Source: $DOTFILES_DIR"
echo ""

# 1. Check/Install Nix
if ! command -v nix &>/dev/null; then
    info "Nix package manager not found. Installing Nix daemon..."
    sh <(curl -L https://nixos.org/nix/install) --daemon --yes
    ok "Nix installed."
else
    ok "Nix is already installed."
fi

# Load Nix environment into current session
if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
    . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
fi

# 2. Configure Nix Flakes
info "Ensuring Nix flakes are enabled..."
mkdir -p ~/.config/nix
cat > ~/.config/nix/nix.conf << 'EOF'
experimental-features = nix-command flakes
EOF
ok "User nix.conf configured."

if command -v sudo &>/dev/null; then
    sudo mkdir -p /etc/nix
    echo "experimental-features = nix-command flakes" | sudo tee /etc/nix/nix.conf >/dev/null
    sudo systemctl restart nix-daemon 2>/dev/null || true
    ok "System /etc/nix/nix.conf configured."
fi

# 3. Symlink / Sync Configurations
info "Linking configurations..."
mkdir -p ~/.config

link_config() {
    local src="$1"
    local dest="$2"
    if [ -e "$dest" ] && [ ! -L "$dest" ]; then
        mv "$dest" "${dest}.bak.$(date +%s)"
    fi
    mkdir -p "$(dirname "$dest")"
    ln -sfn "$src" "$dest"
    ok "Linked $dest -> $src"
}

link_config "$DOTFILES_DIR/home-manager" "$HOME/.config/home-manager"
link_config "$DOTFILES_DIR/hypr"         "$HOME/.config/hypr"
link_config "$DOTFILES_DIR/omarchy"      "$HOME/.config/omarchy"
link_config "$DOTFILES_DIR/direnv"       "$HOME/.config/direnv"
[ -d "$DOTFILES_DIR/aether" ] && link_config "$DOTFILES_DIR/aether" "$HOME/.config/aether"

# 4. Install Home Manager if needed
if ! command -v home-manager &>/dev/null; then
    info "Setting up Home Manager..."
    nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager || true
    nix-channel --update || true
    nix-shell '<home-manager>' -A install || true
    ok "Home Manager initialized."
fi

# 5. Apply Home Manager switch
info "Activating Home Manager configuration..."
home-manager switch -b backup
ok "Home Manager configuration applied."

# 6. Pacman & AUR Packages Reminder
echo ""
echo "=============================================================================="
echo "🎉 Setup complete!"
echo "=============================================================================="
echo ""
echo "To reinstall native Arch / AUR packages on a fresh install, run:"
echo "  sudo pacman -S --needed - < $DOTFILES_DIR/packages/native-packages.txt"
if command -v yay &>/dev/null; then
    echo "  yay -S --needed - < $DOTFILES_DIR/packages/aur-packages.txt"
elif command -v paru &>/dev/null; then
    echo "  paru -S --needed - < $DOTFILES_DIR/packages/aur-packages.txt"
fi
echo ""
echo "Restart your terminal or run 'exec bash' to enjoy your updated setup!"
echo ""
