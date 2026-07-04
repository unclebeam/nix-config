# core.nix — everything both machines need regardless of desktop or role:
# nix itself, boot loader, networking, the user account, and baseline CLI tools.
{ config, lib, pkgs, ... }:

{
  # ── Nix ────────────────────────────────────────────────────────────────
  nix.settings = {
    # Flakes are still technically "experimental" but are the standard now.
    experimental-features = [ "nix-command" "flakes" ];
    # Let wheel users (you) use substituters, run privileged nix commands.
    trusted-users = [ "root" "@wheel" ];
  };

  # Reclaim disk space from old generations automatically.
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  # Needed for Steam and friends. With home-manager.useGlobalPkgs this
  # applies to user packages too.
  nixpkgs.config.allowUnfree = true;

  # ── Boot ───────────────────────────────────────────────────────────────
  # Both machines are modern UEFI boxes. This lives here (not in
  # hardware-configuration.nix) because nixos-generate-config does not emit
  # boot loader settings — keeping it here means replacing the hardware file
  # during install can't accidentally drop the boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 10; # keep /boot from filling up
  boot.loader.efi.canTouchEfiVariables = true;

  # ── Networking ─────────────────────────────────────────────────────────
  # NetworkManager handles wifi + ethernet on both machines.
  # CLI: `nmcli device wifi connect <ssid> --ask`, or `nmtui` for a TUI.
  networking.networkmanager.enable = true;

  # ── Locale / time ──────────────────────────────────────────────────────
  time.timeZone = "Asia/Bangkok";
  i18n.defaultLocale = "en_US.UTF-8";

  # ── User ───────────────────────────────────────────────────────────────
  # fish must be enabled system-wide to be a legal login shell
  # (it registers itself in /etc/shells and wires up completions).
  programs.fish.enable = true;

  users.users.unclebeam = {
    isNormalUser = true;
    description = "unclebeam";
    extraGroups = [
      "wheel"          # sudo
      "networkmanager" # manage connections without a password prompt
      "video"          # backlight control on the laptop
    ];
    shell = pkgs.fish;
    # First-login password — CHANGE IT immediately after install with `passwd`.
    # (nixos-install also asks for the root password interactively.)
    initialPassword = "changeme";
  };

  # ── Baseline packages ──────────────────────────────────────────────────
  # System-wide CLI + the browser. Desktop apps with per-user *config*
  # (alacritty, waybar…) live in home/ instead; these are config-less here.
  environment.systemPackages = with pkgs; [
    fastfetch
    lazygit
    git
    neovim # package only — config/plugins/LSPs are managed by hand, not Nix
    brave  # Chromium-based; runs native Wayland via NIXOS_OZONE_WL (modules/sway.nix)
    wget
    curl
    firefox
  ];
}
