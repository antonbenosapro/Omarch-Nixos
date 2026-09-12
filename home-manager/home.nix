{ config, pkgs, ... }:

{
  home.username = "anton";
  home.homeDirectory = "/home/anton";
  home.stateVersion = "26.05"; # Do not change this value.

  # ─────────────────────────────────────────────
  # User packages managed by Nix
  # These are available globally in your shell.
  # ─────────────────────────────────────────────
  home.packages = with pkgs; [
    # Modern shell utilities
    ripgrep      # fast grep (rg)
    fd           # fast find
    bat          # better cat (with syntax highlighting)
    eza          # better ls (with icons, git status)
    fzf          # fuzzy finder
    jq           # JSON processor
    yq-go        # YAML processor
    delta        # better git diffs
    duf          # better df (disk usage)
    dust         # better du (directory sizes)
    btop         # resource monitor (you likely have this via Omarchy)
    tldr         # simplified man pages

    # Dev tools
    just         # task runner (like make but readable)
    httpie       # friendly HTTP client (http/https commands)
    gh           # GitHub CLI
    git-lfs      # Git large file storage

    # Nix tools
    nix-tree     # visualize nix dependency trees
    nixpkgs-fmt  # format Nix files
  ];

  # ─────────────────────────────────────────────
  # Git configuration
  # ─────────────────────────────────────────────
  programs.git = {
    enable = true;
    settings = {
      user.name = "anton benosa";
      user.email = "antonbenosapro@gmail.com";
      init.defaultBranch = "master";
      pull.rebase = true;
      push.autoSetupRemote = true;
      alias = {
        co = "checkout";
        br = "branch";
        ci = "commit";
        st = "status";
      };
      credential."https://github.com".helper = "!/home/anton/.local/share/mise/shims/gh auth git-credential";
      credential."https://gist.github.com".helper = "!/home/anton/.local/share/mise/shims/gh auth git-credential";
    };
  };

  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      navigate = true;
      line-numbers = true;
      side-by-side = false;
    };
  };

  # ─────────────────────────────────────────────
  # Shell: bash
  # ─────────────────────────────────────────────
  programs.bash = {
    enable = true;
    enableCompletion = true;

    shellAliases = {
      # Modern replacements
      ls  = "eza --icons";
      ll  = "eza -la --icons --git";
      lt  = "eza --tree --icons";
      cat = "bat --paging=never";
      grep = "rg";
      find = "fd";
      df   = "duf";
      du   = "dust";
      top  = "btop";

      # Shortcuts
      ".."   = "cd ..";
      "..."  = "cd ../..";
      g      = "git";
      gs     = "git status";
      gp     = "git push";
      gpl    = "git pull";

      # Nix shortcuts
      hms    = "home-manager switch";
      ndev   = "nix develop";
      nrun   = "nix run";
      nsearch = "nix search nixpkgs";
      ngc    = "nix-collect-garbage -d";
    };

    initExtra = ''
      # Omarchy environment (OMARCHY_PATH + PATH)
      [[ -r /usr/share/omarchy/default/bash/env-bootstrap ]] && source /usr/share/omarchy/default/bash/env-bootstrap
      [[ -n "$OMARCHY_PATH" && -r "$OMARCHY_PATH/default/bash/rc" ]] && source "$OMARCHY_PATH/default/bash/rc"

      # User paths and aliases
      export PATH="/home/anton/.local/bin:$PATH"
      export PATH="/home/anton/.opencode/bin:$PATH"
      alias hx="helix"
      export COMP_KNOWN_HOSTS_WITH_HOSTFILE=

      # Load Nix daemon
      if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
        . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
      fi
    '';
  };

  # ─────────────────────────────────────────────
  # direnv — auto-load .envrc on folder entry
  # ─────────────────────────────────────────────
  programs.direnv = {
    enable = true;
    enableBashIntegration = true;
    nix-direnv.enable = true;  # use nix-direnv for caching
  };

  # ─────────────────────────────────────────────
  # fzf — fuzzy finder config
  # ─────────────────────────────────────────────
  programs.fzf = {
    enable = true;
    enableBashIntegration = true;
    defaultCommand = "fd --type f --hidden --follow --exclude .git";
    defaultOptions = [ "--height 40%" "--border" "--inline-info" ];
  };

  # ─────────────────────────────────────────────
  # Session variables
  # ─────────────────────────────────────────────
  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    PAGER  = "bat --paging=always";
  };

  # Let Home Manager manage itself.
  programs.home-manager.enable = true;
}
