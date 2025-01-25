# nix-configs
Nix configurations for various machines and software used at voidwarranties.  

## Barputer
### Demo
A demo vm configuration for the barputer can be run using `nix run .#barputer-demo`. This will use https://github.com/voidwarranties/backtab and https://github.com/voidwarranties/tab-ui.

### Deployment
Clone this repository to a local machine (with nix and flakes available) which we will use as the host to configure our deployment.

#### Prepare target (once)
1. Install NixOS on target machine
2. Enable nix-command and flakes: `nix.settings.experimental-features = [ "nix-command" "flakes" ];`
3. Permit root login over ssh: `services.openssh.settings.PermitRootLogin = "yes";`
4. Take note of any hardware specific changes you might apply, add them to `/machines/barputer/default.nix` if needed
5. Overwrite `/machines/barputer/hardware-configuration.nix` with the `hardware-configuration.nix` from the target machine

#### Prepare host (once)
1. Edit your ssh config and add the ip-address of the target machine:
   ```
   Host barputer
     Hostname 0.0.0.0
     User root
   ```
2. Use `ssh-copy-id barputer` to copy over the public key of your host to the target machine (this makes deployment easier)
3. Test the connection: `ssh barputer`

#### Deploying NixOS config
1. Use `nix develop` in the repository to enter the provided devshell
2. Deploy to target with `barputer-deploy barputer boot`. This will build the configuration on the target machine, make it the default boot option, but won't activate until next boot
