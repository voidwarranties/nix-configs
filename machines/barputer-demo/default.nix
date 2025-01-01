{pkgs}: {modulesPath, ...}: let

  i3ConfigFile = pkgs.writeTextFile {
    name = "i3-config";
    text = builtins.readFile ./i3config;
  };
in {
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    (modulesPath + "/virtualisation/qemu-vm.nix")
  ];

  config = {
    virtualisation = {
      memorySize = 4096;
      cores = 4;
      qemu.options = [
        "-enable-kvm"
        "-vga virtio"
        "-display gtk,full-screen=on,grab-on-hover=on"
      ];
      forwardPorts = [
        {
          from = "host";
          host.port = 2222;
          guest.port = 22;
        }
      ];
    };

    nix.settings.experimental-features = ["nix-command" "flakes"];
    services.openssh.enable = true;
    services.backtab = {
      enable = true;

      # Point the URL below to the repository where the tab ledger is kept
      repositoryUrl = "git@github.com:voidwarranties/voidtab-testing.git";

      # Keys listed below allow users with the accompanying private key to log in as the backtab user via ssh
      # (provided openssh is enabled of course). This can be used to run `ssh-keygen` as the backtab user to generate a
      # public/private keypair to add as a (write enabled) deploy key to the tab ledger repository.
      authorizedKeys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILes7WTtBxDp1ILq+9iF1v2mmiQ0yFPprMREPUO240me"
      ];
    };
    environment.systemPackages = with pkgs; [
      git
      tab-ui
    ];

    networking.hostName = "barputer-demo";

    # Localization
    time.timeZone = "Europe/Brussels";
    i18n.defaultLocale = "en_US.UTF-8";

    services.xserver = {
      enable = true;
      xkb.layout = "us";
      xkb.variant = "dvorak";
      windowManager.i3 = {
        enable = true;
        extraPackages = with pkgs; [
          dmenu
        ];
        configFile = i3ConfigFile;
      };
    };
    services.displayManager.defaultSession = "none+i3";
    services.displayManager.autoLogin = {
      enable = true;
      user = "demo";
    };

    security.sudo.wheelNeedsPassword = false;
    users.users.demo = {
      createHome = true;
      isNormalUser = true;
      extraGroups = ["networkmanager" "wheel"];
      initialPassword = "demo";
    };

    system.stateVersion = "24.11";
  };
}
