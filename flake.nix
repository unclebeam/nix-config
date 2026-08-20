{
  description = "unclebeam's NixOS machines: desktop (PC) + ThinkPad";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    # Second package set for fast-moving leaf apps only (grep `pkgs-unstable.`).
    # Deliberately NOT `follows` — it must stay its own set, or those packages
    # would rebuild against 26.05 deps and defeat the purpose.
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      # Release branch must match the nixpkgs release.
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Declarative disk layout (hosts/<name>/disko.nix): nixos-anywhere uses it
    # to wipe+format, NixOS reuses it for fileSystems.* mounts.
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # DMS desktop shell. Input is mandatory (nixpkgs' dms-shell is too old);
    # /stable = latest release tag. `follows` is right here: quickshell comes
    # prebuilt from cache.nixos.org via our nixpkgs, only the Go daemon builds.
    # NixOS modules only — never the flake's homeModules (the niri one takes
    # over our config.kdl symlink).
    # Update caveat: upstream 1.6 moves the greeter to a separate dank-greeter
    # repo — that bump needs its own input and a new option namespace in
    # modules/dms-greeter.nix.
    dank-material-shell = {
      url = "github:AvengeMedia/DankMaterialShell/stable";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Declarative flatpak remotes/apps — nixpkgs' services.flatpak has only
    # `enable`. Exists for exactly two apps (reasons in modules/flatpak.nix,
    # orca-slicer.nix, rustdesk.nix); dies with modules/flatpak.nix.
    # Pinned to a tag: it runs privileged activation-time commands.
    nix-flatpak = {
      url = "github:gmodena/nix-flatpak/?ref=v0.7.0";
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
      nix-flatpak,
      ...
    }@inputs:
    let
      mkHost =
        hostName:
        let
          system = "x86_64-linux";
          # Evaluated once, with allowUnfree; handed to every module (system and
          # home) as `pkgs-unstable`.
          pkgs-unstable = import nixpkgs-unstable {
            inherit system;
            config.allowUnfree = true;
          };
        in
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs pkgs-unstable; };
          modules = [
            # Per-host entrypoint; everything else is imported from there.
            ./hosts/${hostName}

            # These only add options — hosts/modules do the enabling.
            disko.nixosModules.disko
            dank-material-shell.nixosModules.dank-material-shell
            dank-material-shell.nixosModules.greeter
            nix-flatpak.nixosModules.nix-flatpak

            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.unclebeam = import ./home;
              # Keep a conflicting dotfile as <name>.backup instead of aborting
              # the switch.
              home-manager.backupFileExtension = "backup";
              # Module imports can only come from specialArgs, hence the mirror.
              home-manager.extraSpecialArgs = { inherit inputs pkgs-unstable; };
            }
          ];
        };
    in
    {
      # Attribute names must equal each machine's networking.hostName — that's
      # what makes a bare `--flake .` rebuild pick the right config.
      nixosConfigurations = {
        unclebeam-pc = mkHost "unclebeam-pc";
        unclebeam-thinkpad = mkHost "unclebeam-thinkpad";
      };
    };
}
