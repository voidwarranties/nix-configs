{
  pkgs,
  lib,
  config,
  ...
}: let
  i3ConfigFile = pkgs.writeTextFile {
    name = "i3-config";
    text = builtins.readFile ./i3config;
  };
in {
  imports = [
    ./hardware-configuration.nix
  ];

  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = ["nix-command" "flakes"];

  networking.interfaces.enp2s0.wakeOnLan.enable = true;

  boot = {
    consoleLogLevel = 0;
    kernelParams = ["quiet"];
    initrd.verbose = false;
    loader.grub.enable = true;
    loader.grub.device = "/dev/sda";
    loader.grub.useOSProber = true;
    #loader.systemd-boot.enable = true;
    #loader.systemd-boot.configurationLimit = 3;
    #loader.systemd-boot.graceful = true;
    #loader.efi.canTouchEfiVariables = true;
    plymouth = {
      enable = true;
      theme = "breeze";
    };
  };

  services.openssh.enable = true;

  services.backtab = {
    enable = true;

    # Point the URL below to the repository where the tab ledger is kept
    repositoryUrl = "git@github.com:voidwarranties/voidtab.git";

    # Keys listed below allow users with the accompanying private key to log in as the backtab user via ssh
    # (provided openssh is enabled of course). This can be used to run `ssh-keygen` as the backtab user to generate a
    # public/private keypair to add as a (write enabled) deploy key to the tab ledger repository.
    authorizedKeys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILes7WTtBxDp1ILq+9iF1v2mmiQ0yFPprMREPUO240me"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJM++IIAAG4SJLCDRv3MQ/CoX9CQg/8XhQeJc2uevkv2 eline@stargazer"
    ];
  };

  environment.systemPackages = with pkgs; [
    git
    tab-ui
    linuxConsoleTools
  ];

  networking.hostName = "barputer";

  # Localization
  time.timeZone = "Europe/Brussels";
  i18n.defaultLocale = "en_US.UTF-8";

  services.xserver = {
    enable = true;
    xkb.layout = "be";
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

  users.users = {
    root = {
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILes7WTtBxDp1ILq+9iF1v2mmiQ0yFPprMREPUO240me m@Tatooine.local"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBa9WsiF3b7e6pszbbDtu7PuwiZemDcfI02n832tVcIX"
      ];
    };
  };

  system.stateVersion = "24.11";
}
