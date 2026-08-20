# gaming.nix — Steam + GameMode. Importing this module = enabling gaming.
# PC-only; the ThinkPad has a commented-out import ready to flip.
{ config, lib, pkgs, ... }:

{
  programs.steam = {
    enable = true;
    # The module brings its own FHS runtime and 32-bit graphics; Proton
    # included. Firewall openings are opt-in niceties:
    remotePlay.openFirewall = true;              # stream games to other devices
    localNetworkGameTransfers.openFirewall = true; # LAN game-download sharing

    # GE-Proton selectable per game (Properties → Compatibility) — some games
    # need a newer Proton than Valve's stable ships. Forces nothing globally.
    extraCompatPackages = [ pkgs.proton-ge-bin ];
  };

  # Steam's UI is XWayland, which xwayland-satellite presents unscaled; this
  # draws it at 1.5x to match the DMS-set monitor scale. Only Steam reads it,
  # and this module is PC-only so the hardcoded 1.5 always matches. If the UI
  # ever double-scales, drop this line.
  environment.sessionVariables.STEAM_FORCE_DESKTOPUI_SCALING = "1.5";

  # Games (or `gamemoderun %command%`) request CPU governor/priority tweaks.
  programs.gamemode.enable = true;

  # HDR is PARKED: niri has no color management yet; games render SDR.
  # Don't re-add HDR plumbing until it ships.
}
