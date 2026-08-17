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

  # Steam's desktop UI is XWayland — under niri that means xwayland-satellite
  # (modules/niri.nix), which presents X11 clients unscaled. This env var
  # (the equivalent of Steam's `-forcedesktopscaling` launch flag) draws the
  # UI at 1.5x to match the monitor scale in home/niri/hosts/unclebeam-pc.kdl.
  # Only Steam reads it, so it's harmless session-wide; this module is
  # PC-only (the ThinkPad import is commented), so the hardcoded 1.5 always
  # matches this host. VERIFY on the first niri login: the hyprland-era
  # partner setting (xwayland force_zero_scaling) is gone, and if satellite's
  # scaling behavior makes the UI double-scale, drop this line.
  environment.sessionVariables.STEAM_FORCE_DESKTOPUI_SCALING = "1.5";

  # GameMode: games (or `gamemoderun %command%` in Steam launch options)
  # request CPU governor/priority tweaks while running.
  programs.gamemode.enable = true;

  # ── HDR gaming — PARKED: niri 26.04 has no HDR/color management ─────────
  # ("we don't support HDR or color management yet" — niri's own docs.) The
  # panels are ready (both PC monitors advertise SMPTE ST2084/PQ + BT2020,
  # ~460 nits, verified 2026-07-25 via edid-decode), and the hyprland era
  # had auto-HDR working (cm_auto_hdr + GE-Proton with
  # PROTON_ENABLE_WAYLAND=1 PROTON_ENABLE_HDR=1 — the recipe lives in git
  # history if needed). Accepted trade of the niri migration 2026-08:
  # games render SDR. Revisit when niri ships color management.
}
