# Anton's Dotfiles: Omarchy + Nix

Personal dotfiles and declarative system configurations for **[Omarchy Linux](https://omarchy.org/) (Arch + Hyprland)** powered by **Nix**, **Home Manager**, and **direnv**.

---

## 🏗️ Architecture & Mental Model

```
┌────────────────────────────────────────────────────────┐
│               Omarchy (Arch Linux + Hyprland)           │
│                                                        │
│  Pacman / AUR                  Nix Ecosystem           │
│  ────────────────────────────  ──────────────────────  │
│  • Linux Kernel & Drivers      • Per-project runtimes  │
│  • Hyprland & Omarchy Shell    • Isolated dev tools    │
│  • Desktop apps (GUI/browsers) • Reproducible flakes   │
│  • Systemd services            • Home Manager dotfiles │
└────────────────────────────────────────────────────────┘
```

- **Pacman / AUR** manages system-level components and desktop software.
- **Nix** manages developer tooling, language runtimes, and isolated project shells.
- **Home Manager** declaratively manages user CLI tools, bash environment, and git configs.
- **direnv + nix-direnv** provides instantaneous per-project shell loading upon `cd`.

---

## 🚀 One-Line Deploy on a Fresh Machine

On a fresh Omarchy or Arch installation, run:

```bash
# 1. Authenticate with GitHub (repository is private)
gh auth login

# 2. Clone and run the all-in-one automated installer
git clone https://github.com/antonbenosapro/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

### What `install.sh` does automatically:
1. **Nix Engine:** Detects and installs the multi-user **Nix daemon** and enables `flakes` & `nix-command`.
2. **Symlinks Configs:** Links `hypr`, `omarchy`, `home-manager`, `direnv`, and `aether` configurations.
3. **Home Manager:** Bootstraps Home Manager and runs `home-manager switch`.
4. **Tooling & Shell:** Sets up modern CLI tools (`eza`, `bat`, `ripgrep`, `fd`, `fzf`, `just`, etc.) and git credentials.
5. **Package Restoration:** Prompts to restore native Arch (`pacman`) and AUR (`yay`/`paru`) packages from manifests.
6. **Auto-Sync Scheduler:** Enables the hourly **auto-sync systemd user timer** (`dotfiles-sync.timer`).
7. **Session Reload:** Refreshes and reloads your interactive shell session.

---

## 🛠️ Daily Cheatsheet & Aliases

### Nix & Home Manager Shortcuts
```bash
hms              # Apply edits made to ~/.config/home-manager/home.nix
ndev             # Manually drop into a project's dev shell (nix develop)
nrun <pkg>       # Run a binary directly from nixpkgs without installing (e.g. nrun nixpkgs#cowsay)
nsearch <pkg>    # Search available packages in nixpkgs
ngc              # Delete unreferenced packages and reclaim disk space (nix-collect-garbage -d)
dotsync          # Manually trigger immediate dotfiles commit & push to GitHub
```

### Modern Shell Aliases
```bash
ls               # eza --icons
ll               # eza -la --icons --git
lt               # eza --tree --icons (tree view)
cat              # bat --paging=never (syntax-highlighted cat)
grep             # rg (ripgrep)
find             # fd
df               # duf (clean disk usage overview)
top              # btop (resource monitor)
hx               # helix
```

---

## 📁 Working with Project Dev Environments

Every project can specify its exact tools and runtimes in a `flake.nix`:

### Starter Template
A template is ready at `~/projects/my-dev-env`:
```
~/projects/my-dev-env/
├── flake.nix       # Pinned tools and shell definition
├── flake.lock      # Exact revision locks
└── .envrc          # direnv trigger ('use flake')
```

### Starting a New Project with Nix + direnv
1. Create your project folder:
   ```bash
   mkdir -p ~/projects/awesome-app && cd ~/projects/awesome-app
   ```
2. Create a `flake.nix`:
   ```nix
   {
     inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
     outputs = { self, nixpkgs }:
     let
       system = "x86_64-linux";
       pkgs = nixpkgs.legacyPackages.${system};
     in {
       devShells.${system}.default = pkgs.mkShell {
         packages = with pkgs; [
           nodejs_20
           python312
           git
         ];
         shellHook = ''
           echo "🚀 awesome-app dev environment ready!"
         '';
       };
     };
   }
   ```
3. Enable auto-loading via direnv:
   ```bash
   echo "use flake" > .envrc
   direnv allow
   ```
4. **Behavior:**
   - On `cd ~/projects/awesome-app`: Tools are added to `$PATH` immediately.
   - On leaving the folder: Tools cleanly unload from `$PATH`. Zero global system pollution.

---

## ⏰ Automated GitHub Sync (systemd user timer)

Changes to your configurations are automatically tracked, committed, and pushed:
- **Timer:** `dotfiles-sync.timer` (runs hourly and on boot/wake)
- **Script:** `~/dotfiles/sync.sh`
- **Behavior:**
  - Syncs `~/.config/{home-manager,hypr,omarchy,direnv,aether}`.
  - Updates `packages/native-packages.txt` and `packages/aur-packages.txt`.
  - If changes exist: commits with timestamp and pushes to `origin main`.
  - If no changes: exits silently in <1 second.

### Useful Sync Commands
```bash
# Check timer schedule
systemctl --user list-timers dotfiles-sync.timer

# View sync logs
journalctl --user -u dotfiles-sync.service -n 20

# Force immediate sync
dotsync
```

---

## 📁 Repository Structure

```
~/dotfiles/
├── install.sh                  # All-in-one automated deployment script
├── sync.sh                     # Auto-sync script triggered by systemd timer
├── .gitignore
├── docs/
│   └── nix-omarchy-setup-guide.md
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
├── systemd/
│   └── user/                   # Systemd user timer & service for auto-sync
└── templates/
    └── my-dev-env/             # Portable per-project dev flake template
        ├── flake.nix
        ├── flake.lock
        └── .envrc
```

---

## 🧹 Maintenance & Clean Up

Nix does not delete old package generations automatically to guarantee rollbacks. When disk space is low:

```bash
# Delete all old generations and run garbage collection
ngc

# Check store size
du -sh /nix/store
```

---
*Maintained by Anton Benosa.*
