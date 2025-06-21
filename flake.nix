{
  description = "Emacs Dev Env";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    system.url = "github:nix-systems/default";
    devenv.url = "github:cachix/devenv/v1.6.1";
  };

  outputs = { self, nixpkgs, devenv, systems, ... } @ inputs:
    let
      forEachSystem = nixpkgs.lib.genAttrs (import systems);
    in
    {
      # https://github.com/cachix/devenv/issues/756#issuecomment-1941486375
      packages = forEachSystem (system: {
        devenv-up = self.devShells.${system}.default.config.procfileScript;
      });

      devShells = forEachSystem (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = devenv.lib.mkShell {
            inherit inputs pkgs;
            modules = [
              {
                # Core packages needed for development
                packages = with pkgs; [
                  emacs
                  mermaid-cli
                  nodejs
                ];

                enterShell = ''
                  # Auto-detect Puppeteer-managed Chrome using npx
                  DETECTED_CHROME=$(npx puppeteer browsers list 2>/dev/null | grep -m1 'chrome@' | sed -E 's/.*\(([^)]+)\) //')
                  if [ -n "$DETECTED_CHROME" ]; then
                    export PUPPETEER_EXECUTABLE_PATH="$DETECTED_CHROME"
                    echo "Auto-set PUPPETEER_EXECUTABLE_PATH to $PUPPETEER_EXECUTABLE_PATH"
                  else
                    echo "No Puppeteer-managed Chrome detected by npx. Please set PUPPETEER_EXECUTABLE_PATH manually if needed."
                  fi
                '';
              }
            ];
          };
        }
      );
    };
}
