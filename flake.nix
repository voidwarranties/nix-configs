{
  description = "barputer flake";

  inputs = {
    # NixOS official package source, using the nixos-24.11 branch here
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";

    devshell = {
      url = "github:numtide/devshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    devshell,
    ...
  } @ inputs: let
    system = "x86_64-linux";
    pkgs = import nixpkgs {
      inherit system;
      overlays = [
        devshell.overlays.default
      ];
    };
  in {
    nixosConfigurations.barputer-test = nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs.inputs = inputs;
      modules = [
        ./machines/barputer-test
      ];
    };
    formatter = {
      "x86_64-linux" = pkgs.alejandra;
    };

    devShells = {
      "x86_64-linux" = {
        default = pkgs.devshell.mkShell {
          name = "Barputer DevShell";
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
            {
              name = "barputer-vm";
              help = "run barputer config in a local vm, SSH available on port 2221";
              command = ''
                nix build .#nixosConfigurations.barputer-test.config.system.build.vm
                QEMU_NET_OPTS="hostfwd=tcp::2221-:22" result/bin/run-barputer-test-vm
              '';
            }
          ];
        };
      };
    };
  };
}
