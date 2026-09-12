# Anton's Dotfiles: Omarchy + Nix

Personal dotfiles and declarative system configurations for **Omarchy Linux (Arch + Hyprland)** powered by **Nix**, **Home Manager**, and **direnv**.

---

## 🚀 One-Line Deploy on a Fresh Machine

On a fresh Omarchy or Arch installation, run:

```bash
git clone https://github.com/antonbenosapro/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

The script will automatically:
1. Detect and install the multi-user **Nix daemon** (with `flakes` & `nix-command`).
2. Symlink `hypr`, `omarchy`, `home-manager`, `direnv`, and `aether` configurations.
3. Install and activate **Home Manager** (`home-manager switch`).
4. Set up modern shell tools (`eza`, `bat`, `ripgrep`, `fd`, `fzf`, `just`, etc.) and git credentials.
5. Prompt to restore native Arch (`pacman`) and AUR (`yay`/`paru`) packages from manifests.
6. Enable the automated hourly **auto-sync systemd user timer** (`dotfiles-sync.timer`).
7. Reload your shell session.

---

## 📁 Repository Structure

```
~/dotfiles/
├── install.sh                  # Automated bootstrap script
├── .gitignore
├── packages/
│   ├── native-packages.txt     # Explicit native pacman packages
│   └── aur-packages.txt        # Explicit AUR packages
├── home-manager/
│   └── home.nix                # Declarative user packages, aliases & git
├── hypr/                       # Hyprland WM config (monitors, keybindings, animations)
├── omarchy/                    # Omarchy shell (status bar, widgets, custom themes)
├── aether/                     # Aether theme assets
├── direnv/
│   └── direnvrc                # nix-direnv caching integration
├── nix/
│   └── nix.conf                # Flakes and nix-command configuration
└── templates/
    └── my-dev-env/             # Portable per-project dev flake template
        ├── flake.nix
        ├── flake.lock
        └── .envrc
```

---

## 🔄 Daily Workflow

### Updating Configurations
When you modify files in `~/.config/home-manager/home.nix` or your Hyprland/Omarchy configs:

```bash
# If you edited Home Manager:
hms

# Commit and push changes to GitHub:
cd ~/dotfiles
git add .
git commit -m "Update configs"
git push
```

### Pulling Updates on Another Machine
```bash
cd ~/dotfiles
git pull
hms
```
