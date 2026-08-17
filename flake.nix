{
  # A flake has two halves: `inputs` (what we pull in, pinned in flake.lock)
  # and `outputs` (what this repo provides — here, two NixOS system configs).
  description = "unclebeam's NixOS machines: desktop (PC) + ThinkPad";

  inputs = {
    # NixOS 26.05 "Yarara" — the current stable release branch.
    # `nix flake update` later moves the pin forward within this branch.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    # A SECOND nixpkgs tracking unstable. Used ONLY to source a curated set of
    # fast-moving LEAF packages (claude-code, lazygit, starship, brave,
    # google-chrome, vscode, slack — grep for `pkgs-unstable.` to enumerate).
    # The compositor no longer rides unstable: that was a hyprland-era
    # exception (0.55's brand-new Lua config), and niri 26.04 in nixos-26.05
    # is current. Everything else stays on nixos-26.05.
    # Deliberately NOT `follows` nixpkgs —
    # it must be its own package set, or those packages would rebuild against
    # 26.05 deps and defeat the purpose. mkHost instantiates it once (with
    # allowUnfree) and hands it to every module as `pkgs-unstable`.
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    # home-manager manages per-user config (dotfiles, niri config, alacritty…).
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

    # nix-flatpak — declarative flatpak remotes + apps. This input exists for
    # exactly ONE app: OrcaSlicer, which cannot be a Nix package here because
    # the nixpkgs build aborts the moment Bambu's proprietary network plugin
    # loads (two libstdc++ copies in one process — the whole story, with the
    # backtrace, is in modules/orca-slicer.nix). The Flathub build is fine.
    #
    # It is needed because nixpkgs' own `services.flatpak` has ONLY `enable` —
    # no way to declare a remote or an app — which would have made installing
    # the slicer a manual step on each machine. This input extends that same
    # `services.flatpak` namespace with `remotes`/`packages`/`update`.
    #
    # Pinned to a release tag rather than a moving branch: it runs privileged
    # activation-time commands, so it should only move when we say so.
    # If OrcaSlicer ever goes back to being a Nix package, this input and the
    # flatpak service in modules/orca-slicer.nix are deleted together.
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
      noctalia,
      noctalia-greeter,
      nix-flatpak,
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

            # nix-flatpak's NixOS module. Same deal again: loading it only
            # extends `services.flatpak` with declarative remotes/packages.
            # modules/orca-slicer.nix is the one place that enables it — and
            # the only reason flatpak exists in this config at all.
            nix-flatpak.nixosModules.nix-flatpak

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
