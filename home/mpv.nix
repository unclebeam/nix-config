# home/mpv.nix — mpv, the HDR-capable video player and default video handler.
# One file per intent: everything that exists because of mpv lives here.
# Removing mpv = delete this file + its import line in default.nix (and give
# the video/* MIME defaults back to home/vlc.nix).
#
# Why a second player exists at all: VLC (home/vlc.nix) has no Wayland HDR
# output — it can't speak wp_color_management_v1, so HDR movies get crushed
# to SDR. mpv's gpu-next output can, which makes it the player that actually
# lights up the AW2725Q's HDR mode. The compositor half of the story is
# documented in modules/gaming.nix's HDR block: Hyprland's render:cm_auto_hdr
# flips a monitor into HDR only while a COMPOSITOR-fullscreen HDR surface is
# up — so press `f` in mpv; a maximized window doesn't count. Verify with
# `hyprctl monitors -j` (the AW2725Q's colorManagementPreset changes while
# fullscreen) and mpv's Shift+i stats page.
{ config, lib, pkgs, ... }:

{
  programs.mpv = {
    enable = true;
    # Rendered to ~/.config/mpv/mpv.conf.
    config = {
      # HDR passthrough needs all four of these together: gpu-next is the
      # libplacebo-based output (the old `gpu` vo can't hint colorspaces),
      # a Vulkan Wayland context is the path that carries the color
      # management protocol, and target-colorspace-hint forwards the
      # video's own colorimetry (PQ/BT.2020) to the compositor instead of
      # tonemapping it down to SDR in the player. Without the hint,
      # Hyprland never sees an HDR surface and cm_auto_hdr never fires.
      vo = "gpu-next";
      gpu-api = "vulkan";
      gpu-context = "waylandvk";
      target-colorspace-hint = "yes";
      # AMD VA-API hardware decode (HEVC/AV1, 10-bit) via mesa — no extra
      # packages needed, hardware.graphics.enable ships the driver.
      # auto-safe = only whitelisted-known-good methods, clean fallback to
      # software decode rather than artifacts.
      hwdec = "auto-safe";
    };
  };

  # Make double-clicking a video in Dolphin open mpv. Merges with the other
  # defaultApplications sets (xdg.mimeApps is enabled in home/dolphin.nix;
  # don't re-set enable here). Video only — audio stays with VLC.
  xdg.mimeApps.defaultApplications = {
    "video/mp4" = "mpv.desktop";
    "video/x-matroska" = "mpv.desktop";
    "video/webm" = "mpv.desktop";
    "video/quicktime" = "mpv.desktop";
    "video/x-msvideo" = "mpv.desktop";
  };
}
