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

  # GameMode: games (or `gamemoderun %command%` in Steam launch options)
  # request CPU governor/priority tweaks while running.
  programs.gamemode.enable = true;
}
