# Omarchy + Nix Dev Environment Reference Guide

This document summarizes the installation, configuration, and day-to-day workflow for the **Nix + Home Manager + direnv** setup on **Omarchy (Arch Linux + Hyprland)**.

---

## 1. System Architecture & Mental Model

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
- **Nix** manages developer tooling and isolated environments.
- **Omarchy configurations** remain clean and undisturbed.

---

## 2. Core Components Installed

| Component | Version | Location / Config | Role |
|---|---|---|---|
| **Nix Daemon** | `2.35.2` | `/nix/store/`, `/etc/nix/nix.conf` | Multi-user package manager & sandbox build users |
| **Flakes & nix-command** | Enabled | `~/.config/nix/nix.conf` | Modern, hermetic package pinning and evaluation |
| **Home Manager** | Unstable (`26.05`) | `~/.config/home-manager/home.nix` | Declarative user packages, bash environment, git setup |
| **direnv** | `2.37.1` | `~/.bashrc` hook | Automatically activates project environments on `cd` |
| **nix-direnv** | `3.2.0` | `~/.config/direnv/direnvrc` | Caches flake evaluations for instantaneous directory switching |

---

## 3. Key Configuration Files

- **Home Manager Configuration:**  
  `~/.config/home-manager/home.nix`  
  *Contains user packages (`ripgrep`, `fd`, `bat`, `eza`, `just`, `fzf`, `gh`, etc.), bash aliases, and git configs.*
- **Nix Daemon Configuration:**  
  `/etc/nix/nix.conf` & `~/.config/nix/nix.conf`  
  *Enables `experimental-features = nix-command flakes`.*
- **Direnv Configuration:**  
  `~/.config/direnv/direnvrc`  
  *Sources `nix-direnv` to enable fast shell caching.*
- **Backed-up Original Files (pre-migration):**  
  - `~/.bashrc.backup`
  - `~/.bash_profile.backup`
  - `~/.config/git/config.backup`

---

## 4. Daily Commands & Shortcuts

### Nix & Home Manager Shortcuts
```bash
hms              # home-manager switch (apply edits in ~/.config/home-manager/home.nix)
ndev             # nix develop (manually drop into a project's dev shell)
nrun <pkg>       # nix run (execute a binary directly from nixpkgs without installing)
nsearch <pkg>    # nix search nixpkgs <pkg> (search available packages)
ngc              # nix-collect-garbage -d (delete unreferenced packages and free disk space)
```

### Modern Shell Aliases (configured in bash)
```bash
ls               # eza --icons
ll               # eza -la --icons --git
lt               # eza --tree --icons
cat              # bat --paging=never
grep             # rg (ripgrep)
find             # fd
df               # duf
top              # btop
hx               # helix
```

---

## 5. Working with Project Dev Environments

### Starter Project Template
A ready-to-use template was created at:
```bash
~/projects/my-dev-env/
├── flake.nix       # Pinned tools and shell definition
├── flake.lock      # Exact revision locks
└── .envrc          # direnv trigger ('use flake')
```

### Starting a New Project with Nix
1. Create your project folder:
   ```bash
   mkdir -p ~/projects/awesome-app && cd ~/projects/awesome-app
   ```
2. Create a minimal `flake.nix`:
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
           echo "Welcome to awesome-app dev shell!"
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
4. Every time you enter the directory:
   - Tools are added to `$PATH` immediately.
   - Every time you leave the directory:
   - Environment unloads, keeping your system clean.

---

## 6. Maintenance & Clean Up

Nix does not delete old package versions automatically to guarantee rollbacks. When disk space runs low:

```bash
# Delete all old generations and run garbage collection
ngc

# Check store size
du -sh /nix/store
```

---

## 7. Replicating This Setup on Another Machine 🚀

Your entire setup is now backed up to your private GitHub dotfiles repository:
👉 `https://github.com/antonbenosapro/dotfiles`

### To reproduce this exact environment on any fresh Omarchy / Arch machine:
```bash
# 1. Authenticate with GitHub (since the repo is private)
gh auth login

# 2. Clone and run the all-in-one installer:
git clone https://github.com/antonbenosapro/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

**The installer will automatically handle:**
- Installing Nix daemon & enabling flakes
- Symlinking Hyprland, Omarchy, Home Manager & direnv configs
- Activating Home Manager (`home-manager switch`)
- Reinstalling native Arch & AUR system packages from manifests
- Enabling the hourly auto-sync timer (`dotfiles-sync.timer`)
- Reloading your shell session

---
*Created on 2026-09-13 for user Anton on Omarchy.*
