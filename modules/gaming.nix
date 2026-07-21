# gaming.nix — Steam + GameMode. Importing this module = enabling gaming.
# The PC imports it; the ThinkPad has a commented-out import ready to flip.
# (Requires allowUnfree, which core.nix already sets globally.)
{ config, lib, pkgs, ... }:

{
  programs.steam = {
    enable = true;
    # Steam's NixOS module brings its own FHS runtime and enables 32-bit
    # graphics automatically; Proton is included. The firewall openings are
    # opt-in niceties:
    remotePlay.openFirewall = true;              # stream games to other devices
    localNetworkGameTransfers.openFirewall = true; # LAN game-download sharing

    # GE-Proton alongside Valve's bundled Proton. Some games need a newer
    # Proton than Valve's stable channel ships — e.g. Monster Hunter Wilds'
    # model streaming (DirectStorage) breaks on older builds and leaves
    # models permanently low-poly. This only makes GE-Proton *selectable*
    # (per game: Properties → Compatibility); it forces nothing globally.
    extraCompatPackages = [ pkgs.proton-ge-bin ];
  };

  # Steam's desktop UI is XWayland; with force_zero_scaling on (home/hypr/
  # hyprland.lua) it renders at native pixels = sharp but tiny. This env var
  # (the equivalent of Steam's `-forcedesktopscaling` launch flag) restores
  # correct size by drawing the UI at 1.5x. MUST match the monitor scale in
  # home/hypr/dms/outputs.lua — only Steam reads it, so it's harmless session-
  # wide. This module is PC-only (the ThinkPad import is commented), so the
  # hardcoded 1.5 always matches this host.
  environment.sessionVariables.STEAM_FORCE_DESKTOPUI_SCALING = "1.5";

  # GameMode: games (or `gamemoderun %command%` in Steam launch options)
  # request CPU governor/priority tweaks while running.
  programs.gamemode.enable = true;
}
