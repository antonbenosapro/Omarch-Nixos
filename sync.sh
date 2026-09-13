#!/usr/bin/env bash
# ==============================================================================
# Auto-sync script for Omarchy + Nix Dotfiles
# ==============================================================================
set -e

DOTFILES_DIR="$HOME/dotfiles"

# Ensure PATH has gh, nix, git, mise, and standard bins
export PATH="$HOME/.local/share/mise/shims:$HOME/.local/bin:/nix/var/nix/profiles/default/bin:$PATH"

# 1. Sync active configs from ~/.config into ~/dotfiles
rsync -a --exclude="*.bak*" "$HOME/.config/home-manager/" "$DOTFILES_DIR/home-manager/"
rsync -a --exclude="*.bak*" "$HOME/.config/hypr/" "$DOTFILES_DIR/hypr/"
rsync -a --exclude="*.bak*" --exclude="crash-ignore" --exclude=".git" "$HOME/.config/omarchy/" "$DOTFILES_DIR/omarchy/"
rsync -a --exclude="*.bak*" "$HOME/.config/direnv/" "$DOTFILES_DIR/direnv/"
[ -d "$HOME/.config/aether" ] && rsync -a "$HOME/.config/aether/" "$DOTFILES_DIR/aether/"
[ -f "$HOME/.config/nix/nix.conf" ] && cp "$HOME/.config/nix/nix.conf" "$DOTFILES_DIR/nix/"

# Sync developer tools & terminals
for tool in mise helix tmux lazygit alacritty foot ghostty kitty; do
    if [ -d "$HOME/.config/$tool" ]; then
        mkdir -p "$DOTFILES_DIR/config/$tool"
        rsync -a --exclude="*.bak*" "$HOME/.config/$tool/" "$DOTFILES_DIR/config/$tool/"
    fi
done
[ -f "$HOME/.config/starship.toml" ] && cp "$HOME/.config/starship.toml" "$DOTFILES_DIR/config/starship.toml"

# 2. Update installed package lists
pacman -Qqen > "$DOTFILES_DIR/packages/native-packages.txt" 2>/dev/null || true
pacman -Qqem > "$DOTFILES_DIR/packages/aur-packages.txt" 2>/dev/null || true

# 3. Check for modifications in dotfiles git repo
cd "$DOTFILES_DIR"

if [ -n "$(git status --porcelain)" ]; then
    git add .
    git commit -m "Auto-backup configs: $(date '+%Y-%m-%d %H:%M:%S')"
    git push origin main
    echo "✓ Dotfiles synced and pushed at $(date '+%Y-%m-%d %H:%M:%S')"
else
    echo "No changes to sync."
fi
