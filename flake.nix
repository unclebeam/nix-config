{
  # A flake has two halves: `inputs` (what we pull in, pinned in flake.lock)
  # and `outputs` (what this repo provides — here, two NixOS system configs).
  description = "unclebeam's NixOS machines: desktop (PC) + ThinkPad";

  inputs = {
    # NixOS 26.05 "Yarara" — the current stable release branch.
    # `nix flake update` later moves the pin forward within this branch.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    # A SECOND nixpkgs tracking unstable. Used ONLY to source a curated set of
    # fast-moving packages (claude-code, lazygit, starship);
    # everything else stays on nixos-26.05. Deliberately NOT `follows` nixpkgs —
    # it must be its own package set, or those packages would rebuild against
    # 26.05 deps and defeat the purpose. mkHost instantiates it once (with
    # allowUnfree) and hands it to every module as `pkgs-unstable`.
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    # home-manager manages per-user config (dotfiles, niri config, the DMS shell…).
    # Its release branch must match the nixpkgs release.
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      # Make home-manager use OUR nixpkgs instead of pulling its own copy —
      # one package set, no version skew, smaller closure.
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # disko — declarative disk partitioning. A host describes its disks as
    # Nix (hosts/<name>/disko.nix) and disko turns that into the actual
    # partitioning/formatting commands. nixos-anywhere uses it to wipe and
    # install a machine over SSH in one shot, and NixOS reuses the same
    # declaration to generate the fileSystems.* mount config.
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Zen Browser is not in nixpkgs at all — this community flake repackages
    # the official releases. It ships only packages (no NixOS module), so
    # nothing gets wired into mkHost; core.nix pulls the package straight
    # out of `inputs` (available there via specialArgs below).
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        home-manager.follows = "home-manager";
      };
    };

    # DankMaterialShell (DMS) — the quickshell-based desktop shell that IS
    # the whole desktop: bar, launcher, notifications, lock screen, OSD,
    # clipboard history, polkit agent, power menu, wallpaper + matugen
    # theming. Ships a home-manager module (the shell itself, enabled in
    # home/dms.nix) and NixOS modules (system defaults in modules/dms.nix,
    # greetd login greeter in modules/dms-greeter.nix). `stable` branch per
    # the official docs. Note: dms-shell builds from source (Go + QML) —
    # there is no binary cache, so the first rebuild compiles it.
    dank-material-shell = {
      url = "github:AvengeMedia/DankMaterialShell/stable";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-unstable,
      home-manager,
      disko,
      dank-material-shell,
      ...
    }@inputs:
    let
      # Small helper so each host is a one-liner below.
      # `nixosSystem` evaluates a list of modules into a bootable system.
      mkHost =
        hostName:
        let
          system = "x86_64-linux";
          # The unstable package set, evaluated ONCE here with allowUnfree so
          # unfree picks like claude-code resolve. Shared to every module via
          # specialArgs/extraSpecialArgs below as `pkgs-unstable`; consumers
          # just write `pkgs-unstable.<name>` to pull that one package.
          pkgs-unstable = import nixpkgs-unstable {
            inherit system;
            config.allowUnfree = true;
          };
        in
        nixpkgs.lib.nixosSystem {
          inherit system;
          # Everything in specialArgs is passed as an argument to every module,
          # so modules can refer to `inputs` if they ever need another flake.
          specialArgs = { inherit inputs pkgs-unstable; };
          modules = [
            # The per-host entrypoint. Everything else is imported from there —
            # this keeps the flake itself boring and the hosts/ dirs in charge.
            ./hosts/${hostName}

            # disko's NixOS module. Loading it only ADDS the `disko.devices`
            # option — it does nothing until a host actually declares disks.
            # Both hosts do, in hosts/<name>/disko.nix.
            disko.nixosModules.disko

            # DMS's NixOS modules. Same deal as disko: loading them only adds
            # options. The shell module (system-side service defaults) is
            # enabled by modules/dms.nix; the greeter module (greetd + DMS
            # greeter UI) is enabled by modules/dms-greeter.nix.
            dank-material-shell.nixosModules.dank-material-shell
            dank-material-shell.nixosModules.greeter

            # Wire home-manager in as a NixOS module: `nixos-rebuild switch`
            # builds system AND user config in one transaction.
            home-manager.nixosModules.home-manager
            {
              # Use the system's nixpkgs (with its allowUnfree etc.) for user
              # packages too, and install them via the system profile.
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              # The shared user environment — identical on both machines.
              home-manager.users.unclebeam = import ./home;
              # On rebuild, keep any pre-existing conflicting dotfile as
              # <name>.backup instead of aborting the whole switch.
              home-manager.backupFileExtension = "backup";
              # Make pkgs-unstable and inputs reachable from home/ modules too
              # (mirrors the system-level specialArgs above): home/fish.nix
              # etc. pull individual packages from unstable, and home/dms.nix
              # imports the DMS home-manager module out of `inputs` — module
              # imports can only come from specialArgs, not ordinary args.
              home-manager.extraSpecialArgs = { inherit inputs pkgs-unstable; };
            }
          ];
        };
    in
    {
      # IMPORTANT: these attribute names must equal each machine's
      # `networking.hostName`. That's what lets a bare
      # `sudo nixos-rebuild switch --flake .` pick the right config
      # on whichever machine you run it.
      nixosConfigurations = {
        unclebeam-pc = mkHost "unclebeam-pc";
        unclebeam-thinkpad = mkHost "unclebeam-thinkpad";
      };
    };
}
