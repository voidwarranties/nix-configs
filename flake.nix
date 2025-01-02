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

  outputs = {
    self,
    nixpkgs,
    devshell,
    backtab,
    tab-ui,
    ...
  } @ inputs: let
    # This list of architectures provides the supported systems to the wrapper function below.
    # It basically defines which architectures can manage the VoidWarranties infrastructure using this flake.
    supportedSystems = [
      "aarch64-darwin"
      "x86_64-linux"
    ];

    # This helper function is used to make the flake outputs below more DRY. It looks a bit intimidating but that's
    # mostly because of the functional programming nature of Nix. I recommend reading
    # [Nix language basics](https://nix.dev/tutorials/nix-language.html) and search online for resources about
    # functional programming paradigms.
    #
    # Basically this function makes it so that instead of declaring outputs for every architecture as the flake schema
    # expects, e.g.:
    #
    # packages = {
    #   "x86_64-linux" = {
    #     ...
    #   };
    #   "aarch64-darwin" = {
    #     ...
    #   };
    # };
    #
    # we can define each output below (package, formatter, ...) once for all the architectures / systems.
    #
    # See https://ayats.org/blog/no-flake-utils to learn more.
    #
    forAllSystems = function:
      nixpkgs.lib.genAttrs supportedSystems (system:
        function (import nixpkgs {
          inherit system;
          overlays = [
            devshell.overlays.default
            inputs.tab-ui.overlays.default
          ];
        }));
  in {
    formatter = forAllSystems (pkgs: pkgs.alejandra);

    packages = forAllSystems (pkgs: {
      barputer-demo =
        (inputs.nixpkgs.lib.nixosSystem {
          system = pkgs.system;
          modules = [
            ({pkgs, ...}: {
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
    });

    devShells = forAllSystems (pkgs: {
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
    });
  };
}
