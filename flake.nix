{
  # A flake has two halves: `inputs` (what we pull in, pinned in flake.lock)
  # and `outputs` (what this repo provides — here, two NixOS system configs).
  description = "unclebeam's NixOS machines: desktop (PC) + ThinkPad";

  inputs = {
    # NixOS 26.05 "Yarara" — the current stable release branch.
    # `nix flake update` later moves the pin forward within this branch.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    # home-manager manages per-user config (dotfiles, sway config, waybar css…).
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
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      disko,
      ...
    }@inputs:
    let
      # Small helper so each host is a one-liner below.
      # `nixosSystem` evaluates a list of modules into a bootable system.
      mkHost =
        hostName:
        nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          # Everything in specialArgs is passed as an argument to every module,
          # so modules can refer to `inputs` if they ever need another flake.
          specialArgs = { inherit inputs; };
          modules = [
            # The per-host entrypoint. Everything else is imported from there —
            # this keeps the flake itself boring and the hosts/ dirs in charge.
            ./hosts/${hostName}

            # disko's NixOS module. Loading it only ADDS the `disko.devices`
            # option — it does nothing until a host actually declares disks.
            # Both hosts do, in hosts/<name>/disko.nix.
            disko.nixosModules.disko

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

      # Per-project toolchains, activated by direnv: a work repo gets an
      # UNTRACKED one-line `.envrc` — e.g. `use flake ~/nix-config#node22` —
      # (hidden from teammates via .git/info/exclude), so the project itself
      # stays Nix-free while direnv (home/direnv.nix) drops the right tool
      # versions onto PATH whenever you cd in, shadowing the globals from
      # core.nix. Each shell's package set is pinned by THIS flake's lock.
      devShells.x86_64-linux =
        let
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
        in
        {
          # cricslabs-co/bdi: .nvmrc says lts/jod (22), engines >=22.12.
          # nodejs_22 bundles its own npm, which shadows the global one too.
          node22 = pkgs.mkShell { packages = [ pkgs.nodejs_22 ]; };
        };
    };
}
