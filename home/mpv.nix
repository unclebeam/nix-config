# home/mpv.nix — mpv, the video player and default video handler.
# One file per intent: everything that exists because of mpv lives here.
# Removing mpv = delete this file + its import line in default.nix (and give
# the video/* MIME defaults back to home/vlc.nix).
#
# Why a second player exists at all: mpv was brought in as the HDR-capable
# player (VLC can't speak wp_color_management_v1). That raison d'être is
# PARKED with the 2026-08 niri migration — niri has no color management
# yet, so HDR video tonemaps to SDR like everything else (the accepted
# trade, see modules/gaming.nix's HDR note) — but mpv stays the better
# player regardless: gpu-next rendering, VA-API 10-bit decode, and it's
# ready to light HDR back up the day niri ships CM (re-add
# target-colorspace-hint = "yes" below, plus the fullscreen caveat from
# git history).
{ config, lib, pkgs, ... }:

{
  programs.mpv = {
    enable = true;
    # Rendered to ~/.config/mpv/mpv.conf.
    config = {
      # gpu-next is the libplacebo-based output — best-quality scaling and
      # tonemapping, and the only vo that can hint colorspaces to the
      # compositor (which is what makes it HDR-ready for the day niri
      # supports it; that hint, target-colorspace-hint, is deliberately NOT
      # set today — with no compositor CM it does nothing). Vulkan Wayland
      # context to match.
      vo = "gpu-next";
      gpu-api = "vulkan";
      gpu-context = "waylandvk";
      # AMD VA-API hardware decode (HEVC/AV1, 10-bit) via mesa — no extra
      # packages needed, hardware.graphics.enable ships the driver.
      # auto-safe = only whitelisted-known-good methods, clean fallback to
      # software decode rather than artifacts.
      hwdec = "auto-safe";
    };
  };

  # Make double-clicking a video in Dolphin open mpv. Merges with the other
  # defaultApplications sets (xdg.mimeApps is enabled in home/default.nix;
  # don't re-set enable here). Video only — audio stays with VLC.
  xdg.mimeApps.defaultApplications = {
    "video/mp4" = "mpv.desktop";
    "video/x-matroska" = "mpv.desktop";
    "video/webm" = "mpv.desktop";
    "video/quicktime" = "mpv.desktop";
    "video/x-msvideo" = "mpv.desktop";
  };
}
