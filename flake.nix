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

    packages = {
      "x86_64-linux" = {
        tab-ui = let
          version = "90c0d413625e53826605c5b92fcc02e5b4a8b736";
        in
          pkgs.stdenv.mkDerivation {
            pname = "tab-ui";
            version = builtins.substring 0 7 version;
            src = pkgs.fetchgit {
              url = "https://github.com/voidwarranties/tab-ui.git";
              rev = version;
              hash = "sha256-uQ/BIEYArVs0KIwfDNQbqxrTSbwZ6NIgW4KMwz7xSHk=";
              fetchSubmodules = true;
            };
            buildInputs = [pkgs.qt5.full];
            nativeBuildInputs = [pkgs.libsForQt5.qmake pkgs.libsForQt5.qt5.wrapQtAppsHook];
          };

        backtab = let
          version = "c39595e5764134864cab09408ba234db7f933501";
        in
          pkgs.python3Packages.buildPythonPackage {
            pname = "backtab";
            version = builtins.substring 0 7 version;
            src = pkgs.fetchFromGitHub {
              owner = "voidwarranties";
              repo = "backtab";
              rev = version;
              hash = "sha256-/H7WPiZeAvLcp8ZjspwdCm0GG8Z/hk7zQgIuycIXkTQ=";
            };
            propagatedBuildInputs = with pkgs.python3Packages; [
              beancount
              bottle
              click
              pyyaml
              sdnotify
            ];
            meta.mainProgram = "backtab-server";
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
