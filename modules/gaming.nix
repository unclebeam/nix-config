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
  };

  # GameMode: games (or `gamemoderun %command%` in Steam launch options)
  # request CPU governor/priority tweaks while running.
  programs.gamemode.enable = true;
}
