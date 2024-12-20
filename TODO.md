# TODO

## Nix packages and modules for tab-ui and backtab

- [x] Package tab-ui using a Nix flake
- [x] Package backtab using a Nix flake
- [ ] Create a NixOS module for running backtab as a systemd service
  - [ ] Consider sensitive information while building the backtab configuration file
- [ ] Add tab-ui and backtab packages and nixos modules as inputs to this nix-configs flake
- [ ] Update the barputer-test VM to get a working barputer setup, ideally using a staging / test tab
      repository (e.g. voidtab-test or something)

## NixOS on barputer hardware

- [ ] Check compatibility of touchscreen hardware with NixOS
- [ ] Install NixOS on barputer
- [ ] Set up remote nixos-rebuild in this flake
- [ ] Set up autoUpgrade from nix-configs flake hosted on Github

## NixOS for Stargazer

- [ ] Evaluate using Nix for Barputer / get potential approval from void members for using Nix on Stargazer
- [ ] Check compatibility of multiseat or consider need for multiseat?
- [ ] Convert screen casting proof of concept to declerative nixos configuration
- [ ] Build and deploy Stargazer test VM
- [ ] Install NixOS on Stargazer
- [ ] Set up remote nixos-rebuild in this flake
- [ ] Set up autoUpgrade from nix-configs flake hosted on Github
