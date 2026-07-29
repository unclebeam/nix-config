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
  # home/hypr/local/outputs.lua — only Steam reads it, so it's harmless
  # session-wide. This module is PC-only (the ThinkPad import is commented),
  # so the hardcoded 1.5 always matches this host.
  environment.sessionVariables.STEAM_FORCE_DESKTOPUI_SCALING = "1.5";

  # GameMode: games (or `gamemoderun %command%` in Steam launch options)
  # request CPU governor/priority tweaks while running.
  programs.gamemode.enable = true;

  # ── HDR gaming — nothing to configure here; it's per-game launch options ──
  # The whole stack below Steam is already HDR-ready with zero config:
  #   - Both PC monitors advertise real HDR in their EDIDs (SMPTE ST2084/PQ +
  #     BT2020, ~460 nits — DisplayHDR-400 class). Verified 2026-07-25 via
  #     `edid-decode /sys/class/drm/card1-DP-{1,2}/edid`.
  #   - Hyprland 0.55's defaults do the rest: render:cm_enabled is on, and
  #     render:cm_auto_hdr = 1 flips a monitor into HDR only while a
  #     fullscreen HDR surface is presented, then back to SDR. That's exactly
  #     what we want on ~460-nit panels: the desktop STAYS SDR (always-on HDR
  #     looks washed out at this brightness), games get HDR for free.
  # The one missing link is the game itself: a Proton game only presents an
  # HDR Wayland surface when it runs Proton's Wayland driver with HDR on.
  # That's deliberately opt-in PER GAME, not a global env var here — the
  # Wayland driver still regresses a few titles (cursor grabs, alt-tab), so
  # flipping every Proton game at once trades known-good defaults for bugs.
  # To enable HDR for a game — GE-PROTON IS REQUIRED, not Valve's builds:
  # Valve's Proton Experimental 11 silently IGNORES PROTON_ENABLE_WAYLAND
  # (verified 2026-07-25: zero references in experimental-11.0-20260713's
  # script and binaries; GE-Proton 11-1 handles it). On a Valve build the
  # game falls back to XWayland and HDR can never engage — the symptom is a
  # grey, washed-out picture when the game's own HDR setting is on (HDR
  # output squashed into an SDR pipeline). So, per game in Steam:
  #   Properties → Compatibility → force GE-Proton, then Launch Options:
  #     PROTON_ENABLE_WAYLAND=1 PROTON_ENABLE_HDR=1 %command%
  #   then turn HDR on in the game's own video settings.
  # One more trap: cm_auto_hdr only fires on a COMPOSITOR-fullscreen window.
  # Games with only borderless/windowed modes need Super+Shift+F (the real
  # fullscreen toggle in home/hypr/binds.lua; Super+F is merely "maximized"
  # and does not count).
  # Verify it took: while the game is fullscreen, `hyprctl monitors -j` shows
  # the output's color preset leave "srgb". If it never flips, the fallback
  # is forcing the monitor to HDR via hl.monitor options (bitdepth/cm/
  # sdrbrightness) in the machine-local home/hypr/local/outputs.lua —
  # hand-maintained there, never in Nix.
}
