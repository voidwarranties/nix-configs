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

  outputs = { self, nixpkgs, devshell, ... }@inputs: 
  let
    system = "x86_64-linux";
    pkgs = (import nixpkgs {
      inherit system;
      overlays = [
        devshell.overlays.default
      ];
    });
  in {
    nixosConfigurations.barputer-test = nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [
        ./machines/barputer-test
      ];
    };

    packages = {
      "x86_64-linux" = {
        tab-ui = pkgs.stdenv.mkDerivation {
          pname = "tab-ui";
          version = "1.0";
          src = pkgs.fetchgit {
            url = "https://github.com/voidwarranties/tab-ui.git";
            rev = "90c0d413625e53826605c5b92fcc02e5b4a8b736";
            hash = "sha256-uQ/BIEYArVs0KIwfDNQbqxrTSbwZ6NIgW4KMwz7xSHk=";
            fetchSubmodules = true;
          };
          buildInputs = [ pkgs.qt5.full ];
          nativeBuildInputs = [ pkgs.libsForQt5.qmake pkgs.libsForQt5.qt5.wrapQtAppsHook ]; 
        };
      };
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
