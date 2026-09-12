{
  description = "My dev environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
  let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
  in {
    devShells.${system}.default = pkgs.mkShell {
      name = "my-dev-env";

      packages = with pkgs; [
        # Version control
        git
        gh           # GitHub CLI

        # Shell tools
        ripgrep      # fast grep
        fd           # fast find
        bat          # better cat
        eza          # better ls
        fzf          # fuzzy finder
        jq           # JSON processor

        # Dev tools
        just         # task runner (like make but simpler)
        httpie       # HTTP client

        # Languages (uncomment what you need)
        # nodejs_20
        # python312
        # go
        # rustup
      ];

      shellHook = ''
        echo ""
        echo "🚀 Dev environment loaded!"
        echo "   Nix: $(nix --version)"
        echo "   Git: $(git --version)"
        echo ""
      '';
    };
  };
}
