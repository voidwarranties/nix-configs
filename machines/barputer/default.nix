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
    loader.grub.enable = true;
    loader.grub.device = "/dev/sda";
    loader.grub.useOSProber = true;
  };

  services.openssh.enable = true;

  services.poweroffd = {
    enable = true;
    mqttHost = "10.98.71.22";
    mqttTopic = "computers/${config.networking.hostName}";
  };

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
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAXyGbpul93Y7ibDPqEdZxw7Tt8gIaTOmTOdlSNOak8i koen@devoegt.be"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHleKo03/jmf/ti0OGJF1it5FSP526Y7LSqyVfNDyEYc snow@lies"
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
    extraConfig = ''
      Section "InputClass"
        Identifier  "Invert Mouse"
        MatchProduct    "Elo Serial TouchScreen"
        MatchDevicePath "/dev/input/event*"
        Option      "InvertY"       "false"
        Option      "InvertX"       "false"
      EndSection

      Section "InputClass"
        Identifier	"calibration"
        MatchProduct	"Elo Serial TouchScreen"
        Driver "libinput"
        Option  "CalibrationMatrix" "-1 0 1 0 1 0 0 0 1"
      EndSection

      Section "InputDevice"
        Driver "elographics"
        Identifier "touchscreen"
        Option "ButtonNumber" "1"
        Option "ButtonThreshold" "17"
        Option "Device" "/dev/ttyS0"
        Option "InputFashion" "Touchpanel"
        Option "MinX" "0"
        Option "MaxX" "3977"
        Option "MinY" "96"
        Option "MaxY" "4062"
        Option "Name" "touchscreen"
        Option "ReportingMode" "Scaled"
        Option "SendCoreEvents" "on"
        Option "ScreenNo" "0"
      EndSection
    '';
  };
  services.displayManager.defaultSession = "none+i3";
  services.displayManager.autoLogin = {
    enable = true;
    user = "baruser";
  };

  systemd.services.elotouch = {
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      description = "Start touchscreen driver";
      serviceConfig = {
        ExecStart = ''${pkgs.linuxConsoleTools}/bin/inputattach -elo /dev/ttyS0''; 
      };
   };

  security.sudo.wheelNeedsPassword = false;

  users.users.baruser = {
    createHome = true;
    isNormalUser = true;
    extraGroups = ["networkmanager" "wheel"];
    initialPassword = "baruser";
  };

  users.users = {
    root = {
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILes7WTtBxDp1ILq+9iF1v2mmiQ0yFPprMREPUO240me m@Tatooine.local"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHleKo03/jmf/ti0OGJF1it5FSP526Y7LSqyVfNDyEYc snow@lies"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAXyGbpul93Y7ibDPqEdZxw7Tt8gIaTOmTOdlSNOak8i koen@devoegt.be"
      ];
    };
  };

  system.stateVersion = "24.11";
}
