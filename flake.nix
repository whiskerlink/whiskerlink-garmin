{
  description = "NixOS-friendly Garmin Connect IQ / Monkey C development template";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
    in {
      devShells.${system}.default = pkgs.mkShell {
        packages = with pkgs; [
          jdk17
          openssl
          unzip
          zip
          libxml2
          go
          git
          curl
        ];

        shellHook = ''
          export JAVA_HOME="${pkgs.jdk17.home}"

          if [ -f ./scripts/env.sh ]; then
            source ./scripts/env.sh
          fi

          echo "Garmin Connect IQ dev shell"
          echo "  Java: $(java -version 2>&1 | head -n1)"

          if command -v connect-iq-sdk-manager >/dev/null 2>&1; then
            echo "  SDK manager CLI: $(command -v connect-iq-sdk-manager)"
          else
            echo "  SDK manager CLI: not installed"
            echo "  Run: ./scripts/install-sdk-manager-cli"
          fi

          if command -v monkeyc >/dev/null 2>&1; then
            echo "  monkeyc: $(command -v monkeyc)"
          else
            echo "  monkeyc: not available yet"
          fi
        '';
      };
    };
}
