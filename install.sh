#!/usr/bin/env bash
# ==============================================================================
# Dotfiles Setup & Complete Deployment Script for Omarchy (Arch) + Nix
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

# ─────────────────────────────────────────────
# 1. Check / Install Nix Package Manager
# ─────────────────────────────────────────────
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

# ─────────────────────────────────────────────
# 2. Configure Nix Flakes & nix-command
# ─────────────────────────────────────────────
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

# ─────────────────────────────────────────────
# 3. Symlink User Configurations
# ─────────────────────────────────────────────
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

# ─────────────────────────────────────────────
# 4. Install & Activate Home Manager
# ─────────────────────────────────────────────
if ! command -v home-manager &>/dev/null; then
    info "Setting up Home Manager..."
    nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager || true
    nix-channel --update || true
    nix-shell '<home-manager>' -A install || true
    ok "Home Manager initialized."
fi

info "Activating Home Manager configuration..."
home-manager switch -b backup
ok "Home Manager configuration applied."

# ─────────────────────────────────────────────
# 5. Restore Native & AUR System Packages
# ─────────────────────────────────────────────
if command -v pacman &>/dev/null; then
    echo ""
    INSTALL_PKGS="y"
    if [ -t 0 ]; then
        read -r -p "Install native Arch & AUR system packages from manifests? [Y/n] " response
        response=${response:-y}
        [[ ! "$response" =~ ^[Yy]$ ]] && INSTALL_PKGS="n"
    fi

    if [ "$INSTALL_PKGS" = "y" ]; then
        if [ -f "$DOTFILES_DIR/packages/native-packages.txt" ]; then
            info "Installing native Arch packages via pacman..."
            sudo pacman -S --needed --noconfirm - < "$DOTFILES_DIR/packages/native-packages.txt" || warn "Some pacman packages failed to install."
            ok "Native packages installed."
        fi

        if [ -f "$DOTFILES_DIR/packages/aur-packages.txt" ]; then
            if command -v yay &>/dev/null; then
                info "Installing AUR packages via yay..."
                yay -S --needed --noconfirm - < "$DOTFILES_DIR/packages/aur-packages.txt" || warn "Some AUR packages failed to install."
                ok "AUR packages installed."
            elif command -v paru &>/dev/null; then
                info "Installing AUR packages via paru..."
                paru -S --needed --noconfirm - < "$DOTFILES_DIR/packages/aur-packages.txt" || warn "Some AUR packages failed to install."
                ok "AUR packages installed."
            else
                warn "Neither 'yay' nor 'paru' was found. Skipping AUR packages."
                echo "  You can install them later using: yay -S --needed - < $DOTFILES_DIR/packages/aur-packages.txt"
            fi
        fi
    fi
fi

# ─────────────────────────────────────────────
# 6. Enable Hourly Auto-Sync Timer
# ─────────────────────────────────────────────
info "Setting up automated dotfiles sync (systemd user timer)..."
mkdir -p ~/.config/systemd/user
if [ -d "$DOTFILES_DIR/systemd/user" ]; then
    cp "$DOTFILES_DIR/systemd/user/"* ~/.config/systemd/user/
    systemctl --user daemon-reload
    systemctl --user enable --now dotfiles-sync.timer 2>/dev/null || true
    ok "dotfiles-sync.timer enabled and active."
fi

# ─────────────────────────────────────────────
# 7. Complete & Shell Reload
# ─────────────────────────────────────────────
echo ""
echo "=============================================================================="
echo "🎉 Setup complete! All configurations, packages, and sync timers are active."
echo "=============================================================================="
echo ""

if [ -t 0 ] && [ -n "$PS1" ]; then
    read -r -p "Reload bash session now? [Y/n] " reload_resp
    reload_resp=${reload_resp:-y}
    if [[ "$reload_resp" =~ ^[Yy]$ ]]; then
        exec bash
    fi
else
    echo "Run 'exec bash' to refresh your current terminal session."
fi
