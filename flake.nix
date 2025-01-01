{
  description = "VoidWarranties infrastructure flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";

    devshell = {
      url = "github:numtide/devshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    backtab = {
      url = "github:voidwarranties/backtab?ref=nixos-module";
      inputs = {
        nixpkgs.follows = "nixpkgs";
      };
    };

    tab-ui = {
      url = "github:voidwarranties/tab-ui";
      inputs = {
        nixpkgs.follows = "nixpkgs";
      };
    };
  };

  outputs = { self, nixpkgs, devshell, backtab, tab-ui, ... }@inputs:
  let
    system = "x86_64-linux";
    pkgs = (import nixpkgs {
      inherit system;
      overlays = [
        devshell.overlays.default
        inputs.tab-ui.overlays.default
      ];
    });
  in {
    packages = {
      "x86_64-linux" = {
        barputer-demo =
          (inputs.nixpkgs.lib.nixosSystem {
            inherit system;
            modules = [
              ({ pkgs, ... }: {
                nixpkgs.overlays = [
                  inputs.backtab.overlays.default
                ];
              })
              inputs.backtab.nixosModules.backtab
              (import ./machines/barputer-demo {inherit pkgs;})
            ];
          })
          .config
          .system
          .build
          .vm;
      };
    };

    devShells = {
      "x86_64-linux" = {
        default = pkgs.devshell.mkShell {
          name = "VoidWarranties infrastructure shell";
          packages = with pkgs; [
            nixos-rebuild
          ];
          commands = [
            {
              name = "barputer-deploy";
              help = "deploys the barputer to a given host";
              command = ''
                host=$1
                shift
                nixos-rebuild --flake ".#$host" \
                  --build-host $host \
                  --target-host $host \
                  --use-remote-sudo \
                  --fast \
                "$@"
              '';
            }
          ];
        };
      };
    };
  };
}
