# core.nix — everything both machines need regardless of desktop or role:
# nix itself, boot loader, networking, the user account, and baseline CLI tools.
{
  config,
  lib,
  pkgs,
  pkgs-unstable,
  ...
}:

{
  # ── Nix ────────────────────────────────────────────────────────────────
  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    trusted-users = [
      "root"
      "@wheel"
    ];
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  # With home-manager.useGlobalPkgs this applies to user packages too.
  nixpkgs.config.allowUnfree = true;

  # ── Boot ───────────────────────────────────────────────────────────────
  # Lives here, not hardware-configuration.nix: nixos-generate-config doesn't
  # emit boot loader settings, so regenerating that file can't drop them.
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 10; # keep /boot from filling up
  boot.loader.efi.canTouchEfiVariables = true;

  # Keep err-level kernel chatter off the console (a flaky USB hub spams it);
  # everything still lands in the journal.
  boot.consoleLogLevel = 3;

  # ── Networking ─────────────────────────────────────────────────────────
  networking.networkmanager.enable = true;

  # iwd instead of wpa_supplicant: the PC's MT7925 intermittently times out
  # the 4-way handshake at cold boot, which wpa_supplicant surfaces as
  # "wrong password" — pre-login there's no secret agent, so NM failed the
  # connect and later re-prompted for a correct on-disk PSK. iwd retries
  # handshakes internally. NM stays the manager (profiles, nmcli, IP config
  # all unchanged); iwd only replaces the supplicant.
  networking.networkmanager.wifi.backend = "iwd";

  # ── Locale / time ──────────────────────────────────────────────────────
  time.timeZone = "Asia/Bangkok";
  i18n.defaultLocale = "en_US.UTF-8";

  # ── User ───────────────────────────────────────────────────────────────
  # System-wide enable makes fish a legal login shell (/etc/shells).
  programs.fish.enable = true;

  users.users.unclebeam = {
    isNormalUser = true;
    description = "unclebeam";
    extraGroups = [
      "wheel" # sudo
      "networkmanager" # manage connections without a password prompt
      "video" # backlight control on the laptop
    ];
    shell = pkgs.fish;
    # First-login password ("changeme") — change immediately with `passwd`.
    # Hashed so the literal doesn't land in the world-readable store. NB:
    # `passwd` does NOT re-key the login keyring — change it in Seahorse too
    # (modules/gnome-keyring.nix).
    initialHashedPassword = "$6$CwzSz2CEk36YeqZ9$jwZf/3qbXcSzqvX2ymARckGqeoxpcT5sBc801REF0PnlHI9u2CDoluoH3d3zqwrhQNdlR6dQp4wWOOeGsqrjE1";
  };

  # ── Baseline packages ──────────────────────────────────────────────────
  # Config-less system-wide tools; apps with per-user config live in home/.
  environment.systemPackages = with pkgs; [
    fastfetch
    fzf
    ripgrep
    fd
    pkgs-unstable.lazygit # fast-moving; tracks unstable
    git
    wget
    curl
    # Whatever nixpkgs calls "latest" at each flake update; projects needing a
    # specific version shadow it via direnv dev shells (home/direnv.nix).
    nodejs_latest
    # No global python3 on purpose: uv downloads per-project interpreters
    # (plain FHS binaries — they run because of modules/nix-ld.nix), and a
    # global one would just be a wrong kernel for notebooks to pick.
    uv
    obsidian
    pkgs-unstable.slack # fast-moving; tracks unstable
    # Discord via Vesktop: stock discord can't screenshare on Wayland; Vesktop
    # captures through the portal ScreenCast path.
    vesktop
    # nixpkgs only carries the upstream binary release; no from-source attr.
    dbeaver-bin
  ];
}
