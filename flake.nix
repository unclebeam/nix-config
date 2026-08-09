{
  # A flake has two halves: `inputs` (what we pull in, pinned in flake.lock)
  # and `outputs` (what this repo provides — here, two NixOS system configs).
  description = "unclebeam's NixOS machines: desktop (PC) + ThinkPad";

  inputs = {
    # NixOS 26.05 "Yarara" — the current stable release branch.
    # `nix flake update` later moves the pin forward within this branch.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    # A SECOND nixpkgs tracking unstable. Used ONLY to source a curated set of
    # fast-moving packages (claude-code, lazygit, starship, brave,
    # google-chrome, slack — and, since this branch, hyprland itself plus its
    # xdg-desktop-portal-hyprland, pinned as a PAIR in modules/hyprland.nix;
    # grep for `pkgs-unstable.` to enumerate; the share-picker input below
    # also follows it). So this is no longer only leaf apps: the compositor
    # rides unstable too, because 0.55 was the first release of the Lua config
    # the whole desktop is built on and stable freezes it for six months.
    # Everything else stays on nixos-26.05. Deliberately NOT `follows` nixpkgs —
    # it must be its own package set, or those packages would rebuild against
    # 26.05 deps and defeat the purpose. mkHost instantiates it once (with
    # allowUnfree) and hands it to every module as `pkgs-unstable`.
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    # home-manager manages per-user config (dotfiles, hyprland config, alacritty…).
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

    # Noctalia v5 — the native desktop shell that IS the whole desktop: bar,
    # launcher, notifications, lock screen, idle policy, OSD, clipboard
    # history, polkit agent, power menu, wallpaper + its own wallpaper-derived
    # theming engine (replaced DMS 2026-07). v5 is a ground-up C++ rewrite —
    # nixpkgs' `noctalia-shell` package is the OLD v4 Quickshell app and must
    # never be substituted for this input. The flake ships a NixOS module and
    # a home-manager module; we use the NixOS module only (enabled in
    # modules/noctalia.nix; home/noctalia.nix holds only user-side glue, no
    # module import).
    #
    # Deliberately NO `inputs.nixpkgs.follows` here (and on the greeter
    # below), unlike every other input: noctalia.cachix.org only caches the
    # build against upstream's own nixpkgs pin — following ours would change
    # the derivation hash and silently recompile the whole C++ shell from
    # source on every machine. The cache substituter/key live in
    # modules/noctalia.nix. The cost is a second nixpkgs closure in the
    # lock, which is exactly the trade the binary cache pays for.
    noctalia = {
      url = "github:noctalia-dev/noctalia";
    };

    # The matching login greeter (greetd UI) — a separate upstream project
    # with its own flake. Same no-follows reasoning as the shell above.
    # Enabled in modules/noctalia-greeter.nix.
    noctalia-greeter = {
      url = "github:noctalia-dev/noctalia-greeter";
    };

    # hyprland-preview-share-picker — an alternative xdph screen-share picker
    # that shows live window/monitor THUMBNAILS before you pick (the default
    # hyprland-share-picker is a flat Qt title list with no visuals). Rust +
    # GTK4. Not in nixpkgs; it ships ONLY a package (no NixOS module), so —
    # exactly like zen-browser above — nothing wires into mkHost;
    # home/hyprland.nix pulls the package straight out of `inputs` and points
    # xdph's screencopy:custom_picker_binary at it.
    #
    # It follows nixpkgs-unstable, NOT our 26.05 nixpkgs: 26.05's rustc SIGABRTs
    # (`double free or corruption`) compiling this picker's `unsafe-libyaml`
    # dependency, while unstable's newer rustc builds it cleanly. This is
    # exactly what the curated nixpkgs-unstable input exists for (a fast-moving
    # package that stable can't build) — and following it reuses an input we
    # already evaluate rather than pulling a third nixpkgs.
    #
    # Fetched via the git+https scheme (NOT `github:`) with `?submodules=1`:
    # the repo vendors git submodules, and this Nix rejects the `submodules`
    # attribute under the github scheme (`not supported by scheme 'github'` on
    # any re-lock) — the git scheme accepts it as a query param and pulls the
    # submodules the build needs.
    hyprland-preview-share-picker = {
      url = "git+https://github.com/WhySoBad/hyprland-preview-share-picker?submodules=1";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-unstable,
      home-manager,
      disko,
      noctalia,
      noctalia-greeter,
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

            # Noctalia's NixOS modules. Same deal as disko: loading them only
            # adds options. The shell module (programs.noctalia) is enabled
            # by modules/noctalia.nix; the greeter module (greetd + Noctalia
            # greeter UI) is enabled by modules/noctalia-greeter.nix.
            noctalia.nixosModules.default
            noctalia-greeter.nixosModules.default

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
              # etc. pull individual packages from unstable, and any future
              # home/ module that imports out of `inputs` needs it here —
              # module imports can only come from specialArgs, not ordinary
              # args.
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
