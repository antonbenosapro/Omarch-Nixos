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

# Link developer tools & terminals
if [ -d "$DOTFILES_DIR/config" ]; then
    for tool_path in "$DOTFILES_DIR/config"/*; do
        tool_name="$(basename "$tool_path")"
        if [ "$tool_name" = "starship.toml" ]; then
            link_config "$tool_path" "$HOME/.config/starship.toml"
        else
            link_config "$tool_path" "$HOME/.config/$tool_name"
        fi
    done
fi

# ─────────────────────────────────────────────
# 4. Bootstrap 'mise' Version Manager & Runtimes
# ─────────────────────────────────────────────
if ! command -v mise &>/dev/null; then
    info "Installing mise version manager..."
    curl -fsSL https://mise.run | sh || warn "Could not install mise via curl."
    export PATH="$HOME/.local/bin:$PATH"
fi

if command -v mise &>/dev/null; then
    info "Installing mise toolchains (Node, Claude, Gemini, OpenCode, etc.)..."
    mise install -y 2>/dev/null || warn "Some mise tools failed to install."
    ok "mise toolchains ready."
fi

# ─────────────────────────────────────────────
# 5. Install & Activate Home Manager
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
# 6. Restore Native & AUR System Packages
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

        # Ensure yay is available if AUR packages are requested
        if [ -f "$DOTFILES_DIR/packages/aur-packages.txt" ]; then
            if ! command -v yay &>/dev/null && ! command -v paru &>/dev/null; then
                info "Bootstrapping 'yay' AUR helper..."
                sudo pacman -S --needed --noconfirm base-devel git
                git clone https://aur.archlinux.org/yay-bin.git /tmp/yay-bin
                (cd /tmp/yay-bin && makepkg -si --noconfirm) || warn "Failed to build yay-bin."
                rm -rf /tmp/yay-bin
            fi

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
            fi
        fi
    fi
fi

# ─────────────────────────────────────────────
# 7. Optional SSH Key Setup for GitHub
# ─────────────────────────────────────────────
if [ ! -f "$HOME/.ssh/id_ed25519" ]; then
    echo ""
    GEN_SSH="y"
    if [ -t 0 ]; then
        read -r -p "Generate and upload a new SSH key to your GitHub account? [Y/n] " ssh_resp
        ssh_resp=${ssh_resp:-y}
        [[ ! "$ssh_resp" =~ ^[Yy]$ ]] && GEN_SSH="n"
    fi

    if [ "$GEN_SSH" = "y" ]; then
        mkdir -p "$HOME/.ssh"
        chmod 700 "$HOME/.ssh"
        ssh-keygen -t ed25519 -C "antonbenosapro@gmail.com" -f "$HOME/.ssh/id_ed25519" -N ""
        ok "SSH key generated at ~/.ssh/id_ed25519"
        if command -v gh &>/dev/null && gh auth status &>/dev/null; then
            gh ssh-key add "$HOME/.ssh/id_ed25519.pub" --title "$(hostname)-$(date +%Y%m%d)" || true
            ok "SSH public key registered with your GitHub account."
        fi
    fi
fi

# ─────────────────────────────────────────────
# 8. Enable Hourly Auto-Sync Timer
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
# 9. Complete & Shell Reload
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
